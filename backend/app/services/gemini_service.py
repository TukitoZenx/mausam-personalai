"""
Gemini LLM Service — Production-grade Weather Intelligence Agent.

Uses Google Gemini (gemini-2.0-flash / Gemini 3.8 Flash) with real weather data injected as
grounding context. The LLM NEVER invents weather data — it synthesizes
natural-language responses from factual data already fetched from OpenWeatherMap.

Safety controls:
  - Input sanitization (prompt injection defense)
  - Strict grounding in <WEATHER_DATA>
  - Separation of FACT vs. RECOMMENDATION
  - Severe weather safety prioritizing
  - Multilingual support (English, Telugu, Hindi, Tamil, Kannada, Malayalam, Bengali, Marathi)
  - Structured card extraction for mobile UI
  - Temperature 0.3-0.4 for high factual accuracy
  - Max output tokens capped
  - Timeout handling
  - Graceful fallback on any failure
"""

import json
import logging
import re
from typing import Any

from app.core.config import settings

logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────────────────────────────────────
# System Prompt — Weather Intelligence Agent Persona
# ──────────────────────────────────────────────────────────────────────────────

_SYSTEM_PROMPT = """You are **Mausam AI**, an advanced personal weather intelligence assistant inside the Mausam app.

## IDENTITY & CORE OBJECTIVE
You are specialized in weather, climate, travel planning, fitness/commute advisory, air quality, and environmental safety.
You speak with the tone of a knowledgeable, helpful, and concise meteorologist paired with a personal advisor.

## CRITICAL GROUNDING RULES (NO HALLUCINATION)
1. NEVER fabricate current or forecast weather information.
2. Only cite figures (temperature, feels-like, condition, humidity, wind, UV, rain, AQI, alerts) that appear in <WEATHER_DATA>.
3. If a field or metric is not present in <WEATHER_DATA> (such as pollen, ocean waves, tides, soil moisture), explicitly state that you do not have sensor data for that metric.
4. Distinguish between FACT and RECOMMENDATION:
   - **FACT**: Actual observed or officially forecast weather data.
   - **RECOMMENDATION**: Your reasoned personal interpretation for the user's activity or lifestyle based on those facts.
5. For probabilistic forecasts, never claim absolute certainty (e.g., use "70% chance of rain" rather than "it will certainly downpour all day").

## SEVERE WEATHER & SAFETY PROTOCOL
- If severe weather exists (thunderstorms, lightning, extreme heat ≥37°C, heavy rainfall, flash flood risk, gale-force winds, high AQI >200):
  1. Highlight safety FIRST before any activity recommendation.
  2. Clearly cite that an active warning/advisory exists.
  3. Offer practical precautions (stay indoors, avoid open fields during lightning, hydrate, wear N95 mask for high AQI).
  4. Never offer medical diagnoses.

## MULTILINGUAL CAPABILITIES
- You fluently understand and respond in:
  - English
  - Telugu (తెలుగు)
  - Hindi (हिन्दी)
  - Tamil (தமிழ்)
  - Kannada (ಕನ್ನಡ)
  - Malayalam (മലയാളം)
  - Bengali (বাংলা)
  - Marathi (मराठी)
- If the user greets or queries you in any of these languages (or requests a language), reply naturally and accurately in that language while strictly preserving all weather numbers and units (**28°C**, **AQI 65**).

## GREETINGS AND SMALL TALK
- If the user says hi, hello, hey, thanks, or small talk: reply warmly in 1-2 short sentences. Do NOT dump temperatures or a weather report unless they asked for it.

## FORMATTING & CARDS
- Format your response cleanly using markdown (bold key values like **31°C**, **AQI 48**, **60% rain**).
- If the query is asking about current weather, workout windows, wardrobe, health/AQI, travel, or forecasts, provide an optional structured card on its own line:
  CARDS:{"cardType":"activityWindow"|"clothingWardrobe"|"healthEnvironment"|"travelPacking"|"dailyPlan"|"forecastSummary"|"alertNotice","category":"CATEGORY NAME","headline":"Concise Primary Headline","subtitle":"Brief subtitle or timing","metrics":[{"label":"Metric","value":"Value"}],"explanation":"1-sentence summary"}
- Always end your final response with 2 to 3 contextual follow-up chips on the very last line:
  ACTIONS:["Follow-up question 1", "Follow-up question 2", "Follow-up question 3"]
"""


