"""
Satellite-based crop health monitoring (NDVI).

Uses Google Earth Engine to compute a Normalized Difference Vegetation Index
(NDVI) reading for a farmer's field - an early signal of crop stress before
it's visible to the eye.
"""

import os
import json
from datetime import datetime, timedelta

import ee
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

router = APIRouter()

_initialized = False


def _init_earth_engine():
    global _initialized
    if _initialized:
        return
    key_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")
    if not key_path or not os.path.exists(key_path):
        raise HTTPException(500, "Earth Engine credentials are not configured")
    with open(key_path) as f:
        key_data = json.load(f)
    credentials = ee.ServiceAccountCredentials(key_data["client_email"], key_path)
    ee.Initialize(credentials)
    _initialized = True


class NdviReading(BaseModel):
    lat: float
    lon: float
    ndvi: float
    health_status: str
    image_date: str
    disclaimer: str = (
        "Vegetation index reflects the most recent cloud-free satellite pass, "
        "not necessarily today's conditions. Confirm with a field visit before acting."
    )


def _status_for(ndvi: float) -> str:
    if ndvi < 0.2:
        return "bare soil or severe stress - inspect the field"
    if ndvi < 0.4:
        return "sparse or stressed vegetation - monitor closely"
    if ndvi < 0.6:
        return "moderate vegetation health"
    return "healthy, dense vegetation"


@router.get("/ndvi", response_model=NdviReading)
async def get_ndvi(
    lat: float = Query(..., description="Latitude of the field"),
    lon: float = Query(..., description="Longitude of the field"),
):
    _init_earth_engine()

    point = ee.Geometry.Point([lon, lat])
    end = datetime.utcnow()
    start = end - timedelta(days=120)

    collection = (
        ee.ImageCollection("COPERNICUS/S2_SR_HARMONIZED")
        .filterBounds(point)
        .filterDate(start.strftime("%Y-%m-%d"), end.strftime("%Y-%m-%d"))
        .filter(ee.Filter.lt("CLOUDY_PIXEL_PERCENTAGE", 30))
        .sort("CLOUDY_PIXEL_PERCENTAGE")
    )

    image = collection.first()
    if image is None:
        raise HTTPException(404, "No cloud-free satellite image found in the last 120 days")

    ndvi_image = image.normalizedDifference(["B8", "B4"]).rename("NDVI")

    stats = ndvi_image.reduceRegion(
        reducer=ee.Reducer.mean(),
        geometry=point.buffer(500),
        scale=10,
    ).getInfo()

    ndvi_value = stats.get("NDVI")
    if ndvi_value is None:
        raise HTTPException(404, "Could not compute NDVI for this location")

    image_date = ee.Date(image.get("system:time_start")).format("YYYY-MM-dd").getInfo()

    return NdviReading(
        lat=lat,
        lon=lon,
        ndvi=round(ndvi_value, 3),
        health_status=_status_for(ndvi_value),
        image_date=image_date,
    )