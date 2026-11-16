import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../../budget/presentation/providers/finance_providers.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

import '../widgets/onboarding_input_field.dart';
import '../widgets/onboarding_step_header.dart';

class OnboardingWalletGoalScreen extends ConsumerStatefulWidget {
  const OnboardingWalletGoalScreen({super.key});

  @override
  ConsumerState<OnboardingWalletGoalScreen> createState() => _OnboardingWalletGoalScreenState();
}

class _OnboardingWalletGoalScreenState extends ConsumerState<OnboardingWalletGoalScreen> {
  String _selectedCurrency = 'IDR';
  String _selectedWalletType = 'Bank';
  late final TextEditingController _walletNameController;
  late final TextEditingController _balanceController;
  String _selectedGoalId = '';

  static const List<Map<String, String>> _walletCategories = [
    {'id': 'Bank', 'name': 'BCA Rekening Utama'},
    {'id': 'E-Wallet', 'name': 'GoPay Utama'},
    {'id': 'Cash', 'name': 'Uang Tunai'},
    {'id': 'Investasi', 'name': 'Portofolio Bibit'},
  ];

  static const List<String> _currencies = ['IDR', 'USD', 'SGD', 'MYR', 'EUR', 'JPY'];

  @override
  void initState() {
    super.initState();
    _walletNameController = TextEditingController();
    _balanceController = TextEditingController();
    _selectedGoalId = '';
    
    // Read user's current currency if set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userCurrency = ref.read(userProfileProvider).currency;
      if (userCurrency.isNotEmpty && _currencies.contains(userCurrency)) {
        setState(() {
          _selectedCurrency = userCurrency;
        });
      }
    });
  }

  List<Map<String, dynamic>> _getGoalOptions() {
    final goals = [
      {
        'id': 'emergency_fund',
        'title': 'Dana Darurat 6 Bulan',
        'targetIdr': 30000000.0,
        'tag': 'Fondasi rasa aman',
        'icon': Icons.shield_outlined,
      },
      {
        'id': 'couple_goal',
        'title': 'Tabungan Nikah & Rumah',
        'targetIdr': 50000000.0,
        'tag': 'Persiapan berkeluarga',
        'icon': Icons.favorite_border_rounded,
      },
      {
        'id': 'umkm_goal',
        'title': 'Modal Ekspansi Usaha',
        'targetIdr': 25000000.0,
        'tag': 'Dana operasional bisnis',
        'icon': Icons.storefront_outlined,
      },
      {
        'id': 'invest_goal',
        'title': 'Portofolio Investasi Pertama',
        'targetIdr': 20000000.0,
        'tag': 'Reksadana & SBN',
        'icon': Icons.trending_up_rounded,
      },
      {
        'id': 'fire_goal',
        'title': 'Target Pensiun Dini (FIRE)',
        'targetIdr': 100000000.0,
        'tag': 'Kebebasan finansial',
        'icon': Icons.diamond_outlined,
      },
    ];

    return goals.map((g) {
      final targetIdr = g['targetIdr'] as double;
      final formatted = CurrencyFormatter.format(targetIdr, currencyCode: _selectedCurrency);
      return {
        'id': g['id'],
        'title': g['title'],
        'targetIdr': targetIdr,
        'desc': '$formatted • ${g['tag']}',
        'icon': g['icon'],
      };
    }).toList();
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _onCurrencySelected(String currency) {
    setState(() {
      _selectedCurrency = currency;
    });
    ref.read(userProfileProvider.notifier).setCurrency(currency);
  }

  void _handleContinue() {
    final name = _walletNameController.text.trim();
    final balanceDigits = _balanceController.text.replaceAll(RegExp(r'\D'), '').trim();
    final enteredAmount = double.tryParse(balanceDigits) ?? 2500000.0;

    // Convert input nominal to base IDR using exchange rate
    final rate = CurrencyFormatter.ratesToIdr[_selectedCurrency] ?? 1.0;
    final idrBalance = _selectedCurrency == 'IDR' ? enteredAmount : enteredAmount * rate;

    final walletName = name.isNotEmpty ? name : 'Dompet Utama ($_selectedWalletType)';
    final wallet = WalletModel(
      id: 'w_init_${DateTime.now().millisecondsSinceEpoch}',
      name: walletName,
      type: _selectedWalletType,
      balance: idrBalance,
    );
    ref.read(walletsProvider.notifier).addWallet(wallet);

    final goalOpts = _getGoalOptions();
    final chosenGoal = goalOpts.firstWhere(
      (g) => g['id'] == _selectedGoalId,
      orElse: () => goalOpts.first,
    );
    final targetIdr = (chosenGoal['targetIdr'] as double?) ?? 30000000.0;

    final newGoal = GoalModel(
      id: 'g_init_${DateTime.now().millisecondsSinceEpoch}',
      name: chosenGoal['title'] as String,
      targetAmount: targetIdr,
      savedAmount: 0.0,
      targetDate: DateTime.now().add(const Duration(days: 180)),
      icon: chosenGoal['icon'] as IconData,
      tagColor: NeoBrutalism.mint,
      tagTextColor: Colors.black,
      priority: 'Urgent',
      sourceAsset: name.isNotEmpty ? name : 'Dompet Utama',
    );
    ref.read(goalsProvider.notifier).addGoal(newGoal);

    context.go('/onboarding/daily-ritual');
  }

  @override
  Widget build(BuildContext context) {
    final goalOptions = _getGoalOptions();
    final currSymbol = CurrencyFormatter.getSymbol(_selectedCurrency);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingStepHeader(
                step: 5,
                totalSteps: 6,
                title: 'Siapkan Dompet & Target Pertamamu',
                subtitle: 'Biar Beranda langsung terisi dan siap digunakan begitu selesai.',
                onBack: () => context.go('/onboarding/advisory-focus'),
                onSkip: () => context.go('/onboarding/daily-ritual'),
              ),
              const SizedBox(height: 18),

              // Currency Selector Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
                  border: NeoBrutalism.border(width: 2.0),
                  boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.currency_exchange_rounded, size: 20, color: NeoBrutalism.teal),
                        const SizedBox(width: 8),
                        Text(
                          'PILIH MATA UANG UTAMA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Semua pencatatan, kalkulasi kurs, & target akan disesuaikan.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currencies.map((curr) {
                        final isSel = _selectedCurrency == curr;
                        final symbol = CurrencyFormatter.getSymbol(curr).trim();
                        return GestureDetector(
                          onTap: () => _onCurrencySelected(curr),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? NeoBrutalism.lime : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: NeoBrutalism.border(width: isSel ? 2.0 : 1.5),
                              boxShadow: isSel ? NeoBrutalism.shadow(yOffset: 2.0) : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  symbol,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: NeoBrutalism.dark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  curr,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                                    color: NeoBrutalism.dark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Wallet Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
                  border: NeoBrutalism.border(width: 2.0),
                  boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, size: 20, color: NeoBrutalism.teal),
                        const SizedBox(width: 8),
                        Text(
                          'DOMPET UTAMA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _walletCategories.map((cat) {
                        final isSel = _selectedWalletType == cat['id'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedWalletType = cat['id']!;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? NeoBrutalism.lime : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: NeoBrutalism.border(width: 1.5),
                            ),
                            child: Text(
                              cat['id']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: NeoBrutalism.dark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    OnboardingInputField(
                      label: 'Nama Akun / Dompet',
                      hintText: 'cth: BCA Rekening Utama',
                      controller: _walletNameController,
                    ),
                    const SizedBox(height: 10),
                    OnboardingInputField(
                      label: 'Saldo Awal Saat Ini',
                      hintText: _selectedCurrency == 'IDR' ? 'cth: 2.500.000' : 'cth: 2.500',
                      controller: _balanceController,
                      prefixText: currSymbol.endsWith(' ') ? currSymbol : '$currSymbol ',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandSeparatorFormatter(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Goal Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
                  border: NeoBrutalism.border(width: 2.0),
                  boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flag_rounded, size: 20, color: NeoBrutalism.teal),
                        const SizedBox(width: 8),
                        Text(
                          'TARGET IMPIAN PERTAMA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...goalOptions.map((goal) {
                      final isSel = _selectedGoalId == goal['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedGoalId = goal['id'] as String),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? NeoBrutalism.mint : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: NeoBrutalism.border(width: isSel ? 2.0 : 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(goal['icon'] as IconData, size: 18, color: NeoBrutalism.dark),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal['title'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: NeoBrutalism.dark,
                                      ),
                                    ),
                                    Text(
                                      goal['desc'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSel)
                                const Icon(Icons.check_circle_rounded, size: 18, color: NeoBrutalism.dark),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Button
              GestureDetector(
                onTap: _handleContinue,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: NeoBrutalism.lime,
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
                    border: NeoBrutalism.border(width: 2.0),
                    boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lanjut ke Ritme Harian',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: NeoBrutalism.dark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
