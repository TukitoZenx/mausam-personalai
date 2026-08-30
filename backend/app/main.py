from fastapi import FastAPI
from app.api.health import router as health_router

app = FastAPI(
    title="Mausam PersonalAI API",
    version="0.1.0",
    description="Personalized weather & recommendations API"
)

app.include_router(health_router)

@app.get("/")
async def root():
    return {"message": "Welcome to Mausam PersonalAI API"}
