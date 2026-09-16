import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class ExportFormatSelector extends StatelessWidget {
  final String selectedFormat;
  final ValueChanged<String> onFormatChanged;

  const ExportFormatSelector({
    super.key,
    required this.selectedFormat,
    required this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formats = [
      {'id': 'PDF', 'title': 'PDF', 'desc': 'Dokumen rapi siap cetak', 'icon': Icons.picture_as_pdf_outlined},
      {'id': 'Excel', 'title': 'Excel', 'desc': 'Spreadsheet format .xlsx', 'icon': Icons.table_chart_outlined},
      {'id': 'CSV', 'title': 'CSV', 'desc': 'Data mentah terpisah koma', 'icon': Icons.list_alt_rounded},
      {'id': 'JSON', 'title': 'JSON', 'desc': 'Cadangan data terstruktur', 'icon': Icons.code_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Format Dokumen',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 74,
          ),
          itemCount: formats.length,
          itemBuilder: (context, index) {
            final f = formats[index];
            final isSelected = selectedFormat == f['id'];

            return GestureDetector(
              onTap: () => onFormatChanged(f['id'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? NeoBrutalism.lime : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset: isSelected ? const Offset(0, 2.5) : const Offset(0, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(f['icon'] as IconData, size: 22, color: Colors.black),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            f['title'] as String,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f['desc'] as String,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
