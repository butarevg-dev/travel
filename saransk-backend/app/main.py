from fastapi import FastAPI
from fastapi.responses import ORJSONResponse

app = FastAPI(
    title="Saransk for Tourists API",
    default_response_class=ORJSONResponse,
)

@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}