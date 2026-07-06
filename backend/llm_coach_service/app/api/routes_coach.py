from fastapi import APIRouter
from pydantic import BaseModel
from app.services.coach_engine import (
    generate_rep_feedback,
    answer_question,
    summarize_workout,
    analyze_image,
)

router = APIRouter(prefix="/coach", tags=["coach"])


class MessageIn(BaseModel):
    role: str  # "user" or "assistant"
    content: str


class RecentWorkoutSummary(BaseModel):
    exercise_name: str
    date: str  # ISO format
    avg_form_score: float
    total_reps: int
    top_issue: str | None = None


class UserContext(BaseModel):
    display_name: str | None = None
    training_experience: str | None = None  # Beginner | Intermediate | Advanced | Elite
    goals: list[str] = []
    height_cm: float | None = None
    weight_kg: float | None = None
    # Recent performance
    total_workouts: int = 0
    current_streak_days: int = 0
    avg_form_score_last_7_days: float | None = None
    most_trained_exercise: str | None = None
    weakest_muscle_group: str | None = None  # lowest muscle balance score
    recent_issues: list[str] = []  # top FormIssue problem strings
    recent_workouts_summary: list[RecentWorkoutSummary] = []


class AskRequest(BaseModel):
    question: str
    conversation_history: list[MessageIn] = []
    user_context: UserContext | None = None


class AskResponse(BaseModel):
    answer: str
    suggested_followups: list[str] = []  # 2-3 follow-up questions
    sources: list[str] = []  # e.g. ["biomechanics", "nutrition"]


class FeedbackRequest(BaseModel):
    problem: str
    reason: str
    correction: str
    confidence: float
    severity: str


class FeedbackResponse(BaseModel):
    message: str


class SummaryRequest(BaseModel):
    workout_data: dict


class SummaryResponse(BaseModel):
    summary: str


class AnalyzeImageRequest(BaseModel):
    image_base64: str
    media_type: str  # "image/jpeg" | "image/png"
    question: str
    user_context: UserContext | None = None


class AnalyzeImageResponse(BaseModel):
    answer: str
    suggested_followups: list[str] = []


class ClearContextResponse(BaseModel):
    status: str


@router.post("/ask", response_model=AskResponse)
async def ask(payload: AskRequest):
    conversation_history = [
        {"role": msg.role, "content": msg.content} for msg in payload.conversation_history
    ]
    user_context = payload.user_context.model_dump() if payload.user_context else None

    answer, followups = await answer_question(
        payload.question, conversation_history, user_context
    )
    return AskResponse(answer=answer, suggested_followups=followups, sources=[])


@router.post("/rep-feedback", response_model=FeedbackResponse)
async def rep_feedback(payload: FeedbackRequest):
    message = await generate_rep_feedback(payload.model_dump())
    return FeedbackResponse(message=message)


@router.post("/workout-summary", response_model=SummaryResponse)
async def workout_summary(payload: SummaryRequest):
    summary = await summarize_workout(payload.workout_data)
    return SummaryResponse(summary=summary)


@router.post("/analyze-image", response_model=AnalyzeImageResponse)
async def analyze_image_endpoint(payload: AnalyzeImageRequest):
    user_context = payload.user_context.model_dump() if payload.user_context else None

    answer, followups = await analyze_image(
        payload.image_base64, payload.media_type, payload.question, user_context
    )
    return AnalyzeImageResponse(answer=answer, suggested_followups=followups)


@router.post("/clear-context", response_model=ClearContextResponse)
async def clear_context():
    # No-op on server (context is stateless) — used by client for logging
    return ClearContextResponse(status="ok")
