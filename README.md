# TreinoLog

A local-first gym workout tracker app built with Flutter. Port of the original SwiftUI/SwiftData iOS app.

## Screenshots

> Coming soon

## Features

- Create and manage workout templates
- Log training sessions with sets, weight, reps and effort
- Rest timer between sets
- Full workout history
- Progression suggestions based on previous sessions
- Total volume calculation per session
- Progress charts per exercise
- Backup / restore via file export
- No cloud required — all data stored locally in SQLite

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| State management | [Riverpod](https://riverpod.dev/) |
| Local storage | [sqflite](https://pub.dev/packages/sqflite) (SQLite) |
| Charts | [fl_chart](https://pub.dev/packages/fl_chart) |
| Language | Dart |

## Getting Started

```bash
# Clone the repo
git clone https://github.com/LucasBarrens/TreinoLog_Flutter.git
cd TreinoLog_Flutter

# Install dependencies
flutter pub get

# Run
flutter run
```

Requires Flutter SDK ≥ 3.x. Install it at [flutter.dev](https://flutter.dev/docs/get-started/install).

## Project Structure

See [STRUCTURE.md](STRUCTURE.md) for a detailed breakdown of directories and data models.

## License

MIT — see [LICENSE](LICENSE).
