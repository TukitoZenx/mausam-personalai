from pydantic import BaseModel


class CurrentWeather(BaseModel):
    location: str
    temperature_celsius: float
    condition: str
    humidity_percent: int
    wind_speed_kmh: float
    uv_index: float
    feels_like_celsius: float | None = None
    high_celsius: float | None = None
    low_celsius: float | None = None
    condition_icon: str | None = None
    dew_point_celsius: float | None = None
    wind_direction_deg: float | None = None
    pressure_hpa: float | None = None
    visibility_km: float | None = None
    rain_mm_1h: float | None = None
    rain_mm_3h: float | None = None
    snow_mm_1h: float | None = None
    sunrise_unix: int | None = None
    sunset_unix: int | None = None
    timezone_offset_sec: int | None = None
    observed_at_unix: int | None = None
    cached: bool = False
    stale: bool = False


class HourlyForecastItem(BaseModel):
    dt_unix: int
    hour_label: str
    temperature_celsius: float
    condition: str
    condition_icon: str | None = None
    rain_probability_percent: int = 0
    rain_mm: float | None = None
    wind_speed_kmh: float | None = None
    wind_direction_deg: float | None = None


class DailyForecastItem(BaseModel):
    day: str
    high_celsius: float
    low_celsius: float
    condition: str
    rain_probability_percent: int
    date: str | None = None
    weekday: str | None = None
    condition_icon: str | None = None
    rain_mm: float | None = None
    moon_phase: float | None = None
    moonrise_unix: int | None = None
    moonset_unix: int | None = None


class ForecastResponse(BaseModel):
    location: str
    current: CurrentWeather
    forecast: list[DailyForecastItem]
    hourly: list[HourlyForecastItem] = []
    precip_next_24h_mm: float | None = None
    cached: bool = False
    stale: bool = False
