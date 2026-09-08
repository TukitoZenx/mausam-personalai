#!/bin/sh
set -e

echo "==> Running database migrations with Alembic..."
alembic upgrade head || echo "==> Alembic upgrade exited with code $?, continuing startup..."

PORT="${PORT:-8000}"
echo "==> Starting Mausam PersonalAI FastAPI service on port $PORT..."
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
