# Orbit 🌍

**Keep your world in sync.**

Orbit is a collaborative location and calendar coordination app for groups, built with Flutter and Firebase. It helps families, friends, and teams stay connected by sharing whereabouts and coordinating events seamlessly.

## ✨ Features

- **Flight Checker & Fare Tracking**: Live Google Flights search for one-way, round-trip, and multi-city routes with multi-currency conversion, lowest fare highlighting, and multi-airline filtering.
- **Group Management**: Create and join groups to coordinate with family, friends, or colleagues.
- **Location Sharing**: Share your current location with group members for specific dates.
- **Event Scheduling**: Create and manage group events with RSVP functionality.
- **Holiday Calendars**: Automatically displays public holidays based on your location.
- **Religious Calendars**: Support for Chinese Lunar and Islamic Hijri calendars.
- **Real-time Sync**: Instant updates across all devices using Firebase.
- **Dark Mode**: Full dark/light theme support.
- **PWA Support**: Install as a Progressive Web App on any device.
- **Admin Controls**: Role-based access and member management.

## 📝 Update Log

### [1.0.3] - 2026-09-12

- **✈️ Live Flight Checker & Fare Intelligence**:
  - Integrated Google Flights scraping backend (`api/check-flights.js`) deployable as a serverless function on Vercel or locally via `node api/local-dev-server.js`.
  - Supports round-trip, one-way, and multi-city flight searches with accurate departure/arrival times, durations, airline logos, layovers, and booking deep links.
  - Real-time client-side multi-currency converter across 10 global currencies (MYR, SGD, USD, EUR, GBP, JPY, AUD, CAD, CNY, THB) with zero network round-trips and instant repaints.
  - Visual lowest fare highlight with a thick green accent border (`AppColors.iosGreen`), ambient glow, and `⚡ Lowest Fare` badge.
  - Full-card clickable navigation to view legroom details (with explicit inch units), carbon emission stats, and aircraft models.
- **🎛️ Multi-Select Airline Filter & Sorting Bar**:
  - Interactive modal dialog (`AirlineFilterDialog`) with carrier checkboxes, dynamic flight counts, "Select All", "Deselect All", and compact "Apply" / "Clear" buttons.
  - Instant client-side sorting (Price low-to-high, Duration shortest, Departure earliest, Nonstop first) and stops filter (All, Nonstop, ≤ 1 Stop).
- **🗺️ Smart Location Autocomplete (e.g. "Bali" → "Indonesia, Bali")**:
  - High-accuracy subdivision detection: typing a city, island, or region (e.g. "Bali", "Penang", "Tokyo", "Seoul") automatically recognizes the parent country and auto-populates both Country and State fields simultaneously.
  - Comma-separated query parsing support (`"Bali, Indonesia"`).
  - Modular architecture strictly adhering to `< 500 lines` limits (`location_database.dart`, `location_input_tiles.dart`, `location_data.dart`).
- **🧪 Expanded Automated Test Suite**:
  - Increased test coverage from 27 to **63 passing tests** across unit, widget, and integration tests (`flight_filter_test.dart`, `flight_checker_dialog_test.dart`, `location_data_test.dart`, `location_picker_test.dart`, and `models_and_helpers_test.dart`).

### [1.0.2] - 2026-09-12

- **🎂 Automated Birthday Push Cron (GitHub Actions)**: Automated daily serverless birthday check running at 00:00 (Midnight) Malaysia Time (`16:00 UTC`). Evaluates Solar and Lunar birthdays across all group members and placeholders, delivering both in-app notifications and Web Push via OneSignal. Features multi-layer deduplication (`lastBirthdayCheck`, deterministic doc IDs, device throttlers) to prevent re-triggering when users log in.
- **⚡ Real-time Group Join & Status Check**: Added real-time group detection upon admin approval. The "No Groups Yet" card now includes an interactive **"Check Status"** button with loading indicator and immediate feedback snackbars, along with background polling every 15s.
- **🛡️ Firestore Web Stability & Stream Protection**: Resolved a critical target state underflow crash (`ca9: {"ve":-1}`) in Firestore Web SDK by decoupling streams from rebuild cycles in `DelayedEmptyStateWidget`. Preserved profile, polling, and pending request streams with safe `onError` handling and 8s query timeouts. Gated offline persistence (`!kIsWeb`) to eliminate Chrome IndexedDB transaction hangs (`Future not completed`).
- **🌍 Free-Text Location Autocomplete**: Completely upgraded location picker from restrictive dropdowns to 100% free-text search with instant autocomplete spanning ~240 countries/territories with flag emojis and state presets.
- **✨ Web Design Guidelines Refinement**: Converted detail modal dates to human-friendly title-cased formats (`Tuesday, Sep 15, 2026`), upgraded headers and accents to dynamic theme tokens, eliminated CLS layout shifts on religious dates, and accelerated group header and edit pencil rendering to frame 0 (0ms).
- **🧹 Code Hygiene & Safety Harness**: Pruned dead imports (`dart:js`, `shared_preferences`, `notification_service`), resolved missing package dependency for `dart_quill_delta`, declared `events` compound index in `firestore.indexes.json`, eliminated unmounted `BuildContext` async gaps, protected `deploy.bat` with automated test execution, and expanded the unit test suite to 27 passing tests with a one-click local `check.bat` runner.

