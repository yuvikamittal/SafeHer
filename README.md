# SafeHer

A personal-safety companion app for women, built with Flutter. It brings the
core safety tools into one fast, offline-capable app: emergency SOS,
live-location sharing, safe-route guidance, nearby help, an in-app safety
assistant, and trusted contacts.

The app is a complete front end. Device and network features (GPS, SMS, maps,
push, auth) are handled through a `services/` layer that currently returns
sample data, so the whole app runs end to end without a backend, API keys, or
device permissions. Going live means swapping a single method body in a service
for a real integration — the UI does not change.

## Features

- **Splash** — animated intro that routes to login
- **Login** — email/password with biometric and SSO entry points, remember me, forgot password
- **Request access** — sign-up form with validation
- **Dashboard** — greeting, protection status, feature grid, recent activity
- **Emergency SOS** — hold-to-activate countdown, dispatch, call and message actions
- **Live location** — map preview, share duration, per-contact sharing
- **Safe route** — safety-scored routes on a route map with nearby police stations
- **Emergency contacts** — add, edit and remove trusted contacts with per-contact toggles
- **Nearby help** — police, hospitals, safe zones and shelters with filters
- **Alerts & notifications** — tabbed alerts and notifications with adjustable sensitivity
- **Safety assistant** — chat with keyword-matched guidance and quick prompts
- **Profile & settings** — user info, safety stats and preferences

## Running

```bash
flutter pub get
flutter run -d chrome      # web
flutter run                # connected device / emulator
flutter test               # smoke test
flutter analyze            # static analysis
```

Build artifacts:

```bash
flutter build web
flutter build apk
flutter build appbundle
```

## Architecture

```
lib/
  main.dart            app entry, theme, initial route
  routes/              centralised route names and onGenerateRoute
  services/            data layer (the swap-in points for real APIs)
  models/              plain data models
  widgets/             shared UI
  Screens/             feature screens
```

Navigation is centralised through `AppRouter.onGenerateRoute`, which also
provides a safe fallback so no route leads to a dead end. Data flows
Screen → Service → Model; to go live, replace a service method body with a real
API or plugin call.

## License

Educational project. Not affiliated with any emergency service; the simulated
SOS does not contact real authorities.
