from fastapi import APIRouter, Depends
from app.db.supabase_client import get_supabase
from app.schemas.workout import ExerciseOut

router = APIRouter(prefix="/exercises", tags=["exercises"])


@router.get("", response_model=list[ExerciseOut])
async def list_exercises(supabase=Depends(get_supabase)):
    res = supabase.table("exercises").select("*").execute()
    return res.data


@router.get("/{exercise_id}", response_model=ExerciseOut)
async def get_exercise(exercise_id: str, supabase=Depends(get_supabase)):
    res = supabase.table("exercises").select("*").eq("id", exercise_id).single().execute()
    return res.data
