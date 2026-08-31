from fastapi import FastAPI
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.health import router as health_router
from app.api.users import router as users_router
from app.api.weather import router as weather_router
from app.api.aqi import router as aqi_router
from app.api.locations import router as locations_router
from app.api.personalization import router as personalization_router
from app.api.alerts import router as alerts_router

from app.core.exceptions import (
    AppException,
    app_exception_handler,
    http_exception_handler,
    unhandled_exception_handler,
)
from app.core.logging import LoggingMiddleware

app = FastAPI(
    title="Mausam PersonalAI API",
    version="0.1.0",
    description="Personalized weather, AQI & recommendations API for Mausam PersonalAI",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Logging middleware
app.add_middleware(LoggingMiddleware)

# Centralized Exception Handlers
app.add_exception_handler(AppException, app_exception_handler)
app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)

# Include Routers
app.include_router(health_router)
app.include_router(users_router)
app.include_router(weather_router)
app.include_router(aqi_router)
app.include_router(locations_router)
app.include_router(personalization_router)
app.include_router(alerts_router)

@app.get("/")
async def root():
    return {"message": "Welcome to Mausam PersonalAI API"}
