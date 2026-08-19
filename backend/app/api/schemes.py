"""
Government scheme assistant.

Uses Tavily live web search to retrieve current scheme information, then
returns clean structured results the app can read aloud to a farmer.
Live search matters here because scheme eligibility and deadlines change
often enough that a hardcoded list goes stale within a season.
"""

import os
from typing import List, Optional

import httpx
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

router = APIRouter()

TAVILY_KEY = os.getenv("TAVILY_API_KEY", "")
TAVILY_URL = "https://api.tavily.com/search"

_TRUSTED = [
    "pmkisan.gov.in",
    "agricoop.gov.in",
    "enam.gov.in",
    "pmfby.gov.in",
    "soilhealth.dac.gov.in",
    "myscheme.gov.in",
    "india.gov.in",
]


class SchemeResult(BaseModel):
    title: str
    summary: str
    source_url: str
    source_name: str


class SchemeResponse(BaseModel):
    query: str
    answer: Optional[str]
    results: List[SchemeResult]
    disclaimer: str = (
        "Scheme details change often. Verify on the official portal or with your "
        "nearest Krishi Vigyan Kendra before applying."
    )


@router.get("/search", response_model=SchemeResponse)
async def search_schemes(
    q: str = Query(..., description="What the farmer wants to know"),
    state: Optional[str] = Query(None, description="State, to narrow results"),
):
    if not TAVILY_KEY:
        raise HTTPException(500, "TAVILY_API_KEY is not configured")

    query = f"{q} farmer scheme India"
    if state:
        query += f" {state}"

    async with httpx.AsyncClient(timeout=25) as client:
        resp = await client.post(
            TAVILY_URL,
            json={
                "api_key": TAVILY_KEY,
                "query": query,
                "search_depth": "advanced",
                "include_answer": True,
                "include_domains": _TRUSTED,
                "max_results": 6,
            },
        )

    if resp.status_code != 200:
        raise HTTPException(resp.status_code, "Search provider error")

    data = resp.json()

    results = [
        SchemeResult(
            title=item.get("title", ""),
            summary=item.get("content", "")[:400],
            source_url=item.get("url", ""),
            source_name=item.get("url", "").split("/")[2] if item.get("url") else "",
        )
        for item in data.get("results", [])
    ]

    return SchemeResponse(
        query=q,
        answer=data.get("answer"),
        results=results,
    )