import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _green = Color(0xFF00C853);
const _amber = Color(0xFFFFB300);
const _red = Color(0xFFFF3D3D);
const _blue = Color(0xFF2979FF);
const _textDark = Color(0xFF0D1F0F);
const _textMid = Color(0xFF4A5E4C);
const _textLight = Color(0xFF8FA891);
const _border = Color(0xFFDDE8DF);
const _bg = Color(0xFFF7F9F5);

// ─── Provider ─────────────────────────────────────────────────────────────────
final rideHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final data = await supabase
      .from('rentals')
      .select('*, bikes(name, type, shops(name, location))')
      .eq('customer_id', user.id)
      .order('checkout_time', ascending: false);

  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Screen ───────────────────────────────────────────────────────────────────
class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = ['All', 'Completed', 'Active', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyAsync = ref.watch(rideHistoryProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : _bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C2128) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : _textDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Ride History',
            style: TextStyle(
                color: isDark ? Colors.white : _textDark,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _green,
          unselectedLabelColor: _textLight,
          indicatorColor: _green,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: historyAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _green)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.red))),
        data: (rides) {
          if (rides.isEmpty) return _buildEmpty(isDark);

          // Stats header
          final completed =
              rides.where((r) => r['status'] == 'completed').toList();
          final totalSpent = completed.fold(
              0.0, (sum, r) => sum + ((r['total_cost'] as num?)?.toDouble() ?? 0));
          final totalRides = completed.length;

          return Column(children: [
            // Stats strip
            Container(
              color: isDark ? const Color(0xFF1C2128) : Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(children: [
                _statChip('$totalRides', 'Total Rides', _green, isDark),
                const SizedBox(width: 12),
                _statChip('\$${totalSpent.toStringAsFixed(2)}',
                    'Total Spent', _amber, isDark),
                const SizedBox(width: 12),
                _statChip(
                    '${rides.where((r) => r['status'] == 'active' || r['status'] == 'reserved').length}',
                    'Active',
                    _blue,
                    isDark),
              ]),
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: _tabs.map((tab) {
                  final filtered = tab == 'All'
                      ? rides
                      : rides
                          .where((r) =>
                              r['status']?.toString().toLowerCase() ==
                              tab.toLowerCase())
                          .toList();
                  return filtered.isEmpty
                      ? _buildEmpty(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) =>
                              _buildRideCard(filtered[i], isDark),
                        );
                }).toList(),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _statChip(
      String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
            Text(label,
                style: TextStyle(
                    color: isDark ? Colors.white54 : _textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride, bool isDark) {
    final bike = ride['bikes'] as Map<String, dynamic>?;
    final bikeName = bike?['name'] as String? ?? 'Unknown Bike';
    final type = bike?['type'] as String? ?? 'standard';
    final shopName =
        (bike?['shops'] as Map?)?['name'] as String? ?? 'Unknown Shop';
    final shopLocation =
        (bike?['shops'] as Map?)?['location'] as String? ?? '';
    final status = ride['status'] as String? ?? 'unknown';
    final checkoutTime =
        DateTime.parse(ride['checkout_time'] as String);
    final checkinTime = ride['checkin_time'] != null
        ? DateTime.parse(ride['checkin_time'] as String)
        : null;
    final totalCost =
        (ride['total_cost'] as num?)?.toDouble();
    final hourlyRate = (ride['hourly_rate'] as num?)?.toDouble() ?? 0;

    final statusColor = switch (status) {
      'completed' => _green,
      'active' => _blue,
      'reserved' => _amber,
      'cancelled' => _red,
      _ => _textLight,
    };

    final typeColor = switch (type) {
      'electric' => _blue,
      'mountainBike' => const Color(0xFFFF6D00),
      'city' => const Color(0xFF9C27B0),
      _ => _green,
    };

    final typeIcon = switch (type) {
      'electric' => Icons.electric_bike,
      'mountainBike' => Icons.terrain,
      'city' => Icons.location_city,
      _ => Icons.pedal_bike,
    };

    Duration? duration;
    if (checkinTime != null) {
      duration = checkinTime.difference(checkoutTime);
    } else if (status == 'active') {
      duration = DateTime.now().difference(checkoutTime);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2128) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(typeIcon, color: typeColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bikeName,
                        style: TextStyle(
                            color: isDark ? Colors.white : _textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(shopName,
                        style: TextStyle(
                            color: isDark ? Colors.white60 : _textMid,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    if (shopLocation.isNotEmpty)
                      Text(shopLocation,
                          style: TextStyle(
                              color: isDark ? Colors.white38 : _textLight,
                              fontSize: 11)),
                  ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),

        // Divider
        Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : _border),

        // Details row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _detailCol(
                '📅 Date',
                _formatDate(checkoutTime),
                isDark),
            _vDivider(),
            _detailCol(
                '⏱ Duration',
                duration != null
                    ? '${duration.inHours}h ${duration.inMinutes % 60}m'
                    : '—',
                isDark),
            _vDivider(),
            _detailCol(
                '💰 Cost',
                totalCost != null
                    ? '\$${totalCost.toStringAsFixed(2)}'
                    : status == 'active'
                        ? 'Running...'
                        : '—',
                isDark,
                valueColor: totalCost != null ? _green : null),
          ]),
        ),

        // Active ride CTA
        if (status == 'active' || status == 'reserved')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/ride'),
                icon: const Icon(Icons.directions_bike,
                    color: Colors.white, size: 16),
                label: Text(
                  status == 'reserved'
                      ? 'View Reservation'
                      : 'View Active Ride',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ),

        // Rate info
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            '\$${hourlyRate.toStringAsFixed(2)}/hr · ${_formatTime(checkoutTime)}',
            style: TextStyle(
                color: isDark ? Colors.white38 : _textLight, fontSize: 11),
          ),
        ),
      ]),
    );
  }

  Widget _detailCol(String label, String value, bool isDark,
      {Color? valueColor}) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: isDark ? Colors.white38 : _textLight,
                fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: valueColor ??
                    (isDark ? Colors.white : _textDark),
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _vDivider() {
    return Container(
        width: 1, height: 36, color: _border,
        margin: const EdgeInsets.symmetric(horizontal: 12));
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history_rounded,
              size: 64,
              color: isDark ? Colors.white12 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No rides yet',
              style: TextStyle(
                  color: isDark ? Colors.white54 : _textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Your ride history will appear here',
              style: TextStyle(
                  color: isDark ? Colors.white38 : _textLight,
                  fontSize: 14)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.pedal_bike, color: Colors.white, size: 18),
            label: const Text('Find a Bike',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }
}