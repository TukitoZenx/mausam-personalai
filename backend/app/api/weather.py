from typing import Any

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_current_user
from app.schemas.weather import CurrentWeather, ForecastResponse
from app.services.weather_service import WeatherService

router = APIRouter(prefix="/weather", tags=["weather"])


@router.get("/current", response_model=CurrentWeather)
async def get_current_weather(
    lat: float = Query(..., description="Latitude", ge=-90, le=90),
    lon: float = Query(..., description="Longitude", ge=-180, le=180),
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await WeatherService.get_current_weather(lat, lon)


@router.get("/forecast", response_model=ForecastResponse)
async def get_weather_forecast(
    lat: float = Query(..., description="Latitude", ge=-90, le=90),
    lon: float = Query(..., description="Longitude", ge=-180, le=180),
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await WeatherService.get_forecast(lat, lon)
