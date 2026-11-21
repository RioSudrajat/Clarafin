## Linked Issue

Closes #

## What & Why (Summary)

<!-- Summarize your change clearly in 2-4 bullets. Explain what this PR changes and why. -->

-

## Repo Impact

- [ ] Touches `services/api` endpoints or JSON payloads (mobile compatibility verified)
- [ ] Adds or modifies SQL migration under `services/api/db/migrations/` or `sqlc` queries (`db/queries/` + `internal/repository/`) — rebased onto latest `main` with sequential migration number
- [ ] Modifies Flutter routes (`apps/mobile/lib/router/`) or dependencies (`apps/mobile/pubspec.yaml` / `pubspec.lock`)
- [ ] Touches auth, Supabase JWT, RLS, CORS, rate limiting, or secrets

## Verification Evidence

- [ ] Backend (`services/api`): `go vet ./...`, `go build ./...`, and `go test ./...` pass
- [ ] Mobile (`apps/mobile`): `flutter analyze --no-fatal-infos` and `flutter test` pass

<!-- Attach screenshots or short recordings for Flutter UI changes if applicable. -->

## PR Rules & Hygiene

- [ ] **Single scope:** Focused on one feature, bugfix, or assigned GitHub Issue (no rigid line-count cap, as long as scope stays clean)
- [ ] **Zero conflicts:** Rebased/merged with latest `origin/main` cleanly before requesting review
- [ ] **Guidelines followed:** Adheres to `AGENTS.md` / `GEMINI.md`, `apps/mobile/docs/DESIGN_SYSTEM.md`, and `apps/mobile/docs/CODE_GUIDELINES.md`
