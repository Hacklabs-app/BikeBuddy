import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/auth_provider.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final supabase = Supabase.instance.client;

// Fetches all shops with their available bike counts
final shopsProvider = FutureProvider<List<ShopWithStats>>((ref) async {
  final data = await supabase.from('shops').select('''
    id, name, logo_url, location, lat, lng, operating_hours,
    bikes(id, status, hourly_rate, type)
  ''');

  return (data as List).map((s) => ShopWithStats.fromMap(s)).toList();
});

// Fetches available bikes (optionally filtered)
final availableBikesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
        (ref, shopId) async {
  var query = supabase
      .from('bikes')
      .select('*, shops(name, location)')
      .eq('status', 'available');

  if (shopId != null) query = query.eq('shop_id', shopId);

  final data = await query.order('hourly_rate');
  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Data Model ──────────────────────────────────────────────────────────────

class ShopWithStats {
  final String id;
  final String name;
  final String? logoUrl;
  final String? location;
  final double? lat;
  final double? lng;
  final int totalBikes;
  final int availableBikes;
  final double? lowestRate;

  ShopWithStats({
    required this.id,
    required this.name,
    this.logoUrl,
    this.location,
    this.lat,
    this.lng,
    required this.totalBikes,
    required this.availableBikes,
    this.lowestRate,
  });

  factory ShopWithStats.fromMap(Map<String, dynamic> map) {
    final bikes = (map['bikes'] as List?) ?? [];
    final available = bikes.where((b) => b['status'] == 'available').length;
    final rates = bikes
        .where((b) => b['hourly_rate'] != null)
        .map((b) => (b['hourly_rate'] as num).toDouble())
        .toList();
    rates.sort();

    return ShopWithStats(
      id: map['id'] as String,
      name: map['name'] as String,
      logoUrl: map['logo_url'] as String?,
      location: map['location'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      totalBikes: bikes.length,
      availableBikes: available,
      lowestRate: rates.isNotEmpty ? rates.first : null,
    );
  }

  bool get hasAvailableBikes => availableBikes > 0;
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class CustomerHome extends ConsumerStatefulWidget {
  const CustomerHome({super.key});

  @override
  ConsumerState<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends ConsumerState<CustomerHome>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  String _selectedFilter = 'All';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _filters = ['All', 'Electric', 'MTB', 'City', 'Standard'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F7FA),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(isDark),
              SliverToBoxAdapter(child: _buildSearchBar(isDark)),
              SliverToBoxAdapter(child: _buildStatsRow(isDark)),
              SliverToBoxAdapter(
                  child: _buildSectionHeader('Nearby Shops', isDark)),
              SliverToBoxAdapter(child: _buildShopsCarousel(isDark)),
              SliverToBoxAdapter(child: _buildFilterRow(isDark)),
              SliverToBoxAdapter(
                  child: _buildSectionHeader('Available Bikes', isDark)),
              _buildBikeGrid(isDark),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(isDark),
        floatingActionButton: _buildScanFAB(isDark),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // ── Sliver App Bar ──────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F7FA),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF00C853), const Color(0xFF004D20)]
                  : [const Color(0xFF00C853), const Color(0xFF69F0AE)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning 👋',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Find Your Ride',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _iconButton(
                            Icons.notifications_outlined,
                            Colors.white,
                            () {},
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {},
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        'Bike Buddy',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      titleTextStyle: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF0D1117),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2128) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: Colors.grey.shade400, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search shops or bike types...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0D1117),
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Row ───────────────────────────────────────────────────────────────

  Widget _buildStatsRow(bool isDark) {
    final shopsAsync = ref.watch(shopsProvider);

    return shopsAsync.when(
      loading: () => const SizedBox(
          height: 80, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SizedBox(),
      data: (shops) {
        final totalAvailable =
            shops.fold(0, (sum, s) => sum + s.availableBikes);
        final totalShops = shops.length;
        final activeRentals =
            shops.fold(0, (sum, s) => sum + (s.totalBikes - s.availableBikes));

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              _statCard('$totalAvailable', 'Available', Icons.pedal_bike,
                  const Color(0xFF00C853), isDark),
              const SizedBox(width: 12),
              _statCard('$totalShops', 'Shops', Icons.store_outlined,
                  const Color(0xFF2979FF), isDark),
              const SizedBox(width: 12),
              _statCard('$activeRentals', 'On Ride', Icons.directions_bike,
                  const Color(0xFFFF6D00), isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2128) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0D1117),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0D1117),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'See all',
              style: TextStyle(
                color: Color(0xFF00C853),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shops Carousel ──────────────────────────────────────────────────────────

  Widget _buildShopsCarousel(bool isDark) {
    final shopsAsync = ref.watch(shopsProvider);

    return SizedBox(
      height: 160,
      child: shopsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load shops',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
        data: (shops) => shops.isEmpty
            ? Center(
                child: Text('No shops found',
                    style: TextStyle(color: Colors.grey.shade500)),
              )
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: shops.length,
                itemBuilder: (context, i) => _buildShopCard(shops[i], isDark),
              ),
      ),
    );
  }

  Widget _buildShopCard(ShopWithStats shop, bool isDark) {
    final isAvailable = shop.hasAvailableBikes;

    return GestureDetector(
      onTap: () {
        // Navigate to shop detail
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2128) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFF00C853)
                      : Colors.grey.shade400,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: shop.logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(shop.logoUrl!,
                                    fit: BoxFit.cover),
                              )
                            : const Icon(Icons.store,
                                color: Color(0xFF00C853), size: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0D1117),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (shop.location != null)
                              Text(
                                shop.location!,
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _availabilityChip(
                          shop.availableBikes, shop.totalBikes, isAvailable),
                      if (shop.lowestRate != null)
                        Text(
                          'from \$${shop.lowestRate!.toStringAsFixed(0)}/hr',
                          style: const TextStyle(
                            color: Color(0xFF00C853),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _availabilityChip(int available, int total, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFF00C853).withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$available/$total bikes',
        style: TextStyle(
          color: isAvailable ? const Color(0xFF00C853) : Colors.grey.shade500,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Filter Row ──────────────────────────────────────────────────────────────

  Widget _buildFilterRow(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final selected = _filters[i] == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = _filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF00C853)
                    : isDark
                        ? const Color(0xFF1C2128)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color:
                                const Color(0xFF00C853).withValues(alpha: 0.3),
                            blurRadius: 8)
                      ]
                    : [],
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Bike Grid ───────────────────────────────────────────────────────────────

  Widget _buildBikeGrid(bool isDark) {
    final bikesAsync = ref.watch(availableBikesProvider(null));

    return bikesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(
            height: 200, child: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(
            child: Text('Could not load bikes',
                style: TextStyle(color: Colors.grey.shade500))),
      ),
      data: (bikes) {
        final filtered = _selectedFilter == 'All'
            ? bikes
            : bikes.where((b) {
                final type = b['type'] as String? ?? '';
                return type.toLowerCase() == _selectedFilter.toLowerCase() ||
                    (type == 'mountainBike' && _selectedFilter == 'MTB');
              }).toList();

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.pedal_bike_outlined,
                      size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No bikes available right now',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildBikeCard(filtered[i], isDark),
              childCount: filtered.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBikeCard(Map<String, dynamic> bike, bool isDark) {
    final type = bike['type'] as String? ?? 'standard';
    final rate = (bike['hourly_rate'] as num?)?.toDouble() ?? 0;
    final shopName =
        (bike['shops'] as Map?)?['name'] as String? ?? 'Unknown Shop';
    final shopLocation = (bike['shops'] as Map?)?['location'] as String? ?? '';

    final typeIcon = switch (type) {
      'electric' => Icons.electric_bike,
      'mountainBike' => Icons.terrain,
      'city' => Icons.location_city,
      _ => Icons.pedal_bike,
    };

    final typeColor = switch (type) {
      'electric' => const Color(0xFF2979FF),
      'mountainBike' => const Color(0xFFFF6D00),
      'city' => const Color(0xFF9C27B0),
      _ => const Color(0xFF00C853),
    };

    final typeLabel = switch (type) {
      'electric' => 'Electric',
      'mountainBike' => 'MTB',
      'city' => 'City',
      _ => 'Standard',
    };

    return GestureDetector(
      onTap: () {
        // Navigate to bike detail / booking
        _showBookingBottomSheet(bike, isDark);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2128) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bike illustration area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(typeIcon,
                          size: 64, color: typeColor.withValues(alpha: 0.6)),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bike['name'] as String? ?? 'Bike',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0D1117),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shopName,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (shopLocation.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            shopLocation,
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${rate.toStringAsFixed(0)}/hr',
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_forward,
                            color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Booking Bottom Sheet ────────────────────────────────────────────────────

  void _showBookingBottomSheet(Map<String, dynamic> bike, bool isDark) {
    final rate = (bike['hourly_rate'] as num?)?.toDouble() ?? 0;
    final shopName =
        (bike['shops'] as Map?)?['name'] as String? ?? 'Unknown Shop';
    int selectedHours = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2128) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                bike['name'] as String? ?? 'Book Bike',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0D1117),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                shopName,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              const SizedBox(height: 24),
              // Duration selector
              Text(
                'Duration',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [1, 2, 4, 8].map((h) {
                  final selected = selectedHours == h;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedHours = h),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF00C853)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${h}h',
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Cost summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF00C853).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimated Total',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${(rate * selectedHours).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Book button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/booking',
                        extra: {'bike': bike, 'hours': selectedHours});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Reserve Bike',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Nav ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav(bool isDark) {
    final isLoggedIn = ref.watch(authStateProvider).valueOrNull != null;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2128) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 'Home', 0, isDark),
          _navItem(Icons.map_outlined, 'Map', 1, isDark),
          const SizedBox(width: 60), // FAB space
          _navItem(Icons.history_rounded, 'History', 2, isDark),
          _navItem(
            Icons.person_outline_rounded,
            'Profile',
            3,
            isDark,
            onTap: () =>
                isLoggedIn ? _showProfileSheet(isDark) : context.go('/login'),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(bool isDark) {
    final user = supabase.auth.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2128) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF00C853).withValues(alpha: 0.12),
              child:
                  const Icon(Icons.person, color: Color(0xFF00C853), size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              user?.email ?? '',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0D1117),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await supabase.auth.signOut();
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, bool isDark,
      {VoidCallback? onTap}) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00C853).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF00C853) : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color:
                    selected ? const Color(0xFF00C853) : Colors.grey.shade400,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Scan FAB ────────────────────────────────────────────────────────────────

  Widget _buildScanFAB(bool isDark) {
    return GestureDetector(
      onTap: () {
        context.go('/scan');
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C853).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _iconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
