from fastapi import FastAPI
from fastapi.responses import ORJSONResponse
from app.api import api_router

app = FastAPI(
    title="Saransk for Tourists API",
    description="Backend API for the Saransk for Tourists mobile application",
    version="0.1.0",
    default_response_class=ORJSONResponse,
)

# Include API routes
app.include_router(api_router)

@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "version": "0.1.0"}

@app.get("/")
async def root() -> dict:
    return {
        "message": "Saransk for Tourists API",
        "docs": "/docs",
        "health": "/health"
    }