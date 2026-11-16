-- Canonical seed data aligned with:
-- 1. apps/mobile/lib/core/models/transaction_category_model.dart (24 parents, 81 subcategories = 105 rows)
-- 2. docs/katalog-paket-dan-harga.md (15 catalog packages, 6 verified practitioners c1..c6)
-- 3. apps/mobile/lib/features/consult & match_expert (packages, tags, pins, slots, venues, vouchers)

-- ---------------------------------------------------------------------------
-- 1. CATEGORIES (24 Top-Level Income/Expense Parents + 81 Subcategories)
-- ---------------------------------------------------------------------------
INSERT INTO categories (
  id, slug, name, parent_id, group_name, type, emoji, icon_key, color_hex, bg_color_hex, sort_order, is_active
) VALUES
  -- Income Parents (6)
  ('10000000-0000-4000-8000-000000000100', 'inc_income', 'Income', NULL, 'INCOME CATEGORIES', 'income', '💰', 'account_balance_wallet', '#10B981', '#D1FAE5', 100, TRUE),
  ('10000000-0000-4000-8000-000000000200', 'inc_business', 'Business', NULL, 'INCOME CATEGORIES', 'income', '💼', 'business_center', '#3B82F6', '#DBEAFE', 200, TRUE),
  ('10000000-0000-4000-8000-000000000300', 'inc_investment', 'Investment', NULL, 'INCOME CATEGORIES', 'income', '🪴', 'eco', '#059669', '#A7F3D0', 300, TRUE),
  ('10000000-0000-4000-8000-000000000400', 'inc_gift', 'Gift', NULL, 'INCOME CATEGORIES', 'income', '🎁', 'card_giftcard', '#EC4899', '#FCE7F3', 400, TRUE),
  ('10000000-0000-4000-8000-000000000500', 'inc_loans', 'Loans', NULL, 'INCOME CATEGORIES', 'income', '🏛️', 'account_balance', '#6366F1', '#E0E7FF', 500, TRUE),
  ('10000000-0000-4000-8000-000000000600', 'inc_transfer', 'Incoming Transfer', NULL, 'INCOME CATEGORIES', 'income', '⬇️', 'arrow_downward', '#0D9488', '#CCFBF1', 600, TRUE),

  -- Expense Parents (18)
  ('10000000-0000-4000-8000-000000001000', 'exp_fnb', 'Food & Beverage', NULL, 'DAILY NEEDS', 'expense', '🍜', 'restaurant', '#EA580C', '#FFEDD5', 1000, TRUE),
  ('10000000-0000-4000-8000-000000001100', 'exp_transportation', 'Transportation', NULL, 'DAILY NEEDS', 'expense', '🚌', 'directions_bus', '#0284C7', '#E0F2FE', 1100, TRUE),
  ('10000000-0000-4000-8000-000000001200', 'exp_household', 'Household Needs', NULL, 'HOUSEHOLD NEEDS', 'expense', '🏠', 'home', '#16A34A', '#DCFCE7', 1200, TRUE),
  ('10000000-0000-4000-8000-000000001300', 'exp_bills', 'Bills & Utilities', NULL, 'HOUSEHOLD NEEDS', 'expense', '🧾', 'receipt_long', '#4F46E5', '#EEF2FF', 1300, TRUE),
  ('10000000-0000-4000-8000-000000001400', 'exp_pets', 'Pets', NULL, 'HOUSEHOLD NEEDS', 'expense', '🐕', 'pets', '#D97706', '#FEF3C7', 1400, TRUE),
  ('10000000-0000-4000-8000-000000001500', 'exp_family', 'Family', NULL, 'HOUSEHOLD NEEDS', 'expense', '👨‍👩‍👧', 'diversity_3', '#9333EA', '#F3E8FF', 1500, TRUE),
  ('10000000-0000-4000-8000-000000001600', 'exp_shopping', 'Shopping', NULL, 'PERSONAL NEEDS', 'expense', '🛍️', 'shopping_bag', '#DB2777', '#FCE7F3', 1600, TRUE),
  ('10000000-0000-4000-8000-000000001700', 'exp_health', 'Health & Sports', NULL, 'PERSONAL NEEDS', 'expense', '🏋️', 'fitness_center', '#E11D48', '#FFE4E6', 1700, TRUE),
  ('10000000-0000-4000-8000-000000001800', 'exp_donations', 'Donations & Gifts', NULL, 'PERSONAL NEEDS', 'expense', '🤲', 'volunteer_activism', '#CA8A04', '#FEF08A', 1800, TRUE),
  ('10000000-0000-4000-8000-000000001900', 'exp_travel', 'Travel', NULL, 'PERSONAL NEEDS', 'expense', '✈️', 'flight', '#0891B2', '#CFFAFE', 1900, TRUE),
  ('10000000-0000-4000-8000-000000002000', 'exp_entertainment', 'Entertainment', NULL, 'PERSONAL NEEDS', 'expense', '🍿', 'movie', '#C026D3', '#FAE8FF', 2000, TRUE),
  ('10000000-0000-4000-8000-000000002100', 'exp_education', 'Education', NULL, 'PERSONAL NEEDS', 'expense', '📚', 'school', '#2563EB', '#DBEAFE', 2100, TRUE),
  ('10000000-0000-4000-8000-000000002200', 'exp_loans', 'Loans', NULL, 'FINANCE', 'expense', '🏛️', 'account_balance', '#475569', '#E2E8F0', 2200, TRUE),
  ('10000000-0000-4000-8000-000000002300', 'exp_investment', 'Investment', NULL, 'FINANCE', 'expense', '🪴', 'trending_up', '#047857', '#A7F3D0', 2300, TRUE),
  ('10000000-0000-4000-8000-000000002400', 'exp_business', 'Business', NULL, 'FINANCE', 'expense', '💼', 'business_center', '#64748B', '#F1F5F9', 2400, TRUE),
  ('10000000-0000-4000-8000-000000002500', 'exp_other_financial', 'Other Financial Expenses', NULL, 'FINANCE', 'expense', '🏷️', 'request_quote', '#78716C', '#E7E5E4', 2500, TRUE),
  ('10000000-0000-4000-8000-000000002600', 'exp_services', 'Other Services', NULL, 'SERVICES', 'expense', '⚙️', 'miscellaneous_services', '#0F766E', '#CCFBF1', 2600, TRUE),
  ('10000000-0000-4000-8000-000000002700', 'exp_others', 'Others', NULL, 'OTHERS', 'expense', '🤔', 'more_horiz', '#6B7280', '#F3F4F6', 2700, TRUE)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  group_name = EXCLUDED.group_name,
  type = EXCLUDED.type,
  emoji = EXCLUDED.emoji,
  icon_key = EXCLUDED.icon_key,
  color_hex = EXCLUDED.color_hex,
  bg_color_hex = EXCLUDED.bg_color_hex,
  sort_order = EXCLUDED.sort_order,
  is_active = TRUE;

