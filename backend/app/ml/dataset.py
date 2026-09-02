import json
import logging
from pathlib import Path
from typing import Any

from sqlalchemy import text

from app.database.connection import AsyncSessionLocal

logger = logging.getLogger(__name__)

SEED_DATA_PATH = Path(__file__).parent / "seed_data.json"


def load_seed_data() -> list[dict[str, Any]]:
    """Load pre-packaged synthetic seed interaction data."""
    if not SEED_DATA_PATH.exists():
        return []
    with open(SEED_DATA_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


async def get_all_interactions(user_id: str | None = None) -> list[dict[str, Any]]:
    """
    Fetch interactions from database if available, combined with seed data if DB records are sparse.
    """
    records: list[dict[str, Any]] = []

    try:
        async with AsyncSessionLocal() as session:
            query = "SELECT * FROM user_interactions"
            params: dict[str, Any] = {}
            if user_id:
                query += " WHERE user_id = :user_id"
                params["user_id"] = user_id

            res = await session.execute(text(query), params)
            rows = res.fetchall()

            for row in rows:
                row_dict = row._mapping
                user_id_val = row_dict.get("user_id")
                persona_val = row_dict.get("persona") or row_dict.get("persona_type") or "Fitness"
                card_type_val = row_dict.get("card_type") or row_dict.get("card_id")
                action_val = row_dict.get("action") or row_dict.get("action_type") or "view"
                created_at_val = row_dict.get("created_at")
                dt_str = created_at_val.isoformat() if hasattr(created_at_val, "isoformat") else str(created_at_val or "")
                hour = created_at_val.hour if hasattr(created_at_val, "hour") else 12

                if card_type_val:
                    records.append({
                        "user_id": str(user_id_val),
                        "persona": str(persona_val),
                        "card_type": str(card_type_val),
                        "action": str(action_val),
                        "hour": hour,
                        "timestamp": dt_str,
                    })
    except Exception as e:
        logger.warning("Could not fetch DB interactions (using seed data fallback): %s", e)

    # Combine with seed data for offline / demo training sufficiency
    seed = load_seed_data()
    if user_id:
        seed = [r for r in seed if r.get("user_id") == user_id]

    combined = records + seed
    return combined
