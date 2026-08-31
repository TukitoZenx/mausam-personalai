from typing import Dict, Any
from app.schemas.weather import CurrentWeather, ForecastResponse, DailyForecastItem

class WeatherService:
    @staticmethod
    async def get_current_weather(user: Dict[str, Any]) -> CurrentWeather:
        return CurrentWeather(
            location="San Francisco, CA",
            temperature_celsius=21.5,
            condition="Partly Cloudy",
            humidity_percent=65,
            wind_speed_kmh=12.4,
            uv_index=4.2,
            status="stub",
        )

    @staticmethod
    async def get_forecast(user: Dict[str, Any]) -> ForecastResponse:
        current = await WeatherService.get_current_weather(user)
        daily_forecast = [
            DailyForecastItem(day="Today", high_celsius=23.0, low_celsius=14.0, condition="Sunny", rain_probability_percent=10),
            DailyForecastItem(day="Tomorrow", high_celsius=20.0, low_celsius=13.0, condition="Rain", rain_probability_percent=80),
            DailyForecastItem(day="Day 3", high_celsius=22.0, low_celsius=15.0, condition="Partly Cloudy", rain_probability_percent=20),
        ]
        return ForecastResponse(
            location="San Francisco, CA",
            current=current,
            forecast=daily_forecast,
            status="stub",
        )