-- Subcategories (15 Income + 66 Expense = 81 Subcategories)
INSERT INTO categories (
  id, slug, name, parent_id, group_name, type, emoji, icon_key, color_hex, bg_color_hex, sort_order, is_active
) VALUES
  -- Income subcategories
  ('10000000-0000-4000-8000-000000000101', 'inc_salary', 'Salary', '10000000-0000-4000-8000-000000000100', 'INCOME CATEGORIES', 'income', '👩‍💻', 'work', '#10B981', '#D1FAE5', 101, TRUE),
  ('10000000-0000-4000-8000-000000000102', 'inc_bonus', 'Bonus', '10000000-0000-4000-8000-000000000100', 'INCOME CATEGORIES', 'income', '⭐', 'star', '#10B981', '#D1FAE5', 102, TRUE),
  ('10000000-0000-4000-8000-000000000103', 'inc_pocket_money', 'Pocket Money', '10000000-0000-4000-8000-000000000100', 'INCOME CATEGORIES', 'income', '🎒', 'savings', '#10B981', '#D1FAE5', 103, TRUE),
  ('10000000-0000-4000-8000-000000000104', 'inc_additional', 'Additional Income', '10000000-0000-4000-8000-000000000100', 'INCOME CATEGORIES', 'income', '➕', 'add_circle', '#10B981', '#D1FAE5', 104, TRUE),

  ('10000000-0000-4000-8000-000000000201', 'inc_biz_sales', 'Sales Revenue', '10000000-0000-4000-8000-000000000200', 'INCOME CATEGORIES', 'income', '📈', 'trending_up', '#3B82F6', '#DBEAFE', 201, TRUE),
  ('10000000-0000-4000-8000-000000000202', 'inc_biz_freelance', 'Freelance & Client', '10000000-0000-4000-8000-000000000200', 'INCOME CATEGORIES', 'income', '💻', 'laptop_mac', '#3B82F6', '#DBEAFE', 202, TRUE),

  ('10000000-0000-4000-8000-000000000301', 'inc_inv_dividend', 'Dividends', '10000000-0000-4000-8000-000000000300', 'INCOME CATEGORIES', 'income', '🪙', 'monetization_on', '#059669', '#A7F3D0', 301, TRUE),
  ('10000000-0000-4000-8000-000000000302', 'inc_inv_capital_gain', 'Capital Gains', '10000000-0000-4000-8000-000000000300', 'INCOME CATEGORIES', 'income', '📊', 'show_chart', '#059669', '#A7F3D0', 302, TRUE),
  ('10000000-0000-4000-8000-000000000303', 'inc_inv_interest', 'Bank Interest', '10000000-0000-4000-8000-000000000300', 'INCOME CATEGORIES', 'income', '🏦', 'account_balance', '#059669', '#A7F3D0', 303, TRUE),

  ('10000000-0000-4000-8000-000000000401', 'inc_gift_family', 'From Family', '10000000-0000-4000-8000-000000000400', 'INCOME CATEGORIES', 'income', '👨‍👩‍👦', 'people', '#EC4899', '#FCE7F3', 401, TRUE),
  ('10000000-0000-4000-8000-000000000402', 'inc_gift_rewards', 'Rewards / Cashback', '10000000-0000-4000-8000-000000000400', 'INCOME CATEGORIES', 'income', '🎉', 'celebration', '#EC4899', '#FCE7F3', 402, TRUE),

  ('10000000-0000-4000-8000-000000000501', 'inc_loan_bank', 'Bank Loan', '10000000-0000-4000-8000-000000000500', 'INCOME CATEGORIES', 'income', '🏢', 'apartment', '#6366F1', '#E0E7FF', 501, TRUE),
  ('10000000-0000-4000-8000-000000000502', 'inc_loan_personal', 'Personal Borrowing', '10000000-0000-4000-8000-000000000500', 'INCOME CATEGORIES', 'income', '🤝', 'handshake', '#6366F1', '#E0E7FF', 502, TRUE),

  ('10000000-0000-4000-8000-000000000601', 'inc_trf_interbank', 'Inter-Bank Transfer', '10000000-0000-4000-8000-000000000600', 'INCOME CATEGORIES', 'income', '💳', 'credit_card', '#0D9488', '#CCFBF1', 601, TRUE),
  ('10000000-0000-4000-8000-000000000602', 'inc_trf_ewallet', 'E-Wallet Top-up', '10000000-0000-4000-8000-000000000600', 'INCOME CATEGORIES', 'income', '📱', 'phone_android', '#0D9488', '#CCFBF1', 602, TRUE),

  -- Expense subcategories: Food & Beverage (6)
  ('10000000-0000-4000-8000-000000001001', 'sub_fnb_restaurant', 'Restaurant', '10000000-0000-4000-8000-000000001000', 'DAILY NEEDS', 'expense', '👨‍🍳', 'dinner_dining', '#EA580C', '#FFEDD5', 1001, TRUE),
  ('10000000-0000-4000-8000-000000001002', 'sub_fnb_delivery', 'Food delivery', '10000000-0000-4000-8000-000000001000', 'DAILY NEEDS', 'expense', '🛵', 'delivery_dining', '#EA580C', '#FFEDD5', 1002, TRUE),
  ('10000000-0000-4000-8000-000000001003', 'sub_fnb_coffee', 'Coffee Shop', '10000000-0000-4000-8000-000000001000', 'DAILY NEEDS', 'expense', '☕', 'coffee', '#EA580C', '#FFEDD5', 1003, TRUE),
  ('10000000-0000-4000-8000-000000001004', 'sub_fnb_fastfood', 'Fast Food', '10000000-0000-4000-8000-000000001000', 'DAILY NEEDS', 'expense', '🍔', 'fastfood', '#EA580C', '#FFEDD5', 1004, TRUE),
  ('10000000-0000-4000-8000-000000001005', 'sub_fnb_alcohol', 'Alcoholic Beverages', '10000000-0000-4000-8000-000000001000', 'DAILY NEEDS', 'expense', '🥂', 'wine_bar', '#EA580C', '#FFEDD5', 1005, TRUE),
  ('10000000-0000-4000-8000-000000001006', 'sub_fnb_bakery', 'Bakery & Cake Shop', '10000000-0000-4000-8000-000000001000', 'DAILY NEEDS', 'expense', '🍞', 'bakery_dining', '#EA580C', '#FFEDD5', 1006, TRUE),

  -- Expense subcategories: Transportation (5)
  ('10000000-0000-4000-8000-000000001101', 'sub_tr_public', 'Public Transport', '10000000-0000-4000-8000-000000001100', 'DAILY NEEDS', 'expense', '🚆', 'train', '#0284C7', '#E0F2FE', 1101, TRUE),
  ('10000000-0000-4000-8000-000000001102', 'sub_tr_ridehailing', 'Ride Hailing / Taxi', '10000000-0000-4000-8000-000000001100', 'DAILY NEEDS', 'expense', '🚕', 'local_taxi', '#0284C7', '#E0F2FE', 1102, TRUE),
  ('10000000-0000-4000-8000-000000001103', 'sub_tr_fuel', 'Fuel & Gas', '10000000-0000-4000-8000-000000001100', 'DAILY NEEDS', 'expense', '⛽', 'local_gas_station', '#0284C7', '#E0F2FE', 1103, TRUE),
  ('10000000-0000-4000-8000-000000001104', 'sub_tr_parking', 'Parking & Toll', '10000000-0000-4000-8000-000000001100', 'DAILY NEEDS', 'expense', '🅿️', 'local_parking', '#0284C7', '#E0F2FE', 1104, TRUE),
  ('10000000-0000-4000-8000-000000001105', 'sub_tr_maint', 'Vehicle Maintenance', '10000000-0000-4000-8000-000000001100', 'DAILY NEEDS', 'expense', '🔧', 'build', '#0284C7', '#E0F2FE', 1105, TRUE),

  -- Expense subcategories: Household Needs (4)
  ('10000000-0000-4000-8000-000000001201', 'sub_hh_groceries', 'Groceries / Belanja Dapur', '10000000-0000-4000-8000-000000001200', 'HOUSEHOLD NEEDS', 'expense', '🛒', 'shopping_basket', '#16A34A', '#DCFCE7', 1201, TRUE),
  ('10000000-0000-4000-8000-000000001202', 'sub_hh_cleaning', 'Cleaning Supplies', '10000000-0000-4000-8000-000000001200', 'HOUSEHOLD NEEDS', 'expense', '🧹', 'cleaning_services', '#16A34A', '#DCFCE7', 1202, TRUE),
  ('10000000-0000-4000-8000-000000001203', 'sub_hh_maintenance', 'Home Repair', '10000000-0000-4000-8000-000000001200', 'HOUSEHOLD NEEDS', 'expense', '🔨', 'handyman', '#16A34A', '#DCFCE7', 1203, TRUE),
  ('10000000-0000-4000-8000-000000001204', 'sub_hh_rent', 'Rent / Sewa', '10000000-0000-4000-8000-000000001200', 'HOUSEHOLD NEEDS', 'expense', '🔑', 'vpn_key', '#16A34A', '#DCFCE7', 1204, TRUE),

  -- Expense subcategories: Bills & Utilities (5)
  ('10000000-0000-4000-8000-000000001301', 'sub_bill_electricity', 'Electricity / Listrik PLN', '10000000-0000-4000-8000-000000001300', 'HOUSEHOLD NEEDS', 'expense', '💡', 'bolt', '#4F46E5', '#EEF2FF', 1301, TRUE),
  ('10000000-0000-4000-8000-000000001302', 'sub_bill_water', 'Water / Air PDAM', '10000000-0000-4000-8000-000000001300', 'HOUSEHOLD NEEDS', 'expense', '🚰', 'water_drop', '#4F46E5', '#EEF2FF', 1302, TRUE),
  ('10000000-0000-4000-8000-000000001303', 'sub_bill_internet', 'Internet & Wi-Fi', '10000000-0000-4000-8000-000000001300', 'HOUSEHOLD NEEDS', 'expense', '📶', 'wifi', '#4F46E5', '#EEF2FF', 1303, TRUE),
  ('10000000-0000-4000-8000-000000001304', 'sub_bill_phone', 'Phone & Mobile Data', '10000000-0000-4000-8000-000000001300', 'HOUSEHOLD NEEDS', 'expense', '📱', 'phone_iphone', '#4F46E5', '#EEF2FF', 1304, TRUE),
  ('10000000-0000-4000-8000-000000001305', 'sub_bill_subscription', 'Digital Subscriptions', '10000000-0000-4000-8000-000000001300', 'HOUSEHOLD NEEDS', 'expense', '📺', 'subscriptions', '#4F46E5', '#EEF2FF', 1305, TRUE),

  -- Expense subcategories: Pets (3)
  ('10000000-0000-4000-8000-000000001401', 'sub_pet_food', 'Pet Food', '10000000-0000-4000-8000-000000001400', 'HOUSEHOLD NEEDS', 'expense', '🥩', 'set_meal', '#D97706', '#FEF3C7', 1401, TRUE),
  ('10000000-0000-4000-8000-000000001402', 'sub_pet_vet', 'Veterinary / Dokter', '10000000-0000-4000-8000-000000001400', 'HOUSEHOLD NEEDS', 'expense', '🩺', 'medical_services', '#D97706', '#FEF3C7', 1402, TRUE),
  ('10000000-0000-4000-8000-000000001403', 'sub_pet_supplies', 'Grooming & Toys', '10000000-0000-4000-8000-000000001400', 'HOUSEHOLD NEEDS', 'expense', '🎾', 'sports_baseball', '#D97706', '#FEF3C7', 1403, TRUE),

  -- Expense subcategories: Family (3)
  ('10000000-0000-4000-8000-000000001501', 'sub_fam_children', 'Childcare & Needs', '10000000-0000-4000-8000-000000001500', 'HOUSEHOLD NEEDS', 'expense', '🍼', 'child_care', '#9333EA', '#F3E8FF', 1501, TRUE),
  ('10000000-0000-4000-8000-000000001502', 'sub_fam_parents', 'Allowance to Parents', '10000000-0000-4000-8000-000000001500', 'HOUSEHOLD NEEDS', 'expense', '👵', 'elderly', '#9333EA', '#F3E8FF', 1502, TRUE),
  ('10000000-0000-4000-8000-000000001503', 'sub_fam_events', 'Family Events', '10000000-0000-4000-8000-000000001500', 'HOUSEHOLD NEEDS', 'expense', '🎂', 'cake', '#9333EA', '#F3E8FF', 1503, TRUE),

  -- Expense subcategories: Shopping (4)
  ('10000000-0000-4000-8000-000000001601', 'sub_shop_clothes', 'Clothing & Fashion', '10000000-0000-4000-8000-000000001600', 'PERSONAL NEEDS', 'expense', '👕', 'checkroom', '#DB2777', '#FCE7F3', 1601, TRUE),
  ('10000000-0000-4000-8000-000000001602', 'sub_shop_electronics', 'Electronics & Gadgets', '10000000-0000-4000-8000-000000001600', 'PERSONAL NEEDS', 'expense', '🎧', 'devices', '#DB2777', '#FCE7F3', 1602, TRUE),
  ('10000000-0000-4000-8000-000000001603', 'sub_shop_beauty', 'Beauty & Skincare', '10000000-0000-4000-8000-000000001600', 'PERSONAL NEEDS', 'expense', '💄', 'face', '#DB2777', '#FCE7F3', 1603, TRUE),
  ('10000000-0000-4000-8000-000000001604', 'sub_shop_shoes', 'Shoes & Accessories', '10000000-0000-4000-8000-000000001600', 'PERSONAL NEEDS', 'expense', '👟', 'snowshoeing', '#DB2777', '#FCE7F3', 1604, TRUE),

  -- Expense subcategories: Health & Sports (4)
  ('10000000-0000-4000-8000-000000001701', 'sub_health_doctor', 'Doctor & Hospital', '10000000-0000-4000-8000-000000001700', 'PERSONAL NEEDS', 'expense', '🏥', 'local_hospital', '#E11D48', '#FFE4E6', 1701, TRUE),
  ('10000000-0000-4000-8000-000000001702', 'sub_health_medicine', 'Medicine & Pharmacy', '10000000-0000-4000-8000-000000001700', 'PERSONAL NEEDS', 'expense', '💊', 'medication', '#E11D48', '#FFE4E6', 1702, TRUE),
  ('10000000-0000-4000-8000-000000001703', 'sub_health_gym', 'Gym & Fitness Membership', '10000000-0000-4000-8000-000000001700', 'PERSONAL NEEDS', 'expense', '💪', 'sports_gymnastics', '#E11D48', '#FFE4E6', 1703, TRUE),
  ('10000000-0000-4000-8000-000000001704', 'sub_health_gear', 'Sports Equipment', '10000000-0000-4000-8000-000000001700', 'PERSONAL NEEDS', 'expense', '⚽', 'sports_soccer', '#E11D48', '#FFE4E6', 1704, TRUE),

  -- Expense subcategories: Donations & Gifts (3)
  ('10000000-0000-4000-8000-000000001801', 'sub_don_charity', 'Charity & Infaq', '10000000-0000-4000-8000-000000001800', 'PERSONAL NEEDS', 'expense', '🕌', 'favorite', '#CA8A04', '#FEF08A', 1801, TRUE),
  ('10000000-0000-4000-8000-000000001802', 'sub_don_gifts', 'Gifts & Presents', '10000000-0000-4000-8000-000000001800', 'PERSONAL NEEDS', 'expense', '🎁', 'card_giftcard', '#CA8A04', '#FEF08A', 1802, TRUE),
  ('10000000-0000-4000-8000-000000001803', 'sub_don_zakat', 'Zakat', '10000000-0000-4000-8000-000000001800', 'PERSONAL NEEDS', 'expense', '🌾', 'spa', '#CA8A04', '#FEF08A', 1803, TRUE),

  -- Expense subcategories: Travel (3)
  ('10000000-0000-4000-8000-000000001901', 'sub_trv_ticket', 'Flight & Train Tickets', '10000000-0000-4000-8000-000000001900', 'PERSONAL NEEDS', 'expense', '🎫', 'confirmation_number', '#0891B2', '#CFFAFE', 1901, TRUE),
  ('10000000-0000-4000-8000-000000001902', 'sub_trv_hotel', 'Hotel & Lodging', '10000000-0000-4000-8000-000000001900', 'PERSONAL NEEDS', 'expense', '🏨', 'hotel', '#0891B2', '#CFFAFE', 1902, TRUE),
  ('10000000-0000-4000-8000-000000001903', 'sub_trv_tours', 'Attractions & Tours', '10000000-0000-4000-8000-000000001900', 'PERSONAL NEEDS', 'expense', '🏖️', 'beach_access', '#0891B2', '#CFFAFE', 1903, TRUE),

  -- Expense subcategories: Entertainment (4)
  ('10000000-0000-4000-8000-000000002001', 'sub_ent_cinema', 'Cinema & Movies', '10000000-0000-4000-8000-000000002000', 'PERSONAL NEEDS', 'expense', '🎬', 'theaters', '#C026D3', '#FAE8FF', 2001, TRUE),
  ('10000000-0000-4000-8000-000000002002', 'sub_ent_gaming', 'Games & Top-up', '10000000-0000-4000-8000-000000002000', 'PERSONAL NEEDS', 'expense', '🎮', 'sports_esports', '#C026D3', '#FAE8FF', 2002, TRUE),
  ('10000000-0000-4000-8000-000000002003', 'sub_ent_concert', 'Concerts & Events', '10000000-0000-4000-8000-000000002000', 'PERSONAL NEEDS', 'expense', '🎸', 'music_note', '#C026D3', '#FAE8FF', 2003, TRUE),
  ('10000000-0000-4000-8000-000000002004', 'sub_ent_hobbies', 'Hobbies & Crafts', '10000000-0000-4000-8000-000000002000', 'PERSONAL NEEDS', 'expense', '🎨', 'palette', '#C026D3', '#FAE8FF', 2004, TRUE),

  -- Expense subcategories: Education (3)
  ('10000000-0000-4000-8000-000000002101', 'sub_edu_courses', 'Courses & Certification', '10000000-0000-4000-8000-000000002100', 'PERSONAL NEEDS', 'expense', '💻', 'menu_book', '#2563EB', '#DBEAFE', 2101, TRUE),
  ('10000000-0000-4000-8000-000000002102', 'sub_edu_books', 'Books & Stationery', '10000000-0000-4000-8000-000000002100', 'PERSONAL NEEDS', 'expense', '📖', 'auto_stories', '#2563EB', '#DBEAFE', 2102, TRUE),
  ('10000000-0000-4000-8000-000000002103', 'sub_edu_tuition', 'Tuition / SPP', '10000000-0000-4000-8000-000000002100', 'PERSONAL NEEDS', 'expense', '🎓', 'workspace_premium', '#2563EB', '#DBEAFE', 2103, TRUE),

  -- Expense subcategories: Loans (4)
  ('10000000-0000-4000-8000-000000002201', 'sub_loan_mortgage', 'Mortgage / KPR', '10000000-0000-4000-8000-000000002200', 'FINANCE', 'expense', '🏡', 'house', '#475569', '#E2E8F0', 2201, TRUE),
  ('10000000-0000-4000-8000-000000002202', 'sub_loan_vehicle', 'Vehicle Installment', '10000000-0000-4000-8000-000000002200', 'FINANCE', 'expense', '🚗', 'directions_car', '#475569', '#E2E8F0', 2202, TRUE),
  ('10000000-0000-4000-8000-000000002203', 'sub_loan_personal', 'Personal Loan', '10000000-0000-4000-8000-000000002200', 'FINANCE', 'expense', '📄', 'assignment', '#475569', '#E2E8F0', 2203, TRUE),
  ('10000000-0000-4000-8000-000000002204', 'sub_loan_cc', 'Credit Card Bill', '10000000-0000-4000-8000-000000002200', 'FINANCE', 'expense', '💳', 'credit_card', '#475569', '#E2E8F0', 2204, TRUE),

  -- Expense subcategories: Investment (4)
  ('10000000-0000-4000-8000-000000002301', 'sub_inv_stocks', 'Stocks / Saham', '10000000-0000-4000-8000-000000002300', 'FINANCE', 'expense', '📈', 'show_chart', '#047857', '#A7F3D0', 2301, TRUE),
  ('10000000-0000-4000-8000-000000002302', 'sub_inv_mutual', 'Mutual Funds / Reksadana', '10000000-0000-4000-8000-000000002300', 'FINANCE', 'expense', '📊', 'bar_chart', '#047857', '#A7F3D0', 2302, TRUE),
  ('10000000-0000-4000-8000-000000002303', 'sub_inv_crypto', 'Crypto Assets', '10000000-0000-4000-8000-000000002300', 'FINANCE', 'expense', '🪙', 'currency_bitcoin', '#047857', '#A7F3D0', 2303, TRUE),
  ('10000000-0000-4000-8000-000000002304', 'sub_inv_gold', 'Gold / Emas', '10000000-0000-4000-8000-000000002300', 'FINANCE', 'expense', '🥇', 'military_tech', '#047857', '#A7F3D0', 2304, TRUE),

  -- Expense subcategories: Business (3)
  ('10000000-0000-4000-8000-000000002401', 'sub_biz_ops', 'Operations & Utilities', '10000000-0000-4000-8000-000000002400', 'FINANCE', 'expense', '⚙️', 'settings', '#64748B', '#F1F5F9', 2401, TRUE),
  ('10000000-0000-4000-8000-000000002402', 'sub_biz_inventory', 'Inventory & Supplies', '10000000-0000-4000-8000-000000002400', 'FINANCE', 'expense', '📦', 'inventory_2', '#64748B', '#F1F5F9', 2402, TRUE),
  ('10000000-0000-4000-8000-000000002403', 'sub_biz_marketing', 'Marketing & Ads', '10000000-0000-4000-8000-000000002400', 'FINANCE', 'expense', '📢', 'campaign', '#64748B', '#F1F5F9', 2403, TRUE),

  -- Expense subcategories: Other Financial Expenses (3)
  ('10000000-0000-4000-8000-000000002501', 'sub_fin_admin', 'Bank Admin Fees', '10000000-0000-4000-8000-000000002500', 'FINANCE', 'expense', '🏧', 'atm', '#78716C', '#E7E5E4', 2501, TRUE),
  ('10000000-0000-4000-8000-000000002502', 'sub_fin_tax', 'Taxes / Pajak', '10000000-0000-4000-8000-000000002500', 'FINANCE', 'expense', '📑', 'gavel', '#78716C', '#E7E5E4', 2502, TRUE),
  ('10000000-0000-4000-8000-000000002503', 'sub_fin_insurance', 'Insurance Premium', '10000000-0000-4000-8000-000000002500', 'FINANCE', 'expense', '🛡️', 'security', '#78716C', '#E7E5E4', 2503, TRUE),

  -- Expense subcategories: Other Services (4)
  ('10000000-0000-4000-8000-000000002601', 'sub_srv_laundry', 'Laundry', '10000000-0000-4000-8000-000000002600', 'SERVICES', 'expense', '🧺', 'local_laundry_service', '#0F766E', '#CCFBF1', 2601, TRUE),
  ('10000000-0000-4000-8000-000000002602', 'sub_srv_salon', 'Salon & Barbershop', '10000000-0000-4000-8000-000000002600', 'SERVICES', 'expense', '✂️', 'content_cut', '#0F766E', '#CCFBF1', 2602, TRUE),
  ('10000000-0000-4000-8000-000000002603', 'sub_srv_repair', 'Repair & Tech Services', '10000000-0000-4000-8000-000000002600', 'SERVICES', 'expense', '🛠️', 'build_circle', '#0F766E', '#CCFBF1', 2603, TRUE),
  ('10000000-0000-4000-8000-000000002604', 'sub_srv_courier', 'Courier & Postage', '10000000-0000-4000-8000-000000002600', 'SERVICES', 'expense', '📦', 'local_shipping', '#0F766E', '#CCFBF1', 2604, TRUE),

  -- Expense subcategories: Others (1)
  ('10000000-0000-4000-8000-000000002701', 'sub_oth_general', 'General Uncategorized', '10000000-0000-4000-8000-000000002700', 'OTHERS', 'expense', '📝', 'edit_note', '#6B7280', '#F3F4F6', 2701, TRUE)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  parent_id = EXCLUDED.parent_id,
  group_name = EXCLUDED.group_name,
  type = EXCLUDED.type,
  emoji = EXCLUDED.emoji,
  icon_key = EXCLUDED.icon_key,
  color_hex = EXCLUDED.color_hex,
  bg_color_hex = EXCLUDED.bg_color_hex,
  sort_order = EXCLUDED.sort_order,
  is_active = TRUE;

