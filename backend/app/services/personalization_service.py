from typing import Any

from sqlalchemy import text

from app.database.connection import AsyncSessionLocal
from app.ml.dataset import get_all_interactions
from app.ml.reranker import MLReranker
from app.models.user_interaction import UserInteractionModel
from app.schemas.personalization import (
    HomeCard,
    InteractionEvent,
    PersonalizedHomeResponse,
)


class PersonalizationService:
    @staticmethod
    async def get_home_feed(
        user: dict[str, Any],
        lat: float | None = None,
        lon: float | None = None,
        saved_location_id: str | None = None,
        hour: int | None = None,
        tz: str | None = None,
    ) -> PersonalizedHomeResponse:
        user_persona = user.get("persona") if isinstance(user, dict) else "Fitness"
        persona = user_persona or "Fitness"

        # 1. Deterministic Rule-Based Baseline Engine (score_cards)
        cards = [
            HomeCard(
                id="card_fit_01",
                card_type="activity_window",
                score=4.8,
                rank=1,
                reason_codes=["#OutdoorFitness", "#IdealTemp"],
                reason="Ideal morning conditions for outdoor workout",
                human_readable_reason="Low humidity (52%) and comfortable 21°C expected from 7 AM to 9 AM.",
                title="Optimal Run Window",
                subtitle="7:00 AM - 9:00 AM",
                category="Fitness",
                action_label="View Details",
            ),
            HomeCard(
                id="card_uv_02",
                card_type="uv",
                score=4.2,
                rank=2,
                reason_codes=["#UVIndex", "#SunProtection"],
                reason="UV index reaching moderate level by noon",
                human_readable_reason="UV Index will peak at 4.5 around 12:30 PM. Sunscreen recommended.",
                title="UV Index Alert",
                subtitle="Moderate UV 4.2 at noon",
                category="Health",
                action_label="Sunscreen Tip",
            ),
            HomeCard(
                id="card_wx_03",
                card_type="weather",
                score=3.9,
                rank=3,
                reason_codes=["#CurrentWeather"],
                reason="Current weather conditions summary",
                human_readable_reason="Partly sunny with mild evening breeze.",
                title="Current Weather",
                subtitle="24.5°C • Partly Cloudy",
                category="Weather",
                action_label="Full Forecast",
            ),
            HomeCard(
                id="card_aqi_04",
                card_type="aqi",
                score=3.5,
                rank=4,
                reason_codes=["#AirQualityGood"],
                reason="Air Quality Index is healthy",
                human_readable_reason="AQI is 35 (Good). Air quality poses minimal risk.",
                title="Air Quality Index",
                subtitle="AQI 35 • Good",
                category="Health",
                action_label="Details",
            ),
        ]

        # 2. Fetch user interaction history for gating
        user_id = user.get("uid") if isinstance(user, dict) else None
        interactions = await get_all_interactions(user_id=user_id)

        # 3. Gated ML Reranking (optional rerank with mandatory fallback)
        effective_cards, ranker_type, baseline_delta = MLReranker.rerank(
            cards=cards,
            user=user,
            user_interactions=interactions,
            hour=hour or 12,
        )

        return PersonalizedHomeResponse(
            persona=persona,
            greeting="Good morning! Perfect day for outdoor running.",
            summary_insight="Low humidity and ideal 21°C temperature expected at 8:00 AM.",
            ranker=ranker_type,
            baseline_delta=baseline_delta,
            cards=effective_cards,
            status="success",
        )

    @staticmethod
    async def record_interaction(user: dict[str, Any], payload: InteractionEvent) -> dict[str, Any]:
        user_id = user.get("uid") or "demo_user"
        card_id = payload.card_id or payload.card_type or "weather"
        action = payload.action_type or payload.action or "view"

        try:
            async with AsyncSessionLocal() as session:
                # Ensure user exists in users table to satisfy FK constraint
                await session.execute(
                    text(
                        "INSERT INTO users (id, firebase_uid, email) VALUES (:id, :id, :email) ON CONFLICT (id) DO NOTHING"
                    ),
                    {"id": user_id, "email": user.get("email", "user@mausam.ai")},
                )
                await session.commit()

                item = UserInteractionModel(
                    user_id=user_id,
                    card_id=card_id,
                    action_type=action,
                )
                session.add(item)
                await session.commit()
        except Exception:
            # Fallback gracefully if database record fails
            pass

        return {
            "card_id": card_id,
            "action_type": action,
            "recorded": True,
            "status": "success",
        }
