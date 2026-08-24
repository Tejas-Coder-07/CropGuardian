"""
Crop Guardian API
Author: Tejas S <tejus.sgowda07@gmail.com>
Team Maverick - Cambridge Institute of Engineering
"""

from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import health, market, weather, schemes, advisory, alerts, satellite

app = FastAPI(
    title="Crop Guardian API",
    description="Backend services for the Crop Guardian farming assistant",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, tags=["health"])
app.include_router(market.router, prefix="/api/v1/market", tags=["market"])
app.include_router(weather.router, prefix="/api/v1/weather", tags=["weather"])
app.include_router(schemes.router, prefix="/api/v1/schemes", tags=["schemes"])
app.include_router(advisory.router, prefix="/api/v1/advisory", tags=["advisory"])
app.include_router(alerts.router, prefix="/api/v1/alerts", tags=["alerts"])
app.include_router(satellite.router, prefix="/api/v1/satellite", tags=["satellite"])


@app.get("/")
def root():
    return {"service": "Crop Guardian API", "version": "1.0.0", "docs": "/docs"}