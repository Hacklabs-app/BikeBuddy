import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationState {
  final String? reservationId;
  final DateTime? expiresAt;
  final bool isExpired;

  const ReservationState({
    this.reservationId,
    this.expiresAt,
    this.isExpired = false,
  });

  Duration get remaining {
    if (expiresAt == null) return Duration.zero;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  ReservationState copyWith({
    String? reservationId,
    DateTime? expiresAt,
    bool? isExpired,
  }) =>
      ReservationState(
        reservationId: reservationId ?? this.reservationId,
        expiresAt: expiresAt ?? this.expiresAt,
        isExpired: isExpired ?? this.isExpired,
      );
}

class ReservationNotifier extends StateNotifier<ReservationState> {
  ReservationNotifier() : super(const ReservationState());

  final _db = Supabase.instance.client;
  Timer? _ticker;

  Future<bool> reserveBike(String bikeId, String userId) async {
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));
    try {
      // Mark bike as reserved in bikes table
      await _db.from('bikes').update({'status': 'reserved'}).eq('id', bikeId);

      final res = await _db
          .from('reservations')
          .insert({
            'bike_id': bikeId,
            'user_id': userId,
            'expires_at': expiresAt.toIso8601String(),
            'status': 'active',
          })
          .select()
          .single();

      state = ReservationState(
        reservationId: res['id'],
        expiresAt: expiresAt,
      );
      _startTicker();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remaining == Duration.zero) {
        _expire();
      } else {
        // trigger rebuild by re-setting same state object
        state = ReservationState(
          reservationId: state.reservationId,
          expiresAt: state.expiresAt,
          isExpired: false,
        );
      }
    });
  }

  Future<void> _expire() async {
    _ticker?.cancel();
    if (state.reservationId != null) {
      await _db
          .from('reservations')
          .update({'status': 'expired'}).eq('id', state.reservationId!);
    }
    state = const ReservationState(isExpired: true);
  }

  Future<void> cancelReservation() async {
    _ticker?.cancel();
    if (state.reservationId != null) {
      await _db
          .from('reservations')
          .update({'status': 'expired'}).eq('id', state.reservationId!);
    }
    state = const ReservationState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final reservationProvider =
    StateNotifierProvider<ReservationNotifier, ReservationState>(
  (_) => ReservationNotifier(),
);
