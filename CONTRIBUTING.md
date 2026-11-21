# Contributing to Clarafin

Welcome to the **Clarafin** engineering workflow. This guide covers local setup, GitHub Issue & Kanban board delegation, branching (`main` = Staging, `production` = Production), conflict prevention, and PR standards for collaborating smoothly.

---

## 1. Local Development Setup

### Prerequisites

- **Go** `1.26+` (for `services/api`)
- **Flutter** `3.50.0` / Dart `3.14+` (for `apps/mobile`)
- **Docker** (Docker Engine / Docker Desktop with Compose) for local PostgreSQL 16 + Redis 7

### First-Time Run

```bash
git clone https://github.com/RioSudrajat/Clarafin.git
cd Clarafin

# 1. Start PostgreSQL + Redis + API locally
cp .env.local services/api/.env   # Fill GEMINI_API_KEY locally; never commit services/api/.env
cd services/api
docker compose up -d postgres redis
go run ./cmd/api

# 2. Run Flutter mobile app (new terminal)
cd apps/mobile
flutter pub get
flutter run
```

- Never commit `services/api/.env`, real API keys, JWT secrets, or DB dumps. `RioSudrajat/Clarafin` is a **public** repository with Secret Scanning and Push Protection enabled.
- Only `.env.local` (safe placeholder template) is tracked.

---

## 2. Team Roles & GitHub Custodian Protocol

| Member | GitHub | Role | Ownership |
| :--- | :--- | :--- | :--- |
| **Selembar Awan (Rio)** | `@RioSudrajat` | Lead Engineer (`admin`) | Repo Settings, GitHub Environments (`staging`, `production`) & Secrets Custodian, Ruleset emergency bypass, fullstack review |
| **Fatih** | `@Fatihmaull` | Collaborator (`write`) | Feature development (`apps/mobile`, `services/api`), PR co-reviewer |

- Both `@RioSudrajat` and `@Fatihmaull` are listed as co-owners on every rule in `.github/CODEOWNERS` so neither member hits a self-approval deadlock.
- **Secrets Rule:** Never paste credentials, `GEMINI_API_KEY`, `SUPABASE_JWT_SECRET`, or `DATABASE_URL` strings into Issues, PR comments, or commits. Pass secret values out-of-band to `@RioSudrajat` to store in GitHub Environments.

---

## 3. Task Delegation & Kanban Board

Track work in **Clarafin Sprint & Roadmap** (Project #2):
`https://github.com/users/RioSudrajat/projects/2`

### 5-Column Kanban Flow

1. **Backlog** — Unrefined ideas or future `priority:p1` / `priority:p2` items.
2. **Ready** — Scoped Issue with clear Goal, Acceptance Criteria, and Out of Scope, assigned to an owner.
3. **In Progress** — Active branch (`feat|fix|ops|chore/<issue>-<slug>`) being worked on.
4. **In Review** — Pull Request opened with green CI awaiting peer approval.
5. **Done** — Merged into `main` (auto-closes the linked Issue via `Closes #<id>`).

### Labels

- **Area:** `area:mobile`, `area:api`, `area:fullstack`, `area:devops`, `area:security`, `area:docs`
- **Priority:** `priority:p0`, `priority:p1`, `priority:p2`
- **Type & Flags:** `type:feature`, `bug`, `type:chore`, `db:migration`, `status:blocked`, `ai-ready`

You can also move cards via CLI (`gh` with `project` scope):

```bash
node scripts/kanban.mjs add <issueNumber> --status Ready --priority P0 --area Mobile
node scripts/kanban.mjs move <issueNumber> "In Progress"
```

---

## 4. Branching & Release Flow (`main` = Staging, `production` = Prod)

We use a lightweight Trunk-Based flow with Option A strict PR reviews:

- **`main` = Staging:** Continuously deployable Staging branch.
- **`production` = Production:** Updated only by promoting verified commits from `main`.
- **Feature branches:** Branch off latest `origin/main` using `feat|fix|ops|chore/<issue>-<short-slug>` (for example, `feat/12-bill-reminder` or `fix/18-sse-timeout`).

### Merge & Protection Rules

- **Feature branch -> `main` (Staging):** Always **Squash & Merge** (1 scoped feature/issue = 1 clean commit). Requires **1 approving review + green CI (`api-build-vet`, `api-test`, `mobile-check-test`)**. Merged branches delete automatically.
- **`main` -> `production` (Release):** Always **Create a Merge Commit** (never squash `main` into `production`, or git history diverges and causes repeated false conflicts on future releases). Requires **1 approving review + green CI**.
- Direct pushes and force-pushes to `main` and `production` are blocked by GitHub Rulesets. Emergency Admin Bypass exists strictly for `@RioSudrajat`.

---

## 5. Monorepo Conflict-Prevention Rules

To collaborate smoothly in parallel without step-on-toes merge conflicts:

1. **Rebase before opening & merging:** Always `git fetch origin && git rebase origin/main` before opening a PR so conflicts are resolved on your feature branch, never on `main`.
2. **SQL Migrations & `sqlc` (`services/api/db/migrations/` & `db/queries/`):**
   - Migrations are sequentially numbered (`000001_...`, `000002_...`). Rebase onto latest `origin/main` right before creating a new `00000X_*.up.sql` / `.down.sql` pair so migration numbers never collide.
   - Commit `.up.sql`, `.down.sql`, `db/queries/*.sql`, and regenerated `internal/repository/*.go` together.
   - Never modify an already-merged migration.
3. **API <-> Mobile Contract Alignment:** When a feature spans Go API and Flutter, align on request/response JSON shapes in the Issue first so Mobile and API work cleanly without breaking deserialization.
4. **Mobile Router & Lockfiles (`apps/mobile/lib/router/`, `pubspec.lock`):** Avoid editing unrelated routes; if `pubspec.lock` conflicts after a rebase, resolve from `origin/main` and re-run `flutter pub get`.

---

## 6. PR Rules & Pre-PR Verification

Clarafin **does not enforce a rigid 400-line PR limit**. Any PR size is fine as long as:

1. **One coherent scope:** Focused on one feature, bugfix, or assigned GitHub Issue (`Closes #<id>`).
2. **Zero conflicts:** Cleanly rebased onto latest `origin/main`.
3. **Follows repo standards:** Adheres to `AGENTS.md`, `GEMINI.md`, `apps/mobile/docs/DESIGN_SYSTEM.md`, and `apps/mobile/docs/CODE_GUIDELINES.md`.
4. **Verified locally before requesting review:**

```bash
# Backend (services/api)
cd services/api
go vet ./...
go build ./...
# With local Postgres + Redis running:
go test -count=1 ./db/migrations
go test -p 1 -count=1 ./internal/...

# Mobile (apps/mobile)
cd apps/mobile
flutter analyze --no-fatal-infos
flutter test
```
