import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/institutions/institution_model.dart';
import '../../../../core/institutions/institution_registry.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/add_wallet_search_header.dart';
import '../widgets/wallet_institution_item.dart';
import '../widgets/wallet_sync_choice_sheet.dart';
import 'manual_wallet_entry_screen.dart';

class AddWalletInstitutionScreen extends StatefulWidget {
  const AddWalletInstitutionScreen({super.key});

  @override
  State<AddWalletInstitutionScreen> createState() => _AddWalletInstitutionScreenState();
}

class _AddWalletInstitutionScreenState extends State<AddWalletInstitutionScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<InstitutionModel> _banks = InstitutionRegistry.popularBanks;
  final List<InstitutionModel> _ewallets = InstitutionRegistry.ewallets;
  final List<InstitutionModel> _investments = InstitutionRegistry.investments;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onInstitutionTap(InstitutionModel inst) {
    if (inst.supportsAutoSync) {
      WalletSyncChoiceSheet.show(context: context, institution: inst);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManualWalletEntryScreen(
            institutionId: inst.id,
            institutionName: inst.name,
            institutionType: inst.type,
          ),
        ),
      );
    }
  }

  void _openManualEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ManualWalletEntryScreen(
          institutionName: '',
          institutionType: 'Bank',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Tambah Dompet Baru',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: NeoBrutalism.dark,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: NeoBrutalism.circleDecoration(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: NeoBrutalism.dark, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          AddWalletSearchHeader(
            searchController: _searchController,
            searchQuery: _searchQuery,
            selectedCategory: _selectedCategory,
            onSearchChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
            onManualEntryTap: _openManualEntry,
            onClearSearch: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          const SizedBox(height: 20),
          ..._buildInstitutionSections(),
        ],
      ),
    );
  }

  List<Widget> _buildInstitutionSections() {
    final showBank = _selectedCategory == 'Semua' || _selectedCategory == 'Bank';
    final showEWallet = _selectedCategory == 'Semua' || _selectedCategory == 'E-Wallet';
    final showInvest = _selectedCategory == 'Semua' || _selectedCategory == 'Investasi';

    final widgets = <Widget>[];
    if (showBank) widgets.addAll(_filterAndBuildGroup('Bank Populer', _banks));
    if (showEWallet) widgets.addAll(_filterAndBuildGroup('E-Wallet', _ewallets));
    if (showInvest) widgets.addAll(_filterAndBuildGroup('Investasi & Aset', _investments));

    if (widgets.isEmpty) {
      widgets.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Tidak ada institusi yang cocok dengan pencarian.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: NeoBrutalism.textMuted,
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _filterAndBuildGroup(String title, List<InstitutionModel> items) {
    final filtered = items.where((i) {
      if (_searchQuery.isEmpty) return true;
      return i.name.toLowerCase().contains(_searchQuery) ||
          i.shortName.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: NeoBrutalism.textMuted,
          ),
        ),
      ),
      ...filtered.map((inst) => WalletInstitutionItem(
            institution: inst,
            onTap: () => _onInstitutionTap(inst),
          )),
      const SizedBox(height: 12),
    ];
  }
}
