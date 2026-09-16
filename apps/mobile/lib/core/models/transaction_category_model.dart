import 'package:flutter/material.dart';

class TransactionSubcategory {
  final String id;
  final String name;
  final String emoji;
  final IconData icon;

  const TransactionSubcategory({
    required this.id,
    required this.name,
    required this.emoji,
    this.icon = Icons.circle,
  });
}

class TransactionCategory {
  final String id;
  final String name;
  final String group;
  final String emoji;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isIncome;
  final List<TransactionSubcategory> subcategories;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.group,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.isIncome = false,
    this.subcategories = const [],
  });

  bool get hasSubcategories => subcategories.isNotEmpty;
}

class TransactionCategories {
  // ─── 1. INCOME CATEGORIES (Image 1) ───
  static const List<TransactionCategory> incomeCategories = [
    TransactionCategory(
      id: 'inc_income',
      name: 'Income',
      group: 'INCOME CATEGORIES',
      emoji: '💰',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF10B981),
      bgColor: Color(0xFFD1FAE5),
      isIncome: true,
      subcategories: [
        TransactionSubcategory(
          id: 'inc_salary',
          name: 'Salary',
          emoji: '👩‍💻',
          icon: Icons.work,
        ),
        TransactionSubcategory(
          id: 'inc_bonus',
          name: 'Bonus',
          emoji: '⭐',
          icon: Icons.star,
        ),
        TransactionSubcategory(
          id: 'inc_pocket_money',
          name: 'Pocket Money',
          emoji: '🎒',
          icon: Icons.savings,
        ),
        TransactionSubcategory(
          id: 'inc_additional',
          name: 'Additional Income',
          emoji: '➕',
          icon: Icons.add_circle,
        ),
      ],
    ),
    TransactionCategory(
      id: 'inc_business',
      name: 'Business',
      group: 'INCOME CATEGORIES',
      emoji: '💼',
      icon: Icons.business_center,
      color: Color(0xFF3B82F6),
      bgColor: Color(0xFFDBEAFE),
      isIncome: true,
      subcategories: [
        TransactionSubcategory(id: 'inc_biz_sales', name: 'Sales Revenue', emoji: '📈', icon: Icons.trending_up),
        TransactionSubcategory(id: 'inc_biz_freelance', name: 'Freelance & Client', emoji: '💻', icon: Icons.laptop_mac),
      ],
    ),
    TransactionCategory(
      id: 'inc_investment',
      name: 'Investment',
      group: 'INCOME CATEGORIES',
      emoji: '🪴',
      icon: Icons.eco,
      color: Color(0xFF059669),
      bgColor: Color(0xFFA7F3D0),
      isIncome: true,
      subcategories: [
        TransactionSubcategory(id: 'inc_inv_dividend', name: 'Dividends', emoji: '🪙', icon: Icons.monetization_on),
        TransactionSubcategory(id: 'inc_inv_capital_gain', name: 'Capital Gains', emoji: '📊', icon: Icons.show_chart),
        TransactionSubcategory(id: 'inc_inv_interest', name: 'Bank Interest', emoji: '🏦', icon: Icons.account_balance),
      ],
    ),
    TransactionCategory(
      id: 'inc_gift',
      name: 'Gift',
      group: 'INCOME CATEGORIES',
      emoji: '🎁',
      icon: Icons.card_giftcard,
      color: Color(0xFFEC4899),
      bgColor: Color(0xFFFCE7F3),
      isIncome: true,
      subcategories: [
        TransactionSubcategory(id: 'inc_gift_family', name: 'From Family', emoji: '👨‍👩‍👦', icon: Icons.people),
        TransactionSubcategory(id: 'inc_gift_rewards', name: 'Rewards / Cashback', emoji: '🎉', icon: Icons.celebration),
      ],
    ),
    TransactionCategory(
      id: 'inc_loans',
      name: 'Loans',
      group: 'INCOME CATEGORIES',
      emoji: '🏛️',
      icon: Icons.account_balance,
      color: Color(0xFF6366F1),
      bgColor: Color(0xFFE0E7FF),
      isIncome: true,
      subcategories: [
        TransactionSubcategory(id: 'inc_loan_bank', name: 'Bank Loan', emoji: '🏢', icon: Icons.apartment),
        TransactionSubcategory(id: 'inc_loan_personal', name: 'Personal Borrowing', emoji: '🤝', icon: Icons.handshake),
      ],
    ),
    TransactionCategory(
      id: 'inc_transfer',
      name: 'Incoming Transfer',
      group: 'INCOME CATEGORIES',
      emoji: '⬇️',
      icon: Icons.arrow_downward,
      color: Color(0xFF0D9488),
      bgColor: Color(0xFFCCFBF1),
      isIncome: true,
      subcategories: [
        TransactionSubcategory(id: 'inc_trf_interbank', name: 'Inter-Bank Transfer', emoji: '💳', icon: Icons.credit_card),
        TransactionSubcategory(id: 'inc_trf_ewallet', name: 'E-Wallet Top-up', emoji: '📱', icon: Icons.phone_android),
      ],
    ),
  ];

  // ─── 2. EXPENSE CATEGORIES (Images 2, 3, 4, 5) ───
  static const List<TransactionCategory> expenseCategories = [
    // DAILY NEEDS
    TransactionCategory(
      id: 'exp_fnb',
      name: 'Food & Beverage',
      group: 'DAILY NEEDS',
      emoji: '🍜',
      icon: Icons.restaurant,
      color: Color(0xFFEA580C),
      bgColor: Color(0xFFFFEDD5),
      subcategories: [
        TransactionSubcategory(id: 'sub_fnb_restaurant', name: 'Restaurant', emoji: '👨‍🍳', icon: Icons.dinner_dining),
        TransactionSubcategory(id: 'sub_fnb_delivery', name: 'Food delivery', emoji: '🛵', icon: Icons.delivery_dining),
        TransactionSubcategory(id: 'sub_fnb_coffee', name: 'Coffee Shop', emoji: '☕', icon: Icons.coffee),
        TransactionSubcategory(id: 'sub_fnb_fastfood', name: 'Fast Food', emoji: '🍔', icon: Icons.fastfood),
        TransactionSubcategory(id: 'sub_fnb_alcohol', name: 'Alcoholic Beverages', emoji: '🥂', icon: Icons.wine_bar),
        TransactionSubcategory(id: 'sub_fnb_bakery', name: 'Bakery & Cake Shop', emoji: '🍞', icon: Icons.bakery_dining),
      ],
    ),
    TransactionCategory(
      id: 'exp_transportation',
      name: 'Transportation',
      group: 'DAILY NEEDS',
      emoji: '🚌',
      icon: Icons.directions_bus,
      color: Color(0xFF0284C7),
      bgColor: Color(0xFFE0F2FE),
      subcategories: [
        TransactionSubcategory(id: 'sub_tr_public', name: 'Public Transport', emoji: '🚆', icon: Icons.train),
        TransactionSubcategory(id: 'sub_tr_ridehailing', name: 'Ride Hailing / Taxi', emoji: '🚕', icon: Icons.local_taxi),
        TransactionSubcategory(id: 'sub_tr_fuel', name: 'Fuel & Gas', emoji: '⛽', icon: Icons.local_gas_station),
        TransactionSubcategory(id: 'sub_tr_parking', name: 'Parking & Toll', emoji: '🅿️', icon: Icons.local_parking),
        TransactionSubcategory(id: 'sub_tr_maint', name: 'Vehicle Maintenance', emoji: '🔧', icon: Icons.build),
      ],
    ),

    // HOUSEHOLD NEEDS
    TransactionCategory(
      id: 'exp_household',
      name: 'Household Needs',
      group: 'HOUSEHOLD NEEDS',
      emoji: '🏠',
      icon: Icons.home,
      color: Color(0xFF16A34A),
      bgColor: Color(0xFFDCFCE7),
      subcategories: [
        TransactionSubcategory(id: 'sub_hh_groceries', name: 'Groceries / Belanja Dapur', emoji: '🛒', icon: Icons.shopping_basket),
        TransactionSubcategory(id: 'sub_hh_cleaning', name: 'Cleaning Supplies', emoji: '🧹', icon: Icons.cleaning_services),
        TransactionSubcategory(id: 'sub_hh_maintenance', name: 'Home Repair', emoji: '🔨', icon: Icons.handyman),
        TransactionSubcategory(id: 'sub_hh_rent', name: 'Rent / Sewa', emoji: '🔑', icon: Icons.vpn_key),
      ],
    ),
    TransactionCategory(
      id: 'exp_bills',
      name: 'Bills & Utilities',
      group: 'HOUSEHOLD NEEDS',
      emoji: '🧾',
      icon: Icons.receipt_long,
      color: Color(0xFF4F46E5),
      bgColor: Color(0xFFEEF2FF),
      subcategories: [
        TransactionSubcategory(id: 'sub_bill_electricity', name: 'Electricity / Listrik PLN', emoji: '💡', icon: Icons.bolt),
        TransactionSubcategory(id: 'sub_bill_water', name: 'Water / Air PDAM', emoji: '🚰', icon: Icons.water_drop),
        TransactionSubcategory(id: 'sub_bill_internet', name: 'Internet & Wi-Fi', emoji: '📶', icon: Icons.wifi),
        TransactionSubcategory(id: 'sub_bill_phone', name: 'Phone & Mobile Data', emoji: '📱', icon: Icons.phone_iphone),
        TransactionSubcategory(id: 'sub_bill_subscription', name: 'Digital Subscriptions', emoji: '📺', icon: Icons.subscriptions),
      ],
    ),
    TransactionCategory(
      id: 'exp_pets',
      name: 'Pets',
      group: 'HOUSEHOLD NEEDS',
      emoji: '🐕',
      icon: Icons.pets,
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFEF3C7),
      subcategories: [
        TransactionSubcategory(id: 'sub_pet_food', name: 'Pet Food', emoji: '🥩', icon: Icons.set_meal),
        TransactionSubcategory(id: 'sub_pet_vet', name: 'Veterinary / Dokter', emoji: '🩺', icon: Icons.medical_services),
        TransactionSubcategory(id: 'sub_pet_supplies', name: 'Grooming & Toys', emoji: '🎾', icon: Icons.sports_baseball),
      ],
    ),
    TransactionCategory(
      id: 'exp_family',
      name: 'Family',
      group: 'HOUSEHOLD NEEDS',
      emoji: '👨‍👩‍👧',
      icon: Icons.diversity_3,
      color: Color(0xFF9333EA),
      bgColor: Color(0xFFF3E8FF),
      subcategories: [
        TransactionSubcategory(id: 'sub_fam_children', name: 'Childcare & Needs', emoji: '🍼', icon: Icons.child_care),
        TransactionSubcategory(id: 'sub_fam_parents', name: 'Allowance to Parents', emoji: '👵', icon: Icons.elderly),
        TransactionSubcategory(id: 'sub_fam_events', name: 'Family Events', emoji: '🎂', icon: Icons.cake),
      ],
    ),

    // PERSONAL NEEDS
    TransactionCategory(
      id: 'exp_shopping',
      name: 'Shopping',
      group: 'PERSONAL NEEDS',
      emoji: '🛍️',
      icon: Icons.shopping_bag,
      color: Color(0xFFDB2777),
      bgColor: Color(0xFFFCE7F3),
      subcategories: [
        TransactionSubcategory(id: 'sub_shop_clothes', name: 'Clothing & Fashion', emoji: '👕', icon: Icons.checkroom),
        TransactionSubcategory(id: 'sub_shop_electronics', name: 'Electronics & Gadgets', emoji: '🎧', icon: Icons.devices),
        TransactionSubcategory(id: 'sub_shop_beauty', name: 'Beauty & Skincare', emoji: '💄', icon: Icons.face),
        TransactionSubcategory(id: 'sub_shop_shoes', name: 'Shoes & Accessories', emoji: '👟', icon: Icons.snowshoeing),
      ],
    ),
    TransactionCategory(
      id: 'exp_health',
      name: 'Health & Sports',
      group: 'PERSONAL NEEDS',
      emoji: '🏋️',
      icon: Icons.fitness_center,
      color: Color(0xFFE11D48),
      bgColor: Color(0xFFFFE4E6),
      subcategories: [
        TransactionSubcategory(id: 'sub_health_doctor', name: 'Doctor & Hospital', emoji: '🏥', icon: Icons.local_hospital),
        TransactionSubcategory(id: 'sub_health_medicine', name: 'Medicine & Pharmacy', emoji: '💊', icon: Icons.medication),
        TransactionSubcategory(id: 'sub_health_gym', name: 'Gym & Fitness Membership', emoji: '💪', icon: Icons.sports_gymnastics),
        TransactionSubcategory(id: 'sub_health_gear', name: 'Sports Equipment', emoji: '⚽', icon: Icons.sports_soccer),
      ],
    ),
    TransactionCategory(
      id: 'exp_donations',
      name: 'Donations & Gifts',
      group: 'PERSONAL NEEDS',
      emoji: '🤲',
      icon: Icons.volunteer_activism,
      color: Color(0xFFCA8A04),
      bgColor: Color(0xFFFEF08A),
      subcategories: [
        TransactionSubcategory(id: 'sub_don_charity', name: 'Charity & Infaq', emoji: '🕌', icon: Icons.favorite),
        TransactionSubcategory(id: 'sub_don_gifts', name: 'Gifts & Presents', emoji: '🎁', icon: Icons.card_giftcard),
        TransactionSubcategory(id: 'sub_don_zakat', name: 'Zakat', emoji: '🌾', icon: Icons.spa),
      ],
    ),
    TransactionCategory(
      id: 'exp_travel',
      name: 'Travel',
      group: 'PERSONAL NEEDS',
      emoji: '✈️',
      icon: Icons.flight,
      color: Color(0xFF0891B2),
      bgColor: Color(0xFFCFFAFE),
      subcategories: [
        TransactionSubcategory(id: 'sub_trv_ticket', name: 'Flight & Train Tickets', emoji: '🎫', icon: Icons.confirmation_number),
        TransactionSubcategory(id: 'sub_trv_hotel', name: 'Hotel & Lodging', emoji: '🏨', icon: Icons.hotel),
        TransactionSubcategory(id: 'sub_trv_tours', name: 'Attractions & Tours', emoji: '🏖️', icon: Icons.beach_access),
      ],
    ),
    TransactionCategory(
      id: 'exp_entertainment',
      name: 'Entertainment',
      group: 'PERSONAL NEEDS',
      emoji: '🍿',
      icon: Icons.movie,
      color: Color(0xFFC026D3),
      bgColor: Color(0xFFFAE8FF),
      subcategories: [
        TransactionSubcategory(id: 'sub_ent_cinema', name: 'Cinema & Movies', emoji: '🎬', icon: Icons.theaters),
        TransactionSubcategory(id: 'sub_ent_gaming', name: 'Games & Top-up', emoji: '🎮', icon: Icons.sports_esports),
        TransactionSubcategory(id: 'sub_ent_concert', name: 'Concerts & Events', emoji: '🎸', icon: Icons.music_note),
        TransactionSubcategory(id: 'sub_ent_hobbies', name: 'Hobbies & Crafts', emoji: '🎨', icon: Icons.palette),
      ],
    ),
    TransactionCategory(
      id: 'exp_education',
      name: 'Education',
      group: 'PERSONAL NEEDS',
      emoji: '📚',
      icon: Icons.school,
      color: Color(0xFF2563EB),
      bgColor: Color(0xFFDBEAFE),
      subcategories: [
        TransactionSubcategory(id: 'sub_edu_courses', name: 'Courses & Certification', emoji: '💻', icon: Icons.menu_book),
        TransactionSubcategory(id: 'sub_edu_books', name: 'Books & Stationery', emoji: '📖', icon: Icons.auto_stories),
        TransactionSubcategory(id: 'sub_edu_tuition', name: 'Tuition / SPP', emoji: '🎓', icon: Icons.workspace_premium),
      ],
    ),

    // FINANCE
    TransactionCategory(
      id: 'exp_loans',
      name: 'Loans',
      group: 'FINANCE',
      emoji: '🏛️',
      icon: Icons.account_balance,
      color: Color(0xFF475569),
      bgColor: Color(0xFFE2E8F0),
      subcategories: [
        TransactionSubcategory(id: 'sub_loan_mortgage', name: 'Mortgage / KPR', emoji: '🏡', icon: Icons.house),
        TransactionSubcategory(id: 'sub_loan_vehicle', name: 'Vehicle Installment', emoji: '🚗', icon: Icons.directions_car),
        TransactionSubcategory(id: 'sub_loan_personal', name: 'Personal Loan', emoji: '📄', icon: Icons.assignment),
        TransactionSubcategory(id: 'sub_loan_cc', name: 'Credit Card Bill', emoji: '💳', icon: Icons.credit_card),
      ],
    ),
    TransactionCategory(
      id: 'exp_investment',
      name: 'Investment',
      group: 'FINANCE',
      emoji: '🪴',
      icon: Icons.trending_up,
      color: Color(0xFF047857),
      bgColor: Color(0xFFA7F3D0),
      subcategories: [
        TransactionSubcategory(id: 'sub_inv_stocks', name: 'Stocks / Saham', emoji: '📈', icon: Icons.show_chart),
        TransactionSubcategory(id: 'sub_inv_mutual', name: 'Mutual Funds / Reksadana', emoji: '📊', icon: Icons.bar_chart),
        TransactionSubcategory(id: 'sub_inv_crypto', name: 'Crypto Assets', emoji: '🪙', icon: Icons.currency_bitcoin),
        TransactionSubcategory(id: 'sub_inv_gold', name: 'Gold / Emas', emoji: '🥇', icon: Icons.military_tech),
      ],
    ),
    TransactionCategory(
      id: 'exp_business',
      name: 'Business',
      group: 'FINANCE',
      emoji: '💼',
      icon: Icons.business_center,
      color: Color(0xFF64748B),
      bgColor: Color(0xFFF1F5F9),
      subcategories: [
        TransactionSubcategory(id: 'sub_biz_ops', name: 'Operations & Utilities', emoji: '⚙️', icon: Icons.settings),
        TransactionSubcategory(id: 'sub_biz_inventory', name: 'Inventory & Supplies', emoji: '📦', icon: Icons.inventory_2),
        TransactionSubcategory(id: 'sub_biz_marketing', name: 'Marketing & Ads', emoji: '📢', icon: Icons.campaign),
      ],
    ),
    TransactionCategory(
      id: 'exp_other_financial',
      name: 'Other Financial Expenses',
      group: 'FINANCE',
      emoji: '🏷️',
      icon: Icons.request_quote,
      color: Color(0xFF78716C),
      bgColor: Color(0xFFE7E5E4),
      subcategories: [
        TransactionSubcategory(id: 'sub_fin_admin', name: 'Bank Admin Fees', emoji: '🏧', icon: Icons.atm),
        TransactionSubcategory(id: 'sub_fin_tax', name: 'Taxes / Pajak', emoji: '📑', icon: Icons.gavel),
        TransactionSubcategory(id: 'sub_fin_insurance', name: 'Insurance Premium', emoji: '🛡️', icon: Icons.security),
      ],
    ),

    // SERVICES
    TransactionCategory(
      id: 'exp_services',
      name: 'Other Services',
      group: 'SERVICES',
      emoji: '⚙️',
      icon: Icons.miscellaneous_services,
      color: Color(0xFF0F766E),
      bgColor: Color(0xFFCCFBF1),
      subcategories: [
        TransactionSubcategory(id: 'sub_srv_laundry', name: 'Laundry', emoji: '🧺', icon: Icons.local_laundry_service),
        TransactionSubcategory(id: 'sub_srv_salon', name: 'Salon & Barbershop', emoji: '✂️', icon: Icons.content_cut),
        TransactionSubcategory(id: 'sub_srv_repair', name: 'Repair & Tech Services', emoji: '🛠️', icon: Icons.build_circle),
        TransactionSubcategory(id: 'sub_srv_courier', name: 'Courier & Postage', emoji: '📦', icon: Icons.local_shipping),
      ],
    ),

    // OTHERS
    TransactionCategory(
      id: 'exp_others',
      name: 'Others',
      group: 'OTHERS',
      emoji: '🤔',
      icon: Icons.more_horiz,
      color: Color(0xFF6B7280),
      bgColor: Color(0xFFF3F4F6),
      subcategories: [
        TransactionSubcategory(id: 'sub_oth_general', name: 'General Uncategorized', emoji: '📝', icon: Icons.edit_note),
      ],
    ),
  ];

  static TransactionCategory? findCategory(String name) {
    final lower = name.toLowerCase().trim();
    for (final cat in expenseCategories) {
      if (cat.name.toLowerCase().trim() == lower) return cat;
    }
    for (final cat in incomeCategories) {
      if (cat.name.toLowerCase().trim() == lower) return cat;
    }
    return null;
  }

  static TransactionCategoryDisplay getCategoryDisplay(String categoryStr) {
    final clean = categoryStr.trim();
    if (clean.toLowerCase() == 'transfer') {
      return const TransactionCategoryDisplay(
        emoji: '🔄',
        icon: Icons.swap_horiz,
        color: Color(0xFF0F758A),
        bgColor: Color(0xFFE0F2FE),
        mainCategory: 'Transfer',
      );
    }

    final parts = clean.contains('•')
        ? clean.split('•')
        : (clean.contains('-') ? clean.split('-') : [clean]);

    final mainPart = parts.first.trim();
    final subPart = parts.length > 1 ? parts[1].trim() : null;

    final mainCat = findCategory(mainPart) ?? findCategory(clean);

    if (mainCat != null) {
      if (subPart != null) {
        final sub = mainCat.subcategories.where(
          (s) => s.name.toLowerCase() == subPart.toLowerCase(),
        ).firstOrNull;

        if (sub != null) {
          return TransactionCategoryDisplay(
            emoji: sub.emoji,
            icon: sub.icon,
            color: mainCat.color,
            bgColor: mainCat.bgColor,
            mainCategory: mainCat.name,
            subcategory: sub.name,
          );
        }
      }

      return TransactionCategoryDisplay(
        emoji: mainCat.emoji,
        icon: mainCat.icon,
        color: mainCat.color,
        bgColor: mainCat.bgColor,
        mainCategory: mainCat.name,
        subcategory: subPart,
      );
    }

    return const TransactionCategoryDisplay(
      emoji: '💳',
      icon: Icons.receipt_long,
      color: Color(0xFF4B5563),
      bgColor: Color(0xFFF3F4F6),
      mainCategory: 'Transaksi',
    );
  }
}

class TransactionCategoryDisplay {
  final String emoji;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String mainCategory;
  final String? subcategory;

  const TransactionCategoryDisplay({
    required this.emoji,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.mainCategory,
    this.subcategory,
  });

  String get displayName =>
      subcategory != null ? '$mainCategory • $subcategory' : mainCategory;
}
