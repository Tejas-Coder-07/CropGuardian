"""
Lyzr agent proxy.

The scheme assistant runs as a deployed Lyzr agent rather than a raw prompt, so
the agent's instructions, memory and session handling live outside our codebase
and can be tuned without a redeploy. We proxy through the backend so the API key
never ships inside the mobile app.
"""

import os
import uuid
from typing import Optional

import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

LYZR_URL = "https://agent-prod.studio.lyzr.ai/v3/inference/chat/"
LYZR_KEY = os.getenv("LYZR_API_KEY", "")
LYZR_AGENT = os.getenv("LYZR_AGENT_ID", "")


class AskRequest(BaseModel):
    message: str
    user_id: Optional[str] = None
    session_id: Optional[str] = None


class AskResponse(BaseModel):
    answer: str
    session_id: str
    source: str = "Lyzr agent"
    disclaimer: str = (
        "Scheme rules change. Confirm at your nearest Krishi Vigyan Kendra "
        "or agriculture office before applying."
    )


@router.post("/ask", response_model=AskResponse)
async def ask_agent(req: AskRequest):
    if not LYZR_KEY or not LYZR_AGENT:
        raise HTTPException(500, "Lyzr agent is not configured")

    # A stable session per farmer lets the agent remember the thread.
    session = req.session_id or f"{LYZR_AGENT}-{uuid.uuid4().hex[:8]}"
    user = req.user_id or "farmer@cropguardian.app"

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(
            LYZR_URL,
            headers={
                "Content-Type": "application/json",
                "x-api-key": LYZR_KEY,
            },
            json={
                "user_id": user,
                "agent_id": LYZR_AGENT,
                "session_id": session,
                "message": req.message,
            },
        )

    if resp.status_code != 200:
        raise HTTPException(resp.status_code, f"Agent error: {resp.text[:200]}")

    data = resp.json()
    answer = data.get("response") or data.get("message") or ""

    if not answer:
        raise HTTPException(502, "Agent returned an empty response")

    return AskResponse(answer=answer, session_id=session)