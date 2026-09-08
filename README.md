# Habit Tracker & Smart Calendar System

A modern, multi-platform habit tracking and dynamic scheduling system powered by **Flutter**, **.NET 9 Web API**, and **Two-Way Google Calendar Synchronization**.

---

## 🌟 Key Features

- 📅 **Interactive Calendar & Habit Dock**: Drag-and-drop unscheduled habits into specific calendar time slots.
- 🔄 **Two-Way Google Calendar Sync**: Real-time bi-directional event synchronization via Webhooks and SignalR push notifications.
- ⚡ **Real-Time SignalR Engine**: Instant UI updates across multi-platform client instances upon schedule changes.
- 📊 **Analytics & Heatmap**: Habit completion metrics, focus time distribution, and continuous streak tracking.
- 📱 **Android Native Widgets**: Jetpack Glance app widgets for *Today's Events* and *Upcoming Tasks*.
- ⏱️ **Pomodoro Focus Timer**: Integrated focus sessions with XP rewards, levels, and avatar cosmetics.
- 🌐 **Multi-Language Support**: i18n support for English and Vietnamese.

---

## 🛠️ Technology Stack

| Layer | Technology | Key Patterns / Frameworks |
|---|---|---|
| **Frontend** | Flutter 3.x | Clean Architecture, Riverpod (`AsyncNotifier`), Shadcn UI, Impeller |
| **Backend** | .NET 9 Web API | Clean Architecture, CQRS (`MediatR`), EF Core 9, SignalR Hubs |
| **Database** | PostgreSQL 16 | Relational persistence, Entity Framework Core migrations |
| **Native Widgets** | Android Jetpack Glance | Kotlin Composables for Android Home Screen widgets |
| **Containerization** | Docker | Multi-stage Docker Compose orchestration |

---

## 🚀 Quick Start (Local Development)

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.19.0`)
- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

### 1. Clone & Setup Sub-Repository
```bash
git clone https://github.com/jessiicamaru/events-management.git
cd events-management
```

### 2. Start PostgreSQL Database
```bash
docker-compose up db -d
```

### 3. Start Backend .NET Service
```bash
cd server
dotnet run --project src/Web/
```
> The API server will start on `http://localhost:5000` with Swagger UI at `http://localhost:5000/swagger`.

### 4. Start Flutter App
```bash
cd apps
flutter pub get
flutter run -d chrome # or android / windows
```

---

## 📚 Documentation & Architecture Specs

Detailed system documentation is located in the [`docs/`](./docs) directory:

- 📐 **[PRD 01: Product Vision & Architecture Specs](./docs/PRD_PRODUCT_AND_ARCHITECTURE.md)**
- 📦 **[PRD 02: Execution & Deployment Guide](./docs/PRD_EXECUTION_AND_PACKAGING.md)**
- 🔄 **[Google Calendar Sync Architecture](./docs/google-calendar-sync-architecture.md)**
- 🚀 **[Stale-While-Revalidate Caching Strategy](./docs/stale-while-revalidate-sync.md)**

---

## 🧪 Testing

### Frontend Tests (Flutter)
```bash
cd apps
flutter test
```

### Backend Tests (.NET)
```bash
cd server
dotnet test
```

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
