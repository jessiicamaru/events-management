# Habit Tracker System

A multi-platform habit tracking and scheduling system powered by **Flutter** and **.NET 9 Web API**.

---

## 🌟 Key Features

- 📅 **Interactive Habit & Event Scheduling**: Create, edit, and track daily habits and scheduled events.
- 📊 **Progress Analytics**: Track habit completion rates and activity metrics.
- 🌐 **Multi-Platform Support**: Cross-platform client supporting Web, Desktop, and Mobile.

---

## 🛠️ Technology Stack

| Layer | Technology | Key Patterns / Frameworks |
|---|---|---|
| **Frontend** | Flutter 3.x | Clean Architecture, Riverpod State Management |
| **Backend** | .NET 9 Web API | Clean Architecture, CQRS (`MediatR`), EF Core 9 |
| **Database** | PostgreSQL | Relational persistence with EF Core |

---

## 🚀 Quick Start (Local Development)

### 1. Start Backend .NET Service
```bash
cd server
dotnet run --project src/Web/
```

### 2. Start Flutter App
```bash
cd apps
flutter pub get
flutter run
```

---

## 📚 Documentation

Detailed system documentation is located in the [`docs/`](./docs) directory:

- 📐 **[PRD 01: Product Vision & Architecture Specs](./docs/PRD_PRODUCT_AND_ARCHITECTURE.md)**
- 📦 **[PRD 02: Execution & Packaging Guide](./docs/PRD_EXECUTION_AND_PACKAGING.md)**
- 🚀 **[Runbook: Commit Extraction Guide](./docs/RUNBOOK.md)**

---

## 📄 License

MIT License
