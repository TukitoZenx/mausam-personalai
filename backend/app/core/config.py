import logging

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    ENVIRONMENT: str = "development"
    PORT: int = 8000
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@db:5432/mausam_db"
    REDIS_URL: str = "redis://redis:6379/0"
    WEATHER_API_KEY: str = "placeholder_weather_key"
    AQI_API_KEY: str = "placeholder_aqi_key"
    FIREBASE_CREDENTIALS_PATH: str = ""
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-2.0-flash"

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def assemble_database_url(cls, v: str) -> str:
        if isinstance(v, str):
            if v.startswith("postgres://"):
                return v.replace("postgres://", "postgresql+asyncpg://", 1)
            elif v.startswith("postgresql://") and not v.startswith("postgresql+"):
                return v.replace("postgresql://", "postgresql+asyncpg://", 1)
        return v

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()

# Startup validation — log key presence (never log the value itself)
if settings.WEATHER_API_KEY and settings.WEATHER_API_KEY != "placeholder_weather_key":
    logger.info("✅ WEATHER_API_KEY loaded: non-empty (%d chars)", len(settings.WEATHER_API_KEY))
else:
    logger.warning("⚠️  WEATHER_API_KEY is missing or still a placeholder — external weather calls will fail")


