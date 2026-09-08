# PRD 02: Execution Methodology, Packaging & Deployment Guide

## 1. Development & Execution Methodology

The project strictly adheres to **Clean Code Standards** and automated quality verification (**Test-Driven Development / Quality Gates**).

### 1.1. Code Quality & Architectural Rules
1. **No Magic Values**: All strings, API endpoint paths, and numeric configurations must be declared in Constants / AppSettings / Environment variables.
2. **SOLID & Clean Architecture**:
   - Presentation Tier contains zero business logic.
   - Application Tier processes Use Cases via CQRS Handlers.
   - Domain Tier remains completely decoupled from external dependencies.
3. **Static Analysis & Linting Gates**:
   - Flutter: `flutter analyze` zero warnings / zero errors.
   - .NET: `dotnet build` clean architecture enforcement.

### 1.2. Automated Testing Strategy
- **Unit Tests**:
  - Flutter: Unit tests for all `Notifiers`, `Providers`, and `Services`.
  - .NET: Unit tests for Command/Query Handlers with `NUnit` / `Moq`.
- **Widget & Component Tests**:
  - Flutter Widget tests for dialogs, habit cards, and calendar sheets.
- **Pre-completion Verification Gate**: All test suites (`flutter test`, `dotnet test`) must pass 100% before delivering any feature.

---

## 2. Packaging & Containerization Architecture

The system is fully containerized using Docker to ensure environment parity between Local Development and Production Deployments.

```
/ (Root)
├── docker-compose.yml
├── server/
│   └── Dockerfile (Multi-stage build .NET 9 Web API)
└── apps/
    └── Dockerfile (Flutter Web Nginx Container)
```

### 2.1. Container Services Specification

| Service Name | Container Base Image | Port Mapping | Purpose |
|---|---|---|---|
| `db` | `postgres:16-alpine` | `54322:5432` | Core PostgreSQL Database |
| `backend` | `mcr.microsoft.com/dotnet/aspnet:9.0` | `5000:80` | Core Web API + SignalR Engine |
| `web-app` | `nginx:alpine` | `8080:80` | Flutter Web Client Distribution |

---

## 3. Database Migration & Automated Seeding

### 3.1. Database Seeder Strategy
The system integrates `ApplicationDbContextInitialiser` in the .NET Backend.
- On initial startup in Dev environment, the system automatically:
  1. Executes Entity Framework Core Migrations (`context.Database.MigrateAsync()`).
  2. Seeds default Test User (`dung@gmail.com` / `Password123!`).
  3. Generates synthetic historical data for the past 30 days (Events, Daily Summaries, Hourly Activity) for analytics testing.

---

## 4. CI/CD & Deployment Procedures

### 4.1. Local Environment Startup Workflow
```bash
# 1. Start PostgreSQL DB
docker-compose up db -d

# 2. Start Backend .NET API
cd server
dotnet run --project src/Web/

# 3. Start Flutter App
cd apps
flutter run -d chrome # or android emulator
```

### 4.2. Production Packaging Steps
1. Build Flutter Web: `flutter build web --release`
2. Build Multi-stage Docker Images: `docker-compose -f docker-compose.prod.yml build`
3. Push to Container Registry & Run Health Check Endpoints (`/healthz` & `/api/v1/health`).
