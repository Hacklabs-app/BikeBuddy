import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/billing_calculator.dart';
import '../../../../core/widgets/bike_buddy_bottom_nav.dart';

final activeRentalProvider = FutureProvider<CustomerActiveRental?>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;

  final data = await client
      .from('rentals')
      .select('id, quantity, rate_per_hour, started_at, shops(name, address)')
      .eq('customer_id', userId)
      .filter('ended_at', 'is', null)
      .order('started_at', ascending: false)
      .limit(1)
      .maybeSingle();

  if (data == null) return null;
  return CustomerActiveRental.fromMap(data);
});

class CustomerActiveRental {
  const CustomerActiveRental({
    required this.id,
    required this.shopName,
    required this.shopAddress,
    required this.quantity,
    required this.ratePerHour,
    required this.startedAt,
  });

  final String id;
  final String shopName;
  final String shopAddress;
  final int quantity;
  final int ratePerHour;
  final DateTime startedAt;

  int estimateAt(DateTime now) {
    return BillingCalculator.calculateAmountDue(
      startedAt: startedAt,
      endedAt: now,
      ratePerHour: ratePerHour,
      quantity: quantity,
    );
  }

  factory CustomerActiveRental.fromMap(Map<String, dynamic> map) {
    final shop = map['shops'] as Map<String, dynamic>? ?? {};
    return CustomerActiveRental(
      id: map['id'] as String,
      shopName: shop['name'] as String? ?? 'Bike station',
      shopAddress: shop['address'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 1,
      ratePerHour: map['rate_per_hour'] as int? ?? 0,
      startedAt: DateTime.parse(map['started_at'] as String),
    );
  }
}

class ActiveRideScreen extends ConsumerStatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rentalAsync = ref.watch(activeRentalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Active ride')),
      bottomNavigationBar: const BikeBuddyBottomNav.customer(
        currentItem: BikeBuddyNavItem.activeRide,
        isLoggedIn: true,
      ),
      body: rentalAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.green),
        ),
        error: (error, _) => _CenteredMessage(
          icon: Icons.error_outline,
          title: 'Could not load active ride',
          body: error.toString(),
        ),
        data: (rental) {
          if (rental == null) {
            return const _CenteredMessage(
              icon: Icons.timer_off_outlined,
              title: 'No active ride',
              body: 'When a shop links your rental, it will appear here.',
            );
          }

          final elapsed = _now.difference(rental.startedAt);
          final estimate = rental.estimateAt(_now);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                rental.shopName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(rental.shopAddress),
              const SizedBox(height: 24),
              _RideMetric(
                icon: Icons.pedal_bike_outlined,
                label: 'Bikes',
                value: '${rental.quantity}',
              ),
              _RideMetric(
                icon: Icons.schedule,
                label: 'Elapsed',
                value: _formatDuration(elapsed),
              ),
              _RideMetric(
                icon: Icons.payments_outlined,
                label: 'Running estimate',
                value: 'KES $estimate',
              ),
              const SizedBox(height: 20),
              const Text(
                'The owner checks this rental in when you return the bikes.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RideMetric extends StatelessWidget {
  const _RideMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.green),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.green),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  return '${hours}h ${minutes}m';
}
