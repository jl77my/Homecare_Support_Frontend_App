# HomeCare UI redesign

This folder contains the redesigned Flutter frontend. Existing providers,
services, REST endpoints, authentication behavior and data models were kept
intact; the work focuses on presentation, navigation and interaction quality.

## Visual direction

- Calm teal and health-green palette with a dedicated emergency red.
- Semantic light/dark theme tokens in `lib/core/theme/app_theme.dart`.
- Softer 24 px cards, clear borders and restrained elevation.
- Material vector icons instead of emoji-based interface icons.
- Minimum 48 dp interactive controls and clearer pressed/disabled states.
- Larger supporting labels and more readable text hierarchy.
- Responsive gutters, safe areas and reduced-motion-aware transitions.
- Material 3 five-item navigation with accessible badges.

The generated source of truth is in
`design-system/homecare/MASTER.md`. A visual overview is available at
`docs/ui_preview.png`.

## Backend-free preview

Use the built-in preview mode to review the caregiver and senior dashboards
without a running API:

```bash
flutter pub get
flutter run -d chrome --dart-define=HOMECARE_UI_PREVIEW=true
```

Use the role selector at the top-right of the preview to switch between the
caregiver and senior experiences. Remove the `--dart-define` flag to run the
normal application and connect to the existing backend.

## Production entry point

Production behavior remains the default:

```bash
flutter run
```

For a physical Android device, continue supplying the backend URL through the
existing `API_BASE_URL` dart definition when required.
