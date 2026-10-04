# Home Workout App

Flutter frontend and a small Node.js REST API for a home workout prototype.

## Backend

Requires Node.js 18 or newer. From the project root:

```powershell
cd backend
npm start
```

The API listens on port `3000` and stores completed workouts in `backend/data/workouts.json`.

- `GET /api/health`
- `GET /api/exercises`
- `GET /api/workouts`
- `POST /api/workouts` with `{"title":"Full body","durationMinutes":12}`

Run backend tests with `npm test` from `backend/`.

## Frontend

The Flutter UI and API client are in `frontend/lib/`; `lib/main.dart` is the Flutter entry point.
Start Flutter Web in a second terminal:

```powershell
flutter run -d chrome
```

The default Web URL is `http://localhost:3000/api`. Android emulator uses `http://10.0.2.2:3000/api`.
For a physical device, pass the computer's LAN address:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:3000/api
```

Run frontend tests with `flutter test` from the project root.
