from typing import Any

from app.schemas.alert import AlertResponse, AlertSubscription


class AlertService:
    @staticmethod
    async def get_alerts(user: dict[str, Any]) -> list[AlertResponse]:
        return [
            AlertResponse(
                id="alt_01",
                headline="Light Rain Warning",
                severity="Moderate",
                description="Intermittent showers expected between 2:00 PM and 4:00 PM.",
                issued_at="2026-08-31T12:00:00Z",
                status="stub",
            )
        ]

    @staticmethod
    async def subscribe_alerts(user: dict[str, Any], payload: AlertSubscription) -> dict[str, Any]:
        return {
            "enabled": payload.enabled,
            "subscribed": True,
            "status": "stub",
        }
