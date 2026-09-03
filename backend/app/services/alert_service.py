from datetime import datetime, timezone
from typing import Any

from app.schemas.alert import AlertResponse, AlertSubscription
from app.services.aqi_service import AQIService
from app.services.weather_service import WeatherService

_DEFAULT_LAT = 12.9716
_DEFAULT_LON = 77.5946


class AlertService:
    @staticmethod
    async def get_alerts(
        user: dict[str, Any],
        lat: float | None = None,
        lon: float | None = None,
    ) -> list[AlertResponse]:
        resolved_lat = lat if lat is not None and abs(lat) > 0.001 else _DEFAULT_LAT
        resolved_lon = lon if lon is not None and abs(lon) > 0.001 else _DEFAULT_LON

        alerts: list[AlertResponse] = []
        now_iso = datetime.now(timezone.utc).isoformat()

        try:
            current = await WeatherService.get_current_weather(resolved_lat, resolved_lon)
            if current.temperature_celsius >= 35.0:
                alerts.append(
                    AlertResponse(
                        id="alt_heat_01",
                        headline="Extreme Heat Warning",
                        severity="High",
                        description=f"Temperature reached {current.temperature_celsius}°C in {current.location}. Avoid prolonged sun exposure & stay hydrated.",
                        issued_at=now_iso,
                        status="active",
                    )
                )
            elif current.temperature_celsius >= 32.0:
                alerts.append(
                    AlertResponse(
                        id="alt_heat_02",
                        headline="Elevated Heat Caution",
                        severity="Moderate",
                        description=f"Warm conditions ({current.temperature_celsius}°C). Drink extra fluids during outdoor activities.",
                        issued_at=now_iso,
                        status="active",
                    )
                )

            if current.condition and any(w in current.condition.lower() for w in ["rain", "drizzle", "shower", "thunderstorm"]):
                alerts.append(
                    AlertResponse(
                        id="alt_rain_01",
                        headline="Active Rainfall Advisory",
                        severity="Moderate",
                        description=f"{current.condition} reported in {current.location}. Carry an umbrella and plan travel accordingly.",
                        issued_at=now_iso,
                        status="active",
                    )
                )

            if current.uv_index >= 8.0:
                alerts.append(
                    AlertResponse(
                        id="alt_uv_01",
                        headline="Very High UV Exposure Alert",
                        severity="High",
                        description=f"UV Index is {current.uv_index}. Sun protection (SPF 30+, hat, sunglasses) is strongly recommended.",
                        issued_at=now_iso,
                        status="active",
                    )
                )
        except Exception:
            pass

        try:
            aqi = await AQIService.get_current_aqi(resolved_lat, resolved_lon)
            if aqi.aqi_value >= 200:
                alerts.append(
                    AlertResponse(
                        id="alt_aqi_01",
                        headline="Severe Air Pollution Warning",
                        severity="Critical",
                        description=f"AQI reached {aqi.aqi_value} ({aqi.category}). N95 mask advised for all outdoor excursions.",
                        issued_at=now_iso,
                        status="active",
                    )
                )
            elif aqi.aqi_value >= 100:
                alerts.append(
                    AlertResponse(
                        id="alt_aqi_02",
                        headline="Unhealthy Air Quality Precaution",
                        severity="Moderate",
                        description=f"AQI is {aqi.aqi_value} ({aqi.category}). Sensitive individuals should limit outdoor activity.",
                        issued_at=now_iso,
                        status="active",
                    )
                )
        except Exception:
            pass

        # Fallback advisory if weather is calm/good
        if not alerts:
            alerts.append(
                AlertResponse(
                    id="alt_info_01",
                    headline="Favorable Weather Advisory",
                    severity="Low",
                    description="No extreme weather warnings reported for your active area.",
                    issued_at=now_iso,
                    status="active",
                )
            )

        return alerts

    @staticmethod
    async def subscribe_alerts(user: dict[str, Any], payload: AlertSubscription) -> dict[str, Any]:
        return {
            "enabled": payload.enabled,
            "subscribed": True,
            "status": "success",
        }
