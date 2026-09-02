import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.ml.reranker import MLReranker

client = TestClient(app)


def test_personalization_home_rules_default():
    response = client.get("/personalization/home", headers={"Authorization": "Bearer test_token"})
    assert response.status_code == 200
    data = response.json()
    assert "persona" in data
    assert "cards" in data
    assert "ranker" in data
    assert data["ranker"] in ("rules", "ml")
    assert len(data["cards"]) > 0
    body = response.text
    assert "21°C" not in body
    assert "24.5°C" not in body
    assert "4.5 around 12:30" not in body
    for card in data["cards"]:
        assert card.get("reason") == card.get("human_readable_reason")


def test_post_interaction_logging():
    payload = {
        "card_id": "card_fit_01",
        "action_type": "click",
        "card_type": "activity_window",
        "action": "click",
    }
    response = client.post(
        "/personalization/interactions",
        json=payload,
        headers={"Authorization": "Bearer test_token"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["recorded"] is True
    assert data["status"] == "success"


def test_missing_model_graceful_fallback():
    # Model reload with invalid path should fallback to rules gracefully
    original_model = MLReranker._model
    MLReranker._model = None
    try:
        cards, ranker, delta = MLReranker.rerank(
            cards=[],
            user={"persona": "Fitness", "uid": "test_user"},
            user_interactions=[],
        )
        assert ranker == "rules"
        assert delta is None
    finally:
        MLReranker._model = original_model
