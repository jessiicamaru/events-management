# SYSTEM ARCHITECTURE & IMPLEMENTATION BLUEPRINT

## Project: Smart Calendar & Habit Tracker (Multi-platform)

**Target Reader:** Antigravity (AI Coding Agent)
**Role:** Senior Full-Stack & Flutter Engineer

---

## 1. TECH STACK & ARCHITECTURE RULES

### 1.1. Frontend (Flutter)

- **Framework:** Flutter (Dart).
- **State Management:** `flutter_riverpod` (Code generation with `riverpod_annotation`).
- **Routing:** `go_router`.
- **Immutable Data & Serialization:** `freezed`, `json_serializable`.
- **Local Storage:** `isar` or `hive` (for offline-first capability & Pomodoro state).
- **UI/Calendar Component:** `syncfusion_flutter_calendar` (Customized for drag-and-drop).
- **Architecture:** Clean Architecture (Feature-first approach).

### 1.2. Backend & AI Services

- **Core Backend:** .NET 10 (ASP .NET Core).
- **Architecture Pattern:** Clean Architecture.
- **Database:** PostgreSQL.

---

## 2. DIRECTORY STRUCTURE (FLUTTER)

Strictly enforce the following feature-based directory structure:

```text
lib/
├── core/
│   ├── network/          # Dio client, interceptors
│   ├── theme/            # Colors, TextStyles, ThemeData
│   ├── utils/            # Helpers, Extensions
│   └── routing/          # GoRouter config
├── features/
│   ├── auth/             # Authentication domain
│   ├── calendar/         # Calendar & Drag-Drop UI
│   ├── habits/           # Habit tracking & Heatmap
│   └── pomodoro/         # Timer logic & Focus state
│       ├── data/         # Repositories, Data sources
│       ├── domain/       # Entities, Use cases
│       └── presentation/ # Widgets, Riverpod controllers
└── main.dart
```

---

## 3. CORE ENTITIES & DATA MODELS

Antigravity must define these models using `@freezed`:

### 3.1. EventModel

- `id` (String)
- `title` (String)
- `startTime` (DateTime)
- `endTime` (DateTime)
- `category` (String - auto-assigned by MultinomialNB AI)
- `isPomodoroAttached` (bool)

### 3.2. HabitModel

- `id` (String)
- `name` (String)
- `targetDays` (List - 1 to 7)
- `streak` (int)
- `heatmapData` (Map<DateTime, int>)

---

## 4. EXECUTION PHASES (STEP-BY-STEP FOR ANTIGRAVITY)

### ✅ Phase 1: Project Initialization & Core Config [COMPLETED]
**Prompt instruction:**
- [x] Initialize Flutter project.
- [x] Add dependencies (`flutter_riverpod`, `freezed_annotation`, `json_annotation`, `go_router`, `dio`, `syncfusion_flutter_calendar`).
- [x] Setup `core/routing` with a basic ShellRoute (BottomNavigationBar) containing 3 tabs: Calendar, Habits, Settings.
- [x] Setup `core/theme` (Light/Dark mode).

### ✅ Phase 2: The Calendar Feature & Drag-Drop UI [COMPLETED]
**Prompt instruction:**
- [x] Implement `syncfusion_flutter_calendar` in `features/calendar/presentation/calendar_screen.dart`.
- [x] **Unified Calendar:** Integrate Personal and Squad events. Add Filter Pills (All, Personal, Squads) and visually distinguish Squad events.
- [x] **Calendar Settings:** Implement customizable visible hours (Start/End) using SharedPreferences.
- [x] Implement a bottom `HabitDock` for "Unscheduled Habits".
- [x] Wrap the unscheduled items in `Draggable<HabitModel>`.
- [x] Wrap the Calendar time slots in `DragTarget`. When an item is dropped, trigger a Riverpod mutation to create a new `EventModel` mapped to that specific time slot.

### ✅ Phase 3: Pomodoro Timer Logic (Complex State) [COMPLETED]
**Prompt instruction:**
- [x] In `features/pomodoro`, create a `TimerNotifier` using Riverpod.
- [x] State must handle: Initial, Running, Paused, Completed.
- [x] Use Dart `Stream.periodic` for the timer countdown.
- [x] UI must sync with the timer state. When Running, lock the screen awake.
- [x] When a Pomodoro session is Completed, update the attached `EventModel` status and update the local database.