-- ---------------------------------------------------------------------------
-- 2. CATALOG_PACKAGES (15 Official Packages from docs/katalog-paket-dan-harga.md)
-- ---------------------------------------------------------------------------
INSERT INTO catalog_packages (
  id, code, service_category, category_tag, tier, participant_type, package_title,
  short_desc, full_desc, features, online_duration_minutes, offline_duration_minutes,
  base_online_price_idr, max_online_price_idr, base_offline_price_idr, max_offline_price_idr, is_active
) VALUES
  (
    '20000000-0000-4000-8000-000000000001', 'personal_basic', 'individual', 'Personal Advisory • Basic', 'basic', 'solo',
    'Fondasi Arus Kas & Utang',
    'Rapikan cashflow bulanan, utang PayLater, dan dana darurat pertama.',
    'Konseling finansial 1-on-1 (60 menit) untuk menghentikan siklus gaji selalu habis, restrukturisasi cicilan, serta menyusun dana darurat pertama yang realistis.',
    ARRAY[
      'Praktisi berlisensi resmi QWP® / AWP® / RFP® (< 300 klien)',
      'Review riwayat pengeluaran 30 hari & bedah pos bocor halus',
      'Rekomendasi strategi pelunasan utang/PayLater prioritas',
      'Action plan 30 hari & template cashflow Clarafin'
    ],
    60, 90, 199000, 299000, 349000, 449000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000002', 'personal_medium', 'individual', 'Personal Advisory • Medium', 'medium', 'solo',
    'Optimalisasi Aset & Proteksi',
    'Investasi reksa dana/saham, evaluasi asuransi, & persiapan KPR.',
    'Perencanaan keuangan komprehensif bersama Senior CFP® untuk menyusun portofolio investasi seimbang, audit polis asuransi, dan kalkulasi aman pengajuan KPR.',
    ARRAY[
      'Perencana Keuangan tersertifikasi resmi CFP® / BKP (301-500 klien)',
      'Audit alokasi investasi reksa dana, obligasi SBN, & saham',
      'Evaluasi kecukupan polis asuransi jiwa & kesehatan',
      'Simulasi kelayakan KPR & rasio DSR terhadap penghasilan'
    ],
    60, 90, 299000, 399000, 449000, 599000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000003', 'personal_premium', 'individual', 'Personal Advisory • Premium', 'premium', 'solo',
    'Menuju Kebebasan Finansial',
    'Peta jalan Financial Freedom (FIRE), passive income, & pensiun.',
    'Perencanaan kekayaan tingkat lanjut bersama Principal CFP®/CFA® untuk membangun passive income dividen/properti, efisiensi pajak pribadi, dan percepatan FIRE.',
    ARRAY[
      'Praktisi Senior CFP® Senior / CFA® / AEPP® (> 500 klien)',
      'Peta jalan Financial Freedom (FIRE) & strategi passive income',
      'Perencanaan waris, proteksi kekayaan, & efisiensi pajak SPT',
      'Blueprint Master Financial Plan (.pdf) & pendampingan prioritas'
    ],
    60, 90, 399000, 549000, 599000, 799000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000004', 'couple_pre_marriage', 'couple', 'Couple Advisory • Pre-Marriage', 'pre_marriage', 'couple',
    'Siap Menikah Tanpa Drama Finansial',
    'Buka-bukaan finansial sebelum akad, budget nikah, & rekening bersama.',
    'Sesi privat 60 menit bersama perencana keuangan spesialis pranikah untuk menyepakati manajemen uang suami-istri tanpa rasa canggung sebelum melangkah ke pelaminan.',
    ARRAY[
      'Praktisi CFP® spesialis keuangan pasangan (301-500 klien)',
      'Diskusi terbuka profil utang, aset bawaan, & transparansi gaji',
      'Penyusunan anggaran pernikahan tanpa jerat utang baru',
      'Kesepakatan model rekening keluarga (1 pintu / 2 pintu)'
    ],
    60, 90, 349000, 449000, 529000, 679000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000005', 'couple_marriage', 'couple', 'Couple Advisory • Marriage', 'marriage', 'couple',
    'Satu Visi Bangun Aset Keluarga',
    'Lepas dari generasi sandwich, dana anak, & percepat lunas KPR.',
    'Pendampingan finansial rumah tangga untuk menyelaraskan prioritas hidup bersama, mengamankan dana pendidikan anak hingga kuliah, dan menuntaskan KPR lebih cepat.',
    ARRAY[
      'Praktisi Senior CFP® spesialis keluarga (> 400 klien)',
      'Strategi mengelola beban generasi sandwich tanpa konflik',
      'Proyeksi biaya sekolah & inflasi dana pendidikan anak',
      'Simulasi percepatan pelunasan KPR keluarga'
    ],
    60, 90, 399000, 549000, 599000, 749000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000006', 'couple_premium', 'couple', 'Couple Advisory • Premium', 'premium', 'couple',
    'Mapan Finansial Lintas Generasi',
    'Proteksi pencari nafkah, studi luar negeri, hibah & waris keluarga.',
    'Perencanaan kekayaan keluarga besar dan perlindungan aset lintas generasi bersama Master Planner untuk memastikan kemakmuran keluarga terus berlanjut tanpa sengketa.',
    ARRAY[
      'Praktisi Utama CFP® Senior / AEPP® (> 500 klien)',
      'Proteksi komprehensif penghasilan kepala keluarga',
      'Persiapan dana studi internasional & mata uang asing',
      'Penataan hibah dan waris keluarga bebas konflik hukum'
    ],
    60, 90, 549000, 749000, 799000, 999000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000007', 'umkm_basic', 'umkm', 'UMKM Advisory • Basic', 'basic', 'solo',
    'Omzet Ramai, Untung Nyata di Rekening',
    'Hentikan kebocoran uang toko tercampur uang dapur & hitung HPP tepat.',
    'Bedah keuangan usaha mikro-kecil bersama Akuntan/QWP® untuk memisahkan rekening pribadi vs bisnis, menentukan gaji pemilik, dan menetapkan HPP yang menguntungkan.',
    ARRAY[
      'Konsultan Keuangan Bisnis / Akuntan (QWP® / Brevet AB)',
      'Pemisahan kas operasional usaha dari pengeluaran rumah tangga',
      'Penetapan formula HPP (COGS) & margin harga jual yang sehat',
      'Template pencatatan arus kas harian toko/warung sederhana'
    ],
    60, 90, 349000, 449000, 549000, 699000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000008', 'umkm_medium', 'umkm', 'UMKM Advisory • Medium', 'medium', 'solo',
    'Ekspansi Cabang & Aman Pajak Bisnis',
    'Kelayakan buka cabang, kredit modal kerja bank, & kepatuhan pajak.',
    'Konsultasi pertumbuhan usaha bersama Senior CFP®/BKP untuk menguji kelayakan ekspansi cabang baru, persiapan pengajuan kredit bank, serta strategi pajak UMKM aman denda.',
    ARRAY[
      'Konsultan Pajak & Bisnis Senior (CFP® / BKP / CPA)',
      'Analisis kelayakan investasi cabang baru tanpa ganggu kas',
      'Strategi restrukturisasi kredit modal usaha perbankan',
      'Audit kepatuhan pajak UMKM (PPh Final 0,5% vs PKP)'
    ],
    60, 90, 549000, 699000, 799000, 999000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000009', 'umkm_premium', 'umkm', 'UMKM Advisory • Premium', 'premium', 'solo',
    'Perpanjang Runway & Siap Pendanaan Investor',
    'Kendalikan burn rate, optimasi CAC/LTV, & model proyeksi investor.',
    'Sesi Fractional CFO bersama Principal Advisor/CFA® untuk memperpanjang cash runway startup, perbaikan unit economics, dan kesiapan dokumen due diligence investor.',
    ARRAY[
      'CFA® / Fractional CFO / Principal Advisor (> 500 klien)',
      'Pengendalian burn rate & perpanjangan cash runway bisnis',
      'Perbaikan unit economics (CAC, LTV, Gross Margin)',
      'Financial projection model & due diligence checklist'
    ],
    60, 90, 849000, 1099000, 1199000, 1500000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000010', 'corporate_basic', 'corporate', 'Corporate Wellness • Basic', 'basic', 'corporate',
    'Karyawan Produktif Bebas Jerat Pinjol',
    'Townhall 90 menit edukasi gaji, putus kasbon & pinjol karyawan.',
    'Workshop edukasi interaktif 90 menit bersama CFP® untuk meningkatkan literasi finansial karyawan, memutus siklus gali lubang tutup lubang, dan memulihkan fokus kerja.',
    ARRAY[
      'Dipandu langsung CFP® trainer korporasi berpengalaman',
      'Workshop interaktif pengelolaan gaji & simulasi dana darurat',
      'Strategi keluar dari jeratan pinjol ilegal & kasbon kantor',
      'E-Handout materi & toolkit kalkulator anggaran karyawan'
    ],
    90, 90, 2500000, 3250000, 4500000, 5500000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000011', 'corporate_medium', 'corporate', 'Corporate Wellness • Medium', 'medium', 'corporate',
    'Klinik Finansial Privat & Retensi Talenta',
    'Paket 5 slot konsultasi rahasia 1-on-1 bagi karyawan kunci HR.',
    'Program benefit karyawan berupa 5 sesi konsultasi privat (masing-masing 60 menit) bersama tim CFP® terverifikasi untuk membantu menyelesaikan beban finansial individu.',
    ARRAY[
      'Paket 5 slot sesi konsultasi 1-on-1 bersama tim CFP®/QWP®',
      '100% Kerahasiaan data karyawan terlindungi standar etik',
      'Penyelesaian masalah utang, KPR, dan persiapan dana anak',
      'Laporan agregat anonim kesehatan finansial tim untuk HRD'
    ],
    60, 90, 1490000, 1890000, 2250000, 2750000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000012', 'corporate_premium', 'corporate', 'Corporate Advisory • Premium', 'premium', 'corporate',
    'Optimalisasi Kas Korporasi & Pajak Eksekutif',
    'Corporate treasury kas menganggur, pajak badan, & pensiun direksi.',
    'Konsultasi tingkat tinggi bersama CFA®/CPA/Konsultan Pajak Terdaftar untuk penempatan likuiditas kas perusahaan menganggur dan perencanaan pajak eksekutif.',
    ARRAY[
      'CFA® / CPA / Konsultan Pajak Terdaftar (> 500 klien)',
      'Penempatan dana kas menganggur (Corporate Treasury)',
      'Optimalisasi efisiensi pajak penghasilan badan usaha',
      'Skema golden parachute & kompensasi pensiun jajaran direksi'
    ],
    90, 90, 1490000, 1990000, 2190000, 2790000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000013', 'checkup_basic', 'financial_checkup', 'Financial Check-Up • Basic', 'basic', 'solo',
    'Bongkar Bocor Halus & Skor Keuanganmu',
    'Rapor skor 4 rasio keuangan utama & resep perbaikan 30 hari.',
    'Sesi bedah kilat 45 menit bersama AWP®/QWP® untuk mendeteksi sumber kebocoran uang bulanan dan mendapatkan skor kesehatan finansial yang jelas beserta panduan aksi.',
    ARRAY[
      'Praktisi AWP® / QWP® (< 300 klien) + sesi bedah 45 menit',
      'Rapor skor 4 rasio keuangan: Tabungan, Utang, Darurat, & Gaya Hidup',
      'Identifikasi titik kebocoran pengeluaran yang tidak disadari',
      'Resep perbaikan finansial 30 hari dalam format ringkas'
    ],
    45, 90, 149000, 199000, 279000, 349000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000014', 'checkup_medium', 'financial_checkup', 'Financial Check-Up • Medium', 'medium', 'solo',
    'Bedah Tuntas Portofolio & Polis Asuransi',
    'Audit seluruh polis asuransi & evaluasi kinerja portofolio investasi.',
    'Sesi review mendalam 60 menit bersama CFP® independen untuk memastikan premi asuransi tidak kemahalan dan racikan investasi sudah optimal sesuai tujuan jangka panjang.',
    ARRAY[
      'Praktisi CFP® independen (301-500 klien) + sesi 60 menit',
      'Audit independen polis asuransi (premi vs manfaat perlindungan)',
      'Evaluasi portofolio reksa dana, saham, crypto, & emas',
      'Rekomendasi rebalancing aset tanpa bias penjualan produk'
    ],
    60, 90, 279000, 379000, 429000, 549000, TRUE
  ),
  (
    '20000000-0000-4000-8000-000000000015', 'checkup_premium', 'financial_checkup', 'Financial Check-Up • Premium', 'premium', 'solo',
    'Peta Jalan Kekayaan & Pensiun Dini (360°)',
    'Master Financial Blueprint PDF 10 tahun, target FIRE, & alokasi aset.',
    'Pemeriksaan kesehatan keuangan holistik 90 menit bersama Principal CFP®/CFA® menghasilkan cetak biru kekayaan 10 tahun untuk mencapai pensiun dini dengan rasa aman.',
    ARRAY[
      'Praktisi Senior CFP® / CFA® (> 500 klien) + sesi 90 menit',
      'Dokumen Master Financial Blueprint PDF 10 tahun',
      'Kalkulasi angka pasti dana pensiun dini (FIRE) & inflasi riil',
      'Matriks alokasi aset multi-instrumen & roadmap eksekusi bulanan'
    ],
    90, 90, 499000, 649000, 699000, 899000, TRUE
  )
