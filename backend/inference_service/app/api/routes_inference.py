from fastapi import APIRouter, HTTPException
import logging
import time
from collections import Counter
from app.api.schemas import (
    AnalyzeSequenceRequest,
    AnalyzeSequenceResponse,
    AnalyzeAnglesRequest,
    AnalyzeAnglesResponse,
    RepResultOut,
    FormIssueOut,
    ScoresBreakdown,
)
from app.ml.joint_angles import compute_joint_angles, Landmark
from app.ml.rep_counter import RepCounter
from app.ml.biomechanics import analyze_rep

router = APIRouter(prefix="/inference", tags=["inference"])
logger = logging.getLogger(__name__)

# Valid exercise IDs
VALID_EXERCISES = {
    'squat', 'deadlift', 'bench-press', 'push-up', 'pull-up', 'overhead-press',
    'lunges', 'bicep-curl', 'tricep-extension', 'rows', 'lat-pulldown',
    'leg-press', 'plank', 'shoulder-press'
}


@router.post("/analyze-sequence", response_model=AnalyzeSequenceResponse)
async def analyze_sequence(payload: AnalyzeSequenceRequest):
    """Accepts a full sequence of pose-landmark frames captured on-device
    (mobile client runs ML Kit / MediaPipe locally and streams structured
    landmarks here — not raw video — keeping payloads small and fast).

    Pipeline: Joint Angle Engine -> Rep Counter (phase-based) ->
    Biomechanics Engine (per-rep scoring + explainable issues).
    """
    start_time = time.time()
    
    counter = RepCounter(payload.exercise)
    all_rep_results: list[RepResultOut] = []
    current_rep_angles: list[dict[str, float]] = []
    all_issues = []

    for frame in payload.frames:
        landmarks = [Landmark(p.x, p.y, p.z, p.visibility) for p in frame.landmarks]
        angles = compute_joint_angles(landmarks)
        current_rep_angles.append(angles)

        completed = counter.update(angles)
        if completed:
            analysis = analyze_rep(current_rep_angles, payload.exercise)
            all_rep_results.append(
                RepResultOut(
                    rep_index=len(all_rep_results) + 1,
                    overall_score=analysis.overall_score,
                    scores=analysis.scores,
                    issues=[FormIssueOut(**vars(i)) for i in analysis.issues],
                )
            )
            all_issues.extend(analysis.issues)
            current_rep_angles = []

    avg_score = (
        round(sum(r.overall_score for r in all_rep_results) / len(all_rep_results), 1)
        if all_rep_results
        else 0.0
    )
    
    # Compute aggregate scores
    scores_breakdown = _compute_scores_breakdown(all_rep_results)
    
    # Get top 3 issues
    top_issues = _get_top_issues(all_issues)
    
    # Build coaching summary
    coaching_summary = _build_coaching_summary(
        payload.exercise, counter.reps, avg_score, top_issues, all_rep_results
    )
    
    processing_time = time.time() - start_time
    logger.info(
        f"Analyzed {payload.exercise}: {counter.reps} reps, "
        f"avg score: {avg_score}, processing time: {processing_time:.2f}s"
    )

    return AnalyzeSequenceResponse(
        exercise=payload.exercise,
        total_reps=counter.reps,
        reps=all_rep_results,
        avg_score=avg_score,
        scores_breakdown=scores_breakdown,
        top_issues=top_issues,
        coaching_summary=coaching_summary,
    )


