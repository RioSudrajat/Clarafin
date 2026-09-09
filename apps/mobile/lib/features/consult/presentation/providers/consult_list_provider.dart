import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/consultant.dart';

/// Categories available for filtering
const List<String> consultCategories = [
  'Semua',
  'Cashflow & Budgeting',
  'Investasi & Saham',
  'Pajak & Bisnis',
  'Hutang & Pinjol',
  'Keluarga & KPR',
];

/// Search query notifier
class ConsultSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final consultSearchQueryProvider =
    NotifierProvider<ConsultSearchQueryNotifier, String>(() {
  return ConsultSearchQueryNotifier();
});

/// Selected category notifier
class ConsultSelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'Semua';

  void setCategory(String category) => state = category;
}

final consultSelectedCategoryProvider =
    NotifierProvider<ConsultSelectedCategoryNotifier, String>(() {
  return ConsultSelectedCategoryNotifier();
});

/// All consultants list provider
final consultantsListProvider = Provider<List<Consultant>>((ref) {
  return ConsultantRepository.initialConsultants;
});

/// Filtered consultants provider combining search and category
final filteredConsultantsProvider = Provider<List<Consultant>>((ref) {
  final all = ref.watch(consultantsListProvider);
  final query = ref.watch(consultSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(consultSelectedCategoryProvider);

  return all.where((c) {
    // Category match
    if (category != 'Semua') {
      final matchesCategory = _matchesCategory(c, category);
      if (!matchesCategory) return false;
    }

    // Query match
    if (query.isNotEmpty) {
      final nameMatches = c.name.toLowerCase().contains(query);
      final titleMatches = c.title.toLowerCase().contains(query);
      final credMatches = c.credentials.toLowerCase().contains(query);
      final locMatches = c.location.toLowerCase().contains(query);
      final tagMatches =
          c.specializations.any((s) => s.toLowerCase().contains(query));

      if (!nameMatches &&
          !titleMatches &&
          !credMatches &&
          !locMatches &&
          !tagMatches) {
        return false;
      }
    }

    return true;
  }).toList();
});

bool _matchesCategory(Consultant c, String category) {
  final allText = '${c.title} ${c.specializations.join(" ")}'.toLowerCase();
  switch (category) {
    case 'Cashflow & Budgeting':
      return allText.contains('cashflow') ||
          allText.contains('budgeting') ||
          allText.contains('dana darurat') ||
          allText.contains('arus kas');
    case 'Investasi & Saham':
      return allText.contains('investasi') ||
          allText.contains('saham') ||
          allText.contains('reksadana') ||
          allText.contains('crypto') ||
          allText.contains('portfolio') ||
          allText.contains('fire');
    case 'Pajak & Bisnis':
      return allText.contains('pajak') ||
          allText.contains('bisnis') ||
          allText.contains('umkm') ||
          allText.contains('korporat');
    case 'Hutang & Pinjol':
      return allText.contains('hutang') ||
          allText.contains('pinjol') ||
          allText.contains('restrukturisasi') ||
          allText.contains('debt');
    case 'Keluarga & KPR':
      return allText.contains('keluarga') ||
          allText.contains('kpr') ||
          allText.contains('pendidikan') ||
          allText.contains('pensiun') ||
          allText.contains('pasangan') ||
          allText.contains('warisan');
    default:
      return true;
  }
}
