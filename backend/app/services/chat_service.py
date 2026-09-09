"""
Chat Service — Mausam AI Orchestrator.

Architecture:
  User Query
      ↓
  Chat Intent & Location Intelligence
      ├── Detect comparison between locations (e.g. "Hyderabad vs Guntur")
      ├── Detect query for specific location (e.g. "weather in Vijayawada")
      ├── Evaluate saved locations comparison (e.g. "lowest temperature in saved locations")
      └── Default to active location / GPS
      ↓
  Weather Tools Execution (Grounded Data Retrieval)
      ├── get_current_weather
      ├── get_hourly_forecast / get_daily_forecast
      ├── get_weather_alerts
      ├── get_air_quality
      └── compare_weather
      ↓
  Gemini Intelligence (Zero-Hallucination Grounding, Multi-Turn Memory, Multilingual)
      ↓ (Graceful Fallback if unconfigured/offline)
  Template & Rule-Based Reasoner (Factual Breakdown + Smart UI Card)
      ↓
  Structured ChatMessageResponse (Reply, Card Data, Actions, Facts, Recommendations)
"""

from datetime import datetime, timezone
import logging
import math
import re
import time
from typing import Any

import httpx

from app.schemas.chat import (
    ChatMessageRequest,
    ChatMessageResponse,
    ReminderCreate,
)
from app.services.adapters import nominatim_adapter
from app.services.gemini_service import GeminiService
from app.services.reminder_service import ReminderService, normalize_time_str
from app.services import weather_tools

logger = logging.getLogger(__name__)

_GREETING_RE = re.compile(
    r"^(hi+|hii+|hello|hey+|yo|hola|namaste|sup|howdy|"
    r"hi there|hey there|hello there|"
    r"good (morning|afternoon|evening|night)|"
    r"నమస్కారం|బాగున్నారా|नमस्ते|வணக்கம்|ನಮಸ್ಕಾರ)"
    r"(\s+(mausam|ai|mausam\s+ai|assistant|there))?"
    r"[\s!.?]*$",
    re.IGNORECASE,
)
_SMALLTALK_RE = re.compile(
    r"^(how are you( doing)?( today)?|how's it going|hows it going|"
    r"what's up|whats up|how do you do|you good|you there|"
    r"ఎలా ఉన్నారు|आप कैसे हैं)"
    r"[\s!.?]*$",
    re.IGNORECASE,
)
_THANKS_RE = re.compile(
    r"^(thanks(\s+a\s+lot)?|thank you(\s+so\s+much|\s+very\s+much)?|thx|ty|tysm|ధన్యవాదాలు|धन्यवाद)[\s!.?]*$",
    re.IGNORECASE,
)
_HELP_RE = re.compile(
    r"^(help|what can you do|who are you|what are you|"
    r"what do you do|how does this work|capabilities|what are your capabilities)[\s!.?]*$",
    re.IGNORECASE,
)
_CASUAL_CHAT_RE = re.compile(
    r"^(ok|okay|cool|nice|awesome|great|super|perfect|got it|sounds good|"
    r"bye|goodbye|see you|see ya|cya|take care|have a nice day|good night)[\s!.?]*$",
    re.IGNORECASE,
)

_WEATHER_HINTS = (
    "weather", "temperature", "temp", "forecast", "rain", "umbrella", "shower",
    "storm", "thunder", "aqi", "air quality", "pollution", "smog", "humidity",
    "wind", "uv", "wear", "outfit", "clothes", "jacket", "coat", "workout",
    "run", "jog", "fitness", "exercise", "commute", "drive", "hot", "cold",
    "sunny", "cloud", "humid", "visibility", "sunrise", "sunset", "outside",
    "outdoor", "heat", "cool", "chilly", "snow", "drizzle", "cricket", "play",
    "tomorrow", "weekend", "briefing", "radar", "travel", "safe", "safest",
    "varsham", "varsham padutunda", "mausam", "kaisa", "hawa",
)


_KNOWN_CITY_COORDS: dict[str, tuple[float, float]] = {
    "chennai": (13.0827, 80.2707),
    "vijayawada": (16.5062, 80.6480),
    "hyderabad": (17.3850, 78.4867),
    "guntur": (16.3067, 80.4365),
    "bangalore": (12.9716, 77.5946),
    "bengaluru": (12.9716, 77.5946),
    "mumbai": (19.0760, 72.8777),
    "delhi": (28.6139, 77.2090),
    "new delhi": (28.6139, 77.2090),
    "kolkata": (22.5726, 88.3639),
    "visakhapatnam": (17.6868, 83.2185),
    "vizag": (17.6868, 83.2185),
    "tirupati": (13.6288, 79.4192),
    "pune": (18.5204, 73.8567),
    "ahmedabad": (23.0225, 72.5714),
    "jaipur": (26.9124, 75.7873),
    "kochi": (9.9312, 76.2673),
    "coimbatore": (11.0168, 76.9558),
    "madurai": (9.9252, 78.1198),
}