@router.post("/analyze-angles", response_model=AnalyzeAnglesResponse)
async def analyze_angles(payload: AnalyzeAnglesRequest):
    """Accepts pre-computed joint angles from mobile device.
    Mobile already runs JointAngleEngine, so we receive angles directly.
    This avoids redundant data and keeps payloads small.
    
    Pipeline: Rep Counter (phase-based) -> Biomechanics Engine (per-rep scoring).
    """
    start_time = time.time()
    
    # Validate exercise ID
    if payload.exercise.lower() not in VALID_EXERCISES:
        raise HTTPException(
            status_code=422,
            detail=f"Exercise '{payload.exercise}' not recognized. Valid exercises: {', '.join(sorted(VALID_EXERCISES))}"
        )
    
    # Handle empty frames
    if not payload.frames_angles:
        logger.warning(f"Empty frames_angles received for exercise: {payload.exercise}")
        return AnalyzeAnglesResponse(
            exercise=payload.exercise,
            total_reps=0,
            reps=[],
            avg_score=0.0,
            scores_breakdown=ScoresBreakdown(
                range_of_motion=0.0,
                symmetry=0.0,
                stability=0.0,
                tempo=0.0,
                lockout=0.0,
                overall=0.0,
            ),
            top_issues=[],
            coaching_summary="No data captured. Please try again.",
        )
    
    # Subsample if too many frames (>3000)
    frames_angles = payload.frames_angles
    if len(frames_angles) > 3000:
        logger.info(f"Subsampling {len(frames_angles)} frames to 1000")
        step = len(frames_angles) / 1000
        frames_angles = [frames_angles[int(i * step)] for i in range(1000)]
    
    counter = RepCounter(payload.exercise)
    all_rep_results: list[RepResultOut] = []
    current_rep_angles: list[dict[str, float]] = []
    all_issues = []

    for angles in frames_angles:
        current_rep_angles.append(angles)
        
        completed = counter.update(angles)
        if completed:
            analysis = analyze_rep(current_rep_angles, payload.exercise)
            all_rep_results.append(
                RepResultOut(
                    rep_index=len(all_rep_results) + 1,
                    overall_score=analysis.overall_score,
                    scores=analysis.scores,
                    issues=[FormIssueOut(**vars(i)) for i in analysis.issues],
                )
            )
            all_issues.extend(analysis.issues)
            current_rep_angles = []

    # Cross-validate with mobile rep count
    server_reps = counter.reps
    mobile_reps = payload.total_reps_mobile
    if abs(server_reps - mobile_reps) > 2:
        logger.warning(
            f"Rep count mismatch: server={server_reps}, mobile={mobile_reps}. "
            f"Trusting mobile count (higher temporal resolution)."
        )
        # Trust mobile count but use server analysis
        server_reps = mobile_reps

    avg_score = (
        round(sum(r.overall_score for r in all_rep_results) / len(all_rep_results), 1)
        if all_rep_results
        else 0.0
    )
    
    # Compute aggregate scores
    scores_breakdown = _compute_scores_breakdown(all_rep_results)
    
    # Get top 3 issues
    top_issues = _get_top_issues(all_issues)
    
    # Build coaching summary
    coaching_summary = _build_coaching_summary(
        payload.exercise, server_reps, avg_score, top_issues, all_rep_results
    )
    
    processing_time = time.time() - start_time
    logger.info(
        f"Analyzed {payload.exercise}: {server_reps} reps, "
        f"avg score: {avg_score}, processing time: {processing_time:.2f}s"
    )

    return AnalyzeAnglesResponse(
        exercise=payload.exercise,
        total_reps=server_reps,
        reps=all_rep_results,
        avg_score=avg_score,
        scores_breakdown=scores_breakdown,
        top_issues=top_issues,
        coaching_summary=coaching_summary,
    )


def _compute_scores_breakdown(reps: list[RepResultOut]) -> ScoresBreakdown:
    """Compute average scores across all reps"""
    if not reps:
        return ScoresBreakdown(
            range_of_motion=0.0,
            symmetry=0.0,
            stability=0.0,
            tempo=0.0,
            lockout=0.0,
            overall=0.0,
        )
    
    rom = sum(r.scores.get('range_of_motion', 0) for r in reps) / len(reps)
    symmetry = sum(r.scores.get('symmetry', 0) for r in reps) / len(reps)
    stability = sum(r.scores.get('stability', 0) for r in reps) / len(reps)
    tempo = sum(r.scores.get('tempo', 0) for r in reps) / len(reps)
    lockout = sum(r.scores.get('lockout', 0) for r in reps) / len(reps)
    overall = (rom + symmetry + stability + tempo + lockout) / 5
    
    return ScoresBreakdown(
        range_of_motion=round(rom, 1),
        symmetry=round(symmetry, 1),
        stability=round(stability, 1),
        tempo=round(tempo, 1),
        lockout=round(lockout, 1),
        overall=round(overall, 1),
    )


def _get_top_issues(all_issues: list) -> list[FormIssueOut]:
    """Get top 3 most frequent issues"""
    if not all_issues:
        return []
    
    # Count occurrences of each problem
    problem_counts = Counter(issue.problem for issue in all_issues)
    
    # Get top 3
    top_problems = problem_counts.most_common(3)
    
    # Find representative issue for each top problem
    top_issues = []
    for problem, _ in top_problems:
        issue = next(i for i in all_issues if i.problem == problem)
        top_issues.append(FormIssueOut(**vars(issue)))
    
    return top_issues


def _build_coaching_summary(
    exercise: str,
    reps: int,
    avg_score: float,
    top_issues: list[FormIssueOut],
    rep_results: list[RepResultOut],
) -> str:
    """Build structured summary for LLM coach"""
    issues_str = ", ".join(i.problem for i in top_issues) if top_issues else "None"
    scores_str = ", ".join(f"Rep {r.rep_index}: {r.overall_score}" for r in rep_results[:5])
    if len(rep_results) > 5:
        scores_str += f", ... ({len(rep_results)} total)"
    
    return (
        f"Exercise: {exercise}. "
        f"Reps: {reps}. "
        f"Avg score: {avg_score}/100. "
        f"Top issues: {issues_str}. "
        f"Per-rep scores: {scores_str}."
    )
