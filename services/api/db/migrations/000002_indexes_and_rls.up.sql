-- Performance indexes (docs/tech/database.md Section 3)
CREATE INDEX idx_transactions_user_occurred ON transactions (user_id, occurred_at DESC);
CREATE INDEX idx_transactions_user_category_date ON transactions (user_id, category, occurred_at DESC);
CREATE INDEX idx_ai_drafts_user_status ON ai_drafts (user_id, status, created_at DESC);
CREATE INDEX idx_budgets_user_month ON budgets (user_id, month_year);

CREATE INDEX idx_ai_ledger_user_month_status ON ai_usage_ledger (user_id, month_year, status);
CREATE INDEX idx_pro_subs_user_active ON pro_subscriptions (user_id, status, expires_at DESC);

CREATE INDEX idx_sessions_client_status ON sessions (client_user_id, status, scheduled_start_at DESC);
CREATE INDEX idx_sessions_practitioner_status ON sessions (practitioner_id, status, scheduled_start_at);
CREATE INDEX idx_orders_user_status ON orders (user_id, status, created_at DESC);
CREATE INDEX idx_slot_holds_expiry ON booking_slot_holds (status, expires_at) WHERE status = 'held';

CREATE INDEX idx_session_messages_session_time ON session_messages (session_id, created_at ASC);
CREATE INDEX idx_audit_events_target ON audit_events (target_table, target_id, created_at DESC);

-- Enable Row-Level Security across all 36 canonical tables (docs/tech/database.md Section 4)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE practitioner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalog_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE practitioner_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE problem_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_practitioner_pins ENABLE ROW LEVEL SECURITY;
ALTER TABLE practitioner_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_expert_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_slot_holds ENABLE ROW LEVEL SECURITY;
ALTER TABLE consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE gmail_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE deleted_account_payment_archives ENABLE ROW LEVEL SECURITY;

-- 1-2, 4-11, 20: Owner-scoped personal finance and profile tables
CREATE POLICY users_owner_all ON users
  FOR ALL
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY user_preferences_owner_all ON user_preferences
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY wallets_owner_all ON wallets
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY goals_owner_all ON goals
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY goal_contributions_owner_all ON goal_contributions
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM goals g
      WHERE g.id = goal_contributions.goal_id
        AND g.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM goals g
      WHERE g.id = goal_contributions.goal_id
        AND g.user_id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM wallets w
      WHERE w.id = goal_contributions.wallet_id
        AND w.user_id = auth.uid()
    )
  );

CREATE POLICY transactions_owner_all ON transactions
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY ai_drafts_owner_all ON ai_drafts
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY budgets_owner_all ON budgets
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY bills_owner_all ON bills
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY notifications_owner_all ON notifications
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY match_expert_submissions_owner_all ON match_expert_submissions
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- 32-33: SaaS subscriptions and AI quota ledger (client SELECT only; Go backend mutates via Service Role)
CREATE POLICY pro_subscriptions_owner_select ON pro_subscriptions
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY ai_usage_ledger_owner_select ON ai_usage_ledger
  FOR SELECT
  USING (user_id = auth.uid());

-- 3, 13, 15, 18, 19: Authenticated read-only catalogs and reference data
CREATE POLICY categories_authenticated_select ON categories
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND is_active = TRUE);

CREATE POLICY catalog_packages_authenticated_select ON catalog_packages
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND is_active = TRUE);

CREATE POLICY problem_tags_authenticated_select ON problem_tags
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND is_active = TRUE);

CREATE POLICY venues_authenticated_select ON venues
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND is_active = TRUE);

CREATE POLICY vouchers_authenticated_select ON vouchers
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND is_active = TRUE);

-- 12, 14, 16, 17: Practitioners, packages, staff pins, and availability
CREATE POLICY practitioner_profiles_select ON practitioner_profiles
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND (status = 'verified' OR user_id = auth.uid()));

