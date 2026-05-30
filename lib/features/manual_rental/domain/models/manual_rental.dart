import 'dart:convert';

enum ManualRentalStatus {
  active,
  completed,
}

class ManualRental {
  final String id;
  final String customerName;
  final String customerPhone;
  final String nationalId;
  final String bikeLabel;
  final double hourlyRate;
  final DateTime startTime;
  final DateTime? endTime;
  final double? totalAmount;
  final ManualRentalStatus status;

  ManualRental({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.nationalId,
    this.bikeLabel = 'Bike',
    this.hourlyRate = 50.0,
    required this.startTime,
    this.endTime,
    this.totalAmount,
    this.status = ManualRentalStatus.active,
  });

  ManualRental copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? nationalId,
    String? bikeLabel,
    double? hourlyRate,
    DateTime? startTime,
    DateTime? endTime,
    double? totalAmount,
    ManualRentalStatus? status,
  }) {
    return ManualRental(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      nationalId: nationalId ?? this.nationalId,
      bikeLabel: bikeLabel ?? this.bikeLabel,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'nationalId': nationalId,
      'bikeLabel': bikeLabel,
      'hourlyRate': hourlyRate,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status.name,
    };
  }

  factory ManualRental.fromMap(Map<String, dynamic> map) {
    return ManualRental(
      id: map['id'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      nationalId: map['nationalId'] ?? '',
      bikeLabel: map['bikeLabel'] ?? 'Bike',
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 50.0,
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      totalAmount: (map['totalAmount'] as num?)?.toDouble(),
      status: ManualRentalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ManualRentalStatus.active,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ManualRental.fromJson(String source) => ManualRental.fromMap(json.decode(source));
}
