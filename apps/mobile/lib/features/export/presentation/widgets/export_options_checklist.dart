import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class ExportOptionsChecklist extends StatelessWidget {
  final Map<String, bool> selectedOptions;
  final Function(String, bool) onOptionToggled;

  const ExportOptionsChecklist({
    super.key,
    required this.selectedOptions,
    required this.onOptionToggled,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'key': 'transactions', 'title': 'Mutasi Transaksi & Akun Dompet', 'desc': 'Pemasukan, pengeluaran, dan transfer saldo'},
      {'key': 'bills', 'title': 'Catatan Tagihan Rutin & Bills', 'desc': 'Status lunas/jatuh tempo dan riwayat pembayaran'},
      {'key': 'goals', 'title': 'Progres Rencana Tabungan (Goals)', 'desc': 'Target terkumpul dan proyeksi pencapaian'},
      {'key': 'consultations', 'title': 'Catatan Rekap Konsultasi', 'desc': 'Rekomendasi tertulis dari perencana keuangan'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cakupan Data yang Disertakan',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 2.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: items.map((it) {
              final isChecked = selectedOptions[it['key']] ?? false;
              final isLast = it == items.last;

              return Column(
                children: [
                  InkWell(
                    onTap: () => onOptionToggled(it['key']!, !isChecked),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isChecked ? NeoBrutalism.lime : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black, width: 2.0),
                            ),
                            child: isChecked
                                ? const Icon(Icons.check, size: 16, color: Colors.black)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it['title']!,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  it['desc']!,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
