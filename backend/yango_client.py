"""
Yango pricing API client.

Endpoint: GET https://taxi-routeinfo.taxi.yandex.net/taxi_info
Auth:     YaTaxi-Api-Key header (key from env var — never hardcoded)

[VERIFY] before wiring:
  - Email integration-support@yango.com to get an API key + UAE clid.
  - Confirm current endpoint host (may have moved from yandex.net to yango.com).
  - Confirm available tariff class names in UAE (econom, vip, etc.).
"""

import os
import httpx
from typing import Optional
import constants as C


_API_KEY = os.environ.get("YANGO_API_KEY", C.YANGO_API_KEY)
_CLIENT_ID = os.environ.get("YANGO_CLIENT_ID", C.YANGO_CLIENT_ID)


class YangoQuote:
    def __init__(self, class_name: str, class_text: str, price: float,
                 min_price: float, waiting_time: int, currency: str):
        self.class_name = class_name
        self.class_text = class_text
        self.price = price
        self.min_price = min_price
        self.waiting_time = waiting_time    # seconds until pickup
        self.currency = currency


async def fetch_yango_quotes(
    pickup_lat: float,
    pickup_lng: float,
    dropoff_lat: float,
    dropoff_lng: float,
) -> list[YangoQuote]:
    """
    Calls Yango taxi_info endpoint and returns available quotes.
    Returns empty list on any error (logged, not raised) so the rest of
    the /quote response still renders.

    NOTE: rll param is longitude-first, tilde-separated:
      {pickup_lng},{pickup_lat}~{dropoff_lng},{dropoff_lat}
    """
    if not _API_KEY or not _CLIENT_ID:
        # Key not yet configured — return empty gracefully
        return []

    rll = f"{pickup_lng},{pickup_lat}~{dropoff_lng},{dropoff_lat}"
    params = {
        "rll": rll,
        "clid": _CLIENT_ID,
        "class": "econom,vip",
    }
    headers = {"YaTaxi-Api-Key": _API_KEY}

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            r = await client.get(f"{C.YANGO_API_HOST}/taxi_info",
                                 params=params, headers=headers)
            r.raise_for_status()
            data = r.json()

        quotes = []
        currency = data.get("currency", "AED")
        for opt in data.get("options", []):
            quotes.append(YangoQuote(
                class_name=opt.get("class_name", ""),
                class_text=opt.get("class_text", "Yango"),
                price=float(opt.get("price", 0)),
                min_price=float(opt.get("min_price", 0)),
                waiting_time=int(opt.get("waiting_time", 0)),
                currency=currency,
            ))
        return quotes

    except Exception as exc:
        # Log but don't fail the whole request
        print(f"[yango_client] error: {exc}")
        return []