CREATE POLICY practitioner_profiles_owner_update ON practitioner_profiles
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Restrict client SELECT/UPDATE on practitioner_profiles to non-sensitive public/editable columns.
-- KYC files, bank details, commission rates, violation counts, and verification status are backend/Staff CMS only.
REVOKE ALL ON practitioner_profiles FROM PUBLIC;
GRANT SELECT (
  user_id, display_name, title_headline, bio, city, practitioner_tier,
  clients_handled_count, certifications, specializations, languages,
  supported_methods, gender, birth_year, consulting_style,
  years_of_experience, is_fully_booked, status, rating_avg,
  review_count, total_sessions_completed, verified_at, created_at, updated_at
) ON practitioner_profiles TO PUBLIC;
GRANT UPDATE (
  display_name, title_headline, bio, city, specializations, languages,
  supported_methods, gender, birth_year, consulting_style, is_fully_booked, updated_at
) ON practitioner_profiles TO PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'REVOKE ALL ON practitioner_profiles FROM authenticated';
    EXECUTE 'GRANT SELECT (user_id, display_name, title_headline, bio, city, practitioner_tier, clients_handled_count, certifications, specializations, languages, supported_methods, gender, birth_year, consulting_style, years_of_experience, is_fully_booked, status, rating_avg, review_count, total_sessions_completed, verified_at, created_at, updated_at) ON practitioner_profiles TO authenticated';
    EXECUTE 'GRANT UPDATE (display_name, title_headline, bio, city, specializations, languages, supported_methods, gender, birth_year, consulting_style, is_fully_booked, updated_at) ON practitioner_profiles TO authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE ALL ON practitioner_profiles FROM anon';
  END IF;
END
$$;

CREATE POLICY practitioner_packages_select ON practitioner_packages
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND (
      practitioner_id = auth.uid()
      OR (
        is_active = TRUE
        AND EXISTS (
          SELECT 1 FROM practitioner_profiles pp
          WHERE pp.user_id = practitioner_packages.practitioner_id
            AND pp.status = 'verified'
        )
      )
    )
  );

CREATE POLICY practitioner_packages_owner_insert ON practitioner_packages
  FOR INSERT
  WITH CHECK (practitioner_id = auth.uid());

CREATE POLICY practitioner_packages_owner_update ON practitioner_packages
  FOR UPDATE
  USING (practitioner_id = auth.uid())
  WITH CHECK (practitioner_id = auth.uid());

CREATE POLICY practitioner_packages_owner_delete ON practitioner_packages
  FOR DELETE
  USING (practitioner_id = auth.uid());

CREATE POLICY practitioner_availability_select ON practitioner_availability
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND (
      practitioner_id = auth.uid()
      OR (
        is_active = TRUE
        AND EXISTS (
          SELECT 1 FROM practitioner_profiles pp
          WHERE pp.user_id = practitioner_availability.practitioner_id
            AND pp.status = 'verified'
        )
      )
    )
  );

CREATE POLICY practitioner_availability_owner_insert ON practitioner_availability
  FOR INSERT
  WITH CHECK (practitioner_id = auth.uid());

CREATE POLICY practitioner_availability_owner_update ON practitioner_availability
  FOR UPDATE
  USING (practitioner_id = auth.uid())
  WITH CHECK (practitioner_id = auth.uid());

CREATE POLICY practitioner_availability_owner_delete ON practitioner_availability
  FOR DELETE
  USING (practitioner_id = auth.uid());

CREATE POLICY staff_practitioner_pins_select ON staff_practitioner_pins
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM practitioner_profiles pp
      WHERE pp.user_id = staff_practitioner_pins.practitioner_id
        AND pp.status = 'verified'
    )
  );

-- 21-22, 24: Orders, payments, and slot holds (client SELECT only; Xendit webhook & booking service mutate)
CREATE POLICY orders_owner_select ON orders
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY payments_owner_select ON payments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = payments.order_id
        AND o.user_id = auth.uid()
    )
  );

CREATE POLICY booking_slot_holds_participant_select ON booking_slot_holds
  FOR SELECT
  USING (
    practitioner_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = booking_slot_holds.order_id
        AND o.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = booking_slot_holds.session_id
        AND (s.client_user_id = auth.uid() OR s.partner_user_id = auth.uid())
    )
  );

-- 23, 25-29: Sessions, consents, chat, notes, reviews, and complaints
CREATE POLICY sessions_participant_select ON sessions
  FOR SELECT
  USING (
    client_user_id = auth.uid()
    OR partner_user_id = auth.uid()
    OR practitioner_id = auth.uid()
  );

CREATE POLICY session_messages_participant_select ON session_messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = session_messages.session_id
        AND (s.client_user_id = auth.uid() OR s.partner_user_id = auth.uid() OR s.practitioner_id = auth.uid())
    )
  );

