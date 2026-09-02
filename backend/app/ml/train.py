import asyncio
import json
import logging
from pathlib import Path
from typing import Any

import joblib
import numpy as np
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.model_selection import train_test_split

from app.ml.dataset import get_all_interactions
from app.ml.features import (
    CARD_TYPES,
    action_to_label,
    compute_user_card_stats,
    extract_features_for_sample,
)

logger = logging.getLogger(__name__)

MODEL_PATH = Path(__file__).parent / "model.joblib"
METRICS_PATH = Path(__file__).parent / "metrics.json"


def train_model(records: list[dict[str, Any]]) -> tuple[Any, dict[str, Any]]:
    """
    Train a scikit-learn model on interaction records and compute baseline comparison metrics.
    """
    if not records:
        raise ValueError("No interaction records available for training.")

    X: list[list[float]] = []
    y: list[int] = []

    # Compute global user card interaction stats for feature extraction
    user_stats = compute_user_card_stats(records)

    for rec in records:
        persona = str(rec.get("persona", "Fitness"))
        card_type = str(rec.get("card_type", "weather"))
        hour = int(rec.get("hour", 12))
        action = str(rec.get("action", "view"))

        label_score = action_to_label(action)
        # Binary target: 1 for positive/weak-positive engagement, 0 for negative/dismiss
        binary_label = 1 if label_score >= 0.5 else 0

        card_stats = user_stats.get(card_type.lower())
        feat_vector = extract_features_for_sample(persona, card_type, hour, card_stats)

        X.append(feat_vector)
        y.append(binary_label)

    X_arr = np.array(X, dtype=np.float32)
    y_arr = np.array(y, dtype=np.int32)

    # Train/test split
    if len(np.unique(y_arr)) > 1 and len(y_arr) >= 10:
        X_train, X_val, y_train, y_val = train_test_split(
            X_arr, y_arr, test_size=0.2, random_state=42, stratify=y_arr
        )
    else:
        X_train, X_val, y_train, y_val = X_arr, X_arr, y_arr, y_arr

    clf = GradientBoostingClassifier(n_estimators=30, max_depth=3, random_state=42)
    clf.fit(X_train, y_train)

    val_acc = float(clf.score(X_val, y_val)) if len(y_val) > 0 else 1.0

    # Compute baseline comparison metrics across the 3 persona scenarios
    persona_scenarios = ["Fitness", "Health", "Traveler"]
    pairwise_agreements: list[float] = []
    top1_matches: list[bool] = []
    top3_overlaps: list[float] = []

    for persona in persona_scenarios:
        # Rule-based baseline order (fixed catalog priority per persona)
        if persona == "Fitness":
            rule_order = ["activity_window", "uv", "weather", "aqi", "rain", "wind", "heat", "alerts", "destination", "packing"]
        elif persona == "Health":
            rule_order = ["aqi", "uv", "heat", "alerts", "weather", "activity_window", "wind", "rain", "destination", "packing"]
        else:  # Traveler
            rule_order = ["destination", "packing", "rain", "alerts", "weather", "wind", "heat", "uv", "aqi", "activity_window"]

        # Predict ML probabilities for each card type
        card_scores: list[tuple[str, float]] = []
        for ctype in CARD_TYPES:
            feats = extract_features_for_sample(persona, ctype, hour=12, user_stats_for_card=user_stats.get(ctype))
            prob = float(clf.predict_proba([feats])[0][1])
            card_scores.append((ctype, prob))

        # Sort by ML probability descending
        ml_order = [c for c, _ in sorted(card_scores, key=lambda x: x[1], reverse=True)]

        # Top-1 match
        top1_match = (ml_order[0] == rule_order[0])
        top1_matches.append(top1_match)

        # Top-3 overlap
        top3_ml = set(ml_order[:3])
        top3_rule = set(rule_order[:3])
        overlap = len(top3_ml.intersection(top3_rule)) / 3.0
        top3_overlaps.append(overlap)

        # Pairwise agreement
        agree_count = 0
        total_pairs = 0
        rule_rank_map = {c: i for i, c in enumerate(rule_order)}
        ml_rank_map = {c: i for i, c in enumerate(ml_order)}

        all_cards = list(set(rule_order).intersection(set(ml_order)))
        for i in range(len(all_cards)):
            for j in range(i + 1, len(all_cards)):
                c1, c2 = all_cards[i], all_cards[j]
                rule_diff = rule_rank_map[c1] - rule_rank_map[c2]
                ml_diff = ml_rank_map[c1] - ml_rank_map[c2]
                if (rule_diff * ml_diff) > 0:
                    agree_count += 1
                total_pairs += 1

        pairwise_agreements.append(agree_count / max(total_pairs, 1))

    metrics = {
        "dataset_size": len(records),
        "validation_accuracy": round(val_acc, 4),
        "pairwise_order_agreement": round(float(np.mean(pairwise_agreements)), 4),
        "top1_match_rate": round(float(np.mean(top1_matches)), 4),
        "top3_overlap_rate": round(float(np.mean(top3_overlaps)), 4),
        "model_type": "GradientBoostingClassifier",
        "features_count": len(X_arr[0]) if len(X_arr) > 0 else 0,
    }

    return clf, metrics


def main() -> None:
    print("Loading interaction training data...")
    records = asyncio.run(get_all_interactions())
    print(f"Loaded {len(records)} interaction records.")

    print("Training ML Reranker model...")
    model, metrics = train_model(records)

    # Save model artifact
    joblib.dump(model, MODEL_PATH)
    print(f"Saved model artifact to {MODEL_PATH}")

    # Save metrics JSON
    with open(METRICS_PATH, "w", encoding="utf-8") as f:
        json.dump(metrics, f, indent=2)
    print(f"Saved training metrics to {METRICS_PATH}")
    print("Metrics:", json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
