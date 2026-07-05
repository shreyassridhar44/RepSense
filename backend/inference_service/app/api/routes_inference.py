from fastapi import APIRouter
from app.api.schemas import (
    AnalyzeSequenceRequest,
    AnalyzeSequenceResponse,
    RepResultOut,
    FormIssueOut,
)
from app.ml.joint_angles import compute_joint_angles, Landmark
from app.ml.rep_counter import RepCounter
from app.ml.biomechanics import analyze_rep

router = APIRouter(prefix="/inference", tags=["inference"])


@router.post("/analyze-sequence", response_model=AnalyzeSequenceResponse)
async def analyze_sequence(payload: AnalyzeSequenceRequest):
    """Accepts a full sequence of pose-landmark frames captured on-device
    (mobile client runs ML Kit / MediaPipe locally and streams structured
    landmarks here — not raw video — keeping payloads small and fast).

    Pipeline: Joint Angle Engine -> Rep Counter (phase-based) ->
    Biomechanics Engine (per-rep scoring + explainable issues).
    """
    counter = RepCounter(payload.exercise)
    all_rep_results: list[RepResultOut] = []
    current_rep_angles: list[dict[str, float]] = []

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
            current_rep_angles = []

    avg_score = (
        round(sum(r.overall_score for r in all_rep_results) / len(all_rep_results), 1)
        if all_rep_results
        else 0.0
    )

    return AnalyzeSequenceResponse(
        exercise=payload.exercise,
        total_reps=counter.reps,
        reps=all_rep_results,
        avg_score=avg_score,
    )