CREATE POLICY session_messages_participant_insert ON session_messages
  FOR INSERT
  WITH CHECK (
    sender_user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = session_messages.session_id
        AND (s.client_user_id = auth.uid() OR s.partner_user_id = auth.uid() OR s.practitioner_id = auth.uid())
    )
  );

CREATE POLICY session_notes_participant_select ON session_notes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = session_notes.session_id
        AND (
          s.practitioner_id = auth.uid()
          OR (
            (s.client_user_id = auth.uid() OR s.partner_user_id = auth.uid())
            AND session_notes.submitted_at IS NOT NULL
          )
        )
    )
  );

CREATE POLICY session_notes_practitioner_insert ON session_notes
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = session_notes.session_id
        AND s.practitioner_id = auth.uid()
    )
  );

CREATE POLICY session_notes_practitioner_update ON session_notes
  FOR UPDATE
  USING (
    locked_at IS NULL
    AND EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = session_notes.session_id
        AND s.practitioner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = session_notes.session_id
        AND s.practitioner_id = auth.uid()
    )
  );

CREATE POLICY session_reviews_participant_select ON session_reviews
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = session_reviews.session_id
        AND (s.client_user_id = auth.uid() OR s.partner_user_id = auth.uid() OR s.practitioner_id = auth.uid())
    )
  );

CREATE POLICY session_reviews_client_insert ON session_reviews
  FOR INSERT
  WITH CHECK (
    reviewer_user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = session_reviews.session_id
        AND (s.client_user_id = auth.uid() OR s.partner_user_id = auth.uid())
    )
  );

CREATE POLICY session_complaints_participant_select ON session_complaints
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = session_complaints.session_id
        AND (s.client_user_id = auth.uid() OR s.partner_user_id = auth.uid() OR s.practitioner_id = auth.uid())
    )
  );

CREATE POLICY session_complaints_client_insert ON session_complaints
  FOR INSERT
  WITH CHECK (
    reporter_user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = session_complaints.session_id
        AND (s.client_user_id = auth.uid() OR s.partner_user_id = auth.uid())
    )
  );

CREATE POLICY consents_owner_and_active_practitioner_select ON consents
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR (
      status = 'active'
      AND NOW() < expires_at
      AND EXISTS (
        SELECT 1 FROM sessions s
        WHERE s.id = consents.session_id
          AND s.practitioner_id = auth.uid()
      )
    )
  );

CREATE POLICY consents_owner_insert ON consents
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND status = 'active'
    AND EXISTS (
      SELECT 1 FROM sessions s
      WHERE s.id = consents.session_id
        AND (s.client_user_id = auth.uid() OR s.partner_user_id = auth.uid())
    )
  );

CREATE POLICY consents_owner_revoke_update ON consents
  FOR UPDATE
  USING (user_id = auth.uid() AND status = 'active')
  WITH CHECK (user_id = auth.uid() AND status = 'revoked');

-- 31: Gmail connections (owner SELECT only; encrypted_refresh_token blocked from client roles)
CREATE POLICY gmail_connections_owner_select ON gmail_connections
  FOR SELECT
  USING (user_id = auth.uid());

REVOKE ALL ON gmail_connections FROM PUBLIC;
GRANT SELECT (user_id, gmail_address, status, last_scanned_at, connected_at) ON gmail_connections TO PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'REVOKE ALL ON gmail_connections FROM authenticated';
    EXECUTE 'GRANT SELECT (user_id, gmail_address, status, last_scanned_at, connected_at) ON gmail_connections TO authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE ALL ON gmail_connections FROM anon';
  END IF;
END
$$;

-- 30, 34-36: Backend-only internal tables (all direct client access denied)
CREATE POLICY payouts_deny_all_client ON payouts
  FOR ALL
  USING (FALSE)
  WITH CHECK (FALSE);

CREATE POLICY platform_settings_deny_all_client ON platform_settings
  FOR ALL
  USING (FALSE)
  WITH CHECK (FALSE);

CREATE POLICY audit_events_deny_all_client ON audit_events
  FOR ALL
  USING (FALSE)
  WITH CHECK (FALSE);

CREATE POLICY deleted_account_payment_archives_deny_all_client ON deleted_account_payment_archives
  FOR ALL
  USING (FALSE)
  WITH CHECK (FALSE);
