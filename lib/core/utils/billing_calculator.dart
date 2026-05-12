class BillingCalculator {
  /// amount_due = CEIL(duration_minutes / 60) x rate_per_hour x quantity.
  static int calculateAmountDue({
    required DateTime startedAt,
    required DateTime endedAt,
    required int ratePerHour,
    required int quantity,
  }) {
    if (ratePerHour <= 0) {
      throw ArgumentError.value(ratePerHour, 'ratePerHour', 'must be positive');
    }
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must be positive');
    }

    final durationMinutes = endedAt.difference(startedAt).inMinutes;
    final billableHours = (durationMinutes / 60).ceil().clamp(1, 99999);
    return billableHours * ratePerHour * quantity;
  }

  /// Available bikes = total_bikes - SUM(active rental quantities).
  static int availableCount({
    required int totalBikes,
    required int activeRentalQuantity,
  }) {
    return (totalBikes - activeRentalQuantity).clamp(0, totalBikes);
  }

  /// Utilization rate as a percentage
  static double utilizationRate({
    required int activeRentalQuantity,
    required int totalBikes,
  }) {
    if (totalBikes == 0) return 0;
    return (activeRentalQuantity / totalBikes) * 100;
  }
}
