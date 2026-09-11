# Orbit 🌍

**Keep your world in sync.**

Orbit is a collaborative location and calendar coordination app for groups, built with Flutter and Firebase. It helps families, friends, and teams stay connected by sharing whereabouts and coordinating events seamlessly.

## ✨ Features

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

### [1.0.2] - 2026-09-12

- **🎂 Automated Birthday Push Cron (GitHub Actions)**: Automated daily serverless birthday check running at 00:00 (Midnight) Malaysia Time (`16:00 UTC`). Evaluates Solar and Lunar birthdays across all group members and placeholders, delivering both in-app notifications and Web Push via OneSignal. Features multi-layer deduplication (`lastBirthdayCheck`, deterministic doc IDs, device throttlers) to prevent re-triggering when users log in.
- **⚡ Real-time Group Join & Status Check**: Added real-time group detection upon admin approval. The "No Groups Yet" card now includes an interactive **"Check Status"** button with loading indicator and immediate feedback snackbars, along with background polling every 15s.
- **🛡️ Firestore Web Stability & Stream Protection**: Resolved a critical target state underflow crash (`ca9: {"ve":-1}`) in Firestore Web SDK by decoupling streams from rebuild cycles in `DelayedEmptyStateWidget`. Preserved profile, polling, and pending request streams with safe `onError` handling and 8s query timeouts.
- **🌍 Free-Text Location Autocomplete**: Completely upgraded location picker from restrictive dropdowns to 100% free-text search with instant autocomplete spanning ~240 countries/territories with flag emojis and state presets.
- **✨ Web Design Guidelines Refinement**: Converted detail modal dates to human-friendly title-cased formats (`Tuesday, Sep 15, 2026`), upgraded headers and accents to dynamic theme tokens, eliminated CLS layout shifts on religious dates, and accelerated group header and edit pencil rendering to frame 0 (0ms).

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

5. Run the app:

   ```bash
   flutter run -d chrome
   ```

## ⚠️ Known Issues

- **Android PWA Keyboard**: Some Android devices may experience UI shifts or difficulty interacting with text areas when the virtual keyboard is active. We are actively working on a more robust viewport-aware solution.

## ⭐ Support

If you find Orbit useful, please consider giving it a star! It helps others discover the project.

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
