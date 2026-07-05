from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "RepSense LLM Coach Service"
    environment: str = "development"

    # Support both Anthropic (Claude) and Google (Gemini)
    anthropic_api_key: str = ""
    anthropic_model: str = "claude-sonnet-4-6"
    
    # Google Gemini configuration
    google_api_key: str = ""
    google_model: str = "gemini-pro"
    
    # Choose which LLM provider to use: "anthropic" or "google"
    llm_provider: str = "google"

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()
