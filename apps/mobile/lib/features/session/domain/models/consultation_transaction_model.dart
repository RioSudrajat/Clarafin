class ConsultationTransactionModel {
  final String id;
  final String bookingCode;
  final String consultantId;
  final String consultantName;
  final String packageTitle;
  final String paymentMethod;
  final double amount;
  final DateTime timestamp;
  final String status;

  const ConsultationTransactionModel({
    required this.id,
    required this.bookingCode,
    required this.consultantId,
    required this.consultantName,
    required this.packageTitle,
    required this.paymentMethod,
    required this.amount,
    required this.timestamp,
    this.status = 'Berhasil',
  });

  static List<ConsultationTransactionModel> initialDummyTransactions = [
    ConsultationTransactionModel(
      id: 'TRX-CFP-001',
      bookingCode: 'HF-CFP-89210',
      consultantId: 'c1',
      consultantName: 'Rian Pratama, CFP®',
      packageTitle: 'Konsultasi CFP® Komprehensif',
      paymentMethod: 'QRIS Gopay',
      amount: 450000.0,
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      status: 'Berhasil',
    ),
  ];
}
