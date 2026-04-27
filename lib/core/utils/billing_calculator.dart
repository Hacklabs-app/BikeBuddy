class BillingCalculator {
  /// Rounds duration to nearest 15-min block, then multiplies by rate
  static double calculate({
    required DateTime checkoutTime,
    required DateTime checkinTime,
    required double hourlyRate,
  }) {
    final rawMinutes = checkinTime.difference(checkoutTime).inMinutes;
    final roundedMinutes = ((rawMinutes / 15).ceil() * 15).clamp(15, 99999);
    final hours = roundedMinutes / 60;
    return double.parse((hours * hourlyRate).toStringAsFixed(2));
  }

  /// Available count = total fleet - rented - reserved
  static int availableCount(int total, int rented, int reserved) {
    return (total - rented - reserved).clamp(0, total);
  }

  /// Utilization rate as a percentage
  static double utilizationRate(int rented, int total) {
    if (total == 0) return 0;
    return (rented / total) * 100;
  }
}
