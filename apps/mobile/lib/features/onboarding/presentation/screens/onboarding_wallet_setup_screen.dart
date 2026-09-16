import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/onboarding_input_field.dart';
import '../widgets/onboarding_step_header.dart';
import '../widgets/onboarding_wallet_type_card.dart';

class OnboardingWalletSetupScreen extends StatefulWidget {
  const OnboardingWalletSetupScreen({super.key});

  @override
  State<OnboardingWalletSetupScreen> createState() => _OnboardingWalletSetupScreenState();
}

class _OnboardingWalletSetupScreenState extends State<OnboardingWalletSetupScreen> {
  String _selectedType = 'Bank';
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  static const List<Map<String, dynamic>> _types = [
    {
      'id': 'Bank',
      'label': 'Rekening Bank',
      'desc': 'BCA, Mandiri, BRI, BNI & lainnya',
      'icon': Icons.account_balance_outlined,
      'defaultName': 'BCA Rekening Utama',
    },
    {
      'id': 'E-Wallet',
      'label': 'Dompet Digital',
      'desc': 'GoPay, OVO, ShopeePay, DANA',
      'icon': Icons.wallet_outlined,
      'defaultName': 'GoPay Utama',
    },
    {
      'id': 'Cash',
      'label': 'Uang Tunai (Cash)',
      'desc': 'Uang fisik di dompet atau brankas',
      'icon': Icons.payments_outlined,
      'defaultName': 'Kas Tunai Dompet',
    },
    {
      'id': 'Investasi',
      'label': 'Investasi & Tabungan',
      'desc': 'Bibit, Stockbit, Deposito',
      'icon': Icons.trending_up_outlined,
      'defaultName': 'Portofolio Bibit',
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'BCA Rekening Utama');
    _balanceController = TextEditingController(text: '2.500.000');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _selectType(String id, String defaultName) {
    setState(() {
      _selectedType = id;
      _nameController.text = defaultName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingStepHeader(
                step: 1,
                totalSteps: 2,
                title: 'Setup Dompet Utama',
                subtitle: 'Pilih sumber dana utamamu untuk memulai pencatatan finansial teratur.',
                onBack: () => context.pop(),
                onSkip: () => context.go('/onboarding/goal'),
              ),
              const SizedBox(height: 20),
              Text(
                'PILIH KATEGORI AKUN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: NeoBrutalism.dark,
                ),
              ),
              const SizedBox(height: 10),
              ..._types.map((type) {
                final isSelected = _selectedType == type['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OnboardingWalletTypeCard(
                    label: type['label'] as String,
                    description: type['desc'] as String,
                    icon: type['icon'] as IconData,
                    isSelected: isSelected,
                    onTap: () => _selectType(type['id'] as String, type['defaultName'] as String),
                  ),
                );
              }),
              const SizedBox(height: 12),
              OnboardingInputField(
                label: 'NAMA DOMPET / AKUN',
                controller: _nameController,
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 14),
              OnboardingInputField(
                label: 'SALDO SAAT INI',
                controller: _balanceController,
                prefixText: 'Rp ',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              _buildSubmitButton(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: NeoBrutalism.lime,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
          border: NeoBrutalism.border(width: 2.0),
          boxShadow: NeoBrutalism.shadow(yOffset: 3.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
            onTap: () => context.go('/onboarding/goal'),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lanjut ke Goals',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.dark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18, color: NeoBrutalism.dark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
