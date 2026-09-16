import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class SessionFilterTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const SessionFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const List<String> tabs = ['Semua', 'Aktif', 'Selesai', 'Batal'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == tabs.length - 1 ? 0 : 4,
              ),
              child: InkWell(
                onTap: () => onSelect(index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? NeoBrutalism.lime : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black,
                      width: isSelected ? 2.0 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(0, 2),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
