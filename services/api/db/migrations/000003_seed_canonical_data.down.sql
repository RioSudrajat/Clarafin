-- Rollback canonical seed rows in reverse dependency order without deleting user data.

DELETE FROM platform_settings
WHERE key IN (
  'consultation_platform_fee_idr',
  'bundle_discounts',
  'ai_quota_limits',
  'chat_sla',
  'booking_hold_ttl',
  'payment_methods_enabled'
);

DELETE FROM vouchers
WHERE code IN (
  'CLARAFIN50',
  'HALOFINCFP',
  'NEWUSER5',
  'HEMAT10',
  'KELUARGA25',
  'INVESTASI100'
);

DELETE FROM venues
WHERE id IN (
  '50000000-0000-4000-8000-000000000001',
  '50000000-0000-4000-8000-000000000002',
  '50000000-0000-4000-8000-000000000003',
  '50000000-0000-4000-8000-000000000004',
  '50000000-0000-4000-8000-000000000005',
  '50000000-0000-4000-8000-000000000006'
);

DELETE FROM practitioner_availability
WHERE practitioner_id IN (
  '00000000-0000-4000-8000-0000000000c1',
  '00000000-0000-4000-8000-0000000000c2',
  '00000000-0000-4000-8000-0000000000c3',
  '00000000-0000-4000-8000-0000000000c4',
  '00000000-0000-4000-8000-0000000000c5',
  '00000000-0000-4000-8000-0000000000c6'
);

DELETE FROM staff_practitioner_pins
WHERE problem_tag_id IN (
  SELECT id FROM problem_tags
  WHERE slug IN (
    'cashflow', 'pinjol', 'dana_darurat', 'pemetaan_utang',
    'restrukturisasi_utang', 'reksadana', 'saham', 'kpr',
    'pajak', 'asuransi', 'budget_nikah', 'kas_bisnis',
    'runway_usaha', 'fire_pensiun', 'crypto'
  )
);

DELETE FROM problem_tags
WHERE slug IN (
  'cashflow', 'pinjol', 'dana_darurat', 'pemetaan_utang',
  'restrukturisasi_utang', 'reksadana', 'saham', 'kpr',
  'pajak', 'asuransi', 'budget_nikah', 'kas_bisnis',
  'runway_usaha', 'fire_pensiun', 'crypto'
);

DELETE FROM practitioner_packages
WHERE practitioner_id IN (
  '00000000-0000-4000-8000-0000000000c1',
  '00000000-0000-4000-8000-0000000000c2',
  '00000000-0000-4000-8000-0000000000c3',
  '00000000-0000-4000-8000-0000000000c4',
  '00000000-0000-4000-8000-0000000000c5',
  '00000000-0000-4000-8000-0000000000c6'
);

DELETE FROM practitioner_profiles
WHERE user_id IN (
  '00000000-0000-4000-8000-0000000000c1',
  '00000000-0000-4000-8000-0000000000c2',
  '00000000-0000-4000-8000-0000000000c3',
  '00000000-0000-4000-8000-0000000000c4',
  '00000000-0000-4000-8000-0000000000c5',
  '00000000-0000-4000-8000-0000000000c6'
);

DELETE FROM users
WHERE id IN (
  '00000000-0000-4000-8000-0000000000c1',
  '00000000-0000-4000-8000-0000000000c2',
  '00000000-0000-4000-8000-0000000000c3',
  '00000000-0000-4000-8000-0000000000c4',
  '00000000-0000-4000-8000-0000000000c5',
  '00000000-0000-4000-8000-0000000000c6'
);

DELETE FROM auth.users
WHERE id IN (
  '00000000-0000-4000-8000-0000000000c1',
  '00000000-0000-4000-8000-0000000000c2',
  '00000000-0000-4000-8000-0000000000c3',
  '00000000-0000-4000-8000-0000000000c4',
  '00000000-0000-4000-8000-0000000000c5',
  '00000000-0000-4000-8000-0000000000c6'
);

DELETE FROM catalog_packages
WHERE code IN (
  'personal_basic', 'personal_medium', 'personal_premium',
  'couple_pre_marriage', 'couple_marriage', 'couple_premium',
  'umkm_basic', 'umkm_medium', 'umkm_premium',
  'corporate_basic', 'corporate_medium', 'corporate_premium',
  'checkup_basic', 'checkup_medium', 'checkup_premium'
);

DELETE FROM categories
WHERE parent_id IS NOT NULL
  AND id::text LIKE '10000000-0000-4000-8000-00000000%';

DELETE FROM categories
WHERE parent_id IS NULL
  AND id::text LIKE '10000000-0000-4000-8000-00000000%';
