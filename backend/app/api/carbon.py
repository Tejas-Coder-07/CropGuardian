"""
Carbon footprint estimator.

Emission factors are per-hectare averages drawn from published Indian
agricultural studies. They are indicative, not measured, and the response says
so - a farmer should not treat this as a certified audit.
"""

from typing import Dict, List, Optional

from fastapi import APIRouter, Query
from pydantic import BaseModel

router = APIRouter()

# kg CO2-equivalent per unit. Sources: IPCC Tier 1 defaults and Indian
# agricultural LCA literature. Rounded deliberately - false precision here
# would be misleading.
FACTORS = {
    "urea_per_kg": 1.57,
    "dap_per_kg": 1.31,
    "mop_per_kg": 0.51,
    "pesticide_per_litre": 16.6,
    "diesel_per_litre": 2.68,
    "electricity_per_kwh": 0.71,
    "farmyard_manure_per_tonne": -12.0,   # net sink from soil carbon
    "residue_burning_per_tonne": 1460.0,  # very high, deliberately shown
}

# Rough per-hectare sequestration if practice adopted.
PRACTICES = {
    "cover_cropping": 350.0,
    "no_till": 400.0,
    "agroforestry": 1200.0,
    "compost_over_chemical": 280.0,
}


class FootprintInput(BaseModel):
    area_hectares: float = 1.0
    urea_kg: float = 0
    dap_kg: float = 0
    mop_kg: float = 0
    pesticide_litres: float = 0
    diesel_litres: float = 0
    electricity_kwh: float = 0
    manure_tonnes: float = 0
    residue_burnt_tonnes: float = 0


class FootprintBreakdown(BaseModel):
    source: str
    kg_co2e: float
    share_pct: float


class FootprintResult(BaseModel):
    total_kg_co2e: float
    per_hectare_kg_co2e: float
    rating: str
    breakdown: List[FootprintBreakdown]
    biggest_source: Optional[str]
    suggestions: List[str]
    potential_saving_kg: float
    disclaimer: str = (
        "Estimate based on published average emission factors, not a measured "
        "audit. Use it to compare your own seasons, not for certification."
    )


def _rating(per_ha: float) -> str:
    if per_ha < 800:
        return "low"
    if per_ha < 2000:
        return "moderate"
    if per_ha < 4000:
        return "high"
    return "very high"


@router.post("/footprint", response_model=FootprintResult)
def calculate_footprint(data: FootprintInput):
    items: Dict[str, float] = {
        "Urea": data.urea_kg * FACTORS["urea_per_kg"],
        "DAP": data.dap_kg * FACTORS["dap_per_kg"],
        "MOP": data.mop_kg * FACTORS["mop_per_kg"],
        "Pesticide": data.pesticide_litres * FACTORS["pesticide_per_litre"],
        "Diesel": data.diesel_litres * FACTORS["diesel_per_litre"],
        "Electricity": data.electricity_kwh * FACTORS["electricity_per_kwh"],
        "Farmyard manure": data.manure_tonnes * FACTORS["farmyard_manure_per_tonne"],
        "Residue burning": data.residue_burnt_tonnes * FACTORS["residue_burning_per_tonne"],
    }

    positives = {k: v for k, v in items.items() if v > 0}
    total = sum(items.values())
    gross = sum(positives.values()) or 1.0

    breakdown = [
        FootprintBreakdown(
            source=k,
            kg_co2e=round(v, 1),
            share_pct=round((v / gross) * 100, 1),
        )
        for k, v in sorted(items.items(), key=lambda x: -abs(x[1]))
        if abs(v) > 0.01
    ]

    biggest = max(positives, key=positives.get) if positives else None
    area = max(data.area_hectares, 0.01)
    per_ha = total / area

    suggestions: List[str] = []
    saving = 0.0

    if data.residue_burnt_tonnes > 0:
        suggestions.append(
            "Stop burning crop residue. Incorporating it into the soil removes "
            "by far the largest part of your footprint and improves soil carbon."
        )
        saving += items["Residue burning"] * 0.9

    if data.urea_kg > 0:
        suggestions.append(
            "Split urea into smaller doses timed to crop need. This cuts both "
            "cost and nitrous oxide loss without reducing yield."
        )
        saving += items["Urea"] * 0.2

    if data.diesel_litres > 20:
        suggestions.append(
            "Reduce tillage passes. Each pass avoided saves diesel and keeps "
            "soil carbon in the ground."
        )
        saving += items["Diesel"] * 0.25

    if data.manure_tonnes == 0:
        suggestions.append(
            "Add farmyard manure or compost. Organic matter builds soil carbon "
            "and reduces how much chemical fertiliser you need."
        )
        saving += PRACTICES["compost_over_chemical"] * area

    if not suggestions:
        suggestions.append(
            "Your inputs are already low. Consider agroforestry on field "
            "boundaries to move towards a net carbon sink."
        )

    return FootprintResult(
        total_kg_co2e=round(total, 1),
        per_hectare_kg_co2e=round(per_ha, 1),
        rating=_rating(per_ha),
        breakdown=breakdown,
        biggest_source=biggest,
        suggestions=suggestions,
        potential_saving_kg=round(saving, 1),
    )


@router.get("/practices")
def sequestration_practices(area_hectares: float = Query(1.0)):
    """What a farmer could offset by adopting each practice."""
    return {
        "area_hectares": area_hectares,
        "practices": [
            {
                "name": name.replace("_", " ").title(),
                "kg_co2e_per_year": round(value * area_hectares, 1),
            }
            for name, value in sorted(PRACTICES.items(), key=lambda x: -x[1])
        ],
        "note": "Indicative sequestration rates. Actual results vary with soil and rainfall.",
    }