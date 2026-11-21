# Clarafin Team Collaboration & GitHub Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Clarafin's GitHub-native collaboration workflow (`main` = Staging, `production` = Production, Option A strict review gates, multi-owner `CODEOWNERS`, AI-ready Issue/PR templates without a 400-line cap, parallel Go + Flutter CI, Environments, Rulesets, Labels, and GitHub Project #2 Kanban board).

**Architecture:** Provision Project #2 (`Clarafin Sprint & Roadmap`) first so its exact GraphQL field/option IDs live in `scripts/kanban.mjs`. Commit all governance files, `CONTRIBUTING.md`, synced `AGENTS.md`/`GEMINI.md` workflow rules, `ci.yml`, and `kanban-automation.yml` to `main` first, wait for `Clarafin CI` to pass green and validate `CODEOWNERS`, branch `production` from that green SHA, and activate Rulesets, Environments, Labels, and kickoff Issues via `gh`.

**Tech Stack:** GitHub Actions, GitHub Rulesets & Environments REST API, GitHub Projects v2 GraphQL API (`gh` CLI), Go `1.26` (`services/api` with Postgres 16 + Redis 7), Flutter `3.50.0` (`apps/mobile`), Node.js `22` (`scripts/kanban.mjs`).

**Spec:** `docs/superpowers/specs/2026-11-21-team-collaboration-github-setup-design.md`

---

### Task 1: Configure GitHub Project #2 (`Clarafin Sprint & Roadmap`)
- [x] Create Project #2 (`PVT_kwHOCKLcDc4Bsn3v`), link to `RioSudrajat/Clarafin`, configure 5-column `Status` (`Backlog`, `Ready`, `In Progress`, `In Review`, `Done`), `Priority` (`P0`, `P1`, `P2`), `Area` (`Mobile`, `API`, `Fullstack`, `DevOps & Security`, `Docs / Design`), `Kanban Board` + `All Tasks (Table)` views, and grant `@Fatihmaull` (`U_kgDOCJt8xw`) `WRITER` collaborator role.

### Task 2: Create `.github/` Governance Files (`CODEOWNERS`, Issue Forms, PR Template)
- [ ] Write `.github/CODEOWNERS` with `@RioSudrajat @Fatihmaull` across all paths.
- [ ] Write `.github/ISSUE_TEMPLATE/{config.yml,feature-task.yml,bug-report.yml,devops-security.yml}`.
- [ ] Write `.github/PULL_REQUEST_TEMPLATE.md` enforcing single-scope / issue-aligned / conflict-free PRs without a 400-line limit.

### Task 3: Create `CONTRIBUTING.md`, Update `AGENTS.md` + `GEMINI.md`, and Add `scripts/kanban.mjs`
- [ ] Create `CONTRIBUTING.md` covering local setup, 2-person ownership, GitHub Custodian secret rules, Kanban workflow, Option A branching & merge methods, migration/`sqlc`/router conflict rules, and verification commands.
- [ ] Sync `Team Collaboration & Git Workflow` section into both `AGENTS.md` and `GEMINI.md`.
- [ ] Create `scripts/kanban.mjs` wired to Project #2 IDs and verify `node --check scripts/kanban.mjs`.

### Task 4: Create `.github/workflows/ci.yml` and `.github/workflows/kanban-automation.yml`, Verify Locally, and Push to `main`
- [ ] Create `ci.yml` with parallel `api-build-vet`, `api-test`, and `mobile-check-test` jobs.
- [ ] Create `kanban-automation.yml` for automated Project #2 status sync.
- [ ] Run local Go (`go vet ./...`, `go build ./...`) and Flutter (`flutter analyze --no-fatal-infos`, `flutter test`) verification, commit, push to `main`, and watch live `Clarafin CI` pass green + verify `codeowners/errors` is empty.

### Task 5: Create `production` Branch, Repo Settings, Labels, Environments, Rulesets & Seed Starter Issue
- [ ] Branch `production` from verified green `main` and push `origin/production`.
- [ ] Configure repo merge/delete settings (`allow_squash_merge`, `allow_merge_commit`, `delete_branch_on_merge`), team labels, `staging` & `production` Environments, and Option A Rulesets (`Protect main (Staging)` and `Protect production (Release)`).
- [ ] Seed kickoff Issue(s) in `Clarafin Sprint & Roadmap` and run full read-back verification via `gh`.
