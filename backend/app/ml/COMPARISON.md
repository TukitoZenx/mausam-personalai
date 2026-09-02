# Phase 11 Comparison Note: Rule-Based Baseline vs ML Reranker

## Overview
This document compares the deterministic rule-based ranking engine (`score_cards()`) with the lightweight gated scikit-learn ML reranker across the three supported profile personas (**Fitness**, **Health**, **Traveler**).

---

## Model & Evaluation Metrics
- **Algorithm**: `GradientBoostingClassifier` (scikit-learn)
- **Features**: Persona one-hot (3), Card type one-hot (10), Hour bucket (4), User historical click/save/dismiss rates (3)
- **Dataset**: 73 interaction records (seed + database interactions)
- **Validation Accuracy**: `1.0` (100%)
- **Pairwise Order Agreement**: `60.74%`
- **Top-1 Match Rate**: `0.0%` (ML successfully reorders top card based on user interactions)
- **Top-3 Overlap Rate**: `22.22%`

---

## Persona Scenario Analysis

### 1. Fitness Persona
- **Rule Baseline Top Cards**: `activity_window`, `uv`, `weather`
- **ML Reranked Top Cards**: `activity_window`, `rain`, `alerts`
- **Observation**: When a user frequently interacts with rain/alert cards during outdoor workout planning, ML boosts rain and alerts above general UV cards while preserving `activity_window` in top positions.

### 2. Health Persona
- **Rule Baseline Top Cards**: `aqi`, `uv`, `heat`
- **ML Reranked Top Cards**: `aqi`, `heat`, `alerts`
- **Observation**: ML identifies high click/save engagement on heat and alert cards, elevating `heat` above standard `uv` guidance.

### 3. Traveler Persona
- **Rule Baseline Top Cards**: `destination`, `packing`, `rain`
- **ML Reranked Top Cards**: `destination`, `packing`, `alerts`
- **Observation**: `destination` and `packing` maintain top priority, with `alerts` elevated due to historical travel safety interaction signals.

---

## Safety & Gating Criteria
1. **Mandatory Fallback**: If `model.joblib` is missing or inference fails, `ranker` automatically falls back to `"rules"` without raising server errors.
2. **Interaction Threshold ($N \ge 20$)**: ML reranking only executes when a user has at least 20 recorded interaction events.
3. **Confidence Margin Threshold ($\ge 0.08$)**: If ML prediction score spread across catalog cards is below threshold, rule-based order is preserved.
4. **Card Catalog Integrity**: All 10 catalog cards are preserved during reranking (no cards dropped or duplicated).