### [1.0.1] - 2026-01-03

- **🎨 UI & Accessibility**: Standardized 90% mobile dialogs with pixel-perfect icon alignment, added variable text scaling (80-150%), and refined Settings labels with vibrant, high-contrast button colors.
- **� Responsive Polish**: Optimized App Bar, Date Picker, and "Load more" button layouts to prevent overflows on narrow screens (320px-450px) while maintaining legibility.
- **⚡ UX & PWA**: Restored original AlertDialog feedback for copy actions, added a manual refresh button, and optimized installation logic for iOS PWA users.
- **� Security & Integrity**: Hardened Firestore rules for user privacy, secured the group join flow, and enforced strict ownership transfer policies to prevent orphaned groups.

### [1.0.0] - 2026-01-01

- **🚀 PWA Manual Install**: Added "Install App" button in drawer for Desktop (Chrome/Edge) and Mobile (Android/iOS).
- **🎂 Birthday Reliability**: Implemented lifecycle-aware, group-wide birthday checks to ensure notifications never miss a beat.
- **🔗 Join Link invitations**: Users can now join groups via shareable, PWA-aware links with automatic login, join request handling, and **smart URL cleanup** to prevent refresh loops.
- **📤 Enhanced Sharing**: Mobile users enjoy **native share sheets** for instant app sharing, while desktop users get a reliable clipboard fallback.
- **📋 Device Info**: Added "Copy Info" button in Feedback dialog to instantly grab App Version, User Agent, Timezone, and PWA status for easier debugging.
- **🎨 UI Modernization**: Refined spaces, icons, and **Dismissible Dialogs** (click outside to close) for a smoother experience.
- **🔗 Share Logic**: Fixed a bug where native sharing on mobile would duplicate the invite link.
- **📱 Mobile Paste Fix**: Empowered mobile users with native long-press context menus for seamless ID pasting.
- **🛡️ Admin Hierarchy**: Refined permissions to allow Admins to edit details while protecting Owners and other Admins from removal.
- **🛠️ Stability & Dedup**: Improved notification deduplication, external ID sync, and fixed join link compilation issues.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.9.2)
- Firebase project with Firestore, Auth, and Storage enabled
- Node.js (for Firebase Functions)

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Nzettodess/Orbit.git
   cd Orbit
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Firestore, Authentication (Email/Password + Google), and Storage
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Run `flutterfire configure` to generate `firebase_options.dart`

4. Create a `.env` file with your API keys:

   ```env
   GOOGLE_API_KEY=your_google_calendar_api_key
   ```

5. (Optional) Run the local Flight Checker backend:

   ```bash
   node api/local-dev-server.js
   ```
   *Note: In production (Vercel), flight queries are handled automatically by the serverless function `/api/check-flights` with zero server management.*

6. Run the app:

   ```bash
   flutter run -d chrome
   ```

### 🚢 Deployment

To test, build, and deploy Orbit to Vercel production with automated test protection:

```bash
deploy.bat
```
*(Runs full Flutter test suite, compiles web release bundle to `build/web`, and deploys via Vercel CLI).*

## ⚠️ Known Issues

- **Android PWA Keyboard**: Some Android devices may experience UI shifts or difficulty interacting with text areas when the virtual keyboard is active. We are actively working on a more robust viewport-aware solution.

## ⭐ Support

If you find Orbit useful, please consider giving it a star! It helps others discover the project.

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
