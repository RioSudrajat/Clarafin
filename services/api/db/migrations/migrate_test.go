package migrations_test

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/pgx/v5"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"github.com/jackc/pgx/v5/pgxpool"
)

var canonicalTables = []string{
	"users",
	"user_preferences",
	"categories",
	"wallets",
	"goals",
	"goal_contributions",
	"transactions",
	"ai_drafts",
	"budgets",
	"bills",
	"notifications",
	"practitioner_profiles",
	"catalog_packages",
	"practitioner_packages",
	"problem_tags",
	"staff_practitioner_pins",
	"practitioner_availability",
	"venues",
	"vouchers",
	"match_expert_submissions",
	"orders",
	"payments",
	"sessions",
	"booking_slot_holds",
	"consents",
	"session_messages",
	"session_notes",
	"session_reviews",
	"session_complaints",
	"payouts",
	"gmail_connections",
	"pro_subscriptions",
	"ai_usage_ledger",
	"platform_settings",
	"audit_events",
	"deleted_account_payment_archives",
}

var canonicalPerformanceIndexes = []string{
	"uq_transactions_client_mutation",
	"uq_ai_drafts_client_mutation",
	"uq_active_practitioner_slot",
	"idx_transactions_user_occurred",
	"idx_transactions_user_category_date",
	"idx_ai_drafts_user_status",
	"idx_budgets_user_month",
	"idx_ai_ledger_user_month_status",
	"idx_pro_subs_user_active",
	"idx_sessions_client_status",
	"idx_sessions_practitioner_status",
	"idx_orders_user_status",
	"idx_slot_holds_expiry",
	"idx_session_messages_session_time",
	"idx_audit_events_target",
}

func TestMigrationsUpDownAndCanonicalSeed(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	pgDSN, migrateDSN := buildTestDSNs()

	pool, err := pgxpool.New(ctx, pgDSN)
	if err != nil {
		t.Fatalf("connect pgxpool: %v", err)
	}
	defer pool.Close()

	if err := pool.Ping(ctx); err != nil {
		t.Fatalf("ping postgres: %v", err)
	}

	m := newMigrator(t, migrateDSN)
	defer func() {
		_, _ = m.Close()
	}()

	// Reset to a clean baseline if a previous run already applied migrations.
	if err := m.Down(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		t.Fatalf("pre-clean down migration: %v", err)
	}

	if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		t.Fatalf("initial up migration failed: %v", err)
	}

	assertSchemaAndSeed(ctx, t, pool, m)

	if err := m.Down(); err != nil {
		t.Fatalf("down migration failed without clean rollback: %v", err)
	}

	remainingTables := countPublicTables(ctx, t, pool)
	if remainingTables != 0 {
		t.Fatalf("expected 0 canonical tables after down migration, got %d", remainingTables)
	}

	// Re-apply Up so the local database ends in a migrated and seeded state.
	if err := m.Up(); err != nil {
		t.Fatalf("re-up migration after down failed: %v", err)
	}

	assertSchemaAndSeed(ctx, t, pool, m)
}

func newMigrator(t *testing.T, migrateDSN string) *migrate.Migrate {
	t.Helper()

	src, err := iofs.New(os.DirFS("."), ".")
	if err != nil {
		t.Fatalf("create iofs migration source: %v", err)
	}

	m, err := migrate.NewWithSourceInstance("iofs", src, migrateDSN)
	if err != nil {
		t.Fatalf("create migrate instance: %v", err)
	}
	return m
}

func buildTestDSNs() (string, string) {
	if raw := strings.TrimSpace(os.Getenv("TEST_DATABASE_URL")); raw != "" {
		return raw, toPgx5DSN(raw)
	}

	user := envOrDefault("POSTGRES_USER", "clarafin")
	pass := envOrDefault("POSTGRES_PASSWORD", "clarafin_dev_password")
	db := envOrDefault("POSTGRES_DB", "clarafin")
	host := envOrDefault("POSTGRES_HOST", "postgres")
	port := envOrDefault("POSTGRES_PORT", "5432")

	u := url.URL{
		Scheme:   "postgres",
		User:     url.UserPassword(user, pass),
		Host:     net.JoinHostPort(host, port),
		Path:     "/" + db,
		RawQuery: "sslmode=disable",
	}
	pgDSN := u.String()
	return pgDSN, toPgx5DSN(pgDSN)
}

func toPgx5DSN(dsn string) string {
	switch {
	case strings.HasPrefix(dsn, "postgresql://"):
		return "pgx5://" + strings.TrimPrefix(dsn, "postgresql://")
	case strings.HasPrefix(dsn, "postgres://"):
		return "pgx5://" + strings.TrimPrefix(dsn, "postgres://")
	default:
		return dsn
	}
}

