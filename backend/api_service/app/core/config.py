from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "RepSense API Service"
    environment: str = "development"

    supabase_url: str = ""
    supabase_service_role_key: str = ""  # server-side only, never ship to the client
    supabase_jwt_secret: str = ""

    inference_service_url: str = "http://localhost:8001"
    llm_coach_service_url: str = "http://localhost:8002"

    cors_origins: list[str] = ["*"]

    class Config:
        env_file = ".env"

    @property
    def database_url(self) -> str:
        # Supabase exposes the underlying Postgres connection string in the
        # dashboard under Project Settings -> Database. Put it directly in
        # .env as DATABASE_URL if you want SQLAlchemy/Alembic access too.
        return ""


@lru_cache
def get_settings() -> Settings:
    return Settings()
