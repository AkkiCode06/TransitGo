# TransitGo

An iOS app that compares ride-hailing and public transit options for a trip in the UAE, so you can pick the best one by cost, time, and convenience.

## What it does

Given a pickup and drop-off point, TransitGo shows ranked quotes across:

- **Ride-hailing:** Careem, Zed, Yango (live pricing), and an independent Uber fare *estimate* (Uber's API is not used for price comparison, per their ToS — estimates carry a clear "not affiliated" disclaimer)
- **Metered taxi:** using RTA's published tariff
- **Public transit:** RTA Metro/bus with Nol zone-based fares

Routing is traffic-aware (MapKit) and detects Salik toll gates along the route so fare estimates account for tolls.

## Architecture

- **iOS app** — Swift/SwiftUI, MapKit for routing, CoreLocation for positioning
- **Backend** — FastAPI service (`backend/`) that proxies the Yango API and runs the fare-estimation engines, deployed on Railway

```
TransitGo/            SwiftUI app (map + search UI, quote cards, ranked results)
backend/              FastAPI service: /quote endpoint, fare engines, Yango proxy
```

## Backend setup

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env   # fill in Yango API credentials
uvicorn main:app --reload
```

## Status

Early build — fare constants (RTA tariff, Nol zones) and Uber estimate coefficients still need real-world calibration before this is production-ready. See inline `[VERIFY]`/`[CALIBRATE]` markers in `backend/constants.py`.
