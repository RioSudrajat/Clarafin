# Team Collaboration, GitHub Governance & Environment Setup — Clarafin

**Date:** 2026-11-21  
**Status:** Approved (Option A selected by founder)  
**Target Repo:** `https://github.com/RioSudrajat/Clarafin` (Personal `User` repo, visibility: `PUBLIC`)  
**Kanban Board:** `https://github.com/users/RioSudrajat/projects/2` (`Clarafin Sprint & Roadmap`, Project #2)

---

## 1. Intent & Why

Clarafin is transitioning from solo commits on `main` to structured 2-person collaboration between `@RioSudrajat` and `@Fatihmaull`, where both engineers also work with AI coding assistants (`AGENTS.md`, `GEMINI.md`).

Without explicit GitHub governance, parallel work on this monorepo risks:

- Sequential SQL migration collisions under `services/api/db/migrations/` (`000001_...`, `000002_...`, etc.) and stale `sqlc` generated outputs in `services/api/internal/repository/`
- Merge conflicts on shared mobile routing (`apps/mobile/lib/router/`) and `apps/mobile/pubspec.lock`
- Broken API contracts between `services/api` (Go) and `apps/mobile` (Flutter)
- Unverified changes slipping directly onto `main` (Staging) or `production` without CI or review

This setup adapts the proven GitHub governance architecture from `RioSudrajat/AnzaBook` to Clarafin's 2-person team and Go + Flutter stack, while keeping PR sizing practical: **no arbitrary 400-line limit**—any PR size is welcome as long as it stays within **one coherent scope / one feature / one assigned Issue (`Closes #`)** and merges cleanly with **zero conflicts**.

---

## 2. Team Roster & Ownership Boundaries

| Member | GitHub Handle | Repo Role | Primary Ownership |
| :--- | :--- | :--- | :--- |
| **Selembar Awan (Rio)** | `@RioSudrajat` | `admin` | Founder, Lead Engineer, GitHub Custodian (Repo Settings, Environments & Secrets, Ruleset emergency Admin Bypass), fullstack review |
| **Fatih** | `@Fatihmaull` | `write` | Collaborator, fullstack feature implementation (`apps/mobile`, `services/api`), PR co-reviewer |

Every rule in `.github/CODEOWNERS` lists both `@RioSudrajat` and `@Fatihmaull` so neither member encounters a self-approval deadlock.

---

## 3. Goals, Non-Goals, and Anti-Goals

### Goals

1. **Trunk-Based Staging & Production**: `main` serves as the Staging branch; `production` serves as the controlled Production release branch.
2. **Option A Strict Gate on Both `main` & `production`**: Every PR to `main` (Squash & Merge) and `production` (Merge Commit) requires **1 approving review + green CI**, with emergency Admin Bypass available for `@RioSudrajat`.
3. **Scope-Based PR Hygiene (No 400-Line Cap)**: No hard line-count cap; PRs must target **one scope / feature / assigned Issue (`Closes #`)**, have zero conflicts against latest `main`, and include verification evidence.
4. **Clarafin-Native Parallel CI**: 3 parallel required GitHub Actions jobs (`api-build-vet`, `api-test` with Postgres 16 + Redis 7, and `mobile-check-test` with Flutter `3.50.0`).
5. **5-Column Kanban Board + Automation**: GitHub Project #2 (`Clarafin Sprint & Roadmap`) linked to the repository with columns `Backlog`, `Ready`, `In Progress`, `In Review`, `Done`, plus `scripts/kanban.mjs` and `.github/workflows/kanban-automation.yml`.

### Non-Goals

- Migrating `RioSudrajat/Clarafin` to a GitHub Organization immediately.
- Enforcing an artificial 400-line PR limit.
- Adopting external trackers (Jira, Linear, Trello) outside GitHub.

### Anti-Goals

- **Squash-merging `main` -> `production`**: Causes recurring git ancestry drift and repeated false merge conflicts on subsequent releases.
- **Single-owner `CODEOWNERS` rules**: Creates self-approval deadlocks in a 2-person team.
- **Direct pushes to `main` or `production`**: Bypassing CI and PR review routinely defeats Staging stability.

---

## 4. Technical Decisions & Constraints

1. **Public Repo Features**: `RioSudrajat/Clarafin` is `PUBLIC`, enabling GitHub Rulesets, `CODEOWNERS`, Environments with required reviewers, Secret Scanning, and Push Protection.
2. **Flutter Analyze Behavior on `3.50.0`**: `apps/mobile` currently reports 306 `info` notices for `'package:flutter/material.dart'` deprecation (`deprecated_member_use`) and `0` warnings/errors. CI runs `flutter analyze --no-fatal-infos` plus `flutter test` so real warnings/errors block PRs without failing on upstream SDK migration infos.
3. **Go Integration Test Ordering (`services/api`)**: `db/migrations/migrate_test.go` executes `m.Down()` and `m.Up()` during `TestMigrationsUpDownAndCanonicalSeed`. CI runs `go test -count=1 ./db/migrations` first against Postgres 16 + Redis 7 services, then `go test -p 1 -count=1 ./internal/...` sequentially so packages never race on dropped tables or shared auth/Redis state.
4. **Branching & Merge Methods**:
   - `feat|fix|ops|chore/<issue>-<slug>` -> `main` via **Squash & Merge**
   - `main` -> `production` via **Merge Commit** (`allowed_merge_methods: ["merge"]` in `Protect production (Release)` ruleset)
5. **Kanban Sync Secret (`GH_PROJECT_PAT`)**: User-level GitHub Projects v2 cannot be updated with the default `GITHUB_TOKEN`. `kanban-automation.yml` gracefully skips if `secrets.GH_PROJECT_PAT` is absent, while built-in GitHub Project workflows and `node scripts/kanban.mjs` work right away.
