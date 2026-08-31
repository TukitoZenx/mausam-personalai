from typing import Dict, Any
from app.schemas.personalization import PersonalizedHomeResponse, HomeCard, InteractionEvent

class PersonalizationService:
    @staticmethod
    async def get_home_feed(user: Dict[str, Any]) -> PersonalizedHomeResponse:
        return PersonalizedHomeResponse(
            persona="Fitness",
            greeting="Good morning! Perfect day for outdoor running.",
            summary_insight="Low humidity and ideal 21°C temperature expected at 8:00 AM.",
            cards=[
                HomeCard(
                    id="card_fit_01",
                    title="Optimal Run Window",
                    subtitle="7:00 AM - 9:00 AM",
                    category="Fitness",
                    action_label="View Details",
                ),
                HomeCard(
                    id="card_uv_02",
                    title="UV Index Alert",
                    subtitle="Moderate UV 4.2 at noon",
                    category="Health",
                    action_label="Sunscreen Tip",
                ),
            ],
            status="stub",
        )

    @staticmethod
    async def record_interaction(user: Dict[str, Any], payload: InteractionEvent) -> Dict[str, Any]:
        return {
            "card_id": payload.card_id,
            "action_type": payload.action_type,
            "recorded": True,
            "status": "stub",
        }
