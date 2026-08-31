"""
Weather-linked disease risk.

Turns an OpenWeatherMap forecast into crop-specific disease risk so the app
can warn a farmer before symptoms appear, rather than after.
"""

import os
from typing import List, Optional

import httpx
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from app.services.crop_conditions import assess, supported_crops

router = APIRouter()

OWM_KEY = os.getenv("OPENWEATHER_API_KEY", "")
OWM_URL = "https://api.openweathermap.org/data/2.5/forecast"


class DiseaseRisk(BaseModel):
    disease: str
    crop: str
    risk_level: str
    reason: str
    action: str


class WeatherAdvisory(BaseModel):
    location: str
    temp_c: float
    humidity: int
    rainfall_mm: float
    conditions: str
    risks: List[DiseaseRisk]
    crop_conditions: Optional[dict] = None
    irrigation_advice: str
    disclaimer: str = (
        "Guidance is indicative. Confirm chemical use with your local agriculture officer."
    )


# condition -> (crop, disease, temp range, humidity threshold, action)
_RULES = [
    ("tomato", "Late blight", (10, 24), 85,
     "Humid and cool - ideal for late blight. Inspect lower leaves and improve airflow."),
    ("tomato", "Early blight", (24, 32), 75,
     "Warm and humid. Remove affected lower leaves and avoid overhead watering."),
    ("potato", "Late blight", (10, 24), 85,
     "Cool damp spell. Check for dark water-soaked lesions on leaves."),
    ("rice", "Blast", (20, 30), 85,
     "High humidity favours rice blast. Avoid excess nitrogen right now."),
    ("grape", "Powdery mildew", (20, 30), 70,
     "Conditions favour mildew. Improve canopy ventilation."),
    ("cotton", "Bacterial blight", (25, 35), 80,
     "Warm and humid. Scout for angular leaf spots."),
]


def _risk_for(temp: float, humidity: int, crop: Optional[str]) -> List[DiseaseRisk]:
    out: List[DiseaseRisk] = []
    for rule_crop, disease, (lo, hi), hum_min, action in _RULES:
        if crop and crop.lower() != rule_crop:
            continue
        if lo <= temp <= hi and humidity >= hum_min:
            level = "high" if humidity >= hum_min + 8 else "moderate"
            out.append(
                DiseaseRisk(
                    disease=disease,
                    crop=rule_crop,
                    risk_level=level,
                    reason=f"{temp:.0f}C with {humidity}% humidity favours {disease.lower()}.",
                    action=action,
                )
            )
    return out


def _irrigation(temp: float, humidity: int, rain: float) -> str:
    if rain > 10:
        return "Recent rainfall is sufficient. Skip irrigation to avoid waterlogging."
    if temp > 32 and humidity < 50:
        return "Hot and dry. Irrigate early morning or after sunset to reduce evaporation loss."
    if humidity > 85:
        return "Humidity is high. Reduce irrigation to limit fungal pressure."
    return "Normal conditions. Maintain your usual irrigation schedule."


@router.get("/advisory", response_model=WeatherAdvisory)
async def weather_advisory(
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude"),
    crop: Optional[str] = Query(None, description="Filter risks to one crop"),
):
    if not OWM_KEY:
        raise HTTPException(500, "OPENWEATHER_API_KEY is not configured")

    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(
            OWM_URL,
            params={"lat": lat, "lon": lon, "appid": OWM_KEY, "units": "metric"},
        )

    if resp.status_code != 200:
        raise HTTPException(resp.status_code, f"Weather provider error: {resp.text[:200]}")

    data = resp.json()
    first = data["list"][0]
    temp = float(first["main"]["temp"])
    humidity = int(first["main"]["humidity"])
    rain = float(first.get("rain", {}).get("3h", 0.0))
    conditions = first["weather"][0]["description"]

    return WeatherAdvisory(
        location=data.get("city", {}).get("name", "Unknown"),
        temp_c=temp,
        humidity=humidity,
        rainfall_mm=rain,
        conditions=conditions,
        risks=_risk_for(temp, humidity, crop),
        crop_conditions=assess(crop, temp, humidity),
        irrigation_advice=_irrigation(temp, humidity, rain),
    )
