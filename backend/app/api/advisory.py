"""
Crop advisory endpoints.

Fertiliser, soil health and crop planning guidance. Uses Gemini for reasoning
but constrains the output shape so the app can render it reliably, and forces
a "verify with your agriculture officer" line onto any chemical advice.
"""

import json
import os
import re
from typing import List, Optional

import httpx
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

router = APIRouter()

GEMINI_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/"
    "models/gemini-flash-latest:generateContent"
)

VERIFY_LINE = (
    "Confirm quantities and chemicals with your local agriculture officer "
    "or Krishi Vigyan Kendra before applying."
)


class AdvisoryStep(BaseModel):
    title: str
    detail: str


class CropAdvisory(BaseModel):
    crop: str
    summary: str
    steps: List[AdvisoryStep]
    warnings: List[str]
    disclaimer: str = VERIFY_LINE


async def _ask_gemini(prompt: str) -> dict:
    if not GEMINI_KEY:
        raise HTTPException(500, "GEMINI_API_KEY is not configured")

    async with httpx.AsyncClient(timeout=45) as client:
        resp = await client.post(
            f"{GEMINI_URL}?key={GEMINI_KEY}",
            json={
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {"temperature": 0.3, "maxOutputTokens": 2048},
            },
        )

    if resp.status_code != 200:
        raise HTTPException(resp.status_code, f"Advisory model error: {resp.text[:200]}")

    text = resp.json()["candidates"][0]["content"]["parts"][0]["text"]
    match = re.search(r"\{[\s\S]*\}", text.replace("```json", "").replace("```", ""))
    if not match:
        raise HTTPException(502, "Advisory model returned an unreadable response")
    return json.loads(match.group(0))


def _to_advisory(crop: str, data: dict) -> CropAdvisory:
    warnings = data.get("warnings", [])
    if VERIFY_LINE not in warnings:
        warnings.append(VERIFY_LINE)

    return CropAdvisory(
        crop=crop,
        summary=data.get("summary", ""),
        steps=[
            AdvisoryStep(title=s.get("title", ""), detail=s.get("detail", ""))
            for s in data.get("steps", [])
        ],
        warnings=warnings,
    )


@router.get("/fertiliser", response_model=CropAdvisory)
async def fertiliser_advice(
    crop: str = Query(..., description="Crop name"),
    soil_type: Optional[str] = Query(None, description="Soil type if known"),
    stage: Optional[str] = Query(None, description="Growth stage"),
    state: Optional[str] = Query(None, description="State, for local practice"),
):
    prompt = f"""You are advising an Indian smallholder farmer growing {crop}.
{f"Soil type: {soil_type}." if soil_type else ""}
{f"Growth stage: {stage}." if stage else ""}
{f"State: {state}." if state else ""}

Give practical fertiliser guidance. Prefer organic and low-cost options first.
Use quantities per acre. Keep language simple enough to translate.

Respond with ONLY valid JSON, no markdown:
{{
  "summary": "one or two sentences",
  "steps": [{{"title": "short step name", "detail": "what to do, with quantity and timing"}}],
  "warnings": ["things to avoid or watch for"]
}}"""
    return _to_advisory(crop, await _ask_gemini(prompt))


@router.get("/soil-health", response_model=CropAdvisory)
async def soil_health_advice(
    crop: str = Query(...),
    soil_type: Optional[str] = Query(None),
    state: Optional[str] = Query(None),
):
    prompt = f"""You are advising an Indian smallholder farmer growing {crop}.
{f"Soil type: {soil_type}." if soil_type else ""}
{f"State: {state}." if state else ""}

Give practical soil health guidance: testing, organic matter, pH correction,
crop rotation. Focus on low-cost methods a small farmer can actually do.

Respond with ONLY valid JSON, no markdown:
{{
  "summary": "one or two sentences",
  "steps": [{{"title": "short step name", "detail": "what to do"}}],
  "warnings": ["things to avoid"]
}}"""
    return _to_advisory(crop, await _ask_gemini(prompt))


@router.get("/crop-plan", response_model=CropAdvisory)
async def crop_plan(
    crop: str = Query(...),
    state: Optional[str] = Query(None),
    season: Optional[str] = Query(None, description="kharif, rabi or zaid"),
):
    prompt = f"""You are advising an Indian smallholder farmer planning {crop}.
{f"State: {state}." if state else ""}
{f"Season: {season}." if season else ""}

Give a season plan: land preparation, sowing window, key irrigation and
input timings, and harvest indicators. Keep it to 5-7 steps.

Respond with ONLY valid JSON, no markdown:
{{
  "summary": "one or two sentences",
  "steps": [{{"title": "stage name with rough timing", "detail": "what to do"}}],
  "warnings": ["common mistakes to avoid"]
}}"""
    return _to_advisory(crop, await _ask_gemini(prompt))