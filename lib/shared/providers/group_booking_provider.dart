import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/bike_model.dart';

const int kMaxGroupSize = 4;

class GroupBookingNotifier extends StateNotifier<List<BikeModel>> {
  GroupBookingNotifier() : super([]);

  void addBike(BikeModel bike) {
    if (state.length >= kMaxGroupSize) return;
    if (state.any((b) => b.id == bike.id)) return;
    state = [...state, bike];
  }

  void removeBike(String bikeId) {
    state = state.where((b) => b.id != bikeId).toList();
  }

  void clear() => state = [];

  Future<List<String>> confirmBooking({
    required String userId,
    required DateTime startTime,
  }) async {
    final db = Supabase.instance.client;
    final rentalIds = <String>[];

    // Batch insert — one rental per bike
    for (final bike in state) {
      final res = await db.from('rentals').insert({
        'user_id': userId,
        'bike_id': bike.id,
        'shop_id': bike.shopId,
        'status': 'reserved',
        'start_time': startTime.toIso8601String(),
      }).select().single();
      rentalIds.add(res['id']);
    }
    clear();
    return rentalIds;
  }
}

final groupBookingProvider =
    StateNotifierProvider<GroupBookingNotifier, List<BikeModel>>(
  (_) => GroupBookingNotifier(),
);