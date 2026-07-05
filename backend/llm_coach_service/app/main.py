from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.api.routes_coach import router as coach_router

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    description="RepSense LLM Coach Service — generates natural-language "
    "explanations, answers user questions, and summarizes workouts based "
    "on structured output from the Inference Service.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "llm_coach_service"}


@app.get("/")
async def root():
    return {"service": "RepSense LLM Coach Service", "docs": "/docs"}


app.include_router(coach_router)
