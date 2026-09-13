# Changelog

All notable changes to the **Orbit** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-09-13

### 🦦 Added
- **Cosmic Otter Mascot & Visual Rebrand**:
  - Brand new custom mascot logo, favicons, launcher icons, and PWA manifest assets (`assets/logo.png`).
  - waifu2x 2x upscaled artwork with transparent background across light and dark theme surfaces.
  - Sized and guarded layout containers with errorBuilder fallbacks to prevent RenderFlex overflow.
- **Flight Checker Suite & Intelligence**:
  - Multi-Trip / Multi-City route searches supporting 3 distinct legs with combined pricing.
  - Smooth collapsible trip cards and leg sections with `SizeTransition` and `easeInOutCubic` curves.
  - Live Google Flights query integration (`api/check-flights.js`) with client-side conversion across 10 global currencies (MYR, SGD, USD, EUR, GBP, JPY, AUD, CAD, CNY, THB).
  - Lowest fare highlight with 2.0px green border (`AppColors.iosGreen`), ambient glow, and `⚡ Lowest Fare` badge.
  - Dedicated "Long wait time" badge for layovers > 5 hours, stops filter, and multi-select airline dialog.
  - Same-location validation, multi-airport city disambiguation (e.g. NYC = JFK, EWR, LGA), and home airport prefill.
- **Personal Member Nicknames**:
  - Users can assign private nicknames/aliases to group members that only they see, rendering across calendar views, attendee lists, and member dialogs.
  - Redesigned responsive `UserProfileDialog` with multiline text wrapping, bio support, and solar/lunar birthday views.
- **Persistent Group Caching & Zero-Delay Boot**:
  - Local caching via `SharedPreferences` (`_persistMyGroupsToCache` and `_loadCachedMyGroups`) providing instantaneous group and calendar display on startup.
  - Subtle pulsating sync indicator (`_isSyncing`) during background Firestore reconciliation.
- **In-App Announcement & What's New Dialog**:
  - "What's New in Orbit v1.1.0" modal dialog showcasing mascot and major features.
  - Strict 1-time delivery and 1-broadcast limit per version via deterministic document IDs (`announcement_v1.1.0_{userId}`) and deduplication keys.
  - 7-day prominent "NEW" badge in the Drawer menu.
  - Automated birthday push cron via GitHub Actions at 00:00 MYT (`16:00 UTC`).

### 🛡️ Changed & Fixed
- Gated Firestore offline persistence to non-web platforms (`!kIsWeb`), permanently resolving Chrome IndexedDB transaction hangs (`ca9: {"ve":-1}`).
- Fixed layout overflows on narrow mobile viewports (iPhone SE, 320px–450px) by wrapping price action bars and allowing multiline route banners.
- Configured custom auth domain for Orbit on Vercel for reliable OAuth redirect flows.
- Expanded automated test suite from 27 to **120 passing tests**.

---

## [1.0.3] - 2026-09-12

### ✈️ Added
- Initial Live Flight Checker with Google Flights scraping backend (`api/check-flights.js`).
- Multi-select airline filter dialog (`AirlineFilterDialog`) with dynamic counts.
- Smart location autocomplete with subdivision detection (e.g., "Bali" → "Indonesia, Bali").

---

## [1.0.2] - 2026-09-12

### 🎂 Added
- Automated birthday push notifications via GitHub Actions cron at 00:00 MYT.
- Real-time group join detection with "Check Status" manual refresh fallback.
- Free-text location autocomplete covering ~240 countries/territories.

---

## [1.0.1] - 2026-01-03

### 🎨 Added & Fixed
- Standardized mobile dialog icon alignments and text scaling (80–150%).
- Hardened Firestore security rules and secured group join flow.
- PWA installation logic improvements for iOS.

---

## [1.0.0] - 2026-01-01

### 🚀 Initial Release
- Multi-group location and calendar coordination.
- Group events with RSVP and version history.
- Public holiday and Chinese Lunar / Islamic Hijri calendar integration.
- PWA install support across desktop and mobile.
