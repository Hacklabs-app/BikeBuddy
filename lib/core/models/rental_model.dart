enum RentalStatus { reserved, active, completed, cancelled }

class RentalModel {
  final String id;
  final String bikeId;
  final String customerId;
  final String shopId;
  final DateTime checkoutTime;
  final DateTime? checkinTime;
  final DateTime? expectedReturn;
  final double hourlyRate;
  final double? totalCost;
  final RentalStatus status;

  const RentalModel({
    required this.id,
    required this.bikeId,
    required this.customerId,
    required this.shopId,
    required this.checkoutTime,
    required this.hourlyRate,
    required this.status,
    this.checkinTime,
    this.expectedReturn,
    this.totalCost,
  });

  // Core billing formula — rounded to nearest 15 mins
  double calculateCost() {
    final end = checkinTime ?? DateTime.now();
    final rawMinutes = end.difference(checkoutTime).inMinutes;
    // Round up to nearest 15-minute block
    final roundedMinutes = ((rawMinutes / 15).ceil() * 15);
    final hours = roundedMinutes / 60;
    return hours * hourlyRate;
  }

  bool get isLate =>
      expectedReturn != null &&
      checkinTime == null &&
      DateTime.now().isAfter(expectedReturn!);

  factory RentalModel.fromMap(Map<String, dynamic> map) {
    return RentalModel(
      id: map['id'] as String,
      bikeId: map['bike_id'] as String,
      customerId: map['customer_id'] as String,
      shopId: map['shop_id'] as String,
      checkoutTime: DateTime.parse(map['checkout_time'] as String),
      checkinTime: map['checkin_time'] != null
          ? DateTime.parse(map['checkin_time'] as String)
          : null,
      expectedReturn: map['expected_return'] != null
          ? DateTime.parse(map['expected_return'] as String)
          : null,
      hourlyRate: (map['hourly_rate'] as num).toDouble(),
      totalCost: map['total_cost'] != null
          ? (map['total_cost'] as num).toDouble()
          : null,
      status: RentalStatus.values.byName(map['status'] as String),
    );
  }
}