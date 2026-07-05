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


class AnalyzeSequenceResponse(BaseModel):
    exercise: str
    total_reps: int
    reps: list[RepResultOut]
    avg_score: float
