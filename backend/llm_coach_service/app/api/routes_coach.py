from fastapi import APIRouter
from pydantic import BaseModel
from app.services.coach_engine import generate_rep_feedback, answer_question, summarize_workout

router = APIRouter(prefix="/coach", tags=["coach"])


class AskRequest(BaseModel):
    question: str
    context: dict | None = None


class AskResponse(BaseModel):
    answer: str


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


@router.post("/ask", response_model=AskResponse)
async def ask(payload: AskRequest):
    answer = await answer_question(payload.question, payload.context)
    return AskResponse(answer=answer)


@router.post("/rep-feedback", response_model=FeedbackResponse)
async def rep_feedback(payload: FeedbackRequest):
    message = await generate_rep_feedback(payload.model_dump())
    return FeedbackResponse(message=message)


@router.post("/workout-summary", response_model=SummaryResponse)
async def workout_summary(payload: SummaryRequest):
    summary = await summarize_workout(payload.workout_data)
    return SummaryResponse(summary=summary)
