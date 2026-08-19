"""
Location resolution.

Maps a farmer's coordinates or district to their nearest mandi and state,
so price, weather and scheme results are local rather than generic.
"""

import math
from typing import Optional

from pydantic import BaseModel


class Mandi(BaseModel):
    name: str
    district: str
    state: str
    lat: float
    lon: float
    price_index: float = 1.0


# Major APMC markets. price_index scales the base national price to reflect
# typical regional variation - a placeholder until the live Agmarknet feed lands.
MANDIS = [
    Mandi(name="Bengaluru", district="Bengaluru Urban", state="Karnataka", lat=12.9716, lon=77.5946, price_index=1.08),
    Mandi(name="Mysuru", district="Mysuru", state="Karnataka", lat=12.2958, lon=76.6394, price_index=0.96),
    Mandi(name="Mandya", district="Mandya", state="Karnataka", lat=12.5218, lon=76.8951, price_index=0.94),
    Mandi(name="Hubballi", district="Dharwad", state="Karnataka", lat=15.3647, lon=75.1240, price_index=0.97),
    Mandi(name="Belagavi", district="Belagavi", state="Karnataka", lat=15.8497, lon=74.4977, price_index=0.95),
    Mandi(name="Kalaburagi", district="Kalaburagi", state="Karnataka", lat=17.3297, lon=76.8343, price_index=0.92),
    Mandi(name="Davanagere", district="Davanagere", state="Karnataka", lat=14.4644, lon=75.9218, price_index=0.95),
    Mandi(name="Tumakuru", district="Tumakuru", state="Karnataka", lat=13.3392, lon=77.1010, price_index=1.02),
    Mandi(name="Kolar", district="Kolar", state="Karnataka", lat=13.1362, lon=78.1291, price_index=1.05),
    Mandi(name="Pune", district="Pune", state="Maharashtra", lat=18.5204, lon=73.8567, price_index=1.10),
    Mandi(name="Nashik", district="Nashik", state="Maharashtra", lat=19.9975, lon=73.7898, price_index=1.06),
    Mandi(name="Hyderabad", district="Hyderabad", state="Telangana", lat=17.3850, lon=78.4867, price_index=1.07),
    Mandi(name="Chennai", district="Chennai", state="Tamil Nadu", lat=13.0827, lon=80.2707, price_index=1.12),
    Mandi(name="Coimbatore", district="Coimbatore", state="Tamil Nadu", lat=11.0168, lon=76.9558, price_index=1.00),
    Mandi(name="Vijayawada", district="Krishna", state="Andhra Pradesh", lat=16.5062, lon=80.6480, price_index=1.01),
    Mandi(name="Lucknow", district="Lucknow", state="Uttar Pradesh", lat=26.8467, lon=80.9462, price_index=0.93),
    Mandi(name="Patna", district="Patna", state="Bihar", lat=25.5941, lon=85.1376, price_index=0.90),
    Mandi(name="Bhopal", district="Bhopal", state="Madhya Pradesh", lat=23.2599, lon=77.4126, price_index=0.91),
    Mandi(name="Jaipur", district="Jaipur", state="Rajasthan", lat=26.9124, lon=75.7873, price_index=0.98),
    Mandi(name="Ahmedabad", district="Ahmedabad", state="Gujarat", lat=23.0225, lon=72.5714, price_index=1.04),
]


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Great-circle distance in kilometres."""
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def nearest_mandi(lat: float, lon: float) -> tuple[Mandi, float]:
    """Return the closest mandi and the distance to it in km."""
    best = min(MANDIS, key=lambda m: _haversine(lat, lon, m.lat, m.lon))
    return best, round(_haversine(lat, lon, best.lat, best.lon), 1)


def find_by_district(district: str) -> Optional[Mandi]:
    key = district.strip().lower()
    for m in MANDIS:
        if m.district.lower() == key or m.name.lower() == key:
            return m
    return None


def state_language(state: str) -> str:
    """Default app language for a state - used to preselect on first launch."""
    return {
        "Karnataka": "Kannada",
        "Maharashtra": "Marathi",
        "Telangana": "Telugu",
        "Andhra Pradesh": "Telugu",
        "Tamil Nadu": "Tamil",
        "Uttar Pradesh": "Hindi",
        "Bihar": "Hindi",
        "Madhya Pradesh": "Hindi",
        "Rajasthan": "Hindi",
        "Gujarat": "Gujarati",
    }.get(state, "Hindi")