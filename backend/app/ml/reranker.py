import logging
from pathlib import Path
from typing import Any

import joblib

from app.ml.features import compute_user_card_stats, extract_features_for_sample
from app.schemas.personalization import HomeCard

logger = logging.getLogger(__name__)

MODEL_PATH = Path(__file__).parent / "model.joblib"
MIN_INTERACTIONS_DEFAULT = 20
CONFIDENCE_MARGIN_DEFAULT = 0.08


class MLReranker:
    _model: Any | None = None
    _model_loaded: bool = False

    @classmethod
    def load_model(cls) -> Any | None:
        """Load joblib model artifact if present."""
        if not cls._model_loaded:
            if MODEL_PATH.exists():
                try:
                    cls._model = joblib.load(MODEL_PATH)
                    logger.info("Loaded ML Reranker model from %s", MODEL_PATH)
                except Exception as e:
                    logger.warning("Failed to load ML model artifact from %s: %s", MODEL_PATH, e)
                    cls._model = None
            else:
                logger.info("ML model artifact %s not found. Gated reranking disabled.", MODEL_PATH)
            cls._model_loaded = True
        return cls._model

    @classmethod
    def reload(cls) -> None:
        """Reset model cache forcing reload."""
        cls._model_loaded = False
        cls._model = None
        cls.load_model()

    @classmethod
    def rerank(
        cls,
        cards: list[HomeCard],
        user: dict[str, Any],
        user_interactions: list[dict[str, Any]] | None = None,
        hour: int = 12,
        min_interactions: int = MIN_INTERACTIONS_DEFAULT,
        confidence_margin_threshold: float = CONFIDENCE_MARGIN_DEFAULT,
    ) -> tuple[list[HomeCard], str, dict[str, Any] | None]:
        """
        Gated ML Reranker. Reranks cards if:
        1. Trained model artifact exists.
        2. User has at least `min_interactions` recorded.
        3. Model confidence margin exceeds `confidence_margin_threshold`.

        Returns: (reranked_cards, "ml" | "rules", baseline_delta | None)
        """
        if not cards:
            return cards, "rules", None

        # Rule 1: Model file check
        model = cls.load_model()
        if model is None:
            return cards, "rules", None

        # Rule 2: User interactions threshold check
        interactions = user_interactions or []
        if len(interactions) < min_interactions:
            return cards, "rules", None

        try:
            persona = str(user.get("persona") or "Fitness")
            user_stats = compute_user_card_stats(interactions)

            # Predict ML engagement probabilities for each card
            ml_probabilities: dict[str, float] = {}
            for card in cards:
                card_type = card.card_type.lower()
                c_stats = user_stats.get(card_type)
                feats = extract_features_for_sample(persona, card_type, hour, c_stats)
                probs = model.predict_proba([feats])[0]
                # Index 1 is probability of positive engagement
                ml_prob = float(probs[1]) if len(probs) > 1 else float(probs[0])
                ml_probabilities[card.id] = ml_prob

            probs_list = list(ml_probabilities.values())
            max_prob = max(probs_list) if probs_list else 0.0
            min_prob = min(probs_list) if probs_list else 0.0
            margin = max_prob - min_prob

            # Rule 3: Confidence margin threshold check
            if margin < confidence_margin_threshold:
                logger.info("ML margin (%.4f) below threshold (%.4f). Falling back to rules.", margin, confidence_margin_threshold)
                return cards, "rules", None

            # Rerank cards using combined hybrid score: rule_score + (ml_probability * 3.0)
            original_order = {card.id: idx + 1 for idx, card in enumerate(cards)}

            scored_cards: list[tuple[HomeCard, float]] = []
            for card in cards:
                rule_score = card.score
                ml_prob = ml_probabilities.get(card.id, 0.5)
                hybrid_score = rule_score + (ml_prob * 3.0)
                scored_cards.append((card, hybrid_score))

            # Sort descending by hybrid score
            scored_cards.sort(key=lambda x: x[1], reverse=True)

            reranked_cards: list[HomeCard] = []
            rank_shifts: dict[str, int] = {}

            for new_rank, (card, new_score) in enumerate(scored_cards, start=1):
                old_rank = original_order[card.id]
                shift = old_rank - new_rank  # positive means moved up, negative means moved down
                rank_shifts[card.card_type] = shift

                # Create updated card with new rank & score
                updated_card = card.model_copy(
                    update={
                        "rank": new_rank,
                        "score": round(new_score, 2),
                    }
                )
                reranked_cards.append(updated_card)

            baseline_delta = {
                "top1_changed": (reranked_cards[0].id != cards[0].id),
                "original_top1": cards[0].card_type,
                "ml_top1": reranked_cards[0].card_type,
                "confidence_margin": round(margin, 4),
                "rank_shifts": rank_shifts,
            }

            return reranked_cards, "ml", baseline_delta

        except Exception:
            logger.exception("Error during ML reranking (falling back to rules)")
            return cards, "rules", None
