"""
Alert endpoints for n8n workflow automation.

n8n polls weather and outbreak data on a schedule, decides when a warning is
worth sending, and posts here. Keeping the decision logic in n8n rather than
in code means the agronomy thresholds can be tuned without a redeploy.

Flow:
  n8n cron -> GET /api/v1/weather/advisory for each district
           -> IF high risk -> POST /api/v1/alerts/dispatch
           -> this endpoint writes to Firestore + returns the payload
"""

import os
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel, Field

router = APIRouter()

# Shared secret so only our n8n workflow can raise an alert.
N8N_SECRET = os.getenv("N8N_WEBHOOK_SECRET", "")


class AlertPayload(BaseModel):
    title: str = Field(..., description="Short headline the farmer sees first")
    body: str = Field(..., description="What is happening")
    action: Optional[str] = Field(None, description="What the farmer should do")
    severity: str = Field("info", description="critical, high, medium or info")
    type: str = Field("general", description="weather, disease, pest or market")
    districts: List[str] = Field(default_factory=list)
    state: Optional[str] = None


class AlertResponse(BaseModel):
    dispatched: bool
    alert_id: str
    targeted: str
    created_at: str


def _verify(secret: Optional[str]) -> None:
    if not N8N_SECRET:
        raise HTTPException(500, "N8N_WEBHOOK_SECRET is not configured")
    if secret != N8N_SECRET:
        raise HTTPException(401, "Invalid webhook secret")


@router.post("/dispatch", response_model=AlertResponse)
async def dispatch_alert(
    payload: AlertPayload,
    x_webhook_secret: Optional[str] = Header(None),
):
    """Called by n8n when a monitored condition crosses a threshold."""
    _verify(x_webhook_secret)

    now = datetime.now(timezone.utc)
    alert_id = f"alert_{int(now.timestamp())}"

    targeted = (
        ", ".join(payload.districts)
        if payload.districts
        else (payload.state or "all farmers")
    )

    # Firestore write happens from the n8n workflow using service-account
    # credentials; this endpoint validates and shapes the payload so the app
    # always receives a consistent structure.
    return AlertResponse(
        dispatched=True,
        alert_id=alert_id,
        targeted=targeted,
        created_at=now.isoformat(),
    )


@router.get("/monitor/{district}")
async def monitor_district(district: str, lat: float, lon: float):
    """
    One call n8n can poll per district. Returns whether an alert is warranted
    and a ready-to-send payload, so the workflow stays simple.
    """
    from app.api.weather import weather_advisory

    advisory = await weather_advisory(lat=lat, lon=lon, crop=None)
    high_risks = [r for r in advisory.risks if r.risk_level.lower() == "high"]

    should_alert = bool(high_risks) or advisory.rainfall_mm > 15

    suggested = None
    if high_risks:
        r = high_risks[0]
        suggested = {
            "title": f"{r.disease} risk in {district}",
            "body": r.reason,
            "action": r.action,
            "severity": "high",
            "type": "disease",
            "districts": [district],
        }
    elif advisory.rainfall_mm > 15:
        suggested = {
            "title": f"Heavy rain expected in {district}",
            "body": f"{advisory.rainfall_mm:.0f} mm forecast in the next 3 hours.",
            "action": "Delay spraying and check field drainage.",
            "severity": "high",
            "type": "weather",
            "districts": [district],
        }

    return {
        "district": district,
        "should_alert": should_alert,
        "temp_c": advisory.temp_c,
        "humidity": advisory.humidity,
        "rainfall_mm": advisory.rainfall_mm,
        "high_risk_count": len(high_risks),
        "suggested_alert": suggested,
    }