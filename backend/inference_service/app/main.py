from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.api.routes_inference import router as inference_router

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    description="RepSense Inference Service — pose estimation, exercise "
    "recognition, rep counting, and biomechanical analysis. Deployable "
    "independently on GPU infrastructure.",
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
    return {"status": "ok", "service": "inference_service"}


@app.get("/")
async def root():
    return {"service": "RepSense Inference Service", "docs": "/docs"}


app.include_router(inference_router)
