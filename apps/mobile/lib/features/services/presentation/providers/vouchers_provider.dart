import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/voucher_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class VouchersNotifier extends Notifier<List<VoucherModel>> {
  @override
  List<VoucherModel> build() {
    return const [
      VoucherModel(
        id: 'vouch_1',
        code: 'CLARAFIN50',
        title: 'Diskon 50% Sesi Pertama',
        description:
            'Hemat separuh harga untuk sesi konsultasi 1-on-1 pertamamu dengan perencana keuangan bersertifikasi.',
        discountHighlight: 'DISKON 50%',
        validUntil: '30 Sep 2026',
        category: 'counseling',
        minTransaction: 'Min. transaksi Rp 150.000',
        accentColor: NeoBrutalism.lime,
      ),
      VoucherModel(
        id: 'vouch_2',
        code: 'FREE15MIN',
        title: 'Gratis 15 Menit Discovery',
        description:
            'Konseling perkenalan bebas biaya untuk evaluasi cepat kebutuhan finansial dan pencocokan perencana tepat.',
        discountHighlight: 'GRATIS 15 MNT',
        validUntil: '31 Des 2026',
        category: 'counseling',
        minTransaction: 'Khusus pengguna baru',
        accentColor: Color(0xFFD1FAE5),
      ),
      VoucherModel(
        id: 'vouch_3',
        code: 'INVESTASI100',
        title: 'Cashback Reksadana Rp 100.000',
        description:
            'Dapatkan bonus saldo investasi reksadana pasar uang setelah menyelesaikan sesi review portofolio.',
        discountHighlight: 'CASHBACK 100RB',
        validUntil: '15 Okt 2026',
        category: 'investment',
        minTransaction: 'Min. alokasi Rp 500.000',
        accentColor: Color(0xFFFEF3C7),
      ),
      VoucherModel(
        id: 'vouch_4',
        code: 'KELUARGA25',
        title: 'Diskon 25% Paket Keluarga',
        description:
            'Perencanaan dana pendidikan buah hati dan proteksi asuransi keluarga bersama konsultan senior.',
        discountHighlight: 'DISKON 25%',
        validUntil: '30 Nov 2026',
        category: 'counseling',
        minTransaction: 'Min. sesi 60 menit',
        accentColor: Color(0xFFEDE9FE),
      ),
    ];
  }

  void claimVoucher(String code) {
    state = [
      for (final v in state)
        if (v.code == code) v.copyWith(isClaimed: true) else v
    ];
  }
}

final vouchersProvider =
    NotifierProvider<VouchersNotifier, List<VoucherModel>>(() {
  return VouchersNotifier();
});

class SelectedVoucherCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setCategory(String category) => state = category;
}

final selectedVoucherCategoryProvider =
    NotifierProvider<SelectedVoucherCategoryNotifier, String>(() {
  return SelectedVoucherCategoryNotifier();
});

final filteredVouchersProvider = Provider<List<VoucherModel>>((ref) {
  final vouchers = ref.watch(vouchersProvider);
  final category = ref.watch(selectedVoucherCategoryProvider);

  if (category == 'all') return vouchers;
  return vouchers.where((v) => v.category == category).toList();
});
