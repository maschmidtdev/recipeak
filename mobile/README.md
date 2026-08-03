# Recipeek Mobile

Flutter Android app for Recipeek, a chart-first recipe editor and viewer.

## Getting Started

Run from the `mobile` directory with a connected Android device or emulator:

```powershell
flutter run
```

The app stores local recipe state with `shared_preferences`. In development mode, settings include a reset action for restoring seed data.

The production seed recipes live in `assets/seeds/production_recipes.json`.

## Android Release Signing

Release builds read signing credentials from `android/key.properties` when that file exists. Copy `android/key.properties.example` to `android/key.properties` and replace the placeholder values with the real keystore settings.

`android/key.properties` is intentionally git-ignored because it contains secrets. Without it, release builds fall back to debug signing for local testing only and must not be published.
