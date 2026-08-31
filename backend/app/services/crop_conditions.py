"""
Crop condition reference.

Optimal ranges and preventive practice per crop, so the advisory always has
something useful to say. A screen that only speaks up during an emergency
teaches a farmer nothing on the other 340 days of the season.

Ranges are indicative growing-season figures from agronomy references, not
prescriptions - soil, variety and stage all shift them.
"""

from typing import Dict, List, Optional
from pydantic import BaseModel


class CropProfile(BaseModel):
    crop: str
    temp_min: float
    temp_max: float
    humidity_min: int
    humidity_max: int
    watch_for: List[str]
    preventive: List[str]


PROFILES: Dict[str, CropProfile] = {
    "tomato": CropProfile(
        crop="tomato",
        temp_min=20, temp_max=27,
        humidity_min=50, humidity_max=70,
        watch_for=[
            "Curling or yellowing lower leaves",
            "Dark water-soaked spots after humid nights",
            "Black sunken patch at the fruit base",
        ],
        preventive=[
            "Water at the base, never over the leaves",
            "Stake plants so air moves through the canopy",
            "Remove the lowest leaves once fruit sets",
        ],
    ),
    "potato": CropProfile(
        crop="potato",
        temp_min=15, temp_max=24,
        humidity_min=60, humidity_max=80,
        watch_for=[
            "Dark lesions with pale edges on leaves",
            "White fuzz under leaves in cool damp weather",
            "Exposed tubers turning green",
        ],
        preventive=[
            "Earth up regularly to keep tubers covered",
            "Avoid evening irrigation in cool weather",
            "Rotate away from tomato and chilli",
        ],
    ),
    "rice": CropProfile(
        crop="rice",
        temp_min=22, temp_max=32,
        humidity_min=60, humidity_max=85,
        watch_for=[
            "Diamond-shaped lesions on leaves",
            "Empty or partly filled grains at the panicle",
            "Yellowing from the leaf tip downward",
        ],
        preventive=[
            "Keep nitrogen split rather than heavy at once",
            "Maintain shallow standing water, not flooding",
            "Keep bunds clear of weeds that harbour pests",
        ],
    ),
    "grape": CropProfile(
        crop="grape",
        temp_min=18, temp_max=30,
        humidity_min=40, humidity_max=65,
        watch_for=[
            "White powdery patches on leaves or berries",
            "Berries splitting after rain",
            "Yellow oily spots on the upper leaf surface",
        ],
        preventive=[
            "Prune to open the canopy for airflow",
            "Keep the vine floor free of fallen leaves",
            "Avoid overhead irrigation entirely",
        ],
    ),
    "cotton": CropProfile(
        crop="cotton",
        temp_min=21, temp_max=32,
        humidity_min=50, humidity_max=75,
        watch_for=[
            "Angular water-soaked spots on leaves",
            "Boll shedding before opening",
            "Sticky honeydew and sooty mould",
        ],
        preventive=[
            "Scout twice weekly once squares form",
            "Keep field borders clear of alternate hosts",
            "Avoid excess nitrogen, which invites sucking pests",
        ],
    ),
    "maize": CropProfile(
        crop="maize",
        temp_min=21, temp_max=30,
        humidity_min=50, humidity_max=75,
        watch_for=[
            "Ragged holes in the whorl",
            "Long grey-green lesions on leaves",
            "Poor grain fill at the cob tip",
        ],
        preventive=[
            "Inspect whorls early morning for larvae",
            "Ensure even moisture at tasselling",
            "Rotate to break pest carry-over",
        ],
    ),
    "wheat": CropProfile(
        crop="wheat",
        temp_min=15, temp_max=24,
        humidity_min=50, humidity_max=70,
        watch_for=[
            "Orange or brown pustules on leaves",
            "Pale striping along leaf veins",
            "Shrivelled grain at harvest",
        ],
        preventive=[
            "Sow at the recommended window for your district",
            "Avoid standing water after irrigation",
            "Use certified seed to limit seed-borne disease",
        ],
    ),
    "onion": CropProfile(
        crop="onion",
        temp_min=13, temp_max=28,
        humidity_min=55, humidity_max=70,
        watch_for=[
            "Silvery streaks and distorted leaf tips",
            "Sunken pale lesions on leaves",
            "Soft necks at maturity",
        ],
        preventive=[
            "Stop irrigation as bulbs begin to mature",
            "Keep beds weed-free to reduce thrips",
            "Cure bulbs fully before storage",
        ],
    ),
}


class ConditionReading(BaseModel):
    label: str
    status: str          # ideal, above, below
    detail: str


def assess(crop: Optional[str], temp: float, humidity: int) -> Optional[dict]:
    """Compare current conditions to the crop's preferred range."""
    if not crop:
        return None
    profile = PROFILES.get(crop.strip().lower())
    if profile is None:
        return None

    readings: List[ConditionReading] = []

    if temp < profile.temp_min:
        readings.append(ConditionReading(
            label="Temperature",
            status="below",
            detail=f"{temp:.0f}C is below the {profile.temp_min:.0f}-{profile.temp_max:.0f}C "
                   f"range {profile.crop} grows best in. Growth will be slow.",
        ))
    elif temp > profile.temp_max:
        readings.append(ConditionReading(
            label="Temperature",
            status="above",
            detail=f"{temp:.0f}C is above the {profile.temp_min:.0f}-{profile.temp_max:.0f}C "
                   f"range {profile.crop} prefers. Watch for heat stress and flower drop.",
        ))
    else:
        readings.append(ConditionReading(
            label="Temperature",
            status="ideal",
            detail=f"{temp:.0f}C sits in the {profile.temp_min:.0f}-{profile.temp_max:.0f}C "
                   f"range {profile.crop} grows best in.",
        ))

    if humidity < profile.humidity_min:
        readings.append(ConditionReading(
            label="Humidity",
            status="below",
            detail=f"{humidity}% is drier than the {profile.humidity_min}-{profile.humidity_max}% "
                   f"{profile.crop} prefers. Irrigation matters more today.",
        ))
    elif humidity > profile.humidity_max:
        readings.append(ConditionReading(
            label="Humidity",
            status="above",
            detail=f"{humidity}% is wetter than the {profile.humidity_min}-{profile.humidity_max}% "
                   f"{profile.crop} prefers. Fungal pressure rises in this range.",
        ))
    else:
        readings.append(ConditionReading(
            label="Humidity",
            status="ideal",
            detail=f"{humidity}% is within the {profile.humidity_min}-{profile.humidity_max}% "
                   f"band that suits {profile.crop}.",
        ))

    all_ideal = all(r.status == "ideal" for r in readings)

    return {
        "crop": profile.crop,
        "readings": [r.model_dump() for r in readings],
        "all_ideal": all_ideal,
        "summary": (
            f"Conditions are good for {profile.crop} right now. Keep monitoring."
            if all_ideal
            else f"Conditions are outside the ideal range for {profile.crop}. "
                 f"No disease warning yet, but stay watchful."
        ),
        "watch_for": profile.watch_for,
        "preventive": profile.preventive,
    }


def supported_crops() -> List[str]:
    return sorted(PROFILES.keys())