### Phase 4: AI Auto-Categorization Integration
**Prompt instruction:**
- Create a Dio client in `core/network`.
- When the user creates an event via text input (e.g., "Review Flutter code"), call the Python AI endpoint `POST /api/v1/categorize` with payload `{"text": "Review Flutter code"}`.
- The backend uses MultinomialNB to return a category tag (e.g., "Study/Code").
- Assign this category to `EventModel` and update the UI with a specific color code based on the category.

---

## 5. CRITICAL CONSTRAINTS & RULES

- **No spaghetti state:** All business logic MUST reside in Riverpod Notifiers/Providers. Widgets should only observe state.
- **Offline-first:** Wrap network calls in repositories. If the backend is unreachable, save the state to local DB and sync later.
- **Pomodoro lifecycle:** The timer must run correctly even if the app goes to the background. Utilize `WidgetsBindingObserver` to calculate elapsed time using `DateTime.now()` upon app resume, instead of keeping a background isolate if unnecessary.

### Phase 5: Future Expansions & Advanced Features (Brainstormed)

**1. Advanced Analytics & AI Insights (Medium Effort)**
- **Feature:** AI-generated weekly/monthly reports analyzing productivity trends (e.g., "You focus best between 8 AM - 10 AM", "You often skip habits on Thursdays").
- **Implementation:** Backend cron job aggregates data, Python AI generates natural language insights, Frontend displays them in a new `AnalyticsScreen`.

**2. Smart Rescheduling & Daily Planning Workflow (High Effort)**
- **Feature:** Missed habits are moved to a "Planning Tray" rather than auto-rescheduled. During a "Morning Planning" phase, the user drags missed habits onto their calendar. The system (via AI) highlights optimal free slots based on historical context to guide the user's placement.
- **Implementation:** Flutter UI handles smooth Drag-and-Drop from tray to calendar. Backend scans for free gaps and Python AI scores/ranks them, allowing the UI to highlight the best slots (e.g., "Gym" slot glowing at 6 PM).

**3. Social Accountability & Micro-Communities (High Effort) - ✅ [COMPLETED]**
- **Feature:** A community system restricting groups to exactly 2 people (Buddy Mode) or up to 5 people (Squad Mode). 
  - **Buddy Mode (2 users):** Purely cooperative (no ranking), shared streaks.
  - **Squad Mode (5 users):** Optional ranking/leaderboard if the group opts in.
- **Reward System:** Completing habits and focus sessions earns "Discipline Points" (or XP). Earning points unlocks cosmetics like custom Reaction Emojis (to react to friends' logs), Avatar Borders, and exclusive Heatmap colors.
- **Implementation:** Backend handles group state and points ledger. SignalR for real-time emoji reactions. Flutter integrated with full ASP.NET Core Identity authentication (JWT) and persistent token storage.

**4. Micro-Journaling & Mood Tracking (Low Effort)**
- **Feature:** Post-session dialog prompts user to rate their mood (1-5 stars) and add a one-sentence journal entry. Plot mood vs. habit completion on the Heatmap.
- **Implementation:** Add `MoodScore` and `JournalEntry` to `EventModel`, update heatmap UI to overlay color tones based on mood.

---

## 6. PHASE 6: TO-DO MANAGEMENT & TIMEBOXING (UPCOMING)

**Goal:** Transform the app into a complete time-management ecosystem by introducing one-off tasks (To-Dos) that integrate directly with the Calendar and Pomodoro modules.

**Core Features:**
- **Todo Tray & Timeboxing:** A dedicated backlog for unscheduled To-Dos. Users can drag and drop a To-Do from the tray directly onto the Calendar to allocate specific time blocks (converting them into time-boxed EventModels).
- **Focus Linking:** Before starting a Pomodoro session, users can select a specific To-Do to focus on. Upon completion, the app prompts to mark the To-Do as finished.
- **Data Model:** Introduce `TodoModel` (`id`, `title`, `description`, `deadline`, `isCompleted`) integrated with backend Minimal APIs (CQRS) and Flutter Riverpod state.
