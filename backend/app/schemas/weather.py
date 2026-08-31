from typing import List, Optional
from pydantic import BaseModel

class CurrentWeather(BaseModel):
    location: str
    temperature_celsius: float
    condition: str
    humidity_percent: int
    wind_speed_kmh: float
    uv_index: float
    status: str = "stub"

class DailyForecastItem(BaseModel):
    day: str
    high_celsius: float
    low_celsius: float
    condition: str
    rain_probability_percent: int

class ForecastResponse(BaseModel):
    location: str
    current: CurrentWeather
    forecast: List[DailyForecastItem]
    status: str = "stub"
