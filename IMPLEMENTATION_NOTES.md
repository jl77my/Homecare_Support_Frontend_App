# HomeCare frontend design refresh

This frontend was refreshed against the supplied HomeCare PNG design boards.

## Updated interface

- role selection, registration, and sign-in
- senior connected and not-connected home states
- role-aware bottom navigation
- care overview and family wellbeing dashboards
- vitals entry, reports, tasks, and reminders
- caregiver and family pairing
- invitation-code modal
- messages, AI assistant, profile, account settings, and care connections
- global medication and SOS overlays

## Backend integration preserved

Provider, service, model, API URL, authentication, WebSocket, and request/response files were not changed. Existing UI actions still invoke the original Riverpod notifier methods for registration, login, vitals, reports, tasks, reminders, pairing, chat, SOS, and AI actions.

## Design system

Reusable colors, typography, controls, form styling, sheets, dialogs, and accessibility-sized touch targets are defined in:

- `lib/core/theme/app_theme.dart`
- `lib/core/widgets/app_ui.dart`
- `design-system/homecare/MASTER.md`

## Local verification

Run these commands on a machine with the Flutter SDK:

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://<your-api-host>:3000/api
```

When testing on a physical phone, do not use `localhost` for the API host. Use the laptop's LAN IP or the deployed API URL.
