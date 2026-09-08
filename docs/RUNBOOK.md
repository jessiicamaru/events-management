# Standard Operating Procedure (Runbook): Commit Extraction from Main to Clean Sub-Repo

> **Purpose**: Step-by-step instructions to create an isolated sub-repository inside the workspace, ignore it in the root `.gitignore`, and extract commit history strictly from the `main` branch into the clean sub-repository.

---

## 📌 CRITICAL RULE: NEVER COPY FROM WORKING TREE

> [!CAUTION]
> **CRITICAL**: DO NOT use `cp -r server` or `cp -r apps` from the current working directory!
> The current working directory contains future commits (Google Calendar Sync, SignalR, Squads, Identity, etc.).
> ALWAYS extract files directly from the target commit using Git commands (`git archive` or `git checkout <commit-hash> -- <path>`).

---

## 📌 INITIAL COMMIT SPECIFICATION (`be783af`)

- **Initial Commit Hash**: `be783af29eb54d0f522888d00f6a47a7ef75b4f2` (`be783af`)
- **Description**: Initial project baseline containing minimal CRUD for Habits & Events.

### Exact File List of `server/` at Commit `be783af` (Total: 37 files):
```text
server/.gitignore
server/HabitTracker.slnx
server/src/Domain/Domain.csproj
server/src/Domain/Entities/Event.cs
server/src/Domain/Entities/Habit.cs
server/src/Domain/Interfaces/IEventRepository.cs
server/src/Domain/Interfaces/IHabitRepository.cs
server/src/Application/Application.csproj
server/src/Application/DependencyInjection.cs
server/src/Application/GlobalUsings.cs
server/src/Application/Features/Events/Commands/CreateEventCommand.cs
server/src/Application/Features/Events/Queries/GetEventsQuery.cs
server/src/Application/Features/Habits/Commands/CreateHabitCommand.cs
server/src/Application/Features/Habits/Queries/GetHabitsQuery.cs
server/src/Infrastructure/Infrastructure.csproj
server/src/Infrastructure/DependencyInjection.cs
server/src/Infrastructure/GlobalUsings.cs
server/src/Infrastructure/Data/ApplicationDbContext.cs
server/src/Infrastructure/Repositories/EventRepository.cs
server/src/Infrastructure/Repositories/HabitRepository.cs
server/src/Web/Web.csproj
server/src/Web/Program.cs
server/src/Web/GlobalUsings.cs
server/src/Web/DependencyInjection.cs
server/src/Web/HabitTracker.Presentation.http
server/src/Web/appsettings.json
server/src/Web/appsettings.Development.json
server/src/Web/Properties/launchSettings.json
server/src/Web/Infrastructure/EndpointGroupBase.cs
server/src/Web/Infrastructure/WebApplicationExtensions.cs
server/src/Web/Endpoints/V1/Events.cs
server/src/Web/Endpoints/V1/Habits.cs
server/tests/Application.UnitTests/Application.UnitTests.csproj
server/tests/Application.UnitTests/CreateEventCommandHandlerTests.cs
server/tests/Application.UnitTests/CreateHabitCommandHandlerTests.cs
server/tests/Application.UnitTests/GetEventsQueryHandlerTests.cs
server/tests/Application.UnitTests/GetHabitsQueryHandlerTests.cs
```

---

## 📋 PREREQUISITES

### Step 1: Add Sub-Repository Path to Root `.gitignore`
Open the root `.gitignore` file (`d:/Code/Flutter/habit-tracker/.gitignore`) and append:

```gitignore
# Clean Sub-Repository (Ignored by main repository)
/habit-tracker-clean/
```

### Step 2: Initialize Sub-Repository Workspace
Execute the following commands from the project root terminal:

```bash
# 1. Create sub-repository directory
mkdir habit-tracker-clean

# 2. Navigate to sub-repository and initialize git
cd habit-tracker-clean
git init -b main

# 3. Copy root .gitignore to the sub-repository
cp ../.gitignore .gitignore
```

---

## 🚀 CORRECT COMMIT EXTRACTION WORKFLOW

To extract files from commit `be783af` into `habit-tracker-clean`:

### Step 1: Extract Exact Commit Files via Git Checkout
From the root project directory:

```bash
# Extract server codebase of commit be783af into habit-tracker-clean
git archive be783af server | tar -x -C habit-tracker-clean/

# Extract apps codebase of commit be783af into habit-tracker-clean
git archive be783af apps | tar -x -C habit-tracker-clean/
```

---

## 🔍 VERIFICATION & QUALITY CHECKS

After extracting each commit:

1. **Verify File List**: Ensure NO future files (e.g. `GoogleCalendarService.cs`, `Squad.cs`) exist in `habit-tracker-clean`.
2. **Execute Test Suites**:
   ```bash
   cd habit-tracker-clean/server && dotnet test
   cd habit-tracker-clean/apps && flutter test
   ```
3. **Verify Root Repository Status**:
   Confirm `git status` in root repository shows `habit-tracker-clean/` as ignored.
