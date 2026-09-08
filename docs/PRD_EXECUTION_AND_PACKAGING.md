# PRD 02: Execution Methodology, Packaging & Deployment Guide

## 1. Development & Execution Methodology

The project adheres to **Clean Code Standards** and automated testing.

### 1.1. Code Quality & Architectural Rules
1. **SOLID & Clean Architecture**:
   - Presentation Tier contains zero business logic.
   - Application Tier processes Use Cases via CQRS Handlers.
   - Domain Tier remains decoupled from external frameworks.
2. **Static Analysis & Build Verification**:
   - .NET Backend: `dotnet build` & `dotnet test`.
   - Flutter App: `flutter analyze` & `flutter test`.

---

## 2. Packaging & Local Development Setup

```
/ (Root)
├── server/
│   └── .NET 9 Web API
└── apps/
    └── Flutter Multi-Platform App
```

### 2.1. Local Startup Workflow
```bash
# 1. Start Backend .NET API
cd server
dotnet run --project src/Web/

# 2. Start Flutter App
cd apps
flutter run
```

---

## 3. Testing Procedures

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
