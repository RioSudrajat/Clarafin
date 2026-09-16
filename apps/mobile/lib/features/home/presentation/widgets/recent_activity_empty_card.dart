import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class RecentActivityEmptyCard extends StatelessWidget {
  const RecentActivityEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: NeoBrutalism.shadow(yOffset: 3),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: NeoBrutalism.lime,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: NeoBrutalism.shadow(yOffset: 2),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 24,
              color: NeoBrutalism.dark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Transaksi',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: NeoBrutalism.dark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Catat pemasukan atau pengeluaran pertamamu untuk mulai mengelola keuangan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: NeoBrutalism.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/transaction/entry'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: NeoBrutalism.lime,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: NeoBrutalism.shadow(yOffset: 2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: NeoBrutalism.dark),
                  SizedBox(width: 6),
                  Text(
                    'Tambah Transaksi',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
