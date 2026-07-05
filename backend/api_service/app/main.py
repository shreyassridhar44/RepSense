from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.api.routes import health, exercises, workouts

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    description="RepSense API Service — authentication, users, workouts, "
    "analytics, reports, persistence, notifications.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(exercises.router)
app.include_router(workouts.router)


@app.get("/")
async def root():
    return {"service": "RepSense API Service", "docs": "/docs"}
