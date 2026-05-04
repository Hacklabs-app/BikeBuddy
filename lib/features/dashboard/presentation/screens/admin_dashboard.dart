import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Supabase client ──────────────────────────────────────────────────────────
final _supabase = Supabase.instance.client;

// ─── Providers ────────────────────────────────────────────────────────────────

final adminShopProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return null;
  final data = await _supabase
      .from('shops')
      .select()
      .eq('owner_id', userId)
      .maybeSingle();
  return data;
});

final fleetProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
    (ref, shopId) async {
  final data = await _supabase
      .from('bikes')
      .select()
      .eq('shop_id', shopId)
      .order('created_at');
  return List<Map<String, dynamic>>.from(data as List);
});

final activeRentalsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, shopId) async {
  final data = await _supabase
      .from('rentals')
      .select('*, profiles(full_name, email)')
      .eq('shop_id', shopId)
      .eq('status', 'active')
      .order('checkout_time');
  return List<Map<String, dynamic>>.from(data as List);
});

final revenueProvider =
    FutureProvider.family<Map<String, double>, String>((ref, shopId) async {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  final data = await _supabase
      .from('rentals')
      .select('total_cost, created_at')
      .eq('shop_id', shopId)
      .eq('status', 'completed')
      .gte('created_at', monthStart.toIso8601String());

  double daily = 0, weekly = 0, monthly = 0;
  for (final r in data as List) {
    final cost = (r['total_cost'] as num?)?.toDouble() ?? 0;
    final date = DateTime.parse(r['created_at'] as String);
    monthly += cost;
    if (date.isAfter(weekStart)) weekly += cost;
    if (date.isAfter(todayStart)) daily += cost;
  }
  return {'daily': daily, 'weekly': weekly, 'monthly': monthly};
});

// ─── Constants ────────────────────────────────────────────────────────────────

const _bgDark = Color(0xFF0F1117);
const _surface = Color(0xFF1A1D27);
const _surfaceAlt = Color(0xFF21242F);
const _green = Color(0xFF00C853);
const _amber = Color(0xFFFFB300);
const _red = Color(0xFFFF3D3D);
const _blue = Color(0xFF2979FF);
const _textPrimary = Color(0xFFEEF0F4);
const _textSecondary = Color(0xFF8B90A0);
const _border = Color(0xFF2A2D3A);

