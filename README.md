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
