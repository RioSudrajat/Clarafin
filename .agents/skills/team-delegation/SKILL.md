---
name: team-delegation
description: >-
  Delegate tasks, create scoped GitHub Issues, manage the Clarafin Sprint &
  Roadmap Kanban board (GitHub Project #2), move cards automatically during local
  work (Ready -> In Progress -> In Review -> Done), review team PRs, or promote
  main to production for RioSudrajat/Clarafin.
---

# Clarafin Team Delegation & Kanban Automation Workflow

Read `CONTRIBUTING.md` for full team rules. Use this skill whenever creating
Issues, starting work on a feature branch, opening/merging PRs, checking sprint
status, or managing releases on `RioSudrajat/Clarafin`.

## 1. Team Roster & Collaboration

| Member | GitHub | Role | Scope |
| :--- | :--- | :--- | :--- |
| **Selembar Awan (Rio)** | `@RioSudrajat` | Lead Engineer / GitHub Custodian (`admin`) | Architecture, PR co-review, GitHub Environments & Secrets, Ruleset emergency bypass |
| **Fatih** | `@Fatihmaull` | Collaborator (`write`) | Feature development (`apps/mobile`, `services/api`), PR co-review |

Both `@RioSudrajat` and `@Fatihmaull` are co-owners on every rule in `.github/CODEOWNERS`.

## 2. Automatic Local Kanban Sync (`scripts/kanban.mjs`)

Whenever an AI agent performs GitHub workflow actions on behalf of `@RioSudrajat`
or `@Fatihmaull` (and local `gh` auth has `project` scope; run `gh auth refresh -s project`
if missing), keep Project #2 synchronized automatically using `scripts/kanban.mjs`:

- **Creating an Issue:**
  ```bash
  node scripts/kanban.mjs add <issueNumber> --status Ready --priority <P0|P1|P2> --area <Mobile|API|Fullstack|DevOps|Docs>
  ```
- **Cutting / starting a feature branch (`feat|fix|ops|chore/<issue>-<slug>`):**
  ```bash
  node scripts/kanban.mjs move <issueNumber> "In Progress"
  ```
- **Opening a non-draft PR (`Closes #<issueNumber>`):**
  ```bash
  node scripts/kanban.mjs move <issueNumber> "In Review"
  ```
- **Merging a PR / closing an Issue:**
  ```bash
  node scripts/kanban.mjs move <issueNumber> "Done"
  ```

Do not fail feature work if a contributor's local `gh` lacks `project` scope — print
a one-line reminder to run `gh auth refresh -s project` and continue.

## 3. Quick Session Sync (Check Live Sprint State)

```bash
gh issue list --repo RioSudrajat/Clarafin
gh pr list --repo RioSudrajat/Clarafin
gh project item-list 2 --owner RioSudrajat --format json \
  --jq '.items[] | {number: .content.number, status: .status, priority: .priority, area: .area, title: .content.title}'
```

## 4. Live GitHub Project #2 Constants (`Clarafin Sprint & Roadmap`)

- **URL:** `https://github.com/users/RioSudrajat/projects/2`
- **Project ID:** `PVT_kwHOCKLcDc4Bsn3v`
- **`Status` Field ID:** `PVTSSF_lAHOCKLcDc4Bsn3vzhq1J7Q`
  - `Backlog`: `1ec1e382`
  - `Ready`: `0246fbe2`
  - `In Progress`: `d99de440`
  - `In Review`: `7a70d343`
  - `Done`: `802a4c1f`
- **`Priority` Field ID:** `PVTSSF_lAHOCKLcDc4Bsn3vzhq1KVU`
  - `P0`: `f8f5d568`
  - `P1`: `b4852217`
  - `P2`: `1509efe7`
- **`Area` Field ID:** `PVTSSF_lAHOCKLcDc4Bsn3vzhq1KXc`
  - `Mobile`: `87d577c2`
  - `API`: `675cca1c`
  - `Fullstack`: `32ecf922`
  - `DevOps & Security`: `00246bbf`
  - `Docs / Design`: `91825c01`

### Labels Reference

- **Area:** `area:mobile`, `area:api`, `area:fullstack`, `area:devops`, `area:security`, `area:docs`
- **Priority:** `priority:p0`, `priority:p1`, `priority:p2`
- **Type/Flags:** `type:feature`, `bug`, `type:chore`, `db:migration`, `status:blocked`, `ai-ready`

## 5. PR & Release Invariants

- **Branching & Merge Methods:**
  - Feature branch (`feat|fix|ops|chore/<issue>-<slug>`) -> `main` (Staging): **Squash & Merge** (`Protect main (Staging)` ruleset `27797225`, requires 1 approval + green CI).
  - `main` -> `production` (Release): **Create a Merge Commit** (`Protect production (Release)` ruleset `27797226`, requires 1 approval + green CI) — never squash `main` into `production`.
- **No 400-line PR cap:** Any PR size is fine as long as it stays in **one scope / feature / Issue (`Closes #`)** and has **zero conflicts** against `origin/main`.
- **Conflict-prone paths:** Rebase onto latest `origin/main` before adding sequential SQL migrations in `services/api/db/migrations/` (`00000X_*.sql`) or regenerating `sqlc` (`services/api/internal/repository/`), and coordinate shared changes in `apps/mobile/lib/router/` or `pubspec.lock`.
- **Required CI checks:** `api-build-vet`, `api-test`, and `mobile-check-test`.
