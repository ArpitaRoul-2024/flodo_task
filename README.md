# Flodo Task Management App

A polished Flutter task management app built for the Flodo AI take-home assignment.

---

## Track & Stretch Goal

- **Track B** — Mobile Specialist (Flutter + Isar local DB, no backend)
- **Stretch Goal** — Debounced Autocomplete Search with match highlighting

---

## Tech Stack

| Layer | Choice | Why |
|---|---|---|
| State Management | Riverpod 2 | Compile-safe, testable, no BuildContext dependency |
| Local Database | Isar | Fast, Flutter-native, reactive streams built-in |
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
git clone https://github.com/YOUR_USERNAME/flodo_task_app.git
cd flodo_task_app

# 2. Install dependencies
flutter pub get

# 3. Generate Isar schema and Riverpod providers
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

> **Note:** Isar requires code generation. Always run `build_runner` before the first run or after modifying the `Task` model.

---

## Features

### Core
- ✅ Full CRUD for tasks
- ✅ Task fields: Title, Description, Due Date, Status, Blocked By
- ✅ Blocked tasks are visually dimmed until their blocker is marked Done
- ✅ 2-second simulated delay on Create & Update with loading state
- ✅ Save button disabled during save to prevent double-submission
- ✅ Draft persistence — text survives app backgrounding / swipe-back
- ✅ Search by title (debounced 300ms)
- ✅ Filter by status (All / To-Do / In Progress / Done)
- ✅ Light & Dark theme toggle (persisted across restarts)
- ✅ Overdue tasks highlighted in red

### Stretch Goal: Debounced Autocomplete Search
- Search input debounces 300ms before filtering the list
- Matching text within task titles is **highlighted** inline using `Text.rich`
- Clear button appears when query is non-empty

---

## Technical Decision I'm Proud Of

**Isar's reactive `watchAll()` stream + Riverpod's `StreamProvider`** — instead of manually invalidating and re-fetching the task list after every mutation, the UI is driven by a live Isar stream. Any write (create, update, delete) instantly reflects in the UI without a single `setState` call or manual refresh. This makes the architecture very clean and bug-resistant.

---

## AI Usage Report

### Most helpful prompts
1. *"Generate an Isar Flutter model for a Task with title, description, dueDate, status (enum), and an optional blockedById foreign key. Include the collection annotation."*
2. *"Write a Riverpod 2 `AsyncNotifier` that persists a draft title and description to SharedPreferences and exposes updateTitle, updateDescription, and clear methods."*
3. *"How do I create a debounced search in Flutter with Riverpod — the raw input goes into one StateProvider, but a 300ms-debounced version flows into a separate StateProvider used for filtering?"*

### AI hallucination example
When asked to generate Isar query syntax, Claude used `filter()` with a chained `.titleContains()` method that doesn't exist in Isar 3. The correct approach is to fetch all and filter in Dart (for small datasets) or use Isar's `where()` clause for indexed fields. Fixed by consulting the Isar docs and falling back to a `.where().findAll()` + Dart `.where()` filter.
