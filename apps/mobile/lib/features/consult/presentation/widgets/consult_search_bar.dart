import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/consult_list_provider.dart';

class ConsultSearchBar extends ConsumerStatefulWidget {
  const ConsultSearchBar({super.key});

  @override
  ConsumerState<ConsultSearchBar> createState() => _ConsultSearchBarState();
}

class _ConsultSearchBarState extends ConsumerState<ConsultSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(consultSearchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuery = ref.watch(consultSearchQueryProvider);
    if (_controller.text != currentQuery) {
      _controller.text = currentQuery;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: NeoBrutalism.border(),
          boxShadow: NeoBrutalism.shadow(yOffset: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 22, color: NeoBrutalism.dark),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (val) {
                  ref.read(consultSearchQueryProvider.notifier).setQuery(val);
                },
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: NeoBrutalism.dark,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search consultant...',
                  hintStyle: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (currentQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  ref.read(consultSearchQueryProvider.notifier).setQuery('');
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.cancel, size: 18, color: NeoBrutalism.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
