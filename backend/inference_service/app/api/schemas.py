from pydantic import BaseModel


class LandmarkIn(BaseModel):
    x: float
    y: float
    z: float = 0.0
    visibility: float = 1.0


class FrameIn(BaseModel):
    landmarks: list[LandmarkIn]  # 33 MediaPipe pose landmarks


class AnalyzeSequenceRequest(BaseModel):
    exercise: str
    frames: list[FrameIn]  # ordered sequence of frames for one set


class FormIssueOut(BaseModel):
    problem: str
    reason: str
    correction: str
    confidence: float
    severity: str


class RepResultOut(BaseModel):
    rep_index: int
    overall_score: float
    scores: dict[str, float]
    issues: list[FormIssueOut]


class ScoresBreakdown(BaseModel):
    range_of_motion: float
    symmetry: float
    stability: float
    tempo: float
    lockout: float
    overall: float


class AnalyzeSequenceResponse(BaseModel):
    exercise: str
    total_reps: int
    reps: list[RepResultOut]
    avg_score: float
    scores_breakdown: ScoresBreakdown
    top_issues: list[FormIssueOut]
    coaching_summary: str


# New schemas for angle-based analysis
class AnalyzeAnglesRequest(BaseModel):
    exercise: str
    frames_angles: list[dict[str, float]]  # Pre-computed angles from mobile
    duration_seconds: int
    total_reps_mobile: int
    rep_quality_mobile: list[bool]


class AnalyzeAnglesResponse(BaseModel):
    exercise: str
    total_reps: int
    reps: list[RepResultOut]
    avg_score: float
    scores_breakdown: ScoresBreakdown
    top_issues: list[FormIssueOut]
    coaching_summary: str
