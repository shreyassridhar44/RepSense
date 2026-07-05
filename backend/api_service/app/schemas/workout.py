from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class ExerciseOut(BaseModel):
    id: str
    name: str
    muscle_groups: list[str]
    difficulty: str
    equipment: Optional[str] = None


class WorkoutCreate(BaseModel):
    exercise_id: str
    total_reps: int
    correct_reps: int
    incorrect_reps: int
    avg_form_score: float = Field(ge=0, le=100)
    duration_seconds: int
    calories: Optional[float] = None
    video_url: Optional[str] = None
    notes: Optional[str] = None


class WorkoutOut(WorkoutCreate):
    id: str
    user_id: str
    created_at: datetime


class AnalyticsSummary(BaseModel):
    total_workouts: int
    avg_form_score: float
    current_streak_days: int
    weekly_consistency_pct: float
