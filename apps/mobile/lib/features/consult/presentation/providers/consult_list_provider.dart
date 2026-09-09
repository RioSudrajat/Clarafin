import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/consultant.dart';

/// Categories available for filtering matching user reference image
const List<String> consultCategories = [
  'All',
  'Tax',
  'Investment',
  'Insurance',
  'Debt',
  'Business',
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
  String build() => 'All';

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
    if (category != 'All') {
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
    case 'Tax':
      return allText.contains('tax') ||
          allText.contains('pajak') ||
          allText.contains('spt');
    case 'Investment':
      return allText.contains('investment') ||
          allText.contains('investasi') ||
          allText.contains('saham') ||
          allText.contains('reksadana') ||
          allText.contains('crypto') ||
          allText.contains('portfolio') ||
          allText.contains('fire') ||
          allText.contains('wealth');
    case 'Insurance':
      return allText.contains('insurance') ||
          allText.contains('asuransi') ||
          allText.contains('dana darurat');
    case 'Debt':
      return allText.contains('debt') ||
          allText.contains('hutang') ||
          allText.contains('pinjol') ||
          allText.contains('restrukturisasi');
    case 'Business':
      return allText.contains('business') ||
          allText.contains('bisnis') ||
          allText.contains('umkm') ||
          allText.contains('korporat');
    default:
      return true;
  }
}
