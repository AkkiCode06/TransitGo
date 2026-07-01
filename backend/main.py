"""
TransitGo — FastAPI backend
Deploy to Railway. Set env vars: YANGO_API_KEY, YANGO_CLIENT_ID
"""

from datetime import datetime, timezone
from urllib.parse import quote as url_quote
import asyncio

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from models import TripRequest, TripResponse, QuoteOption, Provider, ProviderBucket
from fare_engine import (
    compute_metered_fare,
    compute_uber_estimate,
    compute_nol_fare,
    UBER_DISCLAIMER,
)
from yango_client import fetch_yango_quotes
import constants as C

app = FastAPI(title="TransitGo API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok", "time": datetime.now(timezone.utc).isoformat()}


@app.post("/quote", response_model=TripResponse)
async def quote(req: TripRequest) -> TripResponse:
    options: list[QuoteOption] = []

    # ------------------------------------------------------------------
    # 1. Metered providers (Hala, Zed, RTA street taxi) — same fare engine
    # ------------------------------------------------------------------
    metered_fare = compute_metered_fare(
        distance_km=req.distance_km,
        duration_min=req.duration_min,
        departure_time=req.departure_time,
        is_airport_pickup=req.is_airport_pickup,
        salik_gates=req.salik_gates_estimate,
    )
    travel_min = int(req.duration_min)

    for provider, eta_min in [
        (Provider.hala, 4),      # rough default ETAs — ideally from provider APIs
        (Provider.zed,  5),
        (Provider.rta_taxi, 6),
    ]:
        options.append(QuoteOption(
            provider=provider,
            bucket=ProviderBucket.priced,
            fare_min=metered_fare,
            fare_max=metered_fare,
            eta_minutes=eta_min,
            travel_minutes=travel_min,
            deep_link=_careem_deeplink() if provider == Provider.hala else None,
            app_store_url=_appstore(provider),
        ))

    # ------------------------------------------------------------------
    # 2. Normal Careem — unpriced handoff card (no fare number)
    # ------------------------------------------------------------------
    options.append(QuoteOption(
        provider=Provider.careem,
        bucket=ProviderBucket.handoff,
        fare_min=None,
        fare_max=None,
        travel_minutes=travel_min,
        disclaimer="Check the Careem app for live pricing.",
        deep_link="careem://",
        app_store_url="https://apps.apple.com/ae/app/careem/id592978487",
    ))

    # ------------------------------------------------------------------
    # 3. Uber — independent estimate (NEVER Uber's API)
    # ------------------------------------------------------------------
    uber_low, uber_high = compute_uber_estimate(
        distance_km=req.distance_km,
        duration_min=req.duration_min,
        departure_time=req.departure_time,
        is_airport_pickup=req.is_airport_pickup,
        salik_gates=req.salik_gates_estimate,
    )
    options.append(QuoteOption(
        provider=Provider.uber,
        bucket=ProviderBucket.handoff,
        fare_min=uber_low,
        fare_max=uber_high,
        travel_minutes=travel_min,
        disclaimer=UBER_DISCLAIMER,
        deep_link=_uber_deeplink(req),
        web_fallback_url="https://m.uber.com/looking",
        app_store_url="https://apps.apple.com/ae/app/uber-request-a-ride/id368677368",
    ))

    # ------------------------------------------------------------------
    # 4. Yango — live API quote
    # ------------------------------------------------------------------
    yango_quotes = await fetch_yango_quotes(
        pickup_lat=req.pickup_lat,
        pickup_lng=req.pickup_lng,
        dropoff_lat=req.dropoff_lat,
        dropoff_lng=req.dropoff_lng,
    )

    if yango_quotes:
        # Use the econom class by default; surface others if useful later
        econom = next((q for q in yango_quotes if "econom" in q.class_name.lower()), yango_quotes[0])
        options.append(QuoteOption(
            provider=Provider.yango,
            bucket=ProviderBucket.priced,   # Yango's own price — treat as an estimate but show it
            fare_min=econom.min_price if econom.min_price else econom.price,
            fare_max=econom.price,
            eta_minutes=int(econom.waiting_time / 60) if econom.waiting_time else None,
            travel_minutes=travel_min,
            disclaimer="Price from Yango. May vary at booking time.",
            deep_link=None,   # [VERIFY] Yango Universal Link from their partner widget
            app_store_url="https://apps.apple.com/ae/app/yango-taxi/id1239899024",
        ))
    else:
        # Yango key not configured yet — show as handoff only
        options.append(QuoteOption(
            provider=Provider.yango,
            bucket=ProviderBucket.handoff,
            disclaimer="Check the Yango app for pricing.",
            app_store_url="https://apps.apple.com/ae/app/yango-taxi/id1239899024",
        ))

    # ------------------------------------------------------------------
    # 5. RTA Metro (if route distance suggests Metro is viable)
    # Minimum viable: show metro option with Nol fare + rough ETA.
    # TODO: integrate Google Directions API transit mode for proper
    # station-to-station routing and walk-time calculation.
    # ------------------------------------------------------------------
    nol_fare = compute_nol_fare(req.distance_km, is_bus=False)
    if nol_fare is not None:
        metro_travel = int(req.distance_km / C.METRO_AVG_SPEED_KMH * 60) + 10  # +10 min walk/wait
        options.append(QuoteOption(
            provider=Provider.rta_metro,
            bucket=ProviderBucket.priced,
            fare_min=nol_fare,
            fare_max=nol_fare,
            travel_minutes=metro_travel,
            disclaimer="Nol Silver card fare. Route depends on nearest Metro station.",
            deep_link="https://maps.apple.com/?dirflg=r",
            app_store_url="https://apps.apple.com/ae/app/s-hail/id1111549338",
        ))

    return TripResponse(
        options=options,
        computed_at=datetime.now(timezone.utc).isoformat(),
    )


# ---------------------------------------------------------------------------
# Deep-link helpers
# ---------------------------------------------------------------------------

def _careem_deeplink() -> str:
    # Careem ignores coords — just opens the app
    return "careem://"


def _uber_deeplink(req: TripRequest) -> str:
    name = url_quote(req.dropoff_name, safe="")
    return (
        "uber://?action=setPickup"
        f"&pickup%5Blatitude%5D={req.pickup_lat}"
        f"&pickup%5Blongitude%5D={req.pickup_lng}"
        f"&pickup%5Bnickname%5D=Pickup"
        f"&dropoff%5Blatitude%5D={req.dropoff_lat}"
        f"&dropoff%5Blongitude%5D={req.dropoff_lng}"
        f"&dropoff%5Bnickname%5D={name}"
    )


def _appstore(provider: Provider) -> str | None:
    urls = {
        Provider.hala:     "https://apps.apple.com/ae/app/careem/id592978487",
        Provider.zed:      "https://apps.apple.com/ae/app/zed-taxi/id1441056939",
        Provider.rta_taxi: "https://apps.apple.com/ae/app/s-hail/id1111549338",
    }
    return urls.get(provider)
