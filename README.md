# Flodo Task Management App

A polished Flutter task management app built for the Flodo AI take-home assignment.

---

## Track & Stretch Goal

- **Track B** — Mobile Specialist (Flutter + Hive local DB, no backend)
- **Stretch Goal** — Debounced Autocomplete Search with match highlighting

---

## Tech Stack

| Layer | Choice | Why |
|---|---|---|
| State Management | Riverpod 2 | Compile-safe, testable, no BuildContext dependency |
| Local Database | Hive | Lightweight, fast, Flutter-native NoSQL database with built-in type adapters |
| Draft Persistence | SharedPreferences | Lightweight KV store, perfect for draft text |
| Animations | flutter_animate | Declarative, chainable, zero boilerplate |
| Typography | Plus Jakarta Sans (Google Fonts) | Modern, readable, characterful |

---

## Setup Instructions

### Prerequisites
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- A connected device or emulator

### Steps

```bash
# 1. Clone the repo
git clonehttps://github.com/ArpitaRoul-2024/flodo_task
cd flodo_task_app

# 2. Install dependencies
flutter pub get

# 3. Generate Hive type adapters
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run