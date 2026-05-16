import '../../../../core/models/discovery_shop.dart';

abstract class DiscoveryRepository {
  Future<List<DiscoveryShop>> getShops();
}
