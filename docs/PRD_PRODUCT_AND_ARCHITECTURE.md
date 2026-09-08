# PRD 01: Product Vision, Core Features & System Architecture

## 1. Product Vision & Core Idea
**Habit Tracker AI** is an intelligent multi-platform habit tracking and calendar scheduling system (Mobile, Web, Desktop). The product combines **Habit Tracking**, **Two-Way Google Calendar Sync**, **Focus Management (Pomodoro)**, and **Predictive AI Insights (Machine Learning)**.

### Core Value Propositions
1. **Seamless Calendar & Habit Sync**: Converts daily habits into dynamic schedule slots, supporting real-time bi-directional synchronization with Google Calendar via Webhooks and SignalR.
2. **AI-Powered Predictive Insights**: Predicts habit completion probability, recommends optimal time slots, and forecasts streak continuity using dedicated Machine Learning models.
3. **Cross-Platform Native Experience**: Modern UI (Shadcn UI style), native Android App Widgets (Glance Composables), and instant synchronization across devices.
4. **Gamification & Focus Tools**: Integrated Pomodoro Timer, XP progression, level-ups, and cosmetic rewards (Avatars/Borders) to maintain user motivation.

---

## 2. System Architecture Overview

The system follows a **Distributed Micro-Services / Modular Monolith Architecture** with clear boundaries between Frontend, Core Backend, and ML Engine.

```mermaid
graph TD
    Client[Flutter Multi-Platform App] -->|.NET REST API / SignalR| Backend[.NET 9 Web API]
    Client -->|FastAPI Direct REST| ML[Python FastAPI ML Engine]
    Backend -->|EF Core PostgreSQL| DB[(PostgreSQL Database)]
    ML -->|Psycopg2 SQL Query| DB
    Backend <-->|OAuth2 / Webhooks| GCal[Google Calendar API]
```

---

## 3. Technology Stack & Component Specifications

### 3.1. Frontend: Flutter Application (`/apps`)
* **Architecture Pattern**: Clean Architecture + Feature-First structure.
* **State Management**: Flutter Riverpod (`AsyncNotifier`, `FutureProvider`, `StreamProvider`).
* **UI Components**: `shadcn_ui` + `lucide_icons` + custom responsive design.
* **Native Integration**: Android Jetpack Glance (App Widgets for Today's Events & Upcoming Tasks).
* **Key Features**:
  - Offline-first cache & Stale-while-revalidate data strategy.
  - Interactive Habit Dock & Heatmap Calendar.
  - Real-time updates via SignalR connection.
  - Multi-language Support (i18n English / Vietnamese).

### 3.2. Core Backend: .NET 9 Web API (`/server`)
* **Architecture Pattern**: Clean Architecture + CQRS with MediatR + Repository Pattern.
* **Database & ORM**: PostgreSQL 16 + Entity Framework Core 9.
* **Real-time Engine**: SignalR Hubs (`CalendarHub`, `HabitHub`).
* **Security & Auth**: ASP.NET Core Identity + JWT Bearer Authentication.
* **External Services**: Google Calendar API v3 (OAuth2 Token Refreshing, Webhook Receiver, Push Notifications).
* **Key Modules**:
  - `HabitTracker.Domain`: Entities (Habit, Event, DailySummary, Cosmetics, User).
  - `HabitTracker.Application`: Commands, Queries, Behaviors (Validation, Logging).
  - `HabitTracker.Infrastructure`: Persistence, Google API Service, SignalR.
  - `HabitTracker.Web`: Endpoints (Minimal APIs / Controllers), Webhooks, Middlewares.

### 3.3. Machine Learning Engine: Python FastAPI (`/ml`)
* **Framework**: Python 3.11+ FastAPI + Uvicorn.
* **ML Libraries**: `scikit-learn`, `pandas`, `numpy`, `joblib`.
* **Database Connection**: Direct PostgreSQL connection via `psycopg2` feature store.
* **Machine Learning Models**:
  - **Completion Prediction**: Logistic Regression / Random Forest (Predicts daily habit completion probability based on historical patterns).
  - **Optimal Time Slot**: Decision Tree Regressor (Recommends optimal focus hours).
  - **Streak Forecast**: Ridge Regression (Forecasts streak maintenance days).
* **Automated Data Pipeline**: Built-in Seeder & Synthetic Data Generator for 30 days of historical data.

---

## 4. Key Data Flow Models

### 4.1. Two-Way Google Calendar Sync Flow
1. **Outbound**: User creates/edits an Event on Flutter App $\rightarrow$ .NET Web API receives command $\rightarrow$ Creates Event on Google Calendar $\rightarrow$ Emits SignalR push to update UI.
2. **Inbound**: User updates schedule on Google Calendar $\rightarrow$ Google sends Webhook ping to `.NET /api/v1/webhooks/google-calendar` $\rightarrow$ Background Job syncs delta $\rightarrow$ Pushes SignalR notification $\rightarrow$ Flutter Client updates UI seamlessly without manual reload.

### 4.2. AI Recommendation Flow
1. Client requests AI Analytics for a habit $\rightarrow$ Calls `/api/predictions/habit-completion` on FastAPI.
2. FastAPI fetches Feature Store directly from PostgreSQL (`Events`, `DailyUserSummary`, `Habits`).
3. Model executes inference and returns probability + explanatory factors.
4. If FastAPI is offline, Client seamlessly uses Fallback Mechanism to prevent UX disruption.
