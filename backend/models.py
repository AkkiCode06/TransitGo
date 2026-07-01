from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum
import uuid


class Provider(str, Enum):
    hala      = "hala"
    careem    = "careem"
    zed       = "zed"
    uber      = "uber"
    yango     = "yango"
    rta_metro = "rta_metro"
    rta_bus   = "rta_bus"
    rta_taxi  = "rta_taxi"


class ProviderBucket(str, Enum):
    priced  = "priced"   # metered / zone fare — we compute confidently
    handoff = "handoff"  # dynamic — send user to provider app


class QuoteOption(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    provider: Provider
    bucket: ProviderBucket

    fare_min: Optional[float] = None   # None = no estimate available
    fare_max: Optional[float] = None
    currency: str = "AED"

    eta_minutes: Optional[int] = None
    travel_minutes: Optional[int] = None

    disclaimer: Optional[str] = None
    deep_link: Optional[str] = None
    web_fallback_url: Optional[str] = None
    app_store_url: Optional[str] = None


class TripRequest(BaseModel):
    pickup_lat: float
    pickup_lng: float
    dropoff_lat: float
    dropoff_lng: float
    dropoff_name: str
    distance_km: float
    duration_min: float
    departure_time: str       # ISO8601
    is_airport_pickup: bool
    salik_gates_estimate: int


class TripResponse(BaseModel):
    options: list[QuoteOption]
    computed_at: str