func envOrDefault(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func assertSchemaAndSeed(ctx context.Context, t *testing.T, pool *pgxpool.Pool, m *migrate.Migrate) {
	t.Helper()

	version, dirty, err := m.Version()
	if err != nil {
		t.Fatalf("read migration version: %v", err)
	}
	if dirty {
		t.Fatalf("migration version %d is dirty", version)
	}
	if version != 3 {
		t.Fatalf("expected migration version 3, got %d", version)
	}

	assertCanonicalTables(ctx, t, pool)
	assertPerformanceIndexes(ctx, t, pool)
	assertRLSConfigured(ctx, t, pool)
	assertRLSEnforced(ctx, t, pool)
	assertCanonicalSeeds(ctx, t, pool)
}

func countPublicTables(ctx context.Context, t *testing.T, pool *pgxpool.Pool) int {
	t.Helper()

	var count int
	err := pool.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM information_schema.tables
		WHERE table_schema = 'public'
		  AND table_type = 'BASE TABLE'
		  AND table_name <> 'schema_migrations'
	`).Scan(&count)
	if err != nil {
		t.Fatalf("count public tables: %v", err)
	}
	return count
}

func assertCanonicalTables(ctx context.Context, t *testing.T, pool *pgxpool.Pool) {
	t.Helper()

	rows, err := pool.Query(ctx, `
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema = 'public'
		  AND table_type = 'BASE TABLE'
		  AND table_name <> 'schema_migrations'
		ORDER BY table_name
	`)
	if err != nil {
		t.Fatalf("query public tables: %v", err)
	}
	defer rows.Close()

	got := make(map[string]bool, len(canonicalTables))
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			t.Fatalf("scan table name: %v", err)
		}
		got[name] = true
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("iterate table names: %v", err)
	}

	if got["ai_chat_sessions"] || got["ai_chat_messages"] {
		t.Fatalf("ephemeral chat tables must not exist: ai_chat_sessions=%v ai_chat_messages=%v", got["ai_chat_sessions"], got["ai_chat_messages"])
	}

	if len(got) != len(canonicalTables) {
		t.Fatalf("expected exactly %d canonical tables in public schema, got %d", len(canonicalTables), len(got))
	}

	for _, name := range canonicalTables {
		if !got[name] {
			t.Fatalf("missing canonical table %q", name)
		}
	}

	var authUsersExists bool
	if err := pool.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1
			FROM information_schema.tables
			WHERE table_schema = 'auth'
			  AND table_name = 'users'
		)
	`).Scan(&authUsersExists); err != nil {
		t.Fatalf("check auth.users existence: %v", err)
	}
	if !authUsersExists {
		t.Fatal("expected auth.users compatibility table to exist")
	}

	var authUIDExists bool
	if err := pool.QueryRow(ctx, `SELECT to_regprocedure('auth.uid()') IS NOT NULL`).Scan(&authUIDExists); err != nil {
		t.Fatalf("check auth.uid() existence: %v", err)
	}
	if !authUIDExists {
		t.Fatal("expected auth.uid() function to exist")
	}
}

func assertPerformanceIndexes(ctx context.Context, t *testing.T, pool *pgxpool.Pool) {
	t.Helper()

	for _, idx := range canonicalPerformanceIndexes {
		var exists bool
		err := pool.QueryRow(ctx, `
			SELECT EXISTS (
				SELECT 1
				FROM pg_indexes
				WHERE schemaname = 'public'
				  AND indexname = $1
			)
		`, idx).Scan(&exists)
		if err != nil {
			t.Fatalf("query index %q: %v", idx, err)
		}
		if !exists {
			t.Fatalf("expected index %q to exist", idx)
		}
	}
}

func assertRLSConfigured(ctx context.Context, t *testing.T, pool *pgxpool.Pool) {
	t.Helper()

	for _, table := range canonicalTables {
		var rlsEnabled bool
		err := pool.QueryRow(ctx, `
			SELECT c.relrowsecurity
			FROM pg_class c
			JOIN pg_namespace n ON n.oid = c.relnamespace
			WHERE n.nspname = 'public'
			  AND c.relname = $1
		`, table).Scan(&rlsEnabled)
		if err != nil {
			t.Fatalf("check RLS enabled on %q: %v", table, err)
		}
		if !rlsEnabled {
			t.Fatalf("expected RLS enabled on table %q", table)
		}

		var policyCount int
		err = pool.QueryRow(ctx, `
			SELECT COUNT(*)
			FROM pg_policies
			WHERE schemaname = 'public'
			  AND tablename = $1
		`, table).Scan(&policyCount)
		if err != nil {
			t.Fatalf("count policies on %q: %v", table, err)
		}
		if policyCount == 0 {
			t.Fatalf("expected at least 1 RLS policy on table %q", table)
		}
	}
}