// ─── Main Screen ──────────────────────────────────────────────────────────────

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with TickerProviderStateMixin {
  int _selectedNav = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _navItems = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Overview'),
    (Icons.directions_bike_outlined, Icons.directions_bike, 'Fleet'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Rentals'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Revenue'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(adminShopProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bgDark,
        body: shopAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _green),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: _red)),
          ),
          data: (shop) {
            if (shop == null) {
              // Redirect to setup on next frame — keeps build() pure.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) context.go('/shop-setup');
              });
              return const Center(
                child: CircularProgressIndicator(color: _green),
              );
            }
            final shopId = shop['id'] as String;
            final shopName = shop['name'] as String? ?? 'My Shop';

            return Row(
              children: [
                _buildSideNav(shopName),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(shopName, shopId),
                      Expanded(child: _buildContent(shopId)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Side Navigation ─────────────────────────────────────────────────────────

  Widget _buildSideNav(String shopName) {
    return Container(
      width: 220,
      color: _surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pedal_bike,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'BikeBuddy',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store, color: _green, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shopName,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final selected = _selectedNav == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedNav = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? _green.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? _green.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected ? item.$2 : item.$1,
                            color: selected ? _green : _textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.$3,
                            style: TextStyle(
                              color: selected ? _green : _textSecondary,
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          if (i == 2) ...[
                            const Spacer(),
                            _liveChip(),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () async => await _supabase.auth.signOut(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _red.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: _red, size: 16),
                    SizedBox(width: 8),
                    Text('Sign Out',
                        style: TextStyle(
                            color: _red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveChip() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: _pulseAnimation.value * 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'LIVE',
          style: TextStyle(
            color: _green,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ── Top Bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(String shopName, String shopId) {
    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dateStr =
        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day} ${now.year}';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text(
            _navItems[_selectedNav].$3,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 12),
          Container(
              width: 6,
              height: 6,
              decoration:
                  const BoxDecoration(color: _border, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(dateStr,
              style: const TextStyle(color: _textSecondary, fontSize: 13)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              ref.invalidate(fleetProvider(shopId));
              ref.invalidate(activeRentalsProvider(shopId));
              ref.invalidate(revenueProvider(shopId));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.refresh, color: _textSecondary, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showAddBikeSheet(shopId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Add Bike',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content Router ──────────────────────────────────────────────────────────

  Widget _buildContent(String shopId) {
    return switch (_selectedNav) {
      0 => _buildOverview(shopId),
      1 => _buildFleet(shopId),
      2 => _buildRentals(shopId),
      3 => _buildRevenue(shopId),
      4 => _buildSettings(),
      _ => _buildOverview(shopId),
    };
  }

  // ── Overview ────────────────────────────────────────────────────────────────

  Widget _buildOverview(String shopId) {
    final fleetAsync = ref.watch(fleetProvider(shopId));
    final rentalsAsync = ref.watch(activeRentalsProvider(shopId));
    final revenueAsync = ref.watch(revenueProvider(shopId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fleetAsync.when(
            loading: () => const _LoadingCard(),
            error: (e, _) => const SizedBox(),
            data: (fleet) {
              final total = fleet.length;
              final available =
                  fleet.where((b) => b['status'] == 'available').length;
              final rented = fleet.where((b) => b['status'] == 'rented').length;
              final maintenance =
                  fleet.where((b) => b['status'] == 'maintenance').length;
              final utilization =
                  total > 0 ? (rented / total * 100).toStringAsFixed(0) : '0';
              return Row(
                children: [
                  _kpiCard(
                      'Total Fleet', '$total', Icons.pedal_bike, _blue, null),
                  const SizedBox(width: 16),
                  _kpiCard(
                      'Available',
                      '$available',
                      Icons.check_circle_outline,
                      _green,
                      '$available of $total ready'),
                  const SizedBox(width: 16),
                  _kpiCard('On Ride', '$rented', Icons.directions_bike, _amber,
                      'Utilization: $utilization%'),
                  const SizedBox(width: 16),
                  _kpiCard('Maintenance', '$maintenance', Icons.build_outlined,
                      _red, 'Needs attention'),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: revenueAsync.when(
                  loading: () => const _LoadingCard(),
                  error: (e, _) => const SizedBox(),
                  data: (rev) => _revenueCard(rev),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: rentalsAsync.when(
                  loading: () => const _LoadingCard(),
                  error: (e, _) => const SizedBox(),
                  data: (rentals) => _activeRentalsCard(rentals),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          fleetAsync.when(
            loading: () => const _LoadingCard(),
            error: (e, _) => const SizedBox(),
            data: (fleet) => _fleetTable(fleet, shopId),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color,
      String? subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(height: 16),
            Text(value,
                style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _revenueCard(Map<String, double> rev) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.attach_money, color: _green, size: 16),
            SizedBox(width: 6),
            Text('Revenue',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          _revRow('Today', rev['daily'] ?? 0, _green),
          const SizedBox(height: 12),
          _revRow('This Week', rev['weekly'] ?? 0, _blue),
          const SizedBox(height: 12),
          _revRow('This Month', rev['monthly'] ?? 0, _amber),
        ],
      ),
    );
  }

  Widget _revRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: _textSecondary, fontSize: 13)),
        Text('\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _activeRentalsCard(List<Map<String, dynamic>> rentals) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: _pulseAnimation.value),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('Active Rentals (${rentals.length})',
                style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          if (rentals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child: Text('No active rentals',
                      style: TextStyle(color: _textSecondary))),
            )
          else
            ...rentals.take(5).map((r) => _rentalRow(r)),
        ],
      ),
    );
  }

  Widget _rentalRow(Map<String, dynamic> rental) {
    final checkout = DateTime.parse(rental['checkout_time'] as String);
    final duration = DateTime.now().difference(checkout);
    final expected = rental['expected_return'] != null
        ? DateTime.parse(rental['expected_return'] as String)
        : null;
    final isLate = expected != null && DateTime.now().isAfter(expected);
    final customerName =
        (rental['profiles'] as Map?)?['full_name'] as String? ?? 'Customer';
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLate ? _red.withValues(alpha: 0.08) : _surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: isLate ? _red.withValues(alpha: 0.3) : _border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isLate
                  ? _red.withValues(alpha: 0.15)
                  : _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isLate ? Icons.warning_amber : Icons.directions_bike,
              color: isLate ? _red : _green,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customerName,
                    style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(
                  isLate ? '⚠ LATE RETURN' : '${hours}h ${mins}m on ride',
                  style: TextStyle(
                    color: isLate ? _red : _textSecondary,
                    fontSize: 11,
                    fontWeight: isLate ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${((rental['hourly_rate'] as num).toDouble() * (duration.inMinutes / 60)).toStringAsFixed(2)}',
            style: const TextStyle(
                color: _amber, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _fleetTable(List<Map<String, dynamic>> fleet, String shopId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fleet Overview',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _TableHeader('BIKE')),
                Expanded(flex: 2, child: _TableHeader('TYPE')),
                Expanded(flex: 2, child: _TableHeader('STATUS')),
                Expanded(flex: 2, child: _TableHeader('RATE/HR')),
                Expanded(flex: 2, child: _TableHeader('ACTIONS')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (fleet.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: Text('No bikes in fleet yet',
                      style: TextStyle(color: _textSecondary))),
            )
          else
            ...fleet.map((bike) => _bikeRow(bike, shopId)),
        ],
      ),
    );
  }

  Widget _bikeRow(Map<String, dynamic> bike, String shopId) {
    final status = bike['status'] as String? ?? 'available';
    final type = bike['type'] as String? ?? 'standard';
    final rate = (bike['hourly_rate'] as num?)?.toDouble() ?? 0;

    final statusColor = switch (status) {
      'available' => _green,
      'rented' => _amber,
      'reserved' => _blue,
      'maintenance' => _red,
      _ => _textSecondary,
    };

    final typeLabel = switch (type) {
      'electric' => '⚡ Electric',
      'mountainBike' => '⛰ MTB',
      'city' => '🏙 City',
      _ => '🚲 Standard',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: _border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(bike['name'] as String? ?? 'Unknown',
                  style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600))),
          Expanded(
              flex: 2,
              child: Text(typeLabel,
                  style: const TextStyle(color: _textSecondary, fontSize: 12))),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
              flex: 2,
              child: Text('\$${rate.toStringAsFixed(2)}',
                  style: const TextStyle(color: _amber, fontSize: 13))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _actionBtn(Icons.edit_outlined, _blue, () {}),
                const SizedBox(width: 6),
                _actionBtn(Icons.build_outlined, _amber,
                    () => _toggleMaintenance(bike, shopId)),
                const SizedBox(width: 6),
                _actionBtn(Icons.delete_outline, _red,
                    () => _deleteBike(bike['id'] as String, shopId)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }

  // ── Fleet Tab ───────────────────────────────────────────────────────────────

  Widget _buildFleet(String shopId) {
    final fleetAsync = ref.watch(fleetProvider(shopId));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: fleetAsync.when(
        loading: () => const _LoadingCard(),
        error: (e, _) => Text('Error: $e', style: const TextStyle(color: _red)),
        data: (fleet) => _fleetTable(fleet, shopId),
      ),
    );
  }

  // ── Rentals Tab ─────────────────────────────────────────────────────────────

  Widget _buildRentals(String shopId) {
    final rentalsAsync = ref.watch(activeRentalsProvider(shopId));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: rentalsAsync.when(
        loading: () => const _LoadingCard(),
        error: (e, _) => Text('Error: $e', style: const TextStyle(color: _red)),
        data: (rentals) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active Rentals — ${rentals.length} bikes out',
                  style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              if (rentals.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('All bikes are in.',
                      style: TextStyle(color: _textSecondary)),
                ))
              else
                ...rentals.map((r) => _rentalRow(r)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Revenue Tab ─────────────────────────────────────────────────────────────

  Widget _buildRevenue(String shopId) {
    final revenueAsync = ref.watch(revenueProvider(shopId));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: revenueAsync.when(
        loading: () => const _LoadingCard(),
        error: (e, _) => Text('Error: $e', style: const TextStyle(color: _red)),
        data: (rev) => Row(
          children: [
            _bigRevenueCard('Today', rev['daily'] ?? 0, _green, Icons.today),
            const SizedBox(width: 16),
            _bigRevenueCard(
                'This Week', rev['weekly'] ?? 0, _blue, Icons.date_range),
            const SizedBox(width: 16),
            _bigRevenueCard('This Month', rev['monthly'] ?? 0, _amber,
                Icons.calendar_month),
          ],
        ),
      ),
    );
  }

  Widget _bigRevenueCard(
      String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text('\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                    color: color,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: _textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Settings Tab ────────────────────────────────────────────────────────────

  Widget _buildSettings() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text('Shop settings coming soon',
            style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  // ── Add Bike Sheet ──────────────────────────────────────────────────────────

  void _showAddBikeSheet(String shopId) {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    String selectedType = 'standard';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              const Text('Add New Bike',
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              _field('Bike Name', nameCtrl, 'e.g. Trek FX3'),
              const SizedBox(height: 12),
              _field('Hourly Rate (\$)', rateCtrl, 'e.g. 10', isNumber: true),
              const SizedBox(height: 12),
              const Text('Type',
                  style: TextStyle(color: _textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      ['standard', 'electric', 'mountainBike', 'city'].map((t) {
                    final labels = {
                      'standard': '🚲 Standard',
                      'electric': '⚡ Electric',
                      'mountainBike': '⛰ MTB',
                      'city': '🏙 City',
                    };
                    final sel = selectedType == t;
                    return GestureDetector(
                      onTap: () => setSheet(() => selectedType = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? _green.withValues(alpha: 0.15)
                              : _surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: sel ? _green : _border),
                        ),
                        child: Text(labels[t]!,
                            style: TextStyle(
                                color: sel ? _green : _textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || rateCtrl.text.isEmpty) return;
                    await _supabase.from('bikes').insert({
                      'shop_id': shopId,
                      'name': nameCtrl.text.trim(),
                      'type': selectedType,
                      'status': 'available',
                      'hourly_rate': double.tryParse(rateCtrl.text) ?? 0,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(fleetProvider(shopId));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add to Fleet',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: _textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _textSecondary),
            filled: true,
            fillColor: _surfaceAlt,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _green)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _toggleMaintenance(
      Map<String, dynamic> bike, String shopId) async {
    final current = bike['status'] as String;
    final next = current == 'maintenance' ? 'available' : 'maintenance';
    await _supabase
        .from('bikes')
        .update({'status': next}).eq('id', bike['id'] as String);
    ref.invalidate(fleetProvider(shopId));
  }

  Future<void> _deleteBike(String bikeId, String shopId) async {
    await _supabase.from('bikes').delete().eq('id', bikeId);
    ref.invalidate(fleetProvider(shopId));
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: _textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8));
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: _green, strokeWidth: 2),
      ),
    );
  }
}
