from typing import Dict, Any
from app.schemas.aqi import AQIResponse

class AQIService:
    @staticmethod
    async def get_current_aqi(user: Dict[str, Any]) -> AQIResponse:
        return AQIResponse(
            location="San Francisco, CA",
            aqi_value=42,
            category="Good",
            pollutants={"pm2_5": 10.2, "pm10": 18.5, "o3": 28.0, "no2": 8.4},
            status="stub",
        )