func assertRLSEnforced(ctx context.Context, t *testing.T, pool *pgxpool.Pool) {
	t.Helper()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin RLS verification tx: %v", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	userA := "11111111-1111-4111-8111-111111111111"
	userB := "22222222-2222-4222-8222-222222222222"

	seedStatements := []struct {
		sql  string
		args []any
	}{
		{
			sql:  `INSERT INTO auth.users (id, email) VALUES ($1, 'rls-a@clarafin.test'), ($2, 'rls-b@clarafin.test') ON CONFLICT (id) DO NOTHING`,
			args: []any{userA, userB},
		},
		{
			sql:  `INSERT INTO users (id, email, full_name) VALUES ($1, 'rls-a@clarafin.test', 'User A'), ($2, 'rls-b@clarafin.test', 'User B')`,
			args: []any{userA, userB},
		},
		{
			sql:  `INSERT INTO practitioner_profiles (user_id, display_name, title_headline, bio, city, ktp_file_url, status) VALUES ($1, 'Pending Prac', 'Planner', 'Bio', 'Jakarta', 'kyc/pending.pdf', 'pending')`,
			args: []any{userB},
		},
		{
			sql:  `INSERT INTO wallets (id, user_id, name, type, balance) VALUES ('33333333-3333-4333-8333-333333333331', $1, 'BCA A', 'bank', 1000000), ('33333333-3333-4333-8333-333333333332', $2, 'BCA B', 'bank', 2000000)`,
			args: []any{userA, userB},
		},
		{
			sql:  `INSERT INTO gmail_connections (user_id, gmail_address, encrypted_refresh_token) VALUES ($1, 'rls-a@gmail.com', decode('DEADBEEF', 'hex'))`,
			args: []any{userA},
		},
		{
			sql:  `INSERT INTO platform_settings (key, value_json) VALUES ('rls_probe_secret', '{"internal": true}'::jsonb) ON CONFLICT (key) DO NOTHING`,
			args: nil,
		},
	}

	for _, stmt := range seedStatements {
		if _, err := tx.Exec(ctx, stmt.sql, stmt.args...); err != nil {
			t.Fatalf("seed RLS probe row: %v", err)
		}
	}

	roleStatements := []struct {
		sql  string
		args []any
	}{
		{sql: `CREATE ROLE clarafin_rls_probe NOLOGIN`},
		{sql: `GRANT USAGE ON SCHEMA public, auth TO clarafin_rls_probe`},
		{sql: `GRANT SELECT, INSERT, UPDATE, DELETE ON wallets, platform_settings, practitioner_profiles TO clarafin_rls_probe`},
		{sql: `SET LOCAL ROLE clarafin_rls_probe`},
		{sql: `SELECT set_config('request.jwt.claim.sub', $1, true)`, args: []any{userA}},
	}

	for _, stmt := range roleStatements {
		if _, err := tx.Exec(ctx, stmt.sql, stmt.args...); err != nil {
			t.Fatalf("configure RLS probe role: %v", err)
		}
	}

	var walletCount int
	if err := tx.QueryRow(ctx, `SELECT COUNT(*) FROM wallets`).Scan(&walletCount); err != nil {
		t.Fatalf("query wallets under RLS: %v", err)
	}
	if walletCount != 1 {
		t.Fatalf("expected user A to see exactly 1 wallet under RLS, got %d", walletCount)
	}

	var verifiedVisible int
	if err := tx.QueryRow(ctx, `SELECT COUNT(*) FROM practitioner_profiles`).Scan(&verifiedVisible); err != nil {
		t.Fatalf("query practitioner_profiles under RLS: %v", err)
	}
	if verifiedVisible != 6 {
		t.Fatalf("expected client role to see only 6 verified practitioner_profiles (not pending), got %d", verifiedVisible)
	}

	var settingsCount int
	if err := tx.QueryRow(ctx, `SELECT COUNT(*) FROM platform_settings`).Scan(&settingsCount); err != nil {
		t.Fatalf("query platform_settings under RLS: %v", err)
	}
	if settingsCount != 0 {
		t.Fatalf("expected 0 platform_settings rows visible to client role, got %d", settingsCount)
	}

	var gmailAddr string
	if err := tx.QueryRow(ctx, `SELECT gmail_address FROM gmail_connections`).Scan(&gmailAddr); err != nil {
		t.Fatalf("expected client role to read allowed gmail_connections columns via PUBLIC grant: %v", err)
	}
	if gmailAddr != "rls-a@gmail.com" {
		t.Fatalf("unexpected gmail_address %q", gmailAddr)
	}

	var token []byte
	err = tx.QueryRow(ctx, `SELECT encrypted_refresh_token FROM gmail_connections`).Scan(&token)
	if err == nil {
		t.Fatal("expected reading gmail_connections.encrypted_refresh_token as client role to fail")
	}
}

