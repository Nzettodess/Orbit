# Orbit Serverless API

This directory contains the backend serverless functions that power Orbit's live flight searches and notification pipelines.

## 📁 Architecture Overview

```
api/
├── check-flights.js       # Live Google Flights query & HTML scraper (ESM Serverless)
├── location-helper.js      # Airport IATA & city resolution database
├── local-dev-server.js     # Lightweight local Node dev server (port 3001)
├── send-notification.js    # OneSignal Web Push & in-app notification dispatcher
├── package.json            # Node.js ESM configuration ("type": "module")
└── README.md               # API documentation & deployment guide
```

All backend functions strictly comply with the repository's architectural limit of **< 500 lines per file**.

---

## ✈️ Flight Checker API (`/api/check-flights`)

Queries live flight routes, pricing, schedules, airline carriers, layovers, and aircraft details directly from Google Flights with 0 third-party paid API dependencies.

### Request Format (`POST /api/check-flights`)

```json
{
  "origin": "PEN",
  "destination": "KUL",
  "departureDate": "2026-10-15",
  "returnDate": "2026-10-22",
  "adults": 1,
  "travelClass": "economy",
  "currency": "MYR",
  "multiCityTrips": []
}
```

#### Fields:
- `origin` *(string, required)*: Origin airport IATA code or city name (e.g. `"PEN"`, `"Penang"`).
- `destination` *(string, required)*: Destination airport IATA code or city name (e.g. `"KUL"`, `"Tokyo"`).
- `departureDate` *(string, required)*: Departure date in `YYYY-MM-DD` format.
- `returnDate` *(string, optional)*: Return date in `YYYY-MM-DD` format. Set to `null` or omit for one-way journeys.
- `adults` *(integer, optional, default: 1)*: Number of adult passengers (1–9).
- `travelClass` *(string, optional, default: "economy")*: `"economy"`, `"premium_economy"`, `"business"`, or `"first"`.
- `currency` *(string, optional, default: "MYR")*: ISO currency code (e.g. `"MYR"`, `"USD"`, `"SGD"`, `"EUR"`, `"GBP"`, `"JPY"`, etc.).
- `multiCityTrips` *(array, optional)*: Array of flight legs `[{ origin, destination, departureDate }]` for multi-city routing.

---

## 💻 Local Development Server

During local Flutter development (`flutter run -d chrome`), the Flutter app calls `http://localhost:3001/api/check-flights`.

To start the local API daemon:
```bash
node api/local-dev-server.js
```
The server binds to port **3001** with CORS enabled for all `localhost` origins.

---

## 🚢 Production Deployment (Vercel)

When deploying to Vercel (`deploy.bat` or `vercel --prod`):
1. Vercel automatically detects the `api/` directory and compiles each file into a standalone Serverless Function.
2. The root `vercel.json` routes `/api/(.*)` directly to the serverless function without requiring any dev server running.
3. Serverless execution benefits: zero cold starts for cached routes, automatic horizontal scaling, and zero infrastructure maintenance.
