from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    ENVIRONMENT: str = "development"
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@db:5432/mausam_db"
    REDIS_URL: str = "redis://redis:6379/0"
    WEATHER_API_KEY: str = "placeholder_weather_key"
    AQI_API_KEY: str = "placeholder_aqi_key"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()
