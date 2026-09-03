from datetime import datetime, timezone
import logging
from typing import Any

from app.schemas.alert import AlertResponse, AlertSubscription
from app.services.aqi_service import AQIService
from app.services.weather_service import WeatherService

logger = logging.getLogger(__name__)

_DEFAULT_LAT = 17.3850  # Hyderabad default
_DEFAULT_LON = 78.4867


class AlertService:
    @staticmethod
    async def get_alerts(
        user: dict[str, Any],
        lat: float | None = None,
        lon: float | None = None,
        persona: str | None = None,
    ) -> list[AlertResponse]:
        resolved_lat = lat if lat is not None and abs(lat) > 0.001 else _DEFAULT_LAT
        resolved_lon = lon if lon is not None and abs(lon) > 0.001 else _DEFAULT_LON

        selected_persona = (persona or user.get("persona_type") or "Fitness").capitalize()
        alerts: list[AlertResponse] = []
        now_iso = datetime.now(timezone.utc).isoformat()

        # 1. Weather Data Evaluation
        try:
            current = await WeatherService.get_current_weather(resolved_lat, resolved_lon)
            temp = current.temperature_celsius
            feels_like = current.feels_like_celsius
            eff_temp = max(temp, feels_like)
            condition = (current.condition or "").lower()
            rain_mm = current.rain_mm_1h or 0.0
            wind_kph = current.wind_speed_kph or 0.0
            uv = current.uv_index or 0.0

            # Heat alerts
            if eff_temp >= 37.0:
                advice = "Limit outdoor exercise during peak heat hours." if selected_persona == "Fitness" else "Stay hydrated and remain in cool, shaded spaces."
                alerts.append(
                    AlertResponse(
                        id="alt_heat_severe",
                        headline="Extreme Heat Warning",
                        severity="High",
                        description=f"Temperature reached {eff_temp:.1f}°C in {current.location}. {advice}",
                        issued_at=now_iso,
                        status="active",
                    )
                )
            elif eff_temp >= 30.0:
                advice = "Hydrate well before outdoor workouts." if selected_persona == "Fitness" else "Keep hydrated during daytime activities."
                alerts.append(
                    AlertResponse(
                        id="alt_heat_warn",
                        headline="Elevated Heat Caution",
                        severity="Moderate",
                        description=f"Warm conditions ({eff_temp:.1f}°C) in {current.location}. {advice}",
                        issued_at=now_iso,
                        status="active",
                    )
                )

            # Rain / Precipitation alerts
            is_rainy = any(w in condition for w in ["rain", "drizzle", "shower", "thunderstorm", "downpour"]) or rain_mm > 0.0
            if is_rainy or rain_mm >= 5.0:
                if rain_mm >= 5.0 or "thunder" in condition:
                    advice = "Reschedule outdoor runs to indoor tracks." if selected_persona == "Fitness" else "Plan indoor travel and exercise caution on wet roads."
                    alerts.append(
                        AlertResponse(
                            id="alt_rain_severe",
                            headline="Heavy Rainfall Warning",
                            severity="High",
                            description=f"{current.condition or 'Heavy Rain'} reported in {current.location}. {advice}",
                            issued_at=now_iso,
                            status="active",
                        )
                    )
                else:
                    advice = "Carry waterproof gear if heading out." if selected_persona == "Traveler" else "Carry an umbrella if heading outside."
                    alerts.append(
                        AlertResponse(
                            id="alt_rain_advisory",
                            headline="Rainfall Advisory",
                            severity="Moderate",
                            description=f"Light rain or wet roads expected in {current.location}. {advice}",
                            issued_at=now_iso,
                            status="active",
                        )
                    )

            # Wind alert
            if wind_kph >= 45.0:
                alerts.append(
                    AlertResponse(
                        id="alt_wind_severe",
                        headline="High Wind Warning",
                        severity="High",
                        description=f"Strong winds reaching {wind_kph:.1f} km/h in {current.location}. Secure loose outdoor objects.",
                        issued_at=now_iso,
                        status="active",
                    )
                )
            elif wind_kph >= 25.0:
                alerts.append(
                    AlertResponse(
                        id="alt_wind_warn",
                        headline="Gusty Wind Advisory",
                        severity="Moderate",
                        description=f"Breezy conditions ({wind_kph:.1f} km/h) in {current.location}.",
                        issued_at=now_iso,
                        status="active",
                    )
                )

            # UV alert
            if uv >= 8.0:
                alerts.append(
                    AlertResponse(
                        id="alt_uv_high",
                        headline="High UV Index Alert",
                        severity="Moderate",
                        description=f"UV Index at {uv:.1f}. Sun protection (SPF 30+, hat, sunglasses) is strongly recommended.",
                        issued_at=now_iso,
                        status="active",
                    )
                )
        except Exception as exc:
            logger.warning("Weather evaluation for alerts failed: %s", exc)

        # 2. AQI Data Evaluation
        try:
            aqi = await AQIService.get_current_aqi(resolved_lat, resolved_lon)
            aqi_val = aqi.aqi_value
            if aqi_val >= 201:
                advice = "Switch to indoor cardio or gym sessions today." if selected_persona == "Fitness" else "N95 mask strongly advised for outdoor excursions."
                alerts.append(
                    AlertResponse(
                        id="alt_aqi_severe",
                        headline="Severe Air Quality Alert",
                        severity="High",
                        description=f"AQI at {aqi_val} ({aqi.category}). {advice}",
                        issued_at=now_iso,
                        status="active",
                    )
                )
            elif aqi_val >= 101:
                advice = "Consider reducing workout intensity outdoors." if selected_persona == "Fitness" else "Sensitive individuals should limit outdoor exertion."
                alerts.append(
                    AlertResponse(
                        id="alt_aqi_warn",
                        headline="Unhealthy Air Quality Precaution",
                        severity="Moderate",
                        description=f"AQI is {aqi_val} ({aqi.category}). {advice}",
                        issued_at=now_iso,
                        status="active",
                    )
                )
            elif aqi_val >= 51:
                alerts.append(
                    AlertResponse(
                        id="alt_aqi_mod",
                        headline="Moderate Air Quality Advisory",
                        severity="Low",
                        description=f"AQI is {aqi_val} ({aqi.category}). Generally acceptable air quality for most individuals.",
                        issued_at=now_iso,
                        status="active",
                    )
                )
        except Exception as exc:
            logger.warning("AQI evaluation for alerts failed: %s", exc)

        # 3. Informational Favorable Weather Advisory if no active alerts
        if not alerts:
            alerts.append(
                AlertResponse(
                    id="alt_info_favorable",
                    headline="Favorable Weather Advisory",
                    severity="Low",
                    description="Optimal atmospheric conditions reported. Great weather for outdoor activities!",
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
