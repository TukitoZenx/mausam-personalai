import pytest
from unittest.mock import patch
from pathlib import Path

from app.ml.dataset import load_seed_data
from app.ml.features import CARD_TYPES
from app.ml.reranker import MLReranker
from app.ml.train import train_model
from app.schemas.personalization import HomeCard


@pytest.fixture
def sample_cards():
    return [
        HomeCard(id="c1", card_type="activity_window", score=4.8, rank=1, title="Activity Window"),
        HomeCard(id="c2", card_type="uv", score=4.2, rank=2, title="UV Index"),
        HomeCard(id="c3", card_type="weather", score=3.9, rank=3, title="Weather"),
        HomeCard(id="c4", card_type="aqi", score=3.5, rank=4, title="AQI"),
    ]


@pytest.fixture
def seed_interactions():
    return load_seed_data()


def test_train_model_script(seed_interactions):
    model, metrics = train_model(seed_interactions)
    assert model is not None
    assert metrics["dataset_size"] == len(seed_interactions)
    assert "validation_accuracy" in metrics
    assert "pairwise_order_agreement" in metrics
    assert "top1_match_rate" in metrics


def test_missing_model_fallback(sample_cards):
    with patch.object(MLReranker, "load_model", return_value=None):
        cards, ranker, delta = MLReranker.rerank(
            cards=sample_cards,
            user={"persona": "Fitness", "uid": "user_test_01"},
            user_interactions=[{"card_type": "uv", "action": "click"}] * 25,
        )
        assert ranker == "rules"
        assert delta is None
        assert len(cards) == len(sample_cards)


def test_insufficient_interactions_fallback(sample_cards):
    # Only 5 interactions provided (below N=20 threshold)
    few_interactions = [{"card_type": "uv", "action": "click"}] * 5

    cards, ranker, delta = MLReranker.rerank(
        cards=sample_cards,
        user={"persona": "Fitness", "uid": "user_test_02"},
        user_interactions=few_interactions,
    )
    assert ranker == "rules"
    assert delta is None


def test_gated_ml_reranking_success(sample_cards, seed_interactions):
    # Ensure trained model artifact exists
    model, _ = train_model(seed_interactions)
    import joblib
    from app.ml.reranker import MODEL_PATH
    joblib.dump(model, MODEL_PATH)

    # Filter seed interactions for demo_user_fit_01 (has > 20 interactions)
    user_interactions = [r for r in seed_interactions if r.get("user_id") == "demo_user_fit_01"]
    assert len(user_interactions) >= 20

    # Force model load
    MLReranker.reload()

    cards, ranker, delta = MLReranker.rerank(
        cards=sample_cards,
        user={"persona": "Fitness", "uid": "demo_user_fit_01"},
        user_interactions=user_interactions,
        confidence_margin_threshold=0.0,  # 0.0 threshold to test ML path
    )

    assert ranker == "ml"
    assert delta is not None
    assert "top1_changed" in delta
    assert "rank_shifts" in delta
    assert len(cards) == len(sample_cards)


def test_card_catalog_preservation(sample_cards, seed_interactions):
    model, _ = train_model(seed_interactions)
    import joblib
    from app.ml.reranker import MODEL_PATH
    joblib.dump(model, MODEL_PATH)

    user_interactions = [r for r in seed_interactions if r.get("user_id") == "demo_user_fit_01"]
    MLReranker.reload()

    cards, ranker, delta = MLReranker.rerank(
        cards=sample_cards,
        user={"persona": "Fitness", "uid": "demo_user_fit_01"},
        user_interactions=user_interactions,
        confidence_margin_threshold=0.0,
    )

    card_ids = [c.id for c in cards]
    assert len(card_ids) == len(sample_cards)
    assert set(card_ids) == {c.id for c in sample_cards}
