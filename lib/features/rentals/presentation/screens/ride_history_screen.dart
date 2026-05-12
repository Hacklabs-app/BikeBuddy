import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/bike_buddy_bottom_nav.dart';

final rideHistoryProvider = FutureProvider<List<CustomerRideHistory>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await client
      .from('rentals')
      .select('''
        id, quantity, rate_per_hour, started_at, ended_at, amount_due,
        shops(name, address)
      ''')
      .eq('customer_id', userId)
      .not('ended_at', 'is', null)
      .order('ended_at', ascending: false);

  return (data as List)
      .map((row) => CustomerRideHistory.fromMap(row as Map<String, dynamic>))
      .toList();
});

class CustomerRideHistory {
  const CustomerRideHistory({
    required this.id,
    required this.shopName,
    required this.quantity,
    required this.startedAt,
    required this.endedAt,
    required this.amountDue,
  });

  final String id;
  final String shopName;
  final int quantity;
  final DateTime startedAt;
  final DateTime endedAt;
  final int amountDue;

  Duration get duration => endedAt.difference(startedAt);

  factory CustomerRideHistory.fromMap(Map<String, dynamic> map) {
    final shop = map['shops'] as Map<String, dynamic>? ?? {};
    return CustomerRideHistory(
      id: map['id'] as String,
      shopName: shop['name'] as String? ?? 'Bike station',
      quantity: map['quantity'] as int? ?? 1,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: DateTime.parse(map['ended_at'] as String),
      amountDue: map['amount_due'] as int? ?? 0,
    );
  }
}

class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(rideHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ride history')),
      bottomNavigationBar: const BikeBuddyBottomNav.customer(
        currentItem: BikeBuddyNavItem.profile,
        isLoggedIn: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.green),
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (rides) {
          if (rides.isEmpty) {
            return const Center(child: Text('No completed rides yet.'));
          }

          final total = rides.fold<int>(0, (sum, ride) => sum + ride.amountDue);

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: rides.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _HistorySummary(total: total, count: rides.length);
              }

              final ride = rides[index - 1];
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.pedal_bike_outlined,
                    color: AppColors.green,
                  ),
                  title: Text(ride.shopName),
                  subtitle: Text(
                    '${ride.quantity} bikes • ${_formatDuration(ride.duration)} • '
                    '${DateFormat.yMMMd().format(ride.endedAt)}',
                  ),
                  trailing: Text(
                    'KES ${ride.amountDue}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.total,
    required this.count,
  });

  final int total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count completed rides',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            'KES $total',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  return '${hours}h ${minutes}m';
}
