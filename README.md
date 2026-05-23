# CareSnap

CareSnap is a Flutter prototype for smart shift check-in and care reporting in aged care and disability support settings.

## What It Includes

- Staff/admin email login with role-based routing
- Staff dashboard with today's shift, client, location, and locked reporting actions
- GPS shift check-in using a 200 metre assigned-location radius
- Client profile with care needs, mobility notes, risks, and emergency contact
- Progress notes, incident reports, hazard reports, and behaviour charts
- Camera/gallery evidence for incident and hazard reports
- Admin dashboard for GPS check-ins, submitted records, and report status updates
- Firebase Auth, Firestore, and Storage repository implementation
- Demo fallback repository when Firebase config files are not installed

## Project Structure

```text
lib/
  app/          App shell, theme, and inherited controller scope
  controllers/  CareSnap state and workflow controller
  core/         Shared IDs, navigation helpers, and error messages
  data/         Repository interface plus Firebase and demo implementations
  models/       User, shift, client, report, and chart models
  screens/      Login, staff, admin, GPS, client, and reporting screens
  services/     Device services such as GPS location
  widgets/      Reusable cards, grids, forms, badges, and evidence picker
  main.dart     Small entry point only
```

## Demo Login

When Firebase is not configured, the app uses seeded demo data:

- Staff: `staff@caresnap.test` / `password123`
- Admin: `admin@caresnap.test` / `admin123`

The demo GPS screen includes a simulated on-site check-in so the reporting workflow can be demonstrated on an emulator or web preview without changing device GPS coordinates.

## Run Locally

```sh
flutter pub get
flutter run
```

For a web preview after building:

```sh
flutter build web
python3 -m http.server 3000 --bind 127.0.0.1 -d build/web
```

## Firebase Setup

1. Create a Firebase project.
2. Enable Email/Password sign-in in Firebase Authentication.
3. Add Flutter app configs using FlutterFire CLI:

```sh
dart pub global activate flutterfire_cli
flutterfire configure
```

4. Seed Firestore collections: `users`, `clients`, `shifts`, `progressNotes`, `incidentReports`, `hazardReports`, `behaviourCharts`, and `checkIns`.
5. Deploy the included rules:

```sh
firebase deploy --only firestore:rules,storage
```

The app can bootstrap the first Firestore profile for existing Authentication
users whose emails start with `staff@` or `admin@`. On first staff login it also
creates a starter client and today's shift if no shift exists yet.

## Verification

```sh
flutter analyze
flutter test
flutter build web
```

All three commands pass in the current project state.
