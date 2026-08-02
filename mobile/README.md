# Recipeek Mobile

Flutter Android app for Recipeek, a chart-first recipe editor and viewer.

## Getting Started

Run from the `mobile` directory with a connected Android device or emulator:

```powershell
flutter run
```

The app stores local recipe state with `shared_preferences`. In development mode, settings include a reset action for restoring seed data.

The production seed recipes live in `assets/seeds/production_recipes.json`.
