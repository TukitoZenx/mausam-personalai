from typing import Dict
from pydantic import BaseModel

class AQIResponse(BaseModel):
    location: str
    aqi_value: int
    category: str
    pollutants: Dict[str, float]
    status: str = "stub"
