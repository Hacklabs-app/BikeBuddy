import 'package:flutter_test/flutter_test.dart';
import 'package:bike_buddy/core/utils/billing_calculator.dart';

void main() {
  group('BillingCalculator', () {
    test('rounds any partial hour up to the next full hour', () {
      final amountDue = BillingCalculator.calculateAmountDue(
        startedAt: DateTime(2026, 5, 1, 10),
        endedAt: DateTime(2026, 5, 1, 10, 1),
        ratePerHour: 200,
        quantity: 1,
      );

      expect(amountDue, 200);
    });

    test('multiplies billable hours by rate and quantity', () {
      final amountDue = BillingCalculator.calculateAmountDue(
        startedAt: DateTime(2026, 5, 1, 10),
        endedAt: DateTime(2026, 5, 1, 12, 1),
        ratePerHour: 150,
        quantity: 3,
      );

      expect(amountDue, 1350);
    });

    test('calculates availability from active rental quantity only', () {
      final available = BillingCalculator.availableCount(
        totalBikes: 12,
        activeRentalQuantity: 5,
      );

      expect(available, 7);
    });
  });
}
