import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/discovery_shop.dart';

class ShopDiscoveryDatasource {
  ShopDiscoveryDatasource(this._client);

  final SupabaseClient _client;

  Future<List<DiscoveryShop>> fetchShops() async {
    final data = await _client
        .from('shop_discovery')
        .select()
        .order('available_bikes', ascending: false)
        .order('name');

    return (data as List)
        .map((row) => DiscoveryShop.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