ON CONFLICT (code) DO UPDATE SET
  service_category = EXCLUDED.service_category,
  category_tag = EXCLUDED.category_tag,
  tier = EXCLUDED.tier,
  participant_type = EXCLUDED.participant_type,
  package_title = EXCLUDED.package_title,
  short_desc = EXCLUDED.short_desc,
  full_desc = EXCLUDED.full_desc,
  features = EXCLUDED.features,
  online_duration_minutes = EXCLUDED.online_duration_minutes,
  offline_duration_minutes = EXCLUDED.offline_duration_minutes,
  base_online_price_idr = EXCLUDED.base_online_price_idr,
  max_online_price_idr = EXCLUDED.max_online_price_idr,
  base_offline_price_idr = EXCLUDED.base_offline_price_idr,
  max_offline_price_idr = EXCLUDED.max_offline_price_idr,
  is_active = TRUE;

-- ---------------------------------------------------------------------------
-- 3. CANONICAL 6 VERIFIED PRACTITIONERS (c1..c6)
-- ---------------------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
  ('00000000-0000-4000-8000-0000000000c1', 'chrysan.gomargana@practitioner.clarafin.id'),
  ('00000000-0000-4000-8000-0000000000c2', 'nurhuzaifah.amini@practitioner.clarafin.id'),
  ('00000000-0000-4000-8000-0000000000c3', 'rian.pratama@practitioner.clarafin.id'),
  ('00000000-0000-4000-8000-0000000000c4', 'hendra.wijaya@practitioner.clarafin.id'),
  ('00000000-0000-4000-8000-0000000000c5', 'nadia.kusuma@practitioner.clarafin.id'),
  ('00000000-0000-4000-8000-0000000000c6', 'budi.santoso@practitioner.clarafin.id')
