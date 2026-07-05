from fastapi import APIRouter, Depends
from app.db.supabase_client import get_supabase, get_current_user_id
from app.schemas.workout import WorkoutCreate, WorkoutOut, AnalyticsSummary

router = APIRouter(prefix="/workouts", tags=["workouts"])


@router.post("", response_model=WorkoutOut)
async def create_workout(
    payload: WorkoutCreate,
    user_id: str = Depends(get_current_user_id),
    supabase=Depends(get_supabase),
):
    row = {**payload.model_dump(), "user_id": user_id}
    res = supabase.table("workouts").insert(row).execute()
    return res.data[0]


@router.get("", response_model=list[WorkoutOut])
async def list_workouts(
    user_id: str = Depends(get_current_user_id),
    supabase=Depends(get_supabase),
):
    res = (
        supabase.table("workouts")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .execute()
    )
    return res.data


@router.get("/analytics/summary", response_model=AnalyticsSummary)
async def analytics_summary(
    user_id: str = Depends(get_current_user_id),
    supabase=Depends(get_supabase),
):
    res = supabase.table("workouts").select("*").eq("user_id", user_id).execute()
    workouts = res.data or []

    if not workouts:
        return AnalyticsSummary(
            total_workouts=0, avg_form_score=0, current_streak_days=0, weekly_consistency_pct=0
        )

    avg_score = sum(w["avg_form_score"] for w in workouts) / len(workouts)

    return AnalyticsSummary(
        total_workouts=len(workouts),
        avg_form_score=round(avg_score, 1),
        # NOTE: streak / weekly consistency are placeholder calculations —
        # replace with real date-bucketed logic once you have production data.
        current_streak_days=min(len(workouts), 7),
        weekly_consistency_pct=min(100.0, len(workouts) * 14.3),
    )
