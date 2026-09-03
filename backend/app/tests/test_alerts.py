import pytest
from app.services.alert_service import AlertService


@pytest.mark.asyncio
async def test_get_alerts_returns_valid_list():
    mock_user = {"uid": "test_uid_123", "email": "test@mausam.ai", "persona_type": "Fitness"}
    # Hyderabad coordinates
    alerts = await AlertService.get_alerts(mock_user, lat=17.3850, lon=78.4867)

    assert isinstance(alerts, list)
    assert len(alerts) >= 1
    for alert in alerts:
        assert alert.id is not None
        assert alert.headline is not None
        assert alert.severity in ["Low", "Moderate", "High", "Critical"]
        assert alert.description is not None
        assert alert.issued_at is not None


@pytest.mark.asyncio
async def test_alerts_persona_awareness():
    fitness_user = {"uid": "u1", "persona_type": "Fitness"}
    traveler_user = {"uid": "u2", "persona_type": "Traveler"}

    fitness_alerts = await AlertService.get_alerts(fitness_user, lat=19.0760, lon=72.8777, persona="Fitness")
    traveler_alerts = await AlertService.get_alerts(traveler_user, lat=19.0760, lon=72.8777, persona="Traveler")

    assert len(fitness_alerts) >= 1
    assert len(traveler_alerts) >= 1