def calculate_haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Great-circle distance in kilometers using the Haversine formula."""
    r = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    a = math.sin(delta_phi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return r * c


def _clean_travel_place_name(name: str) -> str:
    n = name.strip()
    n = re.sub(r"^(?:the\s+city\s+of|the\s+town\s+of|the)\s+", "", n, flags=re.IGNORECASE)
    n = re.sub(r"\s+(?:city|town|area|state)$", "", n, flags=re.IGNORECASE)
    n = re.sub(r"\b(by\s+road|by\s+car|by\s+bus|by\s+train|road|highway|trip|route|weather|tomorrow|today|tonight)\b.*$", "", n, flags=re.IGNORECASE)
    return n.strip().title()


def _extract_travel_route_endpoints(text: str) -> tuple[str, str] | None:
    """
    Extract (origin, destination) from natural-language travel and route queries:
      - 'I will go to Vijayawada from Chennai' -> ('Chennai', 'Vijayawada')
      - 'Travel from Chennai to Vijayawada' -> ('Chennai', 'Vijayawada')
      - 'Trip to Vijayawada from Chennai' -> ('Chennai', 'Vijayawada')
      - 'Chennai to Vijayawada' -> ('Chennai', 'Vijayawada')
      - 'Commute to Vijayawada from Chennai' -> ('Chennai', 'Vijayawada')
    """
    clean = text.strip()
    if re.search(r"\b(compare|compared|vs\.?|versus)\b", clean, re.IGNORECASE):
        return None
    clean_core = re.sub(
        r"^(?:i\s+will|i'm|i\s+am|we\s+will|we're|we\s+are|planning\s+to|plan\s+to|want\s+to|need\s+to|how\s+is\s+the|what\s+is\s+the|can\s+i|please|check\s+the)\s+",
        "",
        clean,
        flags=re.IGNORECASE,
    ).strip()

    # 1. "to <DEST> from <ORIGIN>"
    m = re.search(
        r"\b(?:go|going|travel|traveling|travelling|trip|commute|commuting|drive|driving)?\s*to\s+([A-Za-z\s]+?)\s+from\s+([A-Za-z\s]+?)(?:\s+(?:by|on|via|with|tomorrow|today|tonight|next)|[?.!,]|$)",
        clean_core,
        re.IGNORECASE,
    )
    if m:
        dest = _clean_travel_place_name(m.group(1))
        origin = _clean_travel_place_name(m.group(2))
        if len(origin) >= 2 and len(dest) >= 2 and origin.lower() != dest.lower():
            return origin, dest

    # 2. "from <ORIGIN> to <DEST>"
    m = re.search(
        r"\b(?:travel|traveling|travelling|trip|commute|commuting|drive|driving|route|going|go)?\s*from\s+([A-Za-z\s]+?)\s+to\s+([A-Za-z\s]+?)(?:\s+(?:by|on|via|with|tomorrow|today|tonight|next)|[?.!,]|$)",
        clean_core,
        re.IGNORECASE,
    )
    if m:
        origin = _clean_travel_place_name(m.group(1))
        dest = _clean_travel_place_name(m.group(2))
        if len(origin) >= 2 and len(dest) >= 2 and origin.lower() != dest.lower():
            return origin, dest

    # 3. "<ORIGIN> to <DEST>" (e.g. "Chennai to Vijayawada")
    m = re.search(
        r"^([A-Za-z\s]+?)\s+(?:to|->|→)\s+([A-Za-z\s]+?)(?:\s+(?:route|trip|drive|weather|by\s+road)|[?.!,]|$)",
        clean_core,
        re.IGNORECASE,
    )
    if m:
        origin = _clean_travel_place_name(m.group(1))
        dest = _clean_travel_place_name(m.group(2))
        stopwords = {"how", "what", "where", "when", "why", "who", "welcome", "thanks"}
        if (
            len(origin) >= 2
            and len(dest) >= 2
            and origin.lower() not in stopwords
            and dest.lower() not in stopwords
            and origin.lower() != dest.lower()
        ):
            return origin, dest

    # 4. "<DEST> from <ORIGIN>" (e.g. "Vijayawada from Chennai")
    m = re.search(
        r"^([A-Za-z\s]+?)\s+from\s+([A-Za-z\s]+?)(?:\s+(?:route|trip|drive|weather|by\s+road)|[?.!,]|$)",
        clean_core,
        re.IGNORECASE,
    )
    if m:
        dest = _clean_travel_place_name(m.group(1))
        origin = _clean_travel_place_name(m.group(2))
        stopwords = {"how", "what", "where", "when", "why", "who", "welcome", "thanks"}
        if (
            len(origin) >= 2
            and len(dest) >= 2
            and origin.lower() not in stopwords
            and dest.lower() not in stopwords
            and origin.lower() != dest.lower()
        ):
            return origin, dest

    return None


async def _resolve_endpoint_coords(
    location: str,
    default_lat: float,
    default_lon: float,
    default_name: str,
) -> tuple[float, float, str]:
    """Resolve endpoint coordinates using real geocoding with known cache fallback."""
    clean = location.strip().lower()
    if clean in _KNOWN_CITY_COORDS:
        lat, lon = _KNOWN_CITY_COORDS[clean]
        return lat, lon, location.strip().title()

    lat, lon, name = await weather_tools.resolve_location_coords(
        location,
        default_lat=default_lat,
        default_lon=default_lon,
        default_name=default_name,
    )
    return lat, lon, name


_ROUTE_REVERSE_GEO_CACHE: dict[str, tuple[float, str]] = {}
_ROUTE_WEATHER_CACHE: dict[str, tuple[float, dict[str, Any]]] = {}
_CACHE_TTL_GEO = 86400.0  # 24 hours
_CACHE_TTL_WEATHER = 900.0  # 15 minutes


async def _query_osrm_route(
    origin_lat: float,
    origin_lon: float,
    dest_lat: float,
    dest_lon: float,
) -> tuple[list[list[float]] | None, float | None, float | None]:
    """
    Query OSRM driving route API over HTTPS for actual road distance, duration, and geometry.
    Returns: (coordinates [[lon, lat], ...], distance_km, duration_minutes) or (None, None, None).
    """
    url = (
        f"https://router.project-osrm.org/route/v1/driving/"
        f"{origin_lon:.6f},{origin_lat:.6f};{dest_lon:.6f},{dest_lat:.6f}"
        f"?overview=simplified&geometries=geojson"
    )
    headers = {"User-Agent": "MausamPersonalAI/1.0 (contact@mausam.ai)"}
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(4.0)) as client:
            resp = await client.get(url, headers=headers)
            if resp.status_code == 200:
                data = resp.json()
                if data.get("code") == "Ok" and data.get("routes"):
                    route = data["routes"][0]
                    dist_km = route.get("distance", 0.0) / 1000.0
                    dur_mins = route.get("duration", 0.0) / 60.0
                    coords = route.get("geometry", {}).get("coordinates", [])
                    if dist_km > 0:
                        return coords, dist_km, dur_mins
    except Exception as exc:
        logger.warning("OSRM route query failed, using geographic fallback: %s", exc)
    return None, None, None


async def _reverse_geocode_stop(lat: float, lon: float) -> str | None:
    """Reverse geocode coordinate to a clean administrative town or city name."""
    cache_key = f"{round(lat, 2)}:{round(lon, 2)}"
    now = time.time()
    if cache_key in _ROUTE_REVERSE_GEO_CACHE:
        ts, name = _ROUTE_REVERSE_GEO_CACHE[cache_key]
        if now - ts < _CACHE_TTL_GEO:
            return name

    name = None
    try:
        res = await nominatim_adapter.reverse_geocode(lat, lon)
        raw_name = res.city or (res.place_name.split(",")[0] if res.place_name else "")
        cleaned = re.sub(
            r"\b(mandal|taluk|district|tehsil|division|county|municipality)\b",
            "",
            raw_name,
            flags=re.IGNORECASE,
        ).strip()
        if len(cleaned) >= 3 and not re.match(r"^\d", cleaned):
            name = cleaned.title()
    except Exception as exc:
        logger.debug("Reverse geocode failed for (%f, %f): %s", lat, lon, exc)

    if name:
        _ROUTE_REVERSE_GEO_CACHE[cache_key] = (now, name)
    return name


async def _fetch_cached_point_weather(name: str, lat: float, lon: float) -> dict[str, Any] | None:
    """Fetch current weather for a stop along the route with in-memory caching and safe error isolation."""
    cache_key = f"{round(lat, 2)}:{round(lon, 2)}"
    now = time.time()
    if cache_key in _ROUTE_WEATHER_CACHE:
        ts, cached_w = _ROUTE_WEATHER_CACHE[cache_key]
        if now - ts < _CACHE_TTL_WEATHER:
            return cached_w

    try:
        w = await weather_tools.get_current_weather(
            location=name,
            default_lat=lat,
            default_lon=lon,
            default_name=name,
        )
        formatted = {
            "temperature": w.get("temperature_celsius"),
            "feelsLike": w.get("feels_like_celsius"),
            "condition": w.get("condition"),
            "humidity": w.get("humidity_percent"),
            "windSpeed": w.get("wind_speed_kmh"),
            "aqi": w.get("aqi"),
            "aqiCategory": w.get("aqi_category"),
            "rainMm": w.get("rain_mm_1h", 0.0),
        }
        _ROUTE_WEATHER_CACHE[cache_key] = (now, formatted)
        return formatted
    except Exception as exc:
        logger.warning("Failed to fetch weather for route stop '%s': %s", name, exc)
        return None


async def _determine_route_locations(
    origin: str,
    dest: str,
    origin_lat: float,
    origin_lon: float,
    dest_lat: float,
    dest_lon: float,
) -> tuple[list[dict[str, Any]], int, str, bool, str]:
    """
    Determine driving route, distance, duration, and intermediate cities.
    Returns:
      (route_points, distance_km, duration_text, is_estimated, route_source)
    """
    coords, osrm_dist_km, osrm_dur_mins = await _query_osrm_route(origin_lat, origin_lon, dest_lat, dest_lon)

    if coords is not None and osrm_dist_km is not None and osrm_dist_km > 0:
        distance_km = round(osrm_dist_km)
        is_estimated = False
        route_source = "osrm"
        dur_mins = round(osrm_dur_mins if osrm_dur_mins is not None else ((distance_km / 60.0) * 60))
        hours = dur_mins // 60
        mins = dur_mins % 60
        if hours > 0 and mins > 0:
            duration_text = f"{hours}h {mins}m"
        elif hours > 0:
            duration_text = f"{hours}h"
        else:
            duration_text = f"{mins}m"
    else:
        crow_km = calculate_haversine_distance_km(origin_lat, origin_lon, dest_lat, dest_lon)
        distance_km = max(1, round(crow_km * 1.22))
        is_estimated = True
        route_source = "estimated"
        est_mins = round((distance_km / 60.0) * 60)
        hours = est_mins // 60
        mins = est_mins % 60
        if hours > 0 and mins > 0:
            duration_text = f"~{hours}h {mins}m (est. drive)"
        elif hours > 0:
            duration_text = f"~{hours}h (est. drive)"
        else:
            duration_text = f"~{mins}m (est. drive)"

    intermediate_stops: list[dict[str, Any]] = []

    if distance_km >= 60:
        if distance_km < 180:
            sample_fractions = [0.50]
        elif distance_km < 450:
            sample_fractions = [0.37, 0.63]
        elif distance_km < 800:
            sample_fractions = [0.25, 0.50, 0.75]
        else:
            sample_fractions = [0.20, 0.40, 0.60, 0.80]

        sampled_coords: list[tuple[float, float]] = []
        if coords and len(coords) >= len(sample_fractions) + 2:
            cum_dists = [0.0]
            for i in range(1, len(coords)):
                d = calculate_haversine_distance_km(coords[i - 1][1], coords[i - 1][0], coords[i][1], coords[i][0])
                cum_dists.append(cum_dists[-1] + d)
            total_poly_dist = cum_dists[-1] if cum_dists[-1] > 0 else float(distance_km)

            for frac in sample_fractions:
                target_d = total_poly_dist * frac
                best_idx = min(range(len(coords)), key=lambda i: abs(cum_dists[i] - target_d))
                lon_val, lat_val = coords[best_idx]
                sampled_coords.append((lat_val, lon_val))
        else:
            for frac in sample_fractions:
                lat_val = origin_lat + frac * (dest_lat - origin_lat)
                lon_val = origin_lon + frac * (dest_lon - origin_lon)
                sampled_coords.append((lat_val, lon_val))

        seen_names = {origin.lower(), dest.lower()}
        for s_lat, s_lon in sampled_coords:
            if calculate_haversine_distance_km(s_lat, s_lon, origin_lat, origin_lon) < 25:
                continue
            if calculate_haversine_distance_km(s_lat, s_lon, dest_lat, dest_lon) < 25:
                continue

            place_name = await _reverse_geocode_stop(s_lat, s_lon)
            if not place_name:
                continue
            if place_name.lower() in seen_names:
                continue

            too_close = False
            for existing in intermediate_stops:
                if calculate_haversine_distance_km(s_lat, s_lon, existing["lat"], existing["lon"]) < 30:
                    too_close = True
                    break
            if too_close:
                continue

            seen_names.add(place_name.lower())
            intermediate_stops.append({
                "name": place_name,
                "role": "intermediate",
                "lat": round(s_lat, 4),
                "lon": round(s_lon, 4),
            })

    all_points_spec = (
        [{"name": origin, "role": "origin", "lat": origin_lat, "lon": origin_lon}]
        + intermediate_stops
        + [{"name": dest, "role": "destination", "lat": dest_lat, "lon": dest_lon}]
    )

    final_route_points: list[dict[str, Any]] = []
    for pt in all_points_spec:
        w_data = await _fetch_cached_point_weather(pt["name"], pt["lat"], pt["lon"])
        final_route_points.append({
            "name": pt["name"],
            "role": pt["role"],
            "lat": pt["lat"],
            "lon": pt["lon"],
            "weather": w_data if w_data is not None else {
                "temperature": None,
                "feelsLike": None,
                "condition": None,
                "humidity": None,
                "windSpeed": None,
                "aqi": None,
                "aqiCategory": None,
                "rainMm": None,
            },
        })

    route_geometry: list[dict[str, float]] = []
    if coords:
        step = max(1, len(coords) // 80)
        sampled = coords[::step]
        if coords[-1] not in sampled:
            sampled.append(coords[-1])
        route_geometry = [{"lat": round(c[1], 4), "lon": round(c[0], 4)} for c in sampled]
    else:
        route_geometry = [{"lat": pt["lat"], "lon": pt["lon"]} for pt in all_points_spec]

    return final_route_points, distance_km, duration_text, is_estimated, route_source, route_geometry


def _extract_comparison_locations(text: str) -> tuple[str, str] | None:
    """
    Detect location comparison patterns like:
      - 'How is Hyderabad compared to Guntur?'
      - 'Compare Hyderabad and Guntur'
      - 'Hyderabad vs Guntur'
      - 'Compare weather in Delhi and Mumbai'
    """
    clean = text.strip()
    m = re.search(r"compare\s+(?:weather\s+in\s+)?([A-Za-z\s]+?)\s+(?:and|with|to)\s+([A-Za-z\s]+?)(?:\?|$)", clean, re.IGNORECASE)
    if m:
        return m.group(1).strip(), m.group(2).strip()

    m = re.search(r"([A-Za-z\s]+?)\s+(?:compared\s+to|vs\.?|versus)\s+([A-Za-z\s]+?)(?:\?|$)", clean, re.IGNORECASE)
    if m:
        loc1 = re.sub(r"^(how is|how's|what is|what's)\s+", "", m.group(1), flags=re.IGNORECASE).strip()
        loc2 = m.group(2).strip()
        if loc1 and loc2:
            return loc1, loc2

    return None


def _extract_location_mention(text: str) -> str | None:
    """
    Extract explicit location targets mentioned with:
      - 'in <City>' or 'for <City>' (e.g. 'weather in Vijayawada tomorrow' -> 'Vijayawada')
      - '<City> weather' (e.g. 'Hyderabad weather' -> 'Hyderabad')
    """
    clean = text.strip()
    truncated = re.sub(r"\b(tomorrow|today|tonight|now|yesterday|this weekend|this evening|next week|the morning)\b.*$", "", clean, flags=re.IGNORECASE).strip()
    stopwords = {
        "the morning", "the evening", "the afternoon", "the night", "my area",
        "this city", "degrees", "celsius", "fahrenheit", "detail", "hours",
        "advance", "a run", "cricket", "outdoor", "walking", "travel",
        "what", "what is", "how is", "show", "tell", "check", "current",
    }
    m = re.search(r"\b(?:in|at|for)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)\b", truncated, re.IGNORECASE)
    if m:
        candidate = m.group(1).strip()
        if candidate.lower() not in stopwords and len(candidate) > 2:
            return candidate

    m = re.search(r"^([A-Za-z]+(?:\s+[A-Za-z]+)?)\s+weather\b", clean, re.IGNORECASE)
    if m:
        candidate = m.group(1).strip()
        if candidate.lower() not in stopwords and len(candidate) > 2:
            return candidate
    return None


def _extract_time_and_frequency(text: str) -> tuple[str | None, str]:
    freq = "once" if "once" in text.lower() else "daily"
    m = re.search(r"\b(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\b", text, re.IGNORECASE)
    if m:
        candidate = m.group(1).strip()
        if any(c.isdigit() for c in candidate):
            if candidate.isdigit():
                val = int(candidate)
                if val <= 12 and f"at {val}" in text.lower():
                    candidate = f"{val}:00"
                elif val <= 24:
                    candidate = f"{val}:00"
            return normalize_time_str(candidate), freq
    return None, freq


def _is_general_chat(text: str) -> bool:
    stripped = text.strip()
    if (
        _GREETING_RE.match(stripped)
        or _SMALLTALK_RE.match(stripped)
        or _THANKS_RE.match(stripped)
        or _HELP_RE.match(stripped)
        or _CASUAL_CHAT_RE.match(stripped)
    ):
        return True
    lower = stripped.lower()
    if re.search(r"\b(how are you|how's it going|hows it going|what's up|whats up|how do you do|you good)\b", lower):
        return True
    if re.search(r"\b(what can you do|who are you|what are you|what do you do|capabilities)\b", lower):
        return True
    if any(w in lower for w in ("thank you", "thanks a lot", "thanks so much", "thx", "tysm")):
        return True
    return False


def _generate_general_chat_reply(text: str, user_name: str | None = None) -> tuple[str, list[str]]:
    """
    Generate fast, natural, conversational responses for general chat messages.
    Adheres strictly to zero external/weather API call constraint.
    """
    stripped = text.strip()
    lower = stripped.lower()

    # “Hey, how are you?” → “I’m doing great! 😊 What can I help you with?”
    if re.search(r"\b(how are you|how's it going|hows it going|what's up|whats up|how do you do|you good)\b", lower):
        reply = "I’m doing great! 😊 What can I help you with?"
        actions = ["What's the weather today?", "Will it rain today?", "Air quality index", "What can you do?"]
        return reply, actions

    # “What can you do?” → Explain chatbot capabilities.
    if _HELP_RE.match(stripped) or any(k in lower for k in ("what can you do", "who are you", "what are you", "what do you do", "capabilities")):
        reply = (
            "I'm **Mausam AI**, your personal weather intelligence assistant! 🌤️ Here is what I can do for you:\n\n"
            "• **Live Weather**: Instant temperature, 'feels-like', humidity, wind, and conditions\n"
            "• **Forecasts**: Hourly trends and 5-day daily forecasts\n"
            "• **Air Quality (AQI)**: Live pollution levels and respiratory health guidance\n"
            "• **Severe Weather Alerts**: Official storm, heatwave, and heavy rain warnings\n"
            "• **Activity Intelligence**: Optimal windows for cricket, running, workouts, and outdoor sports\n"
            "• **Travel & Commute**: Weather comparison across cities and road safety insights\n"
            "• **Wardrobe & Routine**: Personalized outfit advice, umbrella reminders, and daily schedules\n\n"
            "What would you like to check today?"
        )
        actions = ["What's the weather in Hyderabad?", "Will it rain today?", "Check air quality", "Can I play cricket today?"]
        return reply, actions

    # “Thanks” → “You’re welcome! 😊”
    if _THANKS_RE.match(stripped) or any(k in lower for k in ("thanks", "thank you", "thx", "ty", "tysm")):
        reply = "You’re welcome! 😊"
        actions = ["Today's weather", "Air quality index", "5-day forecast"]
        return reply, actions

    # “Hi” → “Hello! 👋 How can I help you today?”
    if _GREETING_RE.match(stripped) or re.match(r"^(hi+|hii+|hello|hey+|yo|hola|namaste|sup|howdy)[\s!.?]*$", stripped, re.IGNORECASE):
        reply = "Hello! 👋 How can I help you today?"
        actions = ["What's the weather today?", "Will it rain today?", "Air quality index", "5-day forecast"]
        return reply, actions

    # Good morning / afternoon / evening
    if "good morning" in lower:
        reply = "Good morning! ☀️ How can I help you today?"
        actions = ["Today's weather", "Will it rain today?", "Air quality index"]
        return reply, actions
    if "good afternoon" in lower:
        reply = "Good afternoon! 🌤️ Hope your day is going well. What can I help you with today?"
        actions = ["Current temperature", "Rain chance today", "Air quality index"]
        return reply, actions
    if "good evening" in lower:
        reply = "Good evening! 🌙 How can I assist you with your evening plans or tomorrow's forecast?"
        actions = ["Forecast for tomorrow", "Tonight's temperature", "Air quality right now"]
        return reply, actions
    if "good night" in lower:
        reply = "Good night! 🌙 Sleep well and stay safe. Check back anytime for tomorrow's weather!"
        actions = ["Tomorrow's weather", "Will it rain tomorrow?"]
        return reply, actions

    # Casual farewells & pleasantries
    if any(w in lower for w in ("bye", "goodbye", "see you", "see ya", "cya", "take care")):
        reply = "Goodbye! 👋 Stay safe and have a fantastic day ahead!"
        actions = ["Today's weather", "Tomorrow's forecast"]
        return reply, actions

    if any(w in lower for w in ("cool", "awesome", "great", "nice", "perfect", "sounds good", "ok", "okay")):
        reply = "Awesome! 😊 Feel free to ask whenever you need weather, AQI, travel, or activity updates."
        actions = ["What's the weather today?", "Will it rain today?", "Air quality index"]
        return reply, actions

    # Default friendly greeting
    reply = "Hello! 👋 How can I help you today?"
    actions = ["What's the weather today?", "Will it rain today?", "Air quality index", "What can you do?"]
    return reply, actions


def _generate_concept_reply(text: str) -> tuple[str, list[str]]:
    """Generate educational replies for meteorological concepts."""
    lower_q = text.lower()
    if "humidity" in lower_q:
        concept_reply = (
            "**Humidity** is the amount of water vapor present in the atmosphere.\n\n"
            "• **Relative Humidity (RH)** indicates how close the air is to being completely saturated with water vapor (100%).\n"
            "• When humidity is high (above 65%), sweat cannot evaporate efficiently from your skin, making the air feel muggy, sticky, and hotter than the actual temperature.\n"
            "• When humidity is low (below 30%), the air feels dry and crisp, which can cause skin dryness or respiratory irritation."
        )
    elif "feel" in lower_q or "30" in lower_q:
        concept_reply = (
            "**Why does 30°C feel like 35°C? (The Heat Index)**\n\n"
            "Your body cools itself down through the evaporation of sweat. When atmospheric humidity is elevated, the air is already laden with moisture, so sweat evaporates much more slowly.\n\n"
            "Because heat remains trapped on your skin, your body perceives a significantly higher temperature than the thermometer reads. Meteorologists calculate this as the **'Feels-Like' Temperature** or **Heat Index**."
        )
    elif "dew" in lower_q:
        concept_reply = (
            "**Dew Point** is the temperature to which air must cool for water vapor to condense into liquid droplets (dew, mist, or clouds).\n\n"
            "• **Below 15°C**: Crisp, dry, and comfortable.\n"
            "• **15°C to 20°C**: Noticeable moisture in the air.\n"
            "• **Above 20°C**: Muggy and oppressive tropical humidity.\n\n"
            "Dew point is often a more reliable indicator of physical human comfort than relative humidity because it measures absolute atmospheric water content."
        )
    elif "thunderstorm" in lower_q:
        concept_reply = (
            "**What causes Thunderstorms?**\n\n"
            "Thunderstorms form when three conditions align:\n"
            "1. **Surface Moisture**: Warm, humid air near the ground.\n"
            "2. **Atmospheric Instability**: Warm air rising rapidly into colder air above.\n"
            "3. **Lift Mechanism**: Solar heating or frontal boundaries pushing the warm air upward.\n\n"
            "As the rising moisture condenses into towering cumulonimbus clouds, ice crystals collide, creating electrical charges that discharge as **lightning and thunder**."
        )
    elif "pressure" in lower_q:
        concept_reply = (
            "**Atmospheric Pressure** represents the weight of the air column pressing down on the Earth's surface.\n\n"
            "• **High Pressure**: Air gently sinks, inhibiting cloud formation and delivering clear, calm skies.\n"
            "• **Low Pressure**: Air rises, cools, and condenses into clouds and precipitation. A rapid drop in barometric pressure often heralds stormy weather."
        )
    elif "rain" in lower_q or "probability" in lower_q or "80%" in lower_q:
        concept_reply = (
            "**What does an 80% chance of rain mean? (Probability of Precipitation)**\n\n"
            "Probability of Precipitation (PoP) combines meteorological certainty with spatial coverage (**PoP = Confidence × Area Fraction**).\n\n"
            "An 80% chance means that under these exact atmospheric parameters, there is an 8-in-10 likelihood that at least 0.1 mm of precipitation will fall anywhere within your local forecast area during that forecast period."
        )
    else:
        concept_reply = (
            "**Meteorological Concepts in Mausam AI**\n\n"
            "Weather parameters like temperature, humidity, wind, and pressure interact continuously to create the conditions you experience outdoors. Ask me about any specific concept like *'What is humidity?'*, *'What is dew point?'*, or *'Why does 30°C feel like 35°C?'*!"
        )
    actions = ["What is dew point?", "Why does 30°C feel hotter?", "Today's weather"]
    return concept_reply, actions


def classify_chat_intent(text: str) -> str:
    """
    Classify user message into one of 9 canonical intents:
      GENERAL_CHAT | WEATHER | FORECAST | LOCATION | AQI | ALERT | TRAVEL | ACTIVITY | OTHER
    """
    stripped = text.strip()
    lower = stripped.lower()

    # 1. Educational meteorological concepts or reminders -> OTHER
    if any(p in lower for p in (
        "what is humidity", "what is dew point", "why does it feel hotter", "why does 30",
        "what causes thunderstorm", "what is atmospheric pressure", "what is wind chill",
        "what does rain probability mean", "what does 80% rain", "explain humidity", "explain dew point",
        "explain pressure", "meteorological concept"
    )):
        return "OTHER"
    if any(k in lower for k in ("remind", "reminder", "alarm", "schedule notification", "notify me")):
        return "OTHER"

    # 2. Location comparison or travel route/commute inquiry -> TRAVEL
    if _extract_travel_route_endpoints(stripped) is not None:
        return "TRAVEL"
    if _extract_comparison_locations(stripped) is not None:
        return "TRAVEL"
    if any(k in lower for k in (
        "travel to", "traveling to", "travelling to", "driving to", "trip to",
        "go to", "going to", "route to", "route from",
        "road condition", "road conditions", "commute to", "commute from",
        "safe to drive", "safe to travel", "flight weather", "highway weather"
    )):
        return "TRAVEL"

    # 3. Saved locations queries -> LOCATION
    if any(k in lower for k in (
        "saved location", "saved locations", "saved cities", "which of my saved",
        "in my saved", "saved places", "coldest saved", "warmest saved"
    )):
        return "LOCATION"

    # 4. Severe weather alerts / warnings -> ALERT
    if any(k in lower for k in (
        "alert", "alerts", "warning", "warnings", "cyclone", "severe weather",
        "storm warning", "heatwave", "heat wave", "flash flood", "flood warning",
        "thunderstorm warning", "emergency weather", "weather advisory"
    )):
        return "ALERT"

    # 5. Air quality / pollution / respiratory queries -> AQI
    if any(k in lower for k in (
        "aqi", "air quality", "pollution", "pm2.5", "pm10", "smog", "smoke",
        "breathe", "breathing", "asthma", "air clean", "mask"
    )):
        return "AQI"

    # 6. Sports / cricket / workout / running -> ACTIVITY
    if any(k in lower for k in (
        "cricket", "play cricket", "sports", "match", "game", "run", "running",
        "jog", "jogging", "workout", "gym", "fitness", "exercise", "cycling",
        "cycle", "walk", "walking", "outdoor activity", "play outside", "picnic"
    )):
        return "ACTIVITY"

    # 7. Future weather / forecast / tomorrow / weekend -> FORECAST
    if any(k in lower for k in (
        "forecast", "tomorrow", "weekend", "5-day", "7-day", "next week",
        "coming days", "days ahead", "later tonight", "this evening",
        "hourly forecast", "hourly breakdown", "future weather", "weekly"
    )):
        return "FORECAST"

    # 8. Check if pure general chat (without substantive weather inquiry) -> GENERAL_CHAT
    has_substantive_weather = (
        any(k in lower for k in _WEATHER_HINTS)
        or _extract_location_mention(stripped) is not None
    )

    if not has_substantive_weather:
        if (
            _GREETING_RE.match(stripped)
            or _SMALLTALK_RE.match(stripped)
            or _THANKS_RE.match(stripped)
            or _HELP_RE.match(stripped)
            or _CASUAL_CHAT_RE.match(stripped)
            or _is_general_chat(stripped)
        ):
            return "GENERAL_CHAT"

    # 9. Current weather conditions & parameters -> WEATHER
    if has_substantive_weather:
        return "WEATHER"

    # Fallback to GENERAL_CHAT for conversational inquiries, else OTHER
    if any(w in lower for w in ("hi", "hello", "hey", "bye", "thanks", "thank", "how", "what", "good", "cool", "nice", "ok", "okay")):
        return "GENERAL_CHAT"

    return "OTHER"


def _build_structured_card(
    snap: dict[str, Any],
    forecast_list: list[dict[str, Any]] | None,
    alerts: list[dict[str, Any]] | None,
    query_text: str,
    intent: str = "WEATHER",
) -> dict[str, Any]:
    """
    Construct a structured WeatherAiCardData dictionary for rich Flutter UI rendering.
    """
    lower = query_text.lower()
    temp = snap["temperature_celsius"]
    feels = snap["feels_like_celsius"]
    loc = snap["location"]
    cond = snap["condition"]
    rain_mm = snap.get("rain_mm_1h", 0.0)
    aqi_val = snap.get("aqi", 0)
    aqi_cat = snap.get("aqi_category", "Moderate")

    # 1. Severe Alert Card
    if intent == "ALERT" or (alerts and len(alerts) > 0):
        top_alert = alerts[0] if alerts else {
            "headline": f"Severe Weather Advisory for {loc}",
            "severity": "Warning",
            "description": f"Conditions in {loc}: {temp}°C with {cond.lower()}. Stay updated with official advisories.",
        }
        return {
            "cardType": "forecastSummary",
            "category": "OFFICIAL WEATHER WARNING",
            "headline": top_alert.get("headline", "Weather Advisory"),
            "subtitle": f"{loc} · {top_alert.get('severity', 'Warning').upper()}",
            "metrics": [
                {"label": "Status", "value": "Active"},
                {"label": "Temp", "value": f"{temp}°C"},
                {"label": "Wind", "value": f"{snap['wind_speed_kmh']} km/h"},
                {"label": "Rain Rate", "value": f"{rain_mm:.1f} mm/h"},
            ],
            "explanation": top_alert.get("description", "Take appropriate precautions."),
            "actionLabel": "View Full Alerts",
            "actionRoute": "/alerts",
        }

    # 2. Workout / Cricket / Running Intent
    if intent == "ACTIVITY" or any(w in lower for w in ("workout", "run", "jog", "fitness", "cricket", "play", "sports", "exercise")):
        is_safe = rain_mm == 0 and temp < 34 and aqi_val < 150
        headline = "Favorable Outdoor Window" if is_safe else "Suboptimal Conditions for Outdoor Activity"
        subtitle = "Optimal early morning or late afternoon" if is_safe else "High heat or precipitation risk"
        return {
            "cardType": "activityWindow",
            "category": "ACTIVITY & OUTDOOR INTELLIGENCE",
            "headline": headline,
            "subtitle": subtitle,
            "metrics": [
                {"label": "Temp", "value": f"{temp}°C"},
                {"label": "Feels Like", "value": f"{feels}°C"},
                {"label": "Rain Risk", "value": "High" if rain_mm > 0 else "Low"},
                {"label": "Air Quality", "value": f"AQI {aqi_val}"},
            ],
            "explanation": f"In {loc}, current temperature is {temp}°C with {cond.lower()}. " + (
                "Ensure hydration and avoid midday peak UV." if is_safe else "Consider moving activity indoors."
            ),
            "actionLabel": "Schedule Reminder",
            "actionRoute": "/chat",
        }

    # 3. Wardrobe / Outfit / Umbrella Intent
    if any(w in lower for w in ("wear", "outfit", "clothes", "jacket", "coat", "umbrella")):
        need_umbrella = rain_mm > 0 or "rain" in cond.lower()
        return {
            "cardType": "clothingWardrobe",
            "category": "WARDROBE ADVISORY",
            "headline": "Carry an Umbrella & Rainwear" if need_umbrella else f"Breathable Attire for {temp}°C",
            "subtitle": f"{loc} · Humidity {snap['humidity_percent']}%",
            "metrics": [
                {"label": "Temp", "value": f"{temp}°C"},
                {"label": "Rain", "value": f"{rain_mm:.1f} mm/h"},
                {"label": "Wind", "value": f"{snap['wind_speed_kmh']} km/h"},
                {"label": "UV Index", "value": f"{snap['uv_index']}"},
            ],
            "explanation": "Rain is active — protect gear with waterproof cover." if need_umbrella else "Light fabrics recommended. Add sunglasses or hat for sun protection.",
            "actionLabel": "Detailed Forecast",
            "actionRoute": "/forecast",
        }

    # 4. Air Quality & Health Intent
    if intent == "AQI" or any(w in lower for w in ("aqi", "air quality", "pollution", "smog", "breathe", "asthma")):
        return {
            "cardType": "healthEnvironment",
            "category": "AIR QUALITY & ENVIRONMENT",
            "headline": f"AQI {aqi_val} · {aqi_cat}",
            "subtitle": f"Monitored in {loc}",
            "metrics": [
                {"label": "AQI", "value": f"{aqi_val}"},
                {"label": "Category", "value": aqi_cat},
                {"label": "Humidity", "value": f"{snap['humidity_percent']}%"},
                {"label": "Wind", "value": f"{snap['wind_speed_kmh']} km/h"},
            ],
            "explanation": "Air quality is elevated — sensitive individuals should minimize prolonged outdoor exertion." if aqi_val > 100 else "Air quality is satisfactory for general outdoor recreation.",
            "actionLabel": "Health Metrics",
            "actionRoute": "/health-metrics",
        }

    # 5. Travel & Forecast Summary (Default Weather Card)
    return {
        "cardType": "forecastSummary",
        "category": "CURRENT CONDITIONS & FORECAST",
        "headline": f"{temp}°C · {cond} in {loc}",
        "subtitle": f"Feels like {feels}°C · Wind {snap['wind_speed_kmh']} km/h",
        "metrics": [
            {"label": "Temp", "value": f"{temp}°C"},
            {"label": "Humidity", "value": f"{snap['humidity_percent']}%"},
            {"label": "AQI", "value": f"{aqi_val} ({aqi_cat})"},
            {"label": "UV", "value": f"{snap['uv_index']}"},
        ],
        "explanation": f"High of {temp}°C expected today with {cond.lower()}.",
        "actionLabel": "View 5-Day Forecast",
        "actionRoute": "/forecast",
    }


def _build_travel_route_card(
    origin: str,
    destination: str,
    origin_lat: float,
    origin_lon: float,
    dest_lat: float,
    dest_lon: float,
    distance_km: int,
    duration_text: str,
    dest_weather: dict[str, Any],
    route_points: list[dict[str, Any]] | None = None,
    is_estimated: bool = True,
    route_source: str = "estimated",
    route_geometry: list[dict[str, float]] | None = None,
) -> dict[str, Any]:
    temp = dest_weather.get("temperature_celsius", dest_weather.get("temperature"))
    temp = temp if temp is not None else 30
    feels = dest_weather.get("feels_like_celsius", dest_weather.get("feelsLike", temp))
    cond = dest_weather.get("condition") or "Clear"
    aqi_val = dest_weather.get("aqi")
    aqi_cat = dest_weather.get("aqi_category", dest_weather.get("aqiCategory")) or "Moderate"
    maps_url = f"https://www.google.com/maps/dir/?api=1&origin={origin}&destination={destination}"

    points = route_points or []
    intermediates = [p for p in points if p.get("role") == "intermediate"]

    subtitle_dist = f"~{distance_km} km (est.)" if is_estimated else f"{distance_km} km"
    subtitle_dur = duration_text if duration_text.startswith("~") or not is_estimated else f"~{duration_text} (est. drive)"
    subtitle = f"{subtitle_dist} · {subtitle_dur}"

    metrics = [
        {"label": "Est. Distance" if is_estimated else "Distance", "value": f"~{distance_km} km" if is_estimated else f"{distance_km} km"},
        {"label": "Est. Duration" if is_estimated else "Duration", "value": duration_text},
        {"label": f"{destination} Temp", "value": f"{temp}°C"},
    ]
    if aqi_val is not None:
        metrics.append({"label": f"{destination} AQI", "value": f"{aqi_val} ({aqi_cat})"})

    if intermediates:
        stops_str = ", ".join(p["name"] for p in intermediates)
        explanation = (
            f"Driving route from {origin} to {destination} passes through {stops_str}. "
            f"Destination conditions ({destination}): {temp}°C, {cond.lower()}"
            f"{f' with AQI {aqi_val} ({aqi_cat.lower()})' if aqi_val is not None else ''}. Safe travels!"
        )
    else:
        explanation = (
            f"Expected conditions in {destination}: {temp}°C, {cond.lower()}"
            f"{f' with AQI {aqi_val} ({aqi_cat.lower()})' if aqi_val is not None else ''}. "
            f"Route covers {distance_km} km. Travel safely!"
        )

    return {
        "cardType": "travelRoute",
        "category": "TRAVEL ROUTE INTELLIGENCE",
        "headline": f"{origin} → {destination}",
        "subtitle": subtitle,
        "origin": origin,
        "destination": destination,
        "distanceKm": distance_km,
        "durationText": duration_text,
        "isEstimate": is_estimated,
        "isEstimated": is_estimated,
        "routeSource": route_source,
        "originCoords": {"latitude": origin_lat, "longitude": origin_lon},
        "destCoords": {"latitude": dest_lat, "longitude": dest_lon},
        "routePoints": points,
        "routeGeometry": route_geometry or [{"lat": p["lat"], "lon": p["lon"]} for p in points],
        "destinationWeather": {
            "temperature": temp,
            "feelsLike": feels,
            "condition": cond,
            "humidity": dest_weather.get("humidity_percent", dest_weather.get("humidity", 55)),
            "windSpeed": dest_weather.get("wind_speed_kmh", dest_weather.get("windSpeed", 12)),
            "aqi": aqi_val if aqi_val is not None else 50,
            "aqiCategory": aqi_cat,
        },
        "metrics": metrics,
        "explanation": explanation,
        "actionLabel": "View route on map",
        "actionRoute": maps_url,
    }


def _build_comparison_card(comp: dict[str, Any]) -> dict[str, Any]:
    w1 = comp["location1"]
    w2 = comp["location2"]
    diff = comp["temperature_difference_celsius"]
    headline = f"{comp['warmer_location']} is warmer by {abs(diff):.1f}°C" if diff != 0 else "Both locations share the same temperature"

    return {
        "cardType": "travelPacking",
        "category": "LOCATION COMPARISON",
        "headline": headline,
        "subtitle": f"{w1['location']} vs {w2['location']}",
        "metrics": [
            {"label": f"{w1['location']} Temp", "value": f"{w1['temperature_celsius']}°C"},
            {"label": f"{w2['location']} Temp", "value": f"{w2['temperature_celsius']}°C"},
            {"label": f"{w1['location']} AQI", "value": f"{w1['aqi']}"},
            {"label": f"{w2['location']} AQI", "value": f"{w2['aqi']}"},
        ],
        "explanation": f"{comp['cleaner_air_location']} currently enjoys cleaner air.",
        "actionLabel": "Saved Locations",
        "actionRoute": "/saved-locations",
    }


def _detailed_weather_reply(
    text: str,
    snap: dict[str, Any],
    forecast_list: list[dict[str, Any]] | None,
    hourly_list: list[dict[str, Any]] | None,
    persona: str | None = None,
    health: list[str] | None = None,
    weather_triggers: list[str] | None = None,
    what_matters_most: list[str] | None = None,
    activity_level: str | None = None,
    user_name: str | None = None,
    alerts: list[dict[str, Any]] | None = None,
) -> tuple[str, list[str], list[str]]:
    """
    Generate a user-first, conversational advisory reply grounded in live weather data.
    Directly answers the user's dilemma (commute, workout, cricket, wardrobe, health)
    before highlighting key weather numbers.
    """
    loc = snap["location"]
    temp = snap["temperature_celsius"]
    feels = snap["feels_like_celsius"]
    cond = snap["condition"]
    hum = snap["humidity_percent"]
    wind = snap["wind_speed_kmh"]
    uv = snap["uv_index"]
    rain_mm = snap.get("rain_mm_1h", 0.0)
    aqi_val = snap.get("aqi", 0)
    aqi_cat = snap.get("aqi_category", "Moderate")

    facts: list[str] = [
        f"Temperature in {loc} is {temp}°C (feels like {feels}°C) with {cond}.",
        f"Humidity is {hum}%, Wind speed is {wind} km/h, and UV Index is {uv}.",
        f"Air Quality Index is {aqi_val} ({aqi_cat}).",
    ]
    if rain_mm > 0:
        facts.append(f"Precipitation rate is {rain_mm:.1f} mm/h.")

    recommendations: list[str] = []

    # 1. Severe alert priority
    alert_warning_str = ""
    if alerts and len(alerts) > 0:
        top_alert = alerts[0]
        headline = top_alert.get("headline", "Weather Advisory")
        desc = top_alert.get("description", "Take appropriate precautions.")
        alert_warning_str = f"⚠️ **SAFETY ALERT: {headline}**\n{desc}\n\n"
        recommendations.append(f"Safety priority: {desc}")

    # 2. Personalized Greeting / Name Address
    name_str = f"{user_name}, " if user_name else ""
    lower = text.lower()

    # 3. Intent-Specific Direct User Answer & Practical Action
    direct_answer = ""
    action_advice = ""

    if any(w in lower for w in ("cricket", "play", "sports", "match", "game")):
        if rain_mm > 0 or "thunder" in cond.lower() or "rain" in cond.lower():
            direct_answer = (
                f"{name_str}outdoor cricket or sports are **not recommended** right now in {loc}. "
                f"Rain is falling ({rain_mm:.1f} mm/h) and pitches will be damp and slippery, posing an injury risk."
            )
            action_advice = "Postpone your match or switch to an indoor sports venue until the rain clears."
            recommendations.append("Ground is wet from rain; postpone outdoor cricket to prevent slipping.")
        elif temp >= 35 or feels >= 38:
            direct_answer = (
                f"{name_str}playing cricket under the midday sun right now in {loc} isn't advisable due to high heat "
                f"({temp}°C, feels like {feels}°C)."
            )
            action_advice = "Consider shifting your match to early morning or after 5:30 PM when the UV index subsides."
            recommendations.append(f"High temperature ({temp}°C) creates heat stress risk; play during cooler evening hours.")
        else:
            direct_answer = (
                f"{name_str}yes! Conditions in {loc} are **favorable for playing cricket** right now. "
                f"The temperature is {temp}°C with {cond.lower()} skies and a gentle breeze ({wind} km/h)."
            )
            action_advice = "Stay well hydrated between overs and enjoy your match!"
            recommendations.append("Conditions are suitable for outdoor sports. Maintain proper hydration.")

    elif any(w in lower for w in ("run", "running", "jog", "workout", "fitness", "exercise")):
        if rain_mm > 0 or "thunder" in cond.lower():
            direct_answer = (
                f"{name_str}outdoor running or workouts are **not recommended** right now in {loc}. "
                f"Rain is actively falling ({rain_mm:.1f} mm/h) with wet road surfaces."
            )
            action_advice = "An indoor treadmill or bodyweight routine is much safer and more comfortable today."
            recommendations.append("Active rain present; shift cardio workout indoors.")
        elif temp >= 34 or feels >= 37 or aqi_val > 150:
            direct_answer = (
                f"{name_str}hold off on strenuous outdoor running right now in {loc}. "
                f"Heat index is at {feels}°C with AQI {aqi_val} ({aqi_cat})."
            )
            action_advice = "Shift your training session to an indoor air-conditioned gym or early tomorrow morning."
            recommendations.append("Elevated heat and AQI; limit strenuous outdoor cardio.")
        else:
            direct_answer = (
                f"{name_str}it's a **great time for your workout** in {loc}! "
                f"Current temperature is {temp}°C (feels like {feels}°C) with {cond.lower()} skies."
            )
            action_advice = "Pace yourself, hydrate adequately, and make the most of this clear weather window."
            recommendations.append("Favorable outdoor workout conditions. Maintain hydration.")

    elif any(w in lower for w in ("umbrella", "raincoat")):
        if rain_mm > 0 or "rain" in cond.lower() or "drizzle" in cond.lower():
            direct_answer = (
                f"{name_str}**yes, definitely take an umbrella** before stepping out in {loc}! "
                f"Precipitation is active ({rain_mm:.1f} mm/h) with {hum}% humidity."
            )
            action_advice = "Keep your bag or electronics in water-resistant sleeves."
            recommendations.append("Carry an umbrella or raincoat; precipitation is active.")
        else:
            direct_answer = (
                f"{name_str}**no umbrella needed** right now in {loc}! "
                f"Skies are {cond.lower()} with no active rain."
            )
            action_advice = "You can travel comfortably without rain gear today."
            recommendations.append(f"No precipitation in {loc}; rain protection not required.")

    elif any(w in lower for w in ("wear", "outfit", "clothes", "jacket", "coat", "dressing")):
        if rain_mm > 0 or "rain" in cond.lower():
            direct_answer = (
                f"{name_str}wear **water-resistant footwear and carry an umbrella or lightweight raincoat** in {loc} today."
            )
            action_advice = f"With {hum}% humidity, breathable waterproof layers will keep you dry without feeling stuffy."
            recommendations.append("Water-resistant layers and wet-traction shoes recommended.")
        elif temp >= 32:
            direct_answer = (
                f"{name_str}go with **light, loose-fitting cotton clothing** today in {loc}. "
                f"The temperature is {temp}°C (feels like {feels}°C) with {cond.lower()} skies."
            )
            action_advice = f"UV index is {uv}, so consider sunglasses or a hat if you'll be in the sun."
            recommendations.append("Light, breathable cotton fabrics and sun protection advised.")
        elif temp < 20:
            direct_answer = (
                f"{name_str}it's cool outside ({temp}°C) in {loc} with a {wind} km/h breeze. "
                f"A **light jacket, cardigan, or sweater** is ideal."
            )
            action_advice = "Layer up comfortably, especially if heading out early or after dark."
            recommendations.append("Light jacket or sweater recommended for cool temperatures.")
        else:
            direct_answer = (
                f"{name_str}**comfortable casual wear** is perfect for {loc} today. "
                f"The temperature is a pleasant {temp}°C with {cond.lower()} conditions."
            )
            action_advice = "Standard everyday clothes will keep you comfortable all day."
            recommendations.append("Standard comfortable everyday attire is appropriate.")

    elif any(w in lower for w in ("aqi", "air quality", "pollution", "smog", "breathe", "asthma")):
        if health and any(h.lower() in ("asthma", "allergy", "allergies", "respiratory") for h in health):
            direct_answer = (
                f"{name_str}for your respiratory sensitivity, please take note: the AQI in {loc} is currently "
                f"**{aqi_val} ({aqi_cat})** with {hum}% humidity."
            )
            action_advice = (
                "Keep your rescue inhaler handy and avoid prolonged outdoor cardio."
                if aqi_val > 100 else
                "Air quality is clean and safe for your normal outdoor activities today."
            )
            recommendations.append(f"AQI is {aqi_val} ({aqi_cat}); sensitive individuals should take precautions.")
        elif aqi_val > 150:
            direct_answer = (
                f"{name_str}air quality in {loc} is currently **{aqi_cat} (AQI {aqi_val})**. "
                f"Pollutant levels are elevated."
            )
            action_advice = "Wear an N95 mask if outdoors for extended periods and limit intense aerobic workouts."
            recommendations.append("Unhealthy air quality; wear an N95 mask outdoors and limit strenuous cardio.")
        else:
            direct_answer = (
                f"{name_str}the air quality in {loc} is **{aqi_cat} (AQI {aqi_val})**, which is favorable for outdoor routines."
            )
            action_advice = "You can freely enjoy outdoor activities and fresh air."
            recommendations.append("Air quality is satisfactory for general outdoor recreation.")

    else:
        direct_answer = (
            f"{name_str}here is your personal weather briefing for {loc}: "
            f"Conditions are **{cond.lower()}** with a temperature of **{temp}°C** (feels like **{feels}°C**)."
        )
        action_advice = f"Wind is blowing at {wind} km/h with {hum}% humidity and AQI **{aqi_val} ({aqi_cat})**."
        recommendations.append(f"Plan your schedule around {cond.lower()} conditions and temperature highs near {temp}°C.")

    # 4. User Triggers & Health Notes
    personalized_notes: list[str] = []
    if weather_triggers:
        if any("humidity" in t.lower() for t in weather_triggers) and hum >= 65:
            personalized_notes.append(f"• **Sensitivity note**: Humidity is high ({hum}%), which might feel muggy or triggering.")
        if any("heat" in t.lower() for t in weather_triggers) and temp >= 32:
            personalized_notes.append(f"• **Heat sensitivity**: High heat ({temp}°C) detected—stay well hydrated.")
        if any("rain" in t.lower() for t in weather_triggers) and rain_mm > 0:
            personalized_notes.append(f"• **Precipitation alert**: Rain is actively falling ({rain_mm:.1f} mm/h).")

    # 5. Hourly window context
    hourly_block = ""
    if hourly_list:
        h_str = " · ".join([f"{h['hour']} {h['temperature_celsius']}°C" for h in hourly_list[:4]])
        hourly_block = f"\n\n**Next Hours**: {h_str}"

    forecast_block = ""
    if forecast_list:
        f_str = " · ".join([f"{d['day'][:3]}: {d['high_celsius']}°/{d['low_celsius']}°" for d in forecast_list[:3]])
        forecast_block = f"\n**Coming Days**: {f_str}"

    trigger_text = ("\n" + "\n".join(personalized_notes)) if personalized_notes else ""
    summary_line = f"\n\n**Conditions in {loc}**: **{temp}°C**, {cond}, AQI **{aqi_val}** ({aqi_cat}), Humidity {hum}%."

    full_text = (
        f"{alert_warning_str}"
        f"{direct_answer}\n\n"
        f"{action_advice}"
        f"{trigger_text}"
        f"{summary_line}"
        f"{hourly_block}"
        f"{forecast_block}"
    )

    return full_text, facts, recommendations


class ChatService:

    @staticmethod
    async def process_message(user: dict[str, Any], payload: ChatMessageRequest) -> ChatMessageResponse:
        text = payload.text.strip()
        intent = classify_chat_intent(text)

        # 1. GENERAL_CHAT Intent -> Zero weather/location/external API calls!
        if intent == "GENERAL_CHAT":
            reply, actions = _generate_general_chat_reply(text, user_name=payload.user_name)
            return ChatMessageResponse(
                reply=reply,
                intent="GENERAL_CHAT",
                source="template",
                suggested_actions=actions,
            )

        # 2. OTHER Intent: Reminders & Meteorological Concepts -> Zero weather tools calls!
        if intent == "OTHER":
            # Reminder handling
            if any(k in text.lower() for k in ("remind", "reminder", "alarm", "schedule notification", "notify me")):
                extracted_time, freq = _extract_time_and_frequency(text)
                if extracted_time:
                    try:
                        created = await ReminderService.create_reminder(
                            user=user,
                            payload=ReminderCreate(time_of_day=extracted_time, frequency=freq),
                        )
                        reply = (
                            f"I have scheduled your {freq} weather reminder for **{created.time_of_day}**. "
                            f"You will receive a daily routine notification with conditions for your area."
                        )
                        return ChatMessageResponse(
                            reply=reply,
                            intent="OTHER",
                            source="template",
                            reminder_created=True,
                            reminder_details=created.model_dump(),
                            suggested_actions=["Today's weather", "AQI right now", "List reminders"],
                        )
                    except Exception as exc:
                        logger.warning("Failed to create reminder from chat: %s", exc)
                        return ChatMessageResponse(
                            reply=f"I understood you want a reminder at {extracted_time}, but encountered an error saving it: {exc}",
                            intent="OTHER",
                            source="template",
                            suggested_actions=["Try setting a reminder again", "Today's weather"],
                        )
                return ChatMessageResponse(
                    reply=(
                        "I'd be glad to set a weather reminder for you! "
                        "What time would you like to receive it (e.g., *7:00 AM* or *9:00 PM*) and how often (*daily* or *once*)?"
                    ),
                    intent="OTHER",
                    source="template",
                    suggested_actions=["Remind me daily at 7:00 AM", "Remind me at 9:00 PM daily", "Today's weather"],
                )

            # Educational concepts
            concept_reply, concept_actions = _generate_concept_reply(text)
            return ChatMessageResponse(
                reply=concept_reply,
                intent="OTHER",
                source="template",
                suggested_actions=concept_actions,
            )

        # 3. TRAVEL: Origin-Destination Route or Multi-City Comparison
        if intent == "TRAVEL":
            route_endpoints = _extract_travel_route_endpoints(text)
            if route_endpoints:
                origin, dest = route_endpoints
                try:
                    # 1. Resolve coordinates for origin and destination
                    origin_lat, origin_lon, res_origin = await _resolve_endpoint_coords(
                        origin,
                        default_lat=payload.resolved_lat or 17.3850,
                        default_lon=payload.resolved_lon or 78.4867,
                        default_name=origin,
                    )
                    dest_lat, dest_lon, res_dest = await _resolve_endpoint_coords(
                        dest,
                        default_lat=16.5062,
                        default_lon=80.6480,
                        default_name=dest,
                    )

                    (
                        route_points,
                        distance_km,
                        duration_text,
                        is_estimated,
                        route_source,
                        route_geometry,
                    ) = await _determine_route_locations(
                        origin=res_origin,
                        dest=res_dest,
                        origin_lat=origin_lat,
                        origin_lon=origin_lon,
                        dest_lat=dest_lat,
                        dest_lon=dest_lon,
                    )

                    dest_point = next((p for p in route_points if p.get("role") == "destination"), None)
                    dest_weather = dest_point.get("weather", {}) if dest_point else {}

                    route_card = _build_travel_route_card(
                        origin=res_origin,
                        destination=res_dest,
                        origin_lat=origin_lat,
                        origin_lon=origin_lon,
                        dest_lat=dest_lat,
                        dest_lon=dest_lon,
                        distance_km=distance_km,
                        duration_text=duration_text,
                        dest_weather=dest_weather,
                        route_points=route_points,
                        is_estimated=is_estimated,
                        route_source=route_source,
                        route_geometry=route_geometry,
                    )

                    intermediate_stops = [p for p in route_points if p.get("role") == "intermediate"]

                    dest_temp = dest_weather.get("temperature")
                    dest_cond = dest_weather.get("condition") or "Clear"
                    dest_aqi = dest_weather.get("aqi")
                    dest_aqi_cat = dest_weather.get("aqiCategory") or "Moderate"

                    reply_text = (
                        f"Got it! You’re planning to travel from **{res_origin}** to **{res_dest}**.\n\n"
                        f"• **{'Estimated Distance' if is_estimated else 'Distance'}**: "
                        f"{f'~{distance_km} km by road' if is_estimated else f'{distance_km} km (via highway)'}\n"
                        f"• **{'Estimated Travel Time' if is_estimated else 'Travel Time'}**: {duration_text}\n"
                    )

                    if dest_temp is not None:
                        reply_text += f"• **Destination Weather ({res_dest})**: **{dest_temp}°C**, {dest_cond}\n"
                    if dest_aqi is not None:
                        reply_text += f"• **Destination Air Quality**: AQI **{dest_aqi}** ({dest_aqi_cat})\n"

                    if intermediate_stops:
                        stops_preview = []
                        for p in intermediate_stops:
                            w = p.get("weather") or {}
                            t = w.get("temperature")
                            if t is not None:
                                stops_preview.append(f"{p['name']} ({t}°C)")
                            else:
                                stops_preview.append(p["name"])
                        reply_text += f"• **Stops Along Route**: {' → '.join(stops_preview)}\n"

                    reply_text += "\nSafe travels! Tap **View route on map** below to see your route preview and live directions."

                    return ChatMessageResponse(
                        reply=reply_text,
                        intent="TRAVEL",
                        source="template",
                        card_data=route_card,
                        suggested_actions=[
                            f"Weather in {res_dest}",
                            f"Weather in {res_origin}",
                            f"Will it rain in {res_dest}?",
                            "Today's weather",
                        ],
                    )
                except Exception as exc:
                    logger.warning("Travel route computation failed: %s", exc)

            comp_locs = _extract_comparison_locations(text)
            if comp_locs:
                loc1, loc2 = comp_locs
                try:
                    comp_data = await weather_tools.compare_weather(
                        loc1, loc2,
                        default_lat=payload.resolved_lat or 17.3850,
                        default_lon=payload.resolved_lon or 78.4867,
                    )
                    comp_card = _build_comparison_card(comp_data)

                    # Try Gemini with comparison grounding
                    gemini_res = await GeminiService.generate_response(
                        user_message=text,
                        comparison_data=comp_data,
                        history=payload.history,
                    )
                    if gemini_res:
                        reply_text, actions, card = gemini_res
                        return ChatMessageResponse(
                            reply=reply_text,
                            intent="TRAVEL",
                            source="gemini",
                            card_data=card or comp_card,
                            suggested_actions=actions,
                        )

                    w1 = comp_data["location1"]
                    w2 = comp_data["location2"]
                    diff = comp_data["temperature_difference_celsius"]
                    reply = (
                        f"**Weather Comparison: {w1['location']} vs {w2['location']}**\n\n"
                        f"• **{w1['location']}**: **{w1['temperature_celsius']}°C** (feels like {w1['feels_like_celsius']}°C), {w1['condition']}, AQI **{w1['aqi']}**\n"
                        f"• **{w2['location']}**: **{w2['temperature_celsius']}°C** (feels like {w2['feels_like_celsius']}°C), {w2['condition']}, AQI **{w2['aqi']}**\n\n"
                        f"**Summary**: {comp_data['warmer_location']} is warmer by {abs(diff):.1f}°C. {comp_data['cleaner_air_location']} has cleaner air quality."
                    )
                    return ChatMessageResponse(
                        reply=reply,
                        intent="TRAVEL",
                        source="template",
                        card_data=comp_card,
                        suggested_actions=[f"Forecast for {w1['location']}", f"Forecast for {w2['location']}", "Will it rain today?"],
                    )
                except Exception as exc:
                    logger.warning("Comparison failed: %s", exc)

        # 4. LOCATION: Saved Locations Query
        if intent == "LOCATION" and payload.saved_locations:
            try:
                results = []
                for loc_item in payload.saved_locations[:5]:
                    name = loc_item.get("name")
                    lat = loc_item.get("latitude")
                    lon = loc_item.get("longitude")
                    if lat and lon:
                        cur = await weather_tools.get_current_weather(
                            location=name, default_lat=lat, default_lon=lon, default_name=name
                        )
                        results.append(cur)

                if results:
                    sorted_by_temp = sorted(results, key=lambda x: x["temperature_celsius"])
                    coldest = sorted_by_temp[0]
                    warmest = sorted_by_temp[-1]
                    breakdown = "\n".join([f"• **{r['location']}**: **{r['temperature_celsius']}°C**, {r['condition']}, AQI {r['aqi']}" for r in results])
                    reply = (
                        f"Here is the weather across your saved locations:\n\n{breakdown}\n\n"
                        f"**Lowest Temperature**: **{coldest['location']}** at **{coldest['temperature_celsius']}°C**.\n"
                        f"**Highest Temperature**: **{warmest['location']}** at **{warmest['temperature_celsius']}°C**."
                    )
                    return ChatMessageResponse(
                        reply=reply,
                        intent="LOCATION",
                        source="template",
                        suggested_actions=[f"Weather in {coldest['location']}", "Air quality index", "Today's weather"],
                    )
            except Exception as exc:
                logger.warning("Saved locations query failed: %s", exc)

        # 5. Targeted Live Weather Fetching for remaining weather intents:
        # WEATHER, FORECAST, AQI, ALERT, ACTIVITY, or non-comparison TRAVEL / LOCATION
        target_location = _extract_location_mention(text) or payload.active_location_name
        default_lat = payload.resolved_lat or 17.3850
        default_lon = payload.resolved_lon or 78.4867
        default_name = payload.active_location_name or "Active Location"

        weather_snapshot = None
        forecast_list = None
        hourly_list = None
        alerts_list = None

        try:
            # 1. Fetch current weather snapshot
            weather_snapshot = await weather_tools.get_current_weather(
                location=target_location,
                default_lat=default_lat,
                default_lon=default_lon,
                default_name=default_name,
            )
            lat = weather_snapshot["latitude"]
            lon = weather_snapshot["longitude"]
            resolved_name = weather_snapshot["location"]

            # 2. Selectively fetch ONLY what this intent requires
            if intent == "FORECAST":
                forecast_list = await weather_tools.get_daily_forecast(
                    location=target_location, default_lat=lat, default_lon=lon, default_name=resolved_name
                )
                hourly_list = await weather_tools.get_hourly_forecast(
                    location=target_location, default_lat=lat, default_lon=lon, default_name=resolved_name
                )
            elif intent == "ACTIVITY":
                hourly_list = await weather_tools.get_hourly_forecast(
                    location=target_location, default_lat=lat, default_lon=lon, default_name=resolved_name
                )
            elif intent in ("ALERT", "TRAVEL"):
                alerts_list = await weather_tools.get_weather_alerts(
                    location=target_location, persona=payload.persona, default_lat=lat, default_lon=lon
                )
            # For "WEATHER" and "AQI", weather_snapshot already contains all needed live data!
        except Exception as exc:
            logger.warning("Targeted weather tool fetch failed: %s", exc)

        if weather_snapshot is None:
            return ChatMessageResponse(
                reply=(
                    "I could not retrieve live weather data right now. "
                    "Please make sure your location services are enabled or specify a city name (e.g., *'Weather in Hyderabad'*)."
                ),
                intent=intent,
                source="template",
                suggested_actions=["Weather in Hyderabad", "Weather in Guntur", "Check air quality"],
            )

        # Build structured card tailored to intent
        structured_card = _build_structured_card(
            snap=weather_snapshot,
            forecast_list=forecast_list,
            alerts=alerts_list,
            query_text=text,
            intent=intent,
        )

        user_context = None
        if (
            payload.persona
            or payload.health_concerns
            or payload.weather_triggers
            or payload.what_matters_most
            or payload.activity_level
            or payload.user_name
        ):
            user_context = {
                "name": payload.user_name,
                "persona": payload.persona,
                "health_concerns": payload.health_concerns or [],
                "weather_triggers": payload.weather_triggers or [],
                "what_matters_most": payload.what_matters_most or [],
                "activity_level": payload.activity_level,
            }

        # 6. Call Gemini Service with targeted Grounding
        gemini_result = await GeminiService.generate_response(
            user_message=text,
            weather_data=weather_snapshot,
            forecast_data=forecast_list,
            user_context=user_context,
            hourly_data=hourly_list,
            alerts_data=alerts_list,
            saved_locations=payload.saved_locations,
            history=payload.history,
        )

        if gemini_result is not None:
            reply_text, suggested_actions, gemini_card = gemini_result
            return ChatMessageResponse(
                reply=reply_text,
                intent=intent,
                source="gemini",
                weather_data=weather_snapshot,
                card_data=gemini_card or structured_card,
                suggested_actions=suggested_actions,
                location_context={"location": weather_snapshot.get("location") if weather_snapshot else target_location},
            )

        # 7. Deterministic Fallback Template
        reply, facts, recs = _detailed_weather_reply(
            text=text,
            snap=weather_snapshot,
            forecast_list=forecast_list,
            hourly_list=hourly_list,
            persona=payload.persona,
            health=payload.health_concerns,
            weather_triggers=payload.weather_triggers,
            what_matters_most=payload.what_matters_most,
            activity_level=payload.activity_level,
            user_name=payload.user_name,
            alerts=alerts_list,
        )
        return ChatMessageResponse(
            reply=reply,
            intent=intent,
            source="template",
            weather_data=weather_snapshot,
            card_data=structured_card,
            facts=facts,
            recommendations=recs,
            location_context={"location": weather_snapshot.get("location")},
            suggested_actions=["Will it rain tomorrow?", "What should I wear?", "Hourly temperature breakdown"],
        )