ON CONFLICT (id) DO NOTHING;

INSERT INTO users (
  id, email, full_name, avatar_url, onboarding_completed
) VALUES
  (
    '00000000-0000-4000-8000-0000000000c1',
    'chrysan.gomargana@practitioner.clarafin.id',
    'Chrysan Gomargana, S.E., CFP®',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&fit=crop&crop=faces',
    TRUE
  ),
  (
    '00000000-0000-4000-8000-0000000000c2',
    'nurhuzaifah.amini@practitioner.clarafin.id',
    'Nurhuzaifah Amini, M.M., CFP®, BKP',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&fit=crop&crop=faces',
    TRUE
  ),
  (
    '00000000-0000-4000-8000-0000000000c3',
    'rian.pratama@practitioner.clarafin.id',
    'Rian Pratama, S.Ak., QWP®, AWP®',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&fit=crop&crop=faces',
    TRUE
  ),
  (
    '00000000-0000-4000-8000-0000000000c4',
    'hendra.wijaya@practitioner.clarafin.id',
    'Dr. Hendra Wijaya, MBA, CFA®, CFP®',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&fit=crop&crop=faces',
    TRUE
  ),
  (
    '00000000-0000-4000-8000-0000000000c5',
    'nadia.kusuma@practitioner.clarafin.id',
    'Nadia Kusuma, S.Psi., CFP®, AEPP®',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&fit=crop&crop=faces',
    TRUE
  ),
  (
    '00000000-0000-4000-8000-0000000000c6',
    'budi.santoso@practitioner.clarafin.id',
    'Budi Santoso, S.E., Ak., CPA, CFP®',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&fit=crop&crop=faces',
    TRUE
  )
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  avatar_url = EXCLUDED.avatar_url,
  onboarding_completed = TRUE;

