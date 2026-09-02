# Mausam PersonalAI

A Flutter + FastAPI weather personalization application tailored for **Fitness**, **Health**, and **Traveler** personas.

## Tech Stack
- **Mobile**: Flutter / Dart
- **Backend**: FastAPI / Python
- **Database**: PostgreSQL + PostGIS
- **Cache**: Redis
- **Dev Environment**: Docker & Docker Compose

## Development Workflow
- **Branch Strategy**: Single branch (`main`) only. All changes are committed and pushed directly to `main`.

## Quickstart

```bash
# 1. Copy environment variables
cp .env.example .env

# 2. Start services (FastAPI, PostGIS DB, Redis)
docker-compose up -d --build

# 3. Check health endpoint
curl http://localhost:8000/health
```

## Configuring API Base URL for Mobile App

The mobile application API base URL is configurable via compile-time `--dart-define` flag:

- **Android Emulator (Default - no flag required)**:
  ```bash
  cd mobile && flutter run
  ```
  *(Defaults to `http://10.0.2.2:8000`)*

- **Physical Android Device**:
  Pass host machine's LAN IP address (e.g. `10.10.212.76`):
  ```bash
  cd mobile && flutter run --dart-define=API_BASE_URL=http://10.10.212.76:8000
  ```

## How to Demo Persona & Context Switching at One Location (Phase 10)

To demo dynamic homepage re-ranking and context switching:

1. **Persona Switching Demo**:
   - Open the app and navigate to the **Profile** screen (top-right account icon on the homepage).
   - Select **Fitness Enthusiast**: Return home to see `activity_window` and `uv` ranked near the top, with the Recommended section highlighting the optimal run window.
   - Select **Health Sensitive**: Return home to see `aqi`, `alerts`, or `uv` highlighted near the top, with air quality and UV advisories prioritized.
   - Select **Active Traveler**: Return home to see `destination`, `packing`, and precipitation cards prioritized.

2. **Location & Destination Switching Demo**:
   - Tap the location title in the top AppBar to open the **Location Switcher**.
   - Toggle between **Current Location** (device GPS) and a **Saved Destination** (e.g. Mysuru Palace).
   - The homepage automatically refetches `/personalization/home` passing `saved_location_id`, dynamically adjusting weather, destination, and packing insights for the selected target.

3. **Pull to Refresh**:
   - Swipe down on the homepage feed to trigger `RefreshIndicator` and fetch live rank-ordered insights.

