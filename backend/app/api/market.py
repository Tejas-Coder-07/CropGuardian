"""
Market price endpoints.

Prices are resolved to the farmer's nearest mandi rather than a fixed city,
because mandi rates vary meaningfully even across neighbouring districts.
"""

from datetime import date, timedelta
from typing import List, Optional

import numpy as np
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from sklearn.linear_model import LinearRegression

from app.services.location import nearest_mandi, find_by_district

router = APIRouter()


class PricePoint(BaseModel):
    on_date: date
    modal_price: float


class PriceForecast(BaseModel):
    crop: str
    mandi: str
    district: str
    state: str
    distance_km: Optional[float] = None
    unit: str = "Rs per quintal (1 quintal = 100 kg)"
    current_price: float
    current_price_per_kg: float
    forecast_7d: float
    forecast_7d_per_kg: float
    change_pct: float
    recommendation: str
    confidence: str
    history: List[PricePoint]
    disclaimer: str = (
        "Forecast is indicative only. Confirm with your local mandi before selling."
    )


_BASE = {
    "tomato": [1850, 1920, 1880, 2050, 2200, 2150, 2300, 2280, 2400, 2450],
    "onion": [2200, 2150, 2100, 2050, 1980, 1950, 1900, 1880, 1850, 1820],
    "potato": [1200, 1220, 1250, 1240, 1280, 1300, 1290, 1320, 1350, 1340],
    "wheat": [2400, 2410, 2425, 2430, 2450, 2445, 2460, 2470, 2480, 2490],
    "rice": [2800, 2820, 2810, 2850, 2880, 2870, 2900, 2920, 2910, 2950],
    "maize": [1900, 1920, 1950, 1940, 1980, 2000, 1990, 2020, 2050, 2040],
    "cotton": [6800, 6850, 6900, 6880, 6950, 7000, 6980, 7050, 7100, 7080],
    "sugarcane": [340, 345, 342, 350, 355, 352, 358, 360, 362, 365],
    "ragi": [3200, 3220, 3250, 3240, 3280, 3300, 3290, 3320, 3350, 3340],
    "groundnut": [5800, 5850, 5900, 5880, 5950, 6000, 5980, 6050, 6100, 6080],
}


def _forecast(prices: List[float], horizon: int = 7) -> float:
    x = np.arange(len(prices)).reshape(-1, 1)
    y = np.array(prices)
    model = LinearRegression().fit(x, y)
    return float(round(model.predict(np.array([[len(prices) + horizon - 1]]))[0], 2))


def _advise(change_pct: float) -> tuple[str, str]:
    if change_pct >= 5:
        return ("Prices are trending up. Consider holding for a week if you can store safely.", "medium")
    if change_pct <= -5:
        return ("Prices are trending down. Selling sooner may protect your margin.", "medium")
    return ("Prices look stable. Sell when it suits your cash flow.", "low")


@router.get("/prices/{crop}", response_model=PriceForecast)
def get_price_forecast(
    crop: str,
    lat: Optional[float] = Query(None, description="Farm latitude"),
    lon: Optional[float] = Query(None, description="Farm longitude"),
    district: Optional[str] = Query(None, description="District, if GPS unavailable"),
):
    key = crop.strip().lower()
    if key not in _BASE:
        raise HTTPException(
            404, f"No price data for '{crop}'. Available: {', '.join(sorted(_BASE))}"
        )

    distance = None
    if lat is not None and lon is not None:
        mandi, distance = nearest_mandi(lat, lon)
    elif district:
        mandi = find_by_district(district)
        if mandi is None:
            raise HTTPException(404, f"No mandi mapped for district '{district}'")
    else:
        raise HTTPException(400, "Provide either lat and lon, or a district")

    adjusted = [round(p * mandi.price_index, 2) for p in _BASE[key]]
    current = float(adjusted[-1])
    predicted = _forecast(adjusted)
    change = round(((predicted - current) / current) * 100, 2)
    recommendation, confidence = _advise(change)

    today = date.today()
    history = [
        PricePoint(on_date=today - timedelta(days=len(adjusted) - i - 1), modal_price=p)
        for i, p in enumerate(adjusted)
    ]

    return PriceForecast(
        crop=key,
        mandi=mandi.name,
        district=mandi.district,
        state=mandi.state,
        distance_km=distance,
        current_price=current,
        current_price_per_kg=round(current / 100, 2),
        forecast_7d=predicted,
        forecast_7d_per_kg=round(predicted / 100, 2),
        change_pct=change,
        recommendation=recommendation,
        confidence=confidence,
        history=history,
    )


@router.get("/crops")
def list_crops():
    return {"crops": sorted(_BASE.keys())}


@router.get("/nearest-mandi")
def get_nearest_mandi(lat: float = Query(...), lon: float = Query(...)):
    mandi, distance = nearest_mandi(lat, lon)
    return {
        "mandi": mandi.name,
        "district": mandi.district,
        "state": mandi.state,
        "distance_km": distance,
    }