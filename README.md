# EarthScore

A digital scoresheet app for the board game [*Earth*](https://boardgamegeek.com/boardgame/350184/earth) by Inside Up Games. Replaces the paper scoresheet with a structured, error-free scoring experience across multiple games and players.

## Features

- **Accurate scoring** — 10 scoring columns matching the official Earth scoresheet
- **Multi-player support** — 2–6 players per game with persistent player profiles
- **Game history** — Browse past games with full score breakdowns
- **Player statistics** — Win rate, average score, high/low scores per player
- **Export** — Share results as a screenshot or CSV file
- **Who goes first** — Random player selector to kick off each game
- **Dark & light themes** — Material Design 3 with theme toggle

## Scoring Categories

| Category | Description |
|---|---|
| Cards VP | Base victory points printed on cards |
| Sprouts | Growth tokens (×1 VP each) |
| Trunks / Canopy | Combined tree growth VP |
| Terrain | End-game terrain bonuses |
| Personal Ecosystem | Personal ecosystem objective |
| Shared Ecosystem 1 & 2 | Shared ecosystem objectives |
| Compost | Cards in compost pile (×1 VP each) |
| Events | Event card VP (can be negative) |
| Fauna Board | Leaf tokens on the fauna board |

## Tech Stack

- **Flutter** (Dart 3.5+) — cross-platform UI framework
- **Riverpod** — reactive state management
- **Hive** — lightweight local database for offline persistence
- **share_plus / screenshot** — native export and sharing

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.5.0 or later
- Android Studio / Xcode (for mobile builds)

### Installation

```bash
git clone https://github.com/your-username/earthscore.git
cd earthscore
flutter pub get
flutter run
```

### Build

```bash
# Android
flutter build apk --release

# iOS
flutter build ios

# Web
flutter build web

# Windows
flutter build windows
```

## Project Structure

```
lib/
├── models/          # Game, Player, PlayerScore data classes
├── providers/       # Riverpod state (games, players, scoring session, theme)
├── screens/         # Full-page UI (home, scoring, history, stats, players)
├── widgets/         # Reusable components (avatars, category rows, chips)
└── utils/           # Score calculation, export helpers, Hive adapters
```

## License

This project is not affiliated with or endorsed by Inside Up Games. *Earth* is a trademark of Inside Up Games.
