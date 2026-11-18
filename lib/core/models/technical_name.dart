class TechnicalNameModel {
  final String id;
  final String name;
  final String letter;
  final double commissionPercentage;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TechnicalNameModel({
    required this.id,
    required this.name,
    required this.letter,
    this.commissionPercentage = 0.0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory TechnicalNameModel.fromJson(Map<String, dynamic> json) {
    final rawCommission = json['commissionPercentage'];
    final commission = rawCommission is num
        ? rawCommission.toDouble()
        : double.tryParse(rawCommission?.toString() ?? '') ?? 0.0;

    return TechnicalNameModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      letter: (json['letter'] ?? '').toString(),
      commissionPercentage: commission,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'letter': letter,
        'commissionPercentage': commissionPercentage,
        'isActive': isActive,
      };

  TechnicalNameModel copyWith({
    String? id,
    String? name,
    String? letter,
    double? commissionPercentage,
    bool? isActive,
  }) {
    return TechnicalNameModel(
      id: id ?? this.id,
      name: name ?? this.name,
      letter: letter ?? this.letter,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get formattedCommission {
    if (commissionPercentage == commissionPercentage.roundToDouble()) {
      return '${commissionPercentage.toInt()}%';
    }
    return '${commissionPercentage.toStringAsFixed(1)}%';
  }
}