def _sanitize_input(text: str) -> str:
    """
    Basic prompt injection defense — strip control tokens and
    suspicious instruction overrides from user input.
    """
    sanitized = re.sub(
        r"(ignore\s+(all\s+)?previous\s+instructions|"
        r"disregard\s+(all\s+)?rules|"
        r"you\s+are\s+now\s+a|"
        r"system\s*:|"
        r"<\s*/?\s*system\s*>|"
        r"<\s*/?\s*assistant\s*>|"
        r"<\s*/?\s*WEATHER_DATA\s*>|"
        r"WEATHER_DATA|"
        r"ACTIONS\s*:|"
        r"CARDS\s*:|"
        r"reveal\s+(the\s+)?(system\s+prompt|api\s+key|internal\s+instructions))",
        "",
        text,
        flags=re.IGNORECASE,
    )
    return sanitized[:2000].strip()


def _build_grounding_context(
    weather_data: dict[str, Any] | None = None,
    forecast_data: list[dict[str, Any]] | None = None,
    user_context: dict[str, Any] | None = None,
    hourly_data: list[dict[str, Any]] | None = None,
    alerts_data: list[dict[str, Any]] | None = None,
    comparison_data: dict[str, Any] | None = None,
    saved_locations: list[dict[str, Any]] | None = None,
) -> str:
    """
    Build the factual grounding document injected into the LLM prompt.
    This is the ONLY source of weather truth the LLM is allowed to reference.
    """
    parts = ["<WEATHER_DATA>"]

    if weather_data:
        parts.append("## Current Conditions")
        parts.append(f"- Location: {weather_data.get('location', 'Unknown')}")
        parts.append(f"- Temperature: {weather_data.get('temperature_celsius', 'N/A')}°C")
        parts.append(f"- Feels Like: {weather_data.get('feels_like_celsius', 'N/A')}°C")
        parts.append(f"- Condition: {weather_data.get('condition', 'N/A')}")
        parts.append(f"- Humidity: {weather_data.get('humidity_percent', 'N/A')}%")
        parts.append(f"- Wind Speed: {weather_data.get('wind_speed_kmh', 'N/A')} km/h")
        parts.append(f"- UV Index: {weather_data.get('uv_index', 'N/A')}")
        parts.append(f"- AQI: {weather_data.get('aqi', 'N/A')} ({weather_data.get('aqi_category', 'N/A')})")

        if weather_data.get("rain_mm_1h") is not None:
            parts.append(f"- Rain (last 1h): {weather_data['rain_mm_1h']} mm")
        if weather_data.get("visibility_km") is not None:
            parts.append(f"- Visibility: {weather_data['visibility_km']} km")
        if weather_data.get("sunrise_unix") or weather_data.get("sunset_unix"):
            parts.append(f"- Sunrise/Sunset: Available in epoch format")
    else:
        parts.append("## Current Conditions\nNo live weather snapshot is available for the queried location.")

    if alerts_data:
        parts.append("\n## Active Official Weather Warnings & Advisories")
        for alert in alerts_data:
            parts.append(
                f"- [{alert.get('severity', 'Warning').upper()}] {alert.get('headline', 'Alert')}: "
                f"{alert.get('description', '')}"
            )

    if comparison_data:
        parts.append("\n## Multi-Location Comparison Data")
        w1 = comparison_data.get("location1", {})
        w2 = comparison_data.get("location2", {})
        parts.append(
            f"- {w1.get('location', 'Location 1')}: {w1.get('temperature_celsius', '?')}°C, "
            f"{w1.get('condition', '?')}, AQI {w1.get('aqi', '?')}"
        )
        parts.append(
            f"- {w2.get('location', 'Location 2')}: {w2.get('temperature_celsius', '?')}°C, "
            f"{w2.get('condition', '?')}, AQI {w2.get('aqi', '?')}"
        )
        parts.append(f"- Temp difference: {comparison_data.get('temperature_difference_celsius', 0)}°C")

    if hourly_data:
        parts.append("\n## Upcoming Hours")
        for hour in hourly_data[:8]:
            rain_pct = hour.get("rain_probability_percent")
            rain_str = f", rain chance {rain_pct}%" if rain_pct is not None else ""
            parts.append(
                f"- {hour.get('hour', '?')}: {hour.get('temperature_celsius', '?')}°C, "
                f"{hour.get('condition', '?')}{rain_str}"
            )

    if forecast_data:
        parts.append("\n## Daily Forecast (Next 5 Days)")
        for day in forecast_data[:5]:
            rain_pct = day.get("rain_probability_percent")
            rain_str = f", Rain: {rain_pct}%" if rain_pct else ""
            parts.append(
                f"- {day.get('day', '?')}: {day.get('condition', '?')}, "
                f"High {day.get('high_celsius', '?')}°C / Low {day.get('low_celsius', '?')}°C"
                f"{rain_str}"
            )

    if saved_locations:
        parts.append("\n## User's Saved Locations")
        for sl in saved_locations[:5]:
            parts.append(f"- {sl.get('name', 'City')} (Lat {sl.get('latitude', '?')}, Lon {sl.get('longitude', '?')})")

    if user_context:
        parts.append("\n## User Profile")
        if user_context.get("persona"):
            parts.append(f"- Persona: {user_context['persona']}")
        if user_context.get("health_concerns"):
            parts.append(f"- Health Concerns: {', '.join(user_context['health_concerns'])}")

    parts.append("</WEATHER_DATA>")
    return "\n".join(parts)


