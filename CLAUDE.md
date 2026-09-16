# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

Monorepo with two independently-built apps and no shared build:

- `apps/` — Flutter client (Dart SDK `^3.11.5`), feature-first, Riverpod 3 + codegen.
- `server/` — .NET backend (`HabitTracker.slnx`), Clean Architecture + MediatR/CQRS, PostgreSQL via EF Core.
- `docs/` — two PRDs: `PRD_PRODUCT_AND_ARCHITECTURE.md` (vision, architecture, entities) and `PRD_EXECUTION_AND_PACKAGING.md`.

The product is a habit tracker: habits, scheduled events on a calendar, a pomodoro/focus timer, and settings.

**The README says ".NET 9"; the projects target `net10.0`.** Trust the `.csproj` files.

## Commands

### Backend (from `server/`)

```bash
dotnet build                                                     # also the static-analysis gate
dotnet run --project src/Web/                                    # http://localhost:5000, Swagger at /swagger in Development
dotnet test                                                      # xunit + Moq + FluentAssertions
dotnet test --filter "FullyQualifiedName~CreateHabitCommandHandlerTests"   # one class
dotnet ef migrations add <Name> --project src/Infrastructure --startup-project src/Web
dotnet ef database update --project src/Infrastructure --startup-project src/Web
```

### Frontend (from `apps/`)

```bash
flutter pub get
flutter run                                                # cold restart after adding a native plugin
flutter analyze                                            # static-analysis gate
flutter test
flutter test test/features/habits/presentation/habits_provider_test.dart
dart run build_runner build --delete-conflicting-outputs   # regenerate *.g.dart / *.freezed.dart
```

Regenerate after touching anything annotated with `@riverpod`, `@freezed` or `@JsonSerializable`, and commit the generated files with the change that caused them.

## Configuration

`AddInfrastructureServices` reads `ConnectionStrings:DefaultConnection` and **falls back to a hardcoded local string** (`Host=localhost;Database=habit-tracker;Username=postgres;Password=postgres`) when it is missing, so a misconfigured environment starts and then fails at the first query rather than at startup. `appsettings.json` ships no connection string; put the real one in `appsettings.Development.json`.

The client picks its base URL by platform in `AppConstants`: `localhost:5000/api/v1` on web and desktop, `10.0.2.2:5000/api/v1` on the Android emulator (`DioClient` chooses with `kIsWeb`).

## Backend architecture

Four projects, dependencies pointing inward: `Web` → `Application` + `Infrastructure` → `Domain`.

- **Domain** — entities (`Habit`, `Event`) and repository interfaces only. No framework references.
- **Application** — one folder per feature under `Features/<Feature>/{Commands,Queries}`. Each file holds the MediatR request *and* its handler (`CreateHabitCommand` + `CreateHabitCommandHandler` in `CreateHabitCommand.cs`). Handlers depend only on Domain interfaces.
- **Infrastructure** — `ApplicationDbContext`, repositories, EF wiring. Everything is registered in `Infrastructure/DependencyInjection.cs`; a new repository must be added there or it will not resolve.
- **Web** — Minimal API endpoint groups. `Program.cs` only composes the three `Add*Services()` calls and `MapEndpoints()`.

### Endpoint convention

Endpoints are **auto-discovered by reflection**: any non-abstract subclass of `EndpointGroupBase` in the `Web` assembly is instantiated by `MapEndpoints()` and mounted at `/api/v{version}/{group}`. The route segment comes from `GroupName ?? the class name`, so the class name *is* the URL (`class Habits` → `/api/v1/habits`). A new endpoint file therefore needs no registration — subclass `EndpointGroupBase` in `Web/Endpoints/V1/` and implement `Map`.

`ApiVersion` defaults to 1.0 per group; override `Version` to move a group.

## Frontend architecture

Feature-first under `lib/features/<feature>/{domain,presentation}`; cross-cutting code in `lib/core/` (`network`, `routing`, `theme`, `utils`).

- **State** — Riverpod 3, with `riverpod_annotation`-generated providers (`*.g.dart`).
- **Models** — `freezed` + `json_serializable`; never edit `*.freezed.dart` or `*.g.dart` by hand.
- **Networking** — `DioClient` builds the Dio instance; `ApiService` holds every endpoint call in one class.
- **Routing** — `go_router` in `core/routing/app_router.dart`. The tabs (`/calendar`, `/habits`, `/settings`) live in a `ShellRoute` with a shared nav bar.
- **Calendar** — `syncfusion_flutter_calendar`. The focus timer uses `wakelock_plus`, which needs a real device or emulator to behave.

## Conventions worth keeping

- Tests belong with the change, not after it: a new handler or provider gets its tests in the same commit, and changing existing code means updating its tests in the same pass.
- Run the analysis gates (`dotnet build`, `flutter analyze`) before calling anything done.
- **There is no root `.gitignore`** — `apps/.gitignore` and `server/.gitignore` cover their own trees only. Anything new at the repository root is untracked-but-not-ignored, so check `git status` before committing.
