enum SessionStatus {
  active,
  scheduled,
  completed,
  cancelled,
}

class SessionItemModel {
  final String id;
  final String consultantName;
  final String consultantRole;
  final String sessionTitle;
  final String scheduleTime;
  final String sessionMethod;
  final SessionStatus status;
  final String bookingCode;
  final String avatarUrl;
  final double? rating;

  const SessionItemModel({
    required this.id,
    required this.consultantName,
    required this.consultantRole,
    required this.sessionTitle,
    required this.scheduleTime,
    required this.sessionMethod,
    required this.status,
    required this.bookingCode,
    required this.avatarUrl,
    this.rating,
  });

  static List<SessionItemModel> dummySessions = [
    const SessionItemModel(
      id: 'sess-01',
      consultantName: 'Rian Pratama, CFP®',
      consultantRole: 'Perencana Keuangan Independen',
      sessionTitle: 'Konsultasi CFP® Komprehensif',
      scheduleTime: 'Hari Ini • 10:00 - 11:00 WIB',
      sessionMethod: 'Chat Konsultasi (3 Hari Akses)',
      status: SessionStatus.active,
      bookingCode: 'HF-CFP-89210',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
    ),
    const SessionItemModel(
      id: 'sess-02',
      consultantName: 'Budi Santoso, CFP®',
      consultantRole: 'Financial Planner & Tax Specialist',
      sessionTitle: 'Virtual Meet (Zoom)',
      scheduleTime: 'Besok, 16 Okt 2026 • 14:00 WIB',
      sessionMethod: 'Video Call (Zoom Meeting)',
      status: SessionStatus.scheduled,
      bookingCode: 'HF-TAX-55102',
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
    ),
    const SessionItemModel(
      id: 'sess-03',
      consultantName: 'Dewi Rahmawati, QWP™',
      consultantRole: 'Investment & Wealth Advisor',
      sessionTitle: 'Rekomendasi Portofolio Reksa Dana',
      scheduleTime: '12 Jan 2026 • 11:00 WIB',
      sessionMethod: 'Chat Konsultasi Selesai',
      status: SessionStatus.completed,
      bookingCode: 'HF-INV-33901',
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
      rating: 5.0,
    ),
  ];
}
