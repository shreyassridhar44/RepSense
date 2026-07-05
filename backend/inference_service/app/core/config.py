from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "RepSense Inference Service"
    environment: str = "development"
    max_upload_mb: int = 100

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()
