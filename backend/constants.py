"""
Rate constants for fare computation.

All values marked [VERIFY] must be confirmed against the current published
RTA tariff before going live. Do NOT ship placeholders.

Sources to check:
  - RTA taxi tariff:  https://www.rta.ae/wps/portal/rta/ae/public-transport/taxis
  - Nol fares:        https://www.nol.ae/en/fares
  - Salik:            https://www.salik.ae
"""

# ---------------------------------------------------------------------------
# RTA Metered Taxi  [VERIFY all values from current RTA published tariff]
# Applies to: Hala, Zed, RTA street taxi
# ---------------------------------------------------------------------------

RTA_DAYTIME_START = 6    # hour (24h) — daytime band starts
RTA_NIGHTTIME_START = 22  # hour (24h) — night band starts

# Daytime (06:00–22:00)
RTA_BASE_FARE_DAY = 5.00      # AED  [VERIFY]
RTA_PER_KM_DAY    = 1.82      # AED/km  [VERIFY]
RTA_MIN_FARE_DAY  = 12.00     # AED  [VERIFY]

# Night / early morning (22:00–06:00)
RTA_BASE_FARE_NIGHT = 5.50    # AED  [VERIFY]
RTA_PER_KM_NIGHT    = 1.99    # AED/km  [VERIFY]
RTA_MIN_FARE_NIGHT  = 13.00   # AED  [VERIFY]

# Per-minute waiting rate (when vehicle is stopped in traffic / waiting)
RTA_PER_MIN_WAITING = 0.50    # AED/min  [VERIFY — confirm RTA bills per-min waiting only, not en-route time]

# Airport surcharge  [VERIFY — ~AED 20 from DXB, may differ by terminal / airport]
RTA_AIRPORT_SURCHARGE = 20.00  # AED

# Salik toll  [VERIFY current per-gate amount — was AED 4, raised to AED 6 in some periods]
SALIK_PER_GATE = 4.00          # AED  [VERIFY]

# ---------------------------------------------------------------------------
# Uber Independent Estimator
# [CALIBRATE] — do NOT trust these priors. Collect 20–30 real UberX quotes
# across varied routes/times in UAE, regress on distance + duration,
# then replace these values with empirical coefficients.
# ---------------------------------------------------------------------------

UBER_BASE_FARE    = 10.00   # AED  [CALIBRATE]
UBER_PER_KM       = 2.70    # AED/km  [CALIBRATE]
UBER_PER_MIN      = 0.45    # AED/min (traffic-aware duration)  [CALIBRATE]
UBER_BOOKING_FEE  = 1.50    # AED  [CALIBRATE]
UBER_MIN_FARE     = 14.00   # AED  [CALIBRATE]

# Surge multiplier range to produce display band
UBER_SURGE_LOW    = 1.0     # off-peak  [CALIBRATE]
UBER_SURGE_HIGH   = 1.6     # typical peak  [CALIBRATE]

# Airport surcharge for Uber (separate from RTA meter)
UBER_AIRPORT_SURCHARGE = 20.00  # AED  [CALIBRATE]

# ---------------------------------------------------------------------------
# Nol / RTA Metro + Bus fares  [VERIFY from nol.ae]
# Zone-based. Gold card is ~2× Silver card rates.
# ---------------------------------------------------------------------------

NOL_SILVER_ZONE1      = 3.00   # AED  [VERIFY]
NOL_SILVER_ZONE2      = 5.00   # AED  [VERIFY]
NOL_SILVER_ZONE1AND2  = 7.50   # AED  [VERIFY]
NOL_DAILY_CAP         = 20.00  # AED/day silver  [VERIFY]

# Bus flat fare (single zone, silver card)
NOL_BUS_FLAT          = 2.00   # AED  [VERIFY — may be zone-dependent]

# RTA Metro typical speed km/h (used for ETA estimate)
METRO_AVG_SPEED_KMH   = 40     # [VERIFY / adjust for route]

# ---------------------------------------------------------------------------
# Yango  [VERIFY — get live values from API; these are fallback only]
# ---------------------------------------------------------------------------

YANGO_API_HOST   = "https://taxi-routeinfo.taxi.yandex.net"
YANGO_CLIENT_ID  = ""   # [VERIFY — obtain from Yango partner program]
YANGO_API_KEY    = ""   # [VERIFY — set via env var YANGO_API_KEY, never hardcode]
