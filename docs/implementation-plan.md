# Implementation Plan: Smart Calendar & Habit Tracker

## 1. Overview
This document outlines the systematic implementation of the Smart Calendar & Habit Tracker, covering both the Frontend (Flutter) and Backend (.NET 10) components. 

## 2. Directory Structure Setup
- **Frontend (Flutter)**: Will be located in `habit-tracker/apps`.
- **Backend (.NET)**: Will be located in `habit-tracker/server`.

## 3. Backend (.NET 10 ASP.NET Core) Implementation
**Architecture**: Clean Architecture

### Phase 1: Solution Setup
- Initialize the .NET solution in `habit-tracker/server`.
- Create projects: `Domain`, `Application`, `Infrastructure`, `Presentation` (API).
- Configure PostgreSQL database connection.

### Phase 2: Domain Layer
- Define Entities: `Event`, `Habit`.
- Define Repository Interfaces.

### Phase 3: Infrastructure & Application Layers
- Implement EF Core DbContext and Migrations.
- Implement Repositories.
- Add MediatR for CQRS pattern (Commands & Queries).
- Integrate the AI Categorization logic (MultinomialNB endpoint) or integrate with Python service.

### Phase 4: API Layer
- Expose RESTful endpoints for Habits and Events.
- Implement Authentication/Authorization if required.

## 4. Frontend (Flutter) Implementation
**Architecture**: Clean Architecture (Feature-first)

### Phase 1: Project Initialization
- Move existing Flutter code to `habit-tracker/apps`.
- Add dependencies: `flutter_riverpod`, `freezed_annotation`, `json_annotation`, `go_router`, `dio`, `syncfusion_flutter_calendar`.
- Set up `core/routing`, `core/theme`, `core/network`.

### Phase 2: Core Data Models
- Implement `EventModel` and `HabitModel` using `@freezed` and `json_serializable`.

### Phase 3: The Calendar Feature & Drag-Drop UI
- Implement `syncfusion_flutter_calendar` in `features/calendar/presentation/calendar_screen.dart`.
- Build the "Unscheduled Habits" panel with `Draggable<HabitModel>`.
- Use `DragTarget` in calendar time slots and mutate state via Riverpod upon drop.

### Phase 4: Pomodoro Timer Logic
- Create `TimerNotifier` (Riverpod) for states: Initial, Running, Paused, Completed.
- Handle background states with `WidgetsBindingObserver`.
- Sync completed sessions to `EventModel`.

### Phase 5: AI Integration & Sync
- Implement Dio client.
- Call POST `/api/v1/categorize` on event creation.
- Ensure Offline-first support (using local DB `isar` or `hive`) with sync mechanisms.

## 5. Testing & Quality Assurance
- **Testing**: Ensure high coverage by writing unit and widget tests for core logic (e.g., `TimerNotifier`, Repositories).
- **Clean Code**: Adhere to naming conventions, SOLID principles.
- **No Magic Numbers/Strings**: Extract all constants into designated constants files.
