"""
Fare engine — metered taxi + Uber independent estimator.

All RTA/Uber constants live in constants.py (with [VERIFY]/[CALIBRATE] markers).
Call compute_metered_fare() for Hala / Zed / RTA street taxi.
Call compute_uber_estimate() for Uber (never calls Uber's API).
"""

from datetime import datetime
from typing import Optional
import constants as C


def _is_night(departure_time: str) -> bool:
    """Returns True if departure is in the night band (22:00–06:00)."""
    try:
        dt = datetime.fromisoformat(departure_time)
        h = dt.hour
        return h >= C.RTA_NIGHTTIME_START or h < C.RTA_DAYTIME_START
    except Exception:
        return False  # default to daytime


def compute_metered_fare(
    distance_km: float,
    duration_min: float,
    departure_time: str,
    is_airport_pickup: bool,
    salik_gates: int,
    waiting_min: float = 0.0,
) -> float:
    """
    Computes metered RTA taxi fare.
    Applies to Hala, Zed, RTA street taxi — all run the same government meter.

    Returns fare in AED.

    Args:
        distance_km:      route distance from MapKit
        duration_min:     traffic-aware journey time from MapKit
        departure_time:   ISO8601 string — determines day/night band
        is_airport_pickup: adds AED airport surcharge
        salik_gates:      number of toll gates crossed
        waiting_min:      per-minute waiting time (e.g. pickup delay).
                          [VERIFY] whether RTA bills waiting-only or total en-route time.
    """
    night = _is_night(departure_time)

    base   = C.RTA_BASE_FARE_NIGHT if night else C.RTA_BASE_FARE_DAY
    per_km = C.RTA_PER_KM_NIGHT    if night else C.RTA_PER_KM_DAY
    min_f  = C.RTA_MIN_FARE_NIGHT  if night else C.RTA_MIN_FARE_DAY

    fare = base
    fare += per_km * distance_km
    fare += C.RTA_PER_MIN_WAITING * waiting_min
    if is_airport_pickup:
        fare += C.RTA_AIRPORT_SURCHARGE
    fare += C.SALIK_PER_GATE * salik_gates

    return round(max(fare, min_f), 2)


def compute_uber_estimate(
    distance_km: float,
    duration_min: float,
    departure_time: str,
    is_airport_pickup: bool,
    salik_gates: int,
) -> tuple[float, float]:
    """
    Computes our own independent Uber fare estimate.
    NEVER calls Uber's API — uses empirically calibrated coefficients.

    Returns (fare_low, fare_high) in AED — always a range, never a point value.

    [CALIBRATE] — collect 20–30 real UberX quotes across varied UAE routes/times,
    regress on distance + traffic-aware duration, update constants.py with
    empirical base/per_km/per_min/booking_fee values.
    """
    base_est = (
        C.UBER_BASE_FARE
        + C.UBER_PER_KM   * distance_km
        + C.UBER_PER_MIN  * duration_min
        + C.UBER_BOOKING_FEE
    )

    if is_airport_pickup:
        base_est += C.UBER_AIRPORT_SURCHARGE

    base_est += C.SALIK_PER_GATE * salik_gates
    base_est = max(base_est, C.UBER_MIN_FARE)

    low  = round(base_est * C.UBER_SURGE_LOW,  0)
    high = round(base_est * C.UBER_SURGE_HIGH, 0)

    return low, high


UBER_DISCLAIMER = (
    "Estimated fare — actual price is set by Uber and may vary, "
    "especially during high demand. Not affiliated with Uber."
)


def compute_nol_fare(
    distance_km: float,
    is_bus: bool = False,
) -> Optional[float]:
    """
    Returns approximate Nol (Silver card) fare for Metro or Bus.
    Zone assignment is a rough heuristic — proper implementation should
    map pickup/dropoff station pairs to RTA zone definitions.

    [VERIFY] Nol zone boundaries and current fare table from nol.ae.
    """
    if is_bus:
        return C.NOL_BUS_FLAT

    # Crude zone heuristic by distance — replace with actual zone lookup
    if distance_km <= 12:
        return C.NOL_SILVER_ZONE1
    elif distance_km <= 28:
        return C.NOL_SILVER_ZONE2
    else:
        return C.NOL_SILVER_ZONE1AND2
