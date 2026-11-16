class WalletModel {
  final String id;
  final String name;
  final String type; // Bank, E-Wallet, Cash, Deposit, Mutual Fund, Bond, Stock, CEX, DEX, Web3 Wallet, Crypto
  final double balance;
  final bool isAutoSync;
  final double? returnPercentage;
  final DateTime? dividendDropDate;
  final bool isVolatile;
  final bool hasClaimedDividend;
  final String? institutionId;
  final String? customColorHex;
  final String? maskedCardNumber;

  WalletModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.isAutoSync = false,
    this.returnPercentage,
    this.dividendDropDate,
    this.isVolatile = false,
    this.hasClaimedDividend = false,
    this.institutionId,
    this.customColorHex,
    this.maskedCardNumber,
  });

  WalletModel copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    bool? isAutoSync,
    double? returnPercentage,
    DateTime? dividendDropDate,
    bool? isVolatile,
    bool? hasClaimedDividend,
    String? institutionId,
    String? customColorHex,
    String? maskedCardNumber,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      isAutoSync: isAutoSync ?? this.isAutoSync,
      returnPercentage: returnPercentage ?? this.returnPercentage,
      dividendDropDate: dividendDropDate ?? this.dividendDropDate,
      isVolatile: isVolatile ?? this.isVolatile,
      hasClaimedDividend: hasClaimedDividend ?? this.hasClaimedDividend,
      institutionId: institutionId ?? this.institutionId,
      customColorHex: customColorHex ?? this.customColorHex,
      maskedCardNumber: maskedCardNumber ?? this.maskedCardNumber,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'balance': balance,
    'isAutoSync': isAutoSync,
    'returnPercentage': returnPercentage,
    'dividendDropDate': dividendDropDate?.toIso8601String(),
    'isVolatile': isVolatile,
    'hasClaimedDividend': hasClaimedDividend,
    'institutionId': institutionId,
    'customColorHex': customColorHex,
    'maskedCardNumber': maskedCardNumber,
  };

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    type: json['type'] as String? ?? '',
    balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    isAutoSync: json['isAutoSync'] as bool? ?? false,
    returnPercentage: (json['returnPercentage'] as num?)?.toDouble(),
    dividendDropDate: json['dividendDropDate'] != null
        ? DateTime.tryParse(json['dividendDropDate'] as String)
        : null,
    isVolatile: json['isVolatile'] as bool? ?? false,
    hasClaimedDividend: json['hasClaimedDividend'] as bool? ?? false,
    institutionId: json['institutionId'] as String?,
    customColorHex: json['customColorHex'] as String?,
    maskedCardNumber: json['maskedCardNumber'] as String?,
  );
}
