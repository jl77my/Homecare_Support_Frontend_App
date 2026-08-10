# HomeCare Flutter App

This project includes the caregiver/family HomeCare Agent interface and personalized health-prediction cards. The Gemini key is intentionally not stored in Flutter; all AI, prediction and database operations go through the authenticated Node.js backend.

## Run locally

```bash
flutter pub get

# Web/Windows, with backend on the same computer
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api

# Physical phone: replace the address with your backend computer's LAN IPv4
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000/api
```

## Agent behavior

- The Care Agent floating button appears only for caregiver and family roles.
- Each conversation is isolated by the selected elderly ID.
- The agent can answer from live medication, mood, task, health and report records.
- The caregiver and family dashboards show personalized anomaly, risk and trend results after health records load.
- The agent can explain the same health prediction because it is included in the backend RAG context.
- Requested writes are displayed as a preview and require Confirm.
- Cancel performs no database write.
- Confirmed records automatically refresh the existing Tasks, Reminders or Reports screen.

Run Flutter tests with:

```bash
flutter test
```

See the backend `README.md` for database migration, environment variables, Postman requests, full acceptance tests and troubleshooting.
