from typing import Dict, Any
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.schemas.weather import CurrentWeather, ForecastResponse
from app.services.weather_service import WeatherService

router = APIRouter(prefix="/weather", tags=["weather"])

@router.get("/current", response_model=CurrentWeather)
async def get_current_weather(current_user: Dict[str, Any] = Depends(get_current_user)):
    return await WeatherService.get_current_weather(current_user)

@router.get("/forecast", response_model=ForecastResponse)
async def get_weather_forecast(current_user: Dict[str, Any] = Depends(get_current_user)):
    return await WeatherService.get_forecast(current_user)
