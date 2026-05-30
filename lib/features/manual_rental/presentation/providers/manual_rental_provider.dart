import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/manual_rental.dart';

class ManualRentalNotifier extends Notifier<List<ManualRental>> {
  static const _storageKey = 'offline_manual_rentals';

  @override
  List<ManualRental> build() {
    _loadFromStorage();
    return [];
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey);
      if (rawList != null) {
        state = rawList.map((item) => ManualRental.fromJson(item)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage(List<ManualRental> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringList = list.map((item) => item.toJson()).toList();
      await prefs.setStringList(_storageKey, stringList);
    } catch (_) {}
  }

  Future<void> startRental({
    required String customerName,
    required String customerPhone,
    String nationalId = '',
    String bikeLabel = 'Bike',
    double hourlyRate = 50.0,
  }) async {
    final newRental = ManualRental(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      customerName: customerName,
      customerPhone: customerPhone,
      nationalId: nationalId,
      bikeLabel: bikeLabel,
      hourlyRate: hourlyRate,
      startTime: DateTime.now(),
      status: ManualRentalStatus.active,
    );

    final updated = [newRental, ...state];
    state = updated;
    await _saveToStorage(updated);

    // Try to sync online (Supabase) if available, but fully offline-first (graceful non-blocking fallback)
    _trySyncOnline(newRental);
  }

  Future<void> _trySyncOnline(ManualRental rental) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final shop = await client
            .from('shops')
            .select('id')
            .eq('owner_id', user.id)
            .maybeSingle();

        if (shop != null) {
          final shopId = shop['id'];
          await client.from('rentals').insert({
            'id': rental.id,
            'shop_id': shopId,
            'status': 'ongoing',
            'start_time': rental.startTime.toIso8601String(),
            'notes': 'Offline manual checkout. Name: ${rental.customerName}, Phone: ${rental.customerPhone}, ID: ${rental.nationalId}',
          });
        }
      }
    } catch (_) {
      // Gracefully catch any network or database connection error (postpones sync)
    }
  }

  Future<void> endRental(String id) async {
    final now = DateTime.now();
    ManualRental? completedRental;

    final updated = state.map((rental) {
      if (rental.id == id && rental.status == ManualRentalStatus.active) {
        final duration = now.difference(rental.startTime);
        
        // Calculate amount (minimum 1 minute to prevent 0.0 calculations in quick tests)
        final minutes = duration.inMinutes.clamp(1, double.infinity);
        final hours = minutes / 60.0;
        final totalAmount = double.parse((hours * rental.hourlyRate).toStringAsFixed(2));

        completedRental = rental.copyWith(
          endTime: now,
          totalAmount: totalAmount,
          status: ManualRentalStatus.completed,
        );
        return completedRental!;
      }
      return rental;
    }).toList();

    state = updated;
    await _saveToStorage(updated);

    if (completedRental != null) {
      _trySyncEndOnline(completedRental!);
    }
  }

  Future<void> _trySyncEndOnline(ManualRental rental) async {
    try {
      final client = Supabase.instance.client;
      await client.from('rentals').update({
        'status': 'completed',
        'end_time': rental.endTime?.toIso8601String(),
        'total_amount': rental.totalAmount,
      }).eq('id', rental.id);
    } catch (_) {
      // Gracefully catch network failure (offline post-processing)
    }
  }

  Future<void> deleteRental(String id) async {
    final updated = state.where((rental) => rental.id != id).toList();
    state = updated;
    await _saveToStorage(updated);
  }
}

final manualRentalsProvider = NotifierProvider<ManualRentalNotifier, List<ManualRental>>(() {
  return ManualRentalNotifier();
});

// Selector providers for helper slices
final activeManualRentalsProvider = Provider<List<ManualRental>>((ref) {
  final rentals = ref.watch(manualRentalsProvider);
  return rentals.where((r) => r.status == ManualRentalStatus.active).toList();
});

final completedManualRentalsProvider = Provider<List<ManualRental>>((ref) {
  final rentals = ref.watch(manualRentalsProvider);
  return rentals.where((r) => r.status == ManualRentalStatus.completed).toList();
});