INSERT INTO practitioner_profiles (
  user_id, display_name, title_headline, bio, city, practitioner_tier, clients_handled_count,
  certifications, certificate_file_urls, ktp_file_url, specializations, languages, supported_methods,
  gender, birth_year, consulting_style, years_of_experience, is_fully_booked, status, platform_cut_pct,
  rating_avg, review_count, total_sessions_completed, verified_at
) VALUES
  (
    '00000000-0000-4000-8000-0000000000c1',
    'Chrysan Gomargana, S.E., CFP®',
    'Financial Planner & Wealth Consultant',
    'Fokus mendampingi individu dan pasangan muda dalam merapikan arus kas, menyiapkan dana darurat, dan memulai portofolio investasi terukur.',
    'Jakarta Selatan',
    'medium',
    380,
    ARRAY['CFP®'],
    ARRAY['certs/practitioners/c1/cfp.pdf'],
    'kyc/practitioners/c1/ktp.pdf',
    ARRAY['Perencanaan Individu', 'Pasangan & Pranikah', 'Keuangan Keluarga', 'Cashflow & Budgeting', 'Investasi Reksadana', 'Financial Check-Up'],
    ARRAY['Indonesia', 'Inggris'],
    ARRAY['online', 'offline'],
    'Perempuan',
    1997,
    'Hangat dan suportif',
    5,
    FALSE,
    'verified',
    20,
    4.95,
    142,
    380,
    NOW()
  ),
  (
    '00000000-0000-4000-8000-0000000000c2',
    'Nurhuzaifah Amini, M.M., CFP®, BKP',
    'Debt Relief & Tax Specialist',
    'Spesialis dalam pemulihan kesehatan finansial dari jeratan hutang konsumtif, optimasi pajak pribadi & UMKM, serta negosiasi restrukturisasi utang.',
    'Tangerang Selatan',
    'premium',
    520,
    ARRAY['CFP®', 'BKP'],
    ARRAY['certs/practitioners/c2/cfp.pdf', 'certs/practitioners/c2/bkp.pdf'],
    'kyc/practitioners/c2/ktp.pdf',
    ARRAY['Restrukturisasi Utang', 'Pajak & Bisnis UMKM', 'Perencanaan Individu', 'KPR & Properti', 'Financial Check-Up', 'Bebas Hutang & Pinjol'],
    ARRAY['Indonesia', 'Inggris'],
    ARRAY['online', 'offline'],
    'Perempuan',
    1991,
    'To the point dan solutif (Data-Driven)',
    6,
    FALSE,
    'verified',
    20,
    4.92,
    198,
    520,
    NOW()
  ),
  (
    '00000000-0000-4000-8000-0000000000c3',
    'Rian Pratama, S.Ak., QWP®, AWP®',
    'Junior Financial Planner & Cashflow Specialist',
    'Membimbing profesional muda dan perintis usaha dalam membenahi arus kas harian, menghentikan kebocoran uang, dan membangun dana darurat pertama.',
    'Surabaya',
    'basic',
    190,
    ARRAY['QWP®', 'AWP®'],
    ARRAY['certs/practitioners/c3/qwp.pdf', 'certs/practitioners/c3/awp.pdf'],
    'kyc/practitioners/c3/ktp.pdf',
    ARRAY['Fondasi Arus Kas', 'Bebas Utang PayLater', 'Dana Darurat Pertama', 'UMKM Pemula', 'Financial Check-Up'],
    ARRAY['Indonesia', 'Inggris'],
    ARRAY['online', 'offline'],
    'Laki-laki',
    2000,
    'Hangat dan suportif',
    2,
    FALSE,
    'verified',
    20,
    4.88,
    95,
    190,
    NOW()
  ),
  (
    '00000000-0000-4000-8000-0000000000c4',
    'Dr. Hendra Wijaya, MBA, CFA®, CFP®',
    'Principal Wealth & Corporate Advisor',
    'Membantu eksekutif, investor, dan pemilik startup mengoptimalkan portofolio kekayaan, memperpanjang runway bisnis, serta menyusun peta jalan Financial Freedom.',
    'Jakarta Pusat',
    'premium',
    850,
    ARRAY['CFA®', 'CFP®'],
    ARRAY['certs/practitioners/c4/cfa.pdf', 'certs/practitioners/c4/cfp.pdf'],
    'kyc/practitioners/c4/ktp.pdf',
    ARRAY['FIRE (Financial Freedom)', 'Corporate Treasury', 'Startup Runway & Valuasi', 'Investasi Saham & Portofolio', 'Financial Check-Up 360°'],
    ARRAY['Indonesia', 'Inggris'],
    ARRAY['online', 'offline'],
    'Laki-laki',
    1984,
    'To the point dan solutif (Data-Driven)',
    10,
    FALSE,
    'verified',
    20,
    4.98,
    310,
    850,
    NOW()
  ),
  (
    '00000000-0000-4000-8000-0000000000c5',
    'Nadia Kusuma, S.Psi., CFP®, AEPP®',
    'Senior Family Wealth & Estate Planner',
    'Membantu pasangan dan keluarga merancang kemapanan finansial lintas generasi, proteksi aset keluarga, serta mengakhiri beban generasi sandwich secara bijak.',
    'Bandung',
    'premium',
    610,
    ARRAY['CFP®', 'AEPP®'],
    ARRAY['certs/practitioners/c5/cfp.pdf', 'certs/practitioners/c5/aepp.pdf'],
    'kyc/practitioners/c5/ktp.pdf',
    ARRAY['Pasangan & Pranikah', 'Keuangan Keluarga', 'Generasi Sandwich', 'Proteksi & Waris Lintas Generasi', 'Dana Pendidikan Anak'],
    ARRAY['Indonesia', 'Inggris'],
    ARRAY['online', 'offline'],
    'Perempuan',
    1990,
    'Hangat dan suportif',
    7,
    FALSE,
    'verified',
    20,
    4.96,
    280,
    610,
    NOW()
  ),
  (
    '00000000-0000-4000-8000-0000000000c6',
    'Budi Santoso, S.E., Ak., CPA, CFP®',
    'SME & Business Tax Strategist',
    'Membantu pelaku UMKM dan manajemen korporasi menyehatkan arus kas, merapikan pembukuan usaha, dan memastikan kepatuhan pajak bebas denda.',
    'Yogyakarta',
    'medium',
    340,
    ARRAY['CPA', 'CFP®', 'Brevet AB'],
    ARRAY['certs/practitioners/c6/cpa.pdf', 'certs/practitioners/c6/cfp.pdf'],
    'kyc/practitioners/c6/ktp.pdf',
    ARRAY['Keuangan UMKM & Bisnis', 'Audit & Pembukuan Kas', 'Pajak Bisnis & UKM', 'Corporate Wellness', 'Pemisahan Kas Usaha'],
    ARRAY['Indonesia', 'Jawa', 'Inggris'],
    ARRAY['online', 'offline'],
    'Laki-laki',
    1994,
    'To the point dan solutif (Data-Driven)',
    4,
    FALSE,
    'verified',
    20,
    4.93,
    175,
    340,
    NOW()
  )
