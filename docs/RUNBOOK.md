# Standard Operating Procedure (Runbook): Commit Extraction from Main to Clean Sub-Repo

> **Purpose**: Step-by-step instructions to create an isolated sub-repository inside the workspace, ignore it in the root `.gitignore`, and extract commit history from the `main` branch into the clean sub-repository.

---

## 📌 FIRST COMMIT IDENTIFICATION

The root repository's true initial commit is:
- **Initial Commit Hash**: `be783af29eb54d0f522888d00f6a47a7ef75b4f2` (`be783af`)
- **Description**: Initial project scaffolding containing base Flutter apps, .NET 9 Web API backend, and core project setup.

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

## 🚀 COMMIT EXTRACTION WORKFLOW

There are two primary methods for commit extraction starting from `be783af`:
- **Method A (Patch-based Replay)**: Preserves original commit hashes, authors, and exact messages using `git format-patch` & `git am`.
- **Method B (Decomposed Milestone Rebuild)**: Decomposes large initial commits (such as `be783af`) into fine-grained, compilable modular commits.

---

### METHOD A: EXACT COMMIT REPLAY (PATCH-BASED)

#### Step 1: Fetch Chronological Commit List Starting from `be783af`
Run from the root repository:

```bash
# List all commits starting from initial commit be783af
git log --oneline --reverse be783af..main
```

#### Step 2: Export Patch for Target Commit
```bash
# Export patch for initial commit be783af or subsequent commits:
git format-patch -1 be783af29eb54d0f522888d00f6a47a7ef75b4f2 --stdout > ../temp.patch
```

#### Step 3: Apply Patch inside Sub-Repository
Run from inside `habit-tracker-clean`:

```bash
cd habit-tracker-clean

# Check patch applicability without applying
git apply --check ../temp.patch

# Apply patch with original author and commit message
git am < ../temp.patch

# Remove temporary patch file
rm ../temp.patch
```

---

### METHOD B: DECOMPOSED MILESTONE REBUILD (RECOMMENDED FOR INITIAL COMMIT `be783af`)

Because initial commit `be783af` contains the full scaffold of both Frontend and Backend, Method B decomposes `be783af` into small, modular commits:

#### Step 1: Root Setup & Environment
- Copy core root setup (`docker-compose.yml`, `.gitignore`).
- Commit in `habit-tracker-clean`:
  ```bash
  git add docker-compose.yml .gitignore
  git commit -m "feat(setup): add root environment setup and docker-compose configuration"
  ```

#### Step 2: Clean Architecture .NET 9 Backend
- Copy `server/` codebase from `be783af`.
- Commit in `habit-tracker-clean`:
  ```bash
  git add server/
  git commit -m "feat(backend): add .NET 9 Clean Architecture backend services and unit tests"
  ```

#### Step 3: Flutter Multi-Platform Application
- Copy `apps/` codebase from `be783af`.
- Commit in `habit-tracker-clean`:
  ```bash
  git add apps/
  git commit -m "feat(frontend): add Flutter multi-platform application codebase and unit tests"
  ```

---

## 🔍 VERIFICATION & QUALITY CHECKS

After each commit extraction, run validation:

1. **Check Sub-Repository Git Status**:
   ```bash
   cd habit-tracker-clean
   git status
   git log --oneline
   ```

2. **Execute Test Suites in Sub-Repo**:
   ```bash
   # Test Flutter Frontend
   cd apps && flutter test

   # Test .NET Backend
   cd ../server && dotnet test
   ```

3. **Verify Root Repository Status**:
   Return to root directory and run `git status`. Ensure `habit-tracker-clean/` remains ignored and does not show up in untracked files.
