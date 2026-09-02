from typing import Any

PERSONAS = ["Fitness", "Health", "Traveler"]

CARD_TYPES = [
    "rain",
    "alerts",
    "activity_window",
    "weather",
    "wind",
    "packing",
    "heat",
    "uv",
    "destination",
    "aqi",
]

HOUR_BUCKETS = ["morning", "afternoon", "evening", "night"]

FEATURE_NAMES = (
    [f"persona_{p}" for p in PERSONAS]
    + [f"card_{c}" for c in CARD_TYPES]
    + [f"hour_{h}" for h in HOUR_BUCKETS]
    + ["user_click_rate", "user_save_rate", "user_dismiss_rate"]
)


def get_hour_bucket(hour: int) -> str:
    if 5 <= hour <= 11:
        return "morning"
    elif 12 <= hour <= 16:
        return "afternoon"
    elif 17 <= hour <= 21:
        return "evening"
    else:
        return "night"


def action_to_label(action: str) -> float:
    act = action.lower()
    if act in ("click", "save"):
        return 1.0
    elif act == "view":
        return 0.5
    else:  # dismiss or unknown
        return 0.0


def extract_features_for_sample(
    persona: str,
    card_type: str,
    hour: int,
    user_stats_for_card: dict[str, float] | None = None,
) -> list[float]:
    """
    Extract a single numerical feature vector matching FEATURE_NAMES.
    """
    feats: list[float] = []

    # 1. Persona One-Hot (3)
    p_clean = persona if persona in PERSONAS else "Fitness"
    for p in PERSONAS:
        feats.append(1.0 if p == p_clean else 0.0)

    # 2. Card Type One-Hot (10)
    c_clean = card_type.lower() if card_type.lower() in CARD_TYPES else "weather"
    for c in CARD_TYPES:
        feats.append(1.0 if c == c_clean else 0.0)

    # 3. Hour Bucket One-Hot (4)
    bucket = get_hour_bucket(hour)
    for h in HOUR_BUCKETS:
        feats.append(1.0 if h == bucket else 0.0)

    # 4. User historical interaction rates (3)
    stats = user_stats_for_card or {}
    feats.append(float(stats.get("click_rate", 0.0)))
    feats.append(float(stats.get("save_rate", 0.0)))
    feats.append(float(stats.get("dismiss_rate", 0.0)))

    return feats


def compute_user_card_stats(interactions: list[dict[str, Any]]) -> dict[str, dict[str, float]]:
    """
    Computes per-card_type historical rates (click_rate, save_rate, dismiss_rate) for a given list of user interactions.
    """
    counts: dict[str, dict[str, int]] = {c: {"click": 0, "save": 0, "view": 0, "dismiss": 0, "total": 0} for c in CARD_TYPES}

    for item in interactions:
        ctype = str(item.get("card_type", "")).lower()
        act = str(item.get("action", "")).lower()
        if ctype in counts:
            counts[ctype]["total"] += 1
            if act in counts[ctype]:
                counts[ctype][act] += 1

    stats: dict[str, dict[str, float]] = {}
    for ctype, data in counts.items():
        total = max(data["total"], 1)
        stats[ctype] = {
            "click_rate": data["click"] / total,
            "save_rate": data["save"] / total,
            "dismiss_rate": data["dismiss"] / total,
        }
    return stats