ON CONFLICT (user_id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  title_headline = EXCLUDED.title_headline,
  bio = EXCLUDED.bio,
  city = EXCLUDED.city,
  practitioner_tier = EXCLUDED.practitioner_tier,
  clients_handled_count = EXCLUDED.clients_handled_count,
  certifications = EXCLUDED.certifications,
  specializations = EXCLUDED.specializations,
  languages = EXCLUDED.languages,
  supported_methods = EXCLUDED.supported_methods,
  gender = EXCLUDED.gender,
  birth_year = EXCLUDED.birth_year,
  consulting_style = EXCLUDED.consulting_style,
  years_of_experience = EXCLUDED.years_of_experience,
  status = 'verified',
  rating_avg = EXCLUDED.rating_avg,
  review_count = EXCLUDED.review_count,
  total_sessions_completed = EXCLUDED.total_sessions_completed;

-- ---------------------------------------------------------------------------
-- 4. PRACTITIONER_PACKAGES (26 Active Package Assignments across c1..c6)
-- ---------------------------------------------------------------------------
INSERT INTO practitioner_packages (
  id, practitioner_id, catalog_package_id, service_category, category_tag, tier,
  package_title, duration_minutes, online_price_idr, offline_price_idr,
  is_online_active, is_offline_active, is_active
)
SELECT
  v.id::uuid,
  v.practitioner_id::uuid,
  cp.id,
  cp.service_category,
  cp.category_tag,
  cp.tier,
  cp.package_title,
  cp.online_duration_minutes,
  cp.base_online_price_idr,
  cp.base_offline_price_idr,
  TRUE,
  TRUE,
  TRUE
FROM (VALUES
  -- c1: Chrysan Gomargana
  ('21000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-0000000000c1', 'personal_medium'),
  ('21000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-0000000000c1', 'couple_pre_marriage'),
  ('21000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-0000000000c1', 'couple_marriage'),
  ('21000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-0000000000c1', 'checkup_medium'),
  -- c2: Nurhuzaifah Amini
  ('21000000-0000-4000-8000-000000000005', '00000000-0000-4000-8000-0000000000c2', 'personal_premium'),
  ('21000000-0000-4000-8000-000000000006', '00000000-0000-4000-8000-0000000000c2', 'umkm_medium'),
  ('21000000-0000-4000-8000-000000000007', '00000000-0000-4000-8000-0000000000c2', 'umkm_premium'),
  ('21000000-0000-4000-8000-000000000008', '00000000-0000-4000-8000-0000000000c2', 'checkup_premium'),
  -- c3: Rian Pratama
  ('21000000-0000-4000-8000-000000000009', '00000000-0000-4000-8000-0000000000c3', 'personal_basic'),
  ('21000000-0000-4000-8000-000000000010', '00000000-0000-4000-8000-0000000000c3', 'umkm_basic'),
  ('21000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-0000000000c3', 'checkup_basic'),
  -- c4: Dr. Hendra Wijaya
  ('21000000-0000-4000-8000-000000000012', '00000000-0000-4000-8000-0000000000c4', 'personal_premium'),
  ('21000000-0000-4000-8000-000000000013', '00000000-0000-4000-8000-0000000000c4', 'umkm_premium'),
  ('21000000-0000-4000-8000-000000000014', '00000000-0000-4000-8000-0000000000c4', 'corporate_premium'),
  ('21000000-0000-4000-8000-000000000015', '00000000-0000-4000-8000-0000000000c4', 'checkup_premium'),
  -- c5: Nadia Kusuma
  ('21000000-0000-4000-8000-000000000016', '00000000-0000-4000-8000-0000000000c5', 'couple_pre_marriage'),
  ('21000000-0000-4000-8000-000000000017', '00000000-0000-4000-8000-0000000000c5', 'couple_marriage'),
  ('21000000-0000-4000-8000-000000000018', '00000000-0000-4000-8000-0000000000c5', 'couple_premium'),
  ('21000000-0000-4000-8000-000000000019', '00000000-0000-4000-8000-0000000000c5', 'personal_premium'),
  ('21000000-0000-4000-8000-000000000020', '00000000-0000-4000-8000-0000000000c5', 'checkup_medium'),
  ('21000000-0000-4000-8000-000000000021', '00000000-0000-4000-8000-0000000000c5', 'checkup_premium'),
  -- c6: Budi Santoso
  ('21000000-0000-4000-8000-000000000022', '00000000-0000-4000-8000-0000000000c6', 'umkm_basic'),
  ('21000000-0000-4000-8000-000000000023', '00000000-0000-4000-8000-0000000000c6', 'umkm_medium'),
  ('21000000-0000-4000-8000-000000000024', '00000000-0000-4000-8000-0000000000c6', 'corporate_basic'),
  ('21000000-0000-4000-8000-000000000025', '00000000-0000-4000-8000-0000000000c6', 'corporate_medium'),
  ('21000000-0000-4000-8000-000000000026', '00000000-0000-4000-8000-0000000000c6', 'personal_medium')
) AS v(id, practitioner_id, catalog_code)
JOIN catalog_packages cp ON cp.code = v.catalog_code
ON CONFLICT (practitioner_id, catalog_package_id) DO UPDATE SET
  online_price_idr = EXCLUDED.online_price_idr,
  offline_price_idr = EXCLUDED.offline_price_idr,
  is_online_active = TRUE,
  is_offline_active = TRUE,
  is_active = TRUE;

-- ---------------------------------------------------------------------------
-- 5. PROBLEM_TAGS (15 Canonical Problem Tags) & STAFF_PRACTITIONER_PINS (Max 3 per Tag)
-- ---------------------------------------------------------------------------
INSERT INTO problem_tags (id, slug, label, min_tier, is_active) VALUES
  ('30000000-0000-4000-8000-000000000001', 'cashflow', '#Arus Kas & Budgeting', 'basic', TRUE),
  ('30000000-0000-4000-8000-000000000002', 'pinjol', '#Pinjol & Paylater', 'basic', TRUE),
  ('30000000-0000-4000-8000-000000000003', 'dana_darurat', '#Dana Darurat', 'basic', TRUE),
  ('30000000-0000-4000-8000-000000000004', 'pemetaan_utang', '#Pemetaan Utang', 'basic', TRUE),
  ('30000000-0000-4000-8000-000000000005', 'restrukturisasi_utang', '#Restrukturisasi Utang', 'medium', TRUE),
  ('30000000-0000-4000-8000-000000000006', 'reksadana', '#Reksadana', 'medium', TRUE),
  ('30000000-0000-4000-8000-000000000007', 'saham', '#Saham & Dividen', 'medium', TRUE),
  ('30000000-0000-4000-8000-000000000008', 'kpr', '#KPR & Properti', 'medium', TRUE),
  ('30000000-0000-4000-8000-000000000009', 'pajak', '#Pajak Pribadi & SPT', 'medium', TRUE),
  ('30000000-0000-4000-8000-000000000010', 'asuransi', '#Asuransi Unitlink', 'medium', TRUE),
  ('30000000-0000-4000-8000-000000000011', 'budget_nikah', '#Budgeting Pasutri', 'medium', TRUE),
  ('30000000-0000-4000-8000-000000000012', 'kas_bisnis', '#Pembukuan Bisnis', 'basic', TRUE),
  ('30000000-0000-4000-8000-000000000013', 'runway_usaha', '#Runway & Startup', 'premium', TRUE),
  ('30000000-0000-4000-8000-000000000014', 'fire_pensiun', '#FIRE & Pensiun Dini', 'premium', TRUE),
  ('30000000-0000-4000-8000-000000000015', 'crypto', '#Crypto & Web3', 'medium', TRUE)
ON CONFLICT (slug) DO UPDATE SET
  label = EXCLUDED.label,
  min_tier = EXCLUDED.min_tier,
  is_active = TRUE;

INSERT INTO staff_practitioner_pins (id, problem_tag_id, practitioner_id, priority_order) VALUES
  -- basic tags
  ('31000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-0000000000c3', 1),
  ('31000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-0000000000c1', 2),
  ('31000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-0000000000c6', 3),
  ('31000000-0000-4000-8000-000000000004', '30000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-0000000000c2', 1),
  ('31000000-0000-4000-8000-000000000005', '30000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-0000000000c3', 2),
  ('31000000-0000-4000-8000-000000000006', '30000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-0000000000c1', 3),
  ('31000000-0000-4000-8000-000000000007', '30000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-0000000000c3', 1),
  ('31000000-0000-4000-8000-000000000008', '30000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-0000000000c1', 2),
  ('31000000-0000-4000-8000-000000000009', '30000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-0000000000c3', 1),
  ('31000000-0000-4000-8000-000000000010', '30000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-0000000000c2', 2),
  ('31000000-0000-4000-8000-000000000011', '30000000-0000-4000-8000-000000000012', '00000000-0000-4000-8000-0000000000c6', 1),
  ('31000000-0000-4000-8000-000000000012', '30000000-0000-4000-8000-000000000012', '00000000-0000-4000-8000-0000000000c3', 2),
  ('31000000-0000-4000-8000-000000000013', '30000000-0000-4000-8000-000000000012', '00000000-0000-4000-8000-0000000000c2', 3),
  -- medium tags (eligible: c1, c6, c2, c4, c5)
  ('31000000-0000-4000-8000-000000000014', '30000000-0000-4000-8000-000000000005', '00000000-0000-4000-8000-0000000000c2', 1),
  ('31000000-0000-4000-8000-000000000015', '30000000-0000-4000-8000-000000000005', '00000000-0000-4000-8000-0000000000c6', 2),
  ('31000000-0000-4000-8000-000000000016', '30000000-0000-4000-8000-000000000006', '00000000-0000-4000-8000-0000000000c1', 1),
  ('31000000-0000-4000-8000-000000000017', '30000000-0000-4000-8000-000000000006', '00000000-0000-4000-8000-0000000000c4', 2),
  ('31000000-0000-4000-8000-000000000018', '30000000-0000-4000-8000-000000000007', '00000000-0000-4000-8000-0000000000c4', 1),
  ('31000000-0000-4000-8000-000000000019', '30000000-0000-4000-8000-000000000007', '00000000-0000-4000-8000-0000000000c1', 2),
  ('31000000-0000-4000-8000-000000000020', '30000000-0000-4000-8000-000000000008', '00000000-0000-4000-8000-0000000000c2', 1),
  ('31000000-0000-4000-8000-000000000021', '30000000-0000-4000-8000-000000000008', '00000000-0000-4000-8000-0000000000c1', 2),
  ('31000000-0000-4000-8000-000000000022', '30000000-0000-4000-8000-000000000009', '00000000-0000-4000-8000-0000000000c2', 1),
  ('31000000-0000-4000-8000-000000000023', '30000000-0000-4000-8000-000000000009', '00000000-0000-4000-8000-0000000000c6', 2),
  ('31000000-0000-4000-8000-000000000024', '30000000-0000-4000-8000-000000000010', '00000000-0000-4000-8000-0000000000c1', 1),
  ('31000000-0000-4000-8000-000000000025', '30000000-0000-4000-8000-000000000010', '00000000-0000-4000-8000-0000000000c5', 2),
  ('31000000-0000-4000-8000-000000000026', '30000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-0000000000c1', 1),
  ('31000000-0000-4000-8000-000000000027', '30000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-0000000000c5', 2),
  ('31000000-0000-4000-8000-000000000028', '30000000-0000-4000-8000-000000000015', '00000000-0000-4000-8000-0000000000c4', 1),
  ('31000000-0000-4000-8000-000000000029', '30000000-0000-4000-8000-000000000015', '00000000-0000-4000-8000-0000000000c6', 2),
  -- premium tags (eligible: c2, c4, c5)
  ('31000000-0000-4000-8000-000000000030', '30000000-0000-4000-8000-000000000013', '00000000-0000-4000-8000-0000000000c4', 1),
  ('31000000-0000-4000-8000-000000000031', '30000000-0000-4000-8000-000000000013', '00000000-0000-4000-8000-0000000000c2', 2),
  ('31000000-0000-4000-8000-000000000032', '30000000-0000-4000-8000-000000000014', '00000000-0000-4000-8000-0000000000c4', 1),
  ('31000000-0000-4000-8000-000000000033', '30000000-0000-4000-8000-000000000014', '00000000-0000-4000-8000-0000000000c5', 2),
  ('31000000-0000-4000-8000-000000000034', '30000000-0000-4000-8000-000000000014', '00000000-0000-4000-8000-0000000000c2', 3)
ON CONFLICT (problem_tag_id, priority_order) DO UPDATE SET
  practitioner_id = EXCLUDED.practitioner_id;

-- ---------------------------------------------------------------------------
-- 6. PRACTITIONER_AVAILABILITY (Weekly Recurring Slots Ensuring 14-Day Coverage)
-- ---------------------------------------------------------------------------
INSERT INTO practitioner_availability (id, practitioner_id, day_of_week, start_time_wib, end_time_wib, is_active) VALUES
  -- c1: Mon-Sat flexible morning/afternoon/evening
  ('40000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-0000000000c1', 1, '09:00:00', '10:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000102', '00000000-0000-4000-8000-0000000000c1', 1, '19:00:00', '20:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000103', '00000000-0000-4000-8000-0000000000c1', 2, '10:30:00', '11:30:00', TRUE),
  ('40000000-0000-4000-8000-000000000104', '00000000-0000-4000-8000-0000000000c1', 3, '13:00:00', '14:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000105', '00000000-0000-4000-8000-0000000000c1', 4, '19:00:00', '20:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000106', '00000000-0000-4000-8000-0000000000c1', 5, '16:00:00', '17:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000107', '00000000-0000-4000-8000-0000000000c1', 6, '09:00:00', '10:00:00', TRUE),

  -- c2: Mon-Sat afternoon/evening
  ('40000000-0000-4000-8000-000000000201', '00000000-0000-4000-8000-0000000000c2', 1, '13:00:00', '14:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000202', '00000000-0000-4000-8000-0000000000c2', 2, '16:00:00', '17:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000203', '00000000-0000-4000-8000-0000000000c2', 3, '19:00:00', '20:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000204', '00000000-0000-4000-8000-0000000000c2', 4, '10:30:00', '11:30:00', TRUE),
  ('40000000-0000-4000-8000-000000000205', '00000000-0000-4000-8000-0000000000c2', 5, '20:00:00', '21:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000206', '00000000-0000-4000-8000-0000000000c2', 6, '10:30:00', '11:30:00', TRUE),

  -- c3: Mon-Sun (evening + weekend friendly for young professionals)
  ('40000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-0000000000c3', 0, '10:30:00', '11:30:00', TRUE),
  ('40000000-0000-4000-8000-000000000302', '00000000-0000-4000-8000-0000000000c3', 1, '19:00:00', '20:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000303', '00000000-0000-4000-8000-0000000000c3', 2, '20:00:00', '21:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000304', '00000000-0000-4000-8000-0000000000c3', 3, '09:00:00', '10:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000305', '00000000-0000-4000-8000-0000000000c3', 4, '19:00:00', '20:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000306', '00000000-0000-4000-8000-0000000000c3', 5, '17:00:00', '18:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000307', '00000000-0000-4000-8000-0000000000c3', 6, '13:00:00', '14:00:00', TRUE),

  -- c4: Mon-Sat executive morning/afternoon/evening
  ('40000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-0000000000c4', 1, '09:00:00', '10:30:00', TRUE),
  ('40000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-0000000000c4', 2, '14:00:00', '15:30:00', TRUE),
  ('40000000-0000-4000-8000-000000000403', '00000000-0000-4000-8000-0000000000c4', 3, '16:00:00', '17:30:00', TRUE),
  ('40000000-0000-4000-8000-000000000404', '00000000-0000-4000-8000-0000000000c4', 4, '20:00:00', '21:30:00', TRUE),
  ('40000000-0000-4000-8000-000000000405', '00000000-0000-4000-8000-0000000000c4', 5, '09:00:00', '10:30:00', TRUE),
  ('40000000-0000-4000-8000-000000000406', '00000000-0000-4000-8000-0000000000c4', 6, '10:30:00', '12:00:00', TRUE),

  -- c5: Mon-Sun couple-friendly evening & weekend slots
  ('40000000-0000-4000-8000-000000000501', '00000000-0000-4000-8000-0000000000c5', 0, '19:00:00', '20:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000502', '00000000-0000-4000-8000-0000000000c5', 1, '20:00:00', '21:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000503', '00000000-0000-4000-8000-0000000000c5', 2, '19:00:00', '20:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000504', '00000000-0000-4000-8000-0000000000c5', 3, '14:00:00', '15:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000505', '00000000-0000-4000-8000-0000000000c5', 5, '19:00:00', '20:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000506', '00000000-0000-4000-8000-0000000000c5', 6, '16:00:00', '17:00:00', TRUE),

  -- c6: Mon-Sat business hours + evening
  ('40000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-0000000000c6', 1, '10:30:00', '11:30:00', TRUE),
  ('40000000-0000-4000-8000-000000000602', '00000000-0000-4000-8000-0000000000c6', 2, '13:00:00', '14:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000603', '00000000-0000-4000-8000-0000000000c6', 3, '16:00:00', '17:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000604', '00000000-0000-4000-8000-0000000000c6', 4, '10:30:00', '11:30:00', TRUE),
  ('40000000-0000-4000-8000-000000000605', '00000000-0000-4000-8000-0000000000c6', 5, '14:00:00', '15:00:00', TRUE),
  ('40000000-0000-4000-8000-000000000606', '00000000-0000-4000-8000-0000000000c6', 6, '09:00:00', '10:00:00', TRUE)
ON CONFLICT (id) DO UPDATE SET
  day_of_week = EXCLUDED.day_of_week,
  start_time_wib = EXCLUDED.start_time_wib,
  end_time_wib = EXCLUDED.end_time_wib,
  is_active = TRUE;

-- ---------------------------------------------------------------------------
-- 7. VENUES (6 Official Clarafin Offline Venues Matching Practitioner Cities)
-- ---------------------------------------------------------------------------
INSERT INTO venues (id, name, city, address, maps_url, is_active) VALUES
  (
    '50000000-0000-4000-8000-000000000001',
    'Clarafin Advisory Lounge Senopati',
    'Jakarta Selatan',
    'Jl. Senopati No. 48, Kebayoran Baru, Jakarta Selatan 12190',
    'https://maps.google.com/?q=Jalan+Senopati+Jakarta+Selatan',
    TRUE
  ),
  (
    '50000000-0000-4000-8000-000000000002',
    'Clarafin Executive Hub Thamrin',
    'Jakarta Pusat',
    'Jl. M.H. Thamrin Kav. 10, Menteng, Jakarta Pusat 10340',
    'https://maps.google.com/?q=Jalan+MH+Thamrin+Jakarta+Pusat',
    TRUE
  ),
  (
    '50000000-0000-4000-8000-000000000003',
    'Clarafin Partner Space BSD',
    'Tangerang Selatan',
    'Jl. BSD Green Office Park Kav. 7, Cisauk, Tangerang Selatan 15345',
    'https://maps.google.com/?q=BSD+Green+Office+Park+Tangerang+Selatan',
    TRUE
  ),
  (
    '50000000-0000-4000-8000-000000000004',
    'Clarafin Lounge Dago Heritage',
    'Bandung',
    'Jl. Ir. H. Juanda No. 112, Coblong, Bandung 40132',
    'https://maps.google.com/?q=Jalan+Dago+Bandung',
    TRUE
  ),
  (
    '50000000-0000-4000-8000-000000000005',
    'Clarafin Meeting Suite Tunjungan',
    'Surabaya',
    'Jl. Basuki Rahmat No. 89, Genteng, Surabaya 60271',
    'https://maps.google.com/?q=Jalan+Basuki+Rahmat+Surabaya',
    TRUE
  ),
  (
    '50000000-0000-4000-8000-000000000006',
    'Clarafin Advisory Room Sudirman',
    'Yogyakarta',
    'Jl. Jend. Sudirman No. 54, Gondokusuman, Yogyakarta 55224',
    'https://maps.google.com/?q=Jalan+Jenderal+Sudirman+Yogyakarta',
    TRUE
  )
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  city = EXCLUDED.city,
  address = EXCLUDED.address,
  maps_url = EXCLUDED.maps_url,
  is_active = TRUE;

-- ---------------------------------------------------------------------------
-- 8. VOUCHERS (6 Canonical Promo Vouchers from Mobile App & Catalog Docs)
-- ---------------------------------------------------------------------------
INSERT INTO vouchers (
  id, code, title, description, category, discount_type, discount_value,
  max_discount_idr, min_transaction_idr, valid_until, usage_limit, is_active
) VALUES
  (
    '60000000-0000-4000-8000-000000000001',
    'CLARAFIN50',
    'Diskon 50% Sesi Pertama',
    'Hemat separuh harga untuk sesi konsultasi 1-on-1 pertamamu dengan perencana keuangan bersertifikasi.',
    'counseling',
    'percentage',
    50,
    150000,
    150000,
    '2027-12-31T23:59:59+07:00',
    NULL,
    TRUE
  ),
  (
    '60000000-0000-4000-8000-000000000002',
    'HALOFINCFP',
    'Diskon Sesi CFP Komprehensif',
    'Potongan Rp 18.000 langsung untuk konsultasi perencanaan keuangan bersama perencana CFP®.',
    'counseling',
    'fixed_idr',
    18000,
    18000,
    0,
    '2027-12-31T23:59:59+07:00',
    NULL,
    TRUE
  ),
  (
    '60000000-0000-4000-8000-000000000003',
    'NEWUSER5',
    'Promo Spesial Member Baru',
    'Potongan Rp 25.000 tanpa minimum transaksi untuk pengguna baru Clarafin.',
    'all',
    'fixed_idr',
    25000,
    25000,
    0,
    '2027-12-31T23:59:59+07:00',
    NULL,
    TRUE
  ),
  (
    '60000000-0000-4000-8000-000000000004',
    'HEMAT10',
    'Finansial Mantap 10%',
    'Potongan Rp 35.000 untuk konsultasi perencanaan keuangan individu atau bisnis.',
    'counseling',
    'fixed_idr',
    35000,
    35000,
    150000,
    '2027-12-31T23:59:59+07:00',
    NULL,
    TRUE
  ),
  (
    '60000000-0000-4000-8000-000000000005',
    'KELUARGA25',
    'Diskon 25% Paket Keluarga',
    'Perencanaan dana pendidikan buah hati dan proteksi asuransi keluarga bersama konsultan senior.',
    'counseling',
    'percentage',
    25,
    150000,
    300000,
    '2027-12-31T23:59:59+07:00',
    NULL,
    TRUE
  ),
  (
    '60000000-0000-4000-8000-000000000006',
    'INVESTASI100',
    'Cashback Reksadana Rp 100.000',
    'Bonus saldo investasi reksadana pasar uang setelah menyelesaikan sesi review portofolio.',
    'investment',
    'fixed_idr',
    100000,
    100000,
    500000,
    '2027-12-31T23:59:59+07:00',
    NULL,
    TRUE
  )
ON CONFLICT (code) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  discount_type = EXCLUDED.discount_type,
  discount_value = EXCLUDED.discount_value,
  max_discount_idr = EXCLUDED.max_discount_idr,
  min_transaction_idr = EXCLUDED.min_transaction_idr,
  valid_until = EXCLUDED.valid_until,
  is_active = TRUE;

-- ---------------------------------------------------------------------------
-- 9. PLATFORM_SETTINGS (Operational Constants)
-- ---------------------------------------------------------------------------
INSERT INTO platform_settings (key, value_json) VALUES
  ('consultation_platform_fee_idr', '{"amount_idr": 15000}'::jsonb),
  ('bundle_discounts', '{"1": 0, "2": 0, "3": 7, "8": 12}'::jsonb),
  ('ai_quota_limits', '{"free_monthly": 40, "pro_30d": 400, "unlimited_30d": -1, "rate_limit_per_min": 10}'::jsonb),
  ('chat_sla', '{"first_reply_hours": 12, "chat_window_days": 3}'::jsonb),
  ('booking_hold_ttl', '{"solo_minutes": 15, "couple_hours": 24}'::jsonb),
  ('payment_methods_enabled', '{"qris": true, "va": false, "ewallet": false}'::jsonb)
ON CONFLICT (key) DO UPDATE SET
  value_json = EXCLUDED.value_json,
  updated_at = NOW();
