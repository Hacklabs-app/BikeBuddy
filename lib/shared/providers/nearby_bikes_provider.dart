import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/bike_model.dart';

// Streams all available bikes — PostGIS radius filter added once lat/lng
// columns are added to the bikes table.
final nearbyBikesProvider = StreamProvider.family<List<BikeModel>, double>(
  (ref, radiusKm) {
    final db = Supabase.instance.client;
    return db
        .from('bikes')
        .stream(primaryKey: ['id'])
        .eq('status', 'available')
        .map((rows) => rows.map(BikeModel.fromMap).toList());
  },
);
