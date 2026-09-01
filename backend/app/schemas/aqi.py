
from pydantic import BaseModel


class AQIResponse(BaseModel):
    location: str
    aqi_value: int
    category: str
    pollutants: dict[str, float]
    cached: bool = False
    stale: bool = False