func assertCanonicalSeeds(ctx context.Context, t *testing.T, pool *pgxpool.Pool) {
	t.Helper()

	var pkgCount int
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM catalog_packages WHERE is_active = TRUE`).Scan(&pkgCount); err != nil {
		t.Fatalf("count catalog_packages: %v", err)
	}
	if pkgCount != 15 {
		t.Fatalf("expected 15 active catalog_packages, got %d", pkgCount)
	}

	var verifiedPractitioners int
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM practitioner_profiles WHERE status = 'verified'`).Scan(&verifiedPractitioners); err != nil {
		t.Fatalf("count verified practitioner_profiles: %v", err)
	}
	if verifiedPractitioners != 6 {
		t.Fatalf("expected 6 verified practitioner_profiles, got %d", verifiedPractitioners)
	}

	for i := 1; i <= 6; i++ {
		uuid := fmt.Sprintf("00000000-0000-4000-8000-0000000000c%d", i)
		var exists bool
		if err := pool.QueryRow(ctx, `
			SELECT EXISTS (
				SELECT 1
				FROM practitioner_profiles pp
				JOIN users u ON u.id = pp.user_id
				WHERE pp.user_id = $1::uuid
				  AND pp.status = 'verified'
			)
		`, uuid).Scan(&exists); err != nil {
			t.Fatalf("check practitioner %s: %v", uuid, err)
		}
		if !exists {
			t.Fatalf("expected verified practitioner %s and matching users row", uuid)
		}
	}

	var pracPkgCount int
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM practitioner_packages WHERE is_active = TRUE`).Scan(&pracPkgCount); err != nil {
		t.Fatalf("count practitioner_packages: %v", err)
	}
	if pracPkgCount < 26 {
		t.Fatalf("expected at least 26 active practitioner_packages, got %d", pracPkgCount)
	}

	var availPractitioners int
	if err := pool.QueryRow(ctx, `
		SELECT COUNT(DISTINCT practitioner_id)
		FROM practitioner_availability
		WHERE is_active = TRUE
	`).Scan(&availPractitioners); err != nil {
		t.Fatalf("count practitioners with availability: %v", err)
	}
	if availPractitioners != 6 {
		t.Fatalf("expected all 6 practitioners to have active availability slots, got %d", availPractitioners)
	}

	var incomeCats, expenseCats int
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM categories WHERE type = 'income' AND is_active = TRUE`).Scan(&incomeCats); err != nil {
		t.Fatalf("count income categories: %v", err)
	}
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM categories WHERE type = 'expense' AND is_active = TRUE`).Scan(&expenseCats); err != nil {
		t.Fatalf("count expense categories: %v", err)
	}
	if incomeCats != 21 || expenseCats != 84 {
		t.Fatalf("expected 21 income and 84 expense category rows, got income=%d expense=%d", incomeCats, expenseCats)
	}

	var tagCount int
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM problem_tags WHERE is_active = TRUE`).Scan(&tagCount); err != nil {
		t.Fatalf("count problem_tags: %v", err)
	}
	if tagCount < 10 {
		t.Fatalf("expected at least 10 active problem_tags, got %d", tagCount)
	}

	var maxPinsPerTag int
	if err := pool.QueryRow(ctx, `
		SELECT COALESCE(MAX(cnt), 0)
		FROM (
			SELECT COUNT(*) AS cnt
			FROM staff_practitioner_pins
			GROUP BY problem_tag_id
		) sub
	`).Scan(&maxPinsPerTag); err != nil {
		t.Fatalf("check staff_practitioner_pins cap: %v", err)
	}
	if maxPinsPerTag == 0 || maxPinsPerTag > 3 {
		t.Fatalf("expected 1..3 staff_practitioner_pins per tag, got max=%d", maxPinsPerTag)
	}

	var venueCount int
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM venues WHERE is_active = TRUE`).Scan(&venueCount); err != nil {
		t.Fatalf("count venues: %v", err)
	}
	if venueCount < 6 {
		t.Fatalf("expected at least 6 active venues, got %d", venueCount)
	}

	var voucherCount int
	if err := pool.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM vouchers
		WHERE is_active = TRUE
		  AND code IN ('CLARAFIN50', 'HALOFINCFP')
	`).Scan(&voucherCount); err != nil {
		t.Fatalf("count canonical vouchers: %v", err)
	}
	if voucherCount != 2 {
		t.Fatalf("expected CLARAFIN50 and HALOFINCFP active vouchers, got %d", voucherCount)
	}

	var settingCount int
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM platform_settings`).Scan(&settingCount); err != nil {
		t.Fatalf("count platform_settings: %v", err)
	}
	if settingCount < 5 {
		t.Fatalf("expected at least 5 platform_settings rows, got %d", settingCount)
	}
}