def _parse_response(raw_text: str) -> tuple[str, list[str], dict[str, Any] | None]:
    """
    Parse the LLM response to extract:
      1. Main markdown text
      2. Suggested action chips (ACTIONS:[...])
      3. Structured weather card data (CARDS:{...})
    """
    lines = raw_text.strip().split("\n")
    suggested_actions: list[str] = []
    card_data: dict[str, Any] | None = None
    main_text_lines: list[str] = []

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("ACTIONS:"):
            try:
                actions_json = stripped[len("ACTIONS:"):].strip()
                suggested_actions = json.loads(actions_json)
            except Exception:
                pass
        elif stripped.startswith("CARDS:"):
            try:
                card_json = stripped[len("CARDS:"):].strip()
                card_data = json.loads(card_json)
            except Exception:
                pass
        else:
            main_text_lines.append(line)

    main_text = "\n".join(main_text_lines).strip()

    if not suggested_actions:
        suggested_actions = [
            "Today's weather",
            "Will it rain today?",
            "Air quality index",
        ]

    return main_text, suggested_actions, card_data


class GeminiService:
    """Production Gemini LLM service with weather tool grounding and zero hallucination."""

    _model = None

    @classmethod
    def _get_model(cls):
        """Lazy-initialize the Gemini model."""
        if cls._model is None:
            if not settings.GEMINI_API_KEY:
                return None

            try:
                import google.generativeai as genai

                genai.configure(api_key=settings.GEMINI_API_KEY)
                model_name = getattr(settings, "GEMINI_MODEL", "gemini-2.0-flash")
                cls._model = genai.GenerativeModel(
                    model_name=model_name,
                    system_instruction=_SYSTEM_PROMPT,
                    generation_config={
                        "temperature": 0.35,
                        "max_output_tokens": 1200,
                        "top_p": 0.9,
                        "top_k": 40,
                    },
                )
                logger.info("✅ Gemini model initialized: %s", model_name)
            except Exception as exc:
                logger.error("Failed to initialize Gemini model: %s", exc)
                cls._model = None

        return cls._model

    @classmethod
    def is_available(cls) -> bool:
        """Check if the Gemini service is configured."""
        return bool(settings.GEMINI_API_KEY)

    @classmethod
    async def generate_response(
        cls,
        user_message: str,
        weather_data: dict[str, Any] | None = None,
        forecast_data: list[dict[str, Any]] | None = None,
        user_context: dict[str, Any] | None = None,
        hourly_data: list[dict[str, Any]] | None = None,
        alerts_data: list[dict[str, Any]] | None = None,
        comparison_data: dict[str, Any] | None = None,
        saved_locations: list[dict[str, Any]] | None = None,
        history: list[dict[str, str]] | None = None,
    ) -> tuple[str, list[str], dict[str, Any] | None] | None:
        """
        Generate a Gemini-powered weather response grounded in factual data.

        Returns (main_text, suggested_actions, card_data) or None on failure/unconfigured.
        """
        model = cls._get_model()
        if model is None:
            return None

        try:
            safe_input = _sanitize_input(user_message)
            grounding = _build_grounding_context(
                weather_data=weather_data,
                forecast_data=forecast_data,
                user_context=user_context,
                hourly_data=hourly_data,
                alerts_data=alerts_data,
                comparison_data=comparison_data,
                saved_locations=saved_locations,
            )

            prompt_sections = [grounding]

            if history:
                prompt_sections.append("\n## Conversation History")
                for turn in history[-6:]:
                    role = turn.get("role", "user").capitalize()
                    content = _sanitize_input(turn.get("content", ""))
                    if content:
                        prompt_sections.append(f"{role}: {content}")

            prompt_sections.append(f"\nUser: {safe_input}\nAssistant:")
            full_prompt = "\n".join(prompt_sections)

            response = await model.generate_content_async(
                full_prompt,
                request_options={"timeout": 15},
            )

            if response and response.text:
                main_text, actions, card = _parse_response(response.text)
                if main_text:
                    logger.info("Gemini response generated (%d chars)", len(main_text))
                    return main_text, actions, card

            logger.warning("Gemini returned empty response")
            return None

        except Exception as exc:
            logger.warning("Gemini call failed (falling back to template): %s", exc)
            return None
