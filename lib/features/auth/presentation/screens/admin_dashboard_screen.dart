import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../app/app.dart';
import '../widgets/admin_dashboard_widgets.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _shopDetails;
  int _activeRentalsCount = 0;
  List<dynamic> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _fetchDashboardData();
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('cached_shop_name');
      final cachedTotalBikes = prefs.getInt('cached_shop_total_bikes') ?? 0;
      if (cachedName != null && mounted) {
        setState(() {
          _shopDetails = {
            'name': cachedName,
            'total_bikes': cachedTotalBikes,
          };
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchDashboardData() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    try {
      final client = Supabase.instance.client;

      final shop = await client
          .from('shops')
          .select()
          .eq('owner_id', user.id)
          .maybeSingle();

      if (shop != null) {
        final shopId = shop['id'];

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_shop_name', shop['name'] ?? '');
          await prefs.setInt(
              'cached_shop_total_bikes', shop['total_bikes'] ?? 0);
        } catch (_) {}

        final activeRentalsRes = await client
            .from('rentals')
            .select('id')
            .eq('shop_id', shopId)
            .eq('status', 'ongoing');

        final activeCount = (activeRentalsRes as List).length;

        final activitiesRes = await client
            .from('rentals')
            .select('*, profiles(full_name), bikes(identifier)')
            .eq('shop_id', shopId)
            .order('start_time', ascending: false)
            .limit(10);

        if (mounted) {
          setState(() {
            _shopDetails = shop;
            _activeRentalsCount = activeCount;
            _recentActivities = activitiesRes as List;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[DASHBOARD ERROR] $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _registerNewBikes(int count) async {
    final shopId = _shopDetails?['id'];
    if (shopId == null) return;

    try {
      final client = Supabase.instance.client;

      final currentTotal = _shopDetails?['total_bikes'] ?? 0;
      final newTotal = currentTotal + count;
      await client
          .from('shops')
          .update({'total_bikes': newTotal}).eq('id', shopId);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('cached_shop_total_bikes', newTotal);
      } catch (_) {}

      await _fetchDashboardData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added $count new bike(s) to inventory!',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[ADMIN ERROR] Failed to register bikes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add bikes: $e',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddBikeDialog() {
    final countController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add New Bikes',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Increase your station\'s live bike inventory by quantity.',
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              style: GoogleFonts.inter(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of Bikes',
                labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                hintText: 'e.g. 5',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white10),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.green),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final countText = countController.text.trim();
              final count = int.tryParse(countText) ?? 0;
              if (count > 0) {
                Navigator.pop(context);
                _registerNewBikes(count);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add Bikes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.green)),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Center(
          child: Text('Error loading profile: $err',
              style: const TextStyle(color: Colors.white)),
        ),
      ),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final stationName = _shopDetails?['name'] ?? 'Loading Station...';
        final totalBikes = _shopDetails?['total_bikes'] ?? 0;
        final activeRentals = _activeRentalsCount;
        final availableBikes =
            (totalBikes - activeRentals).clamp(0, totalBikes);

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.green)),
                )
              : RefreshIndicator(
                  color: AppColors.green,
                  backgroundColor: AppColors.surfaceDark,
                  onRefresh: _fetchDashboardData,
                  child: SafeArea(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  stationName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () async {
                                  await context.push(AppRoutes.profile);
                                  _fetchDashboardData();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceDark,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome back, ${user.fullName.split(' ')[0]}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: 'Total Bikes',
                                  value: '$totalBikes',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MetricCard(
                                  title: 'Active Rentals',
                                  value: '$activeRentals',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MetricCard(
                                  title: 'Available',
                                  value: '$availableBikes',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Quick Operations',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DashboardActionButton(
                                  label: 'Rent Out Bike',
                                  icon: Icons.qr_code_scanner_rounded,
                                  color: AppColors.green,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Launch Bike QR scanner to initiate checkout...',
                                            style: GoogleFonts.inter(
                                                color: Colors.white)),
                                        backgroundColor: AppColors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DashboardActionButton(
                                  label: 'New Bike',
                                  icon: Icons.add_circle_outline,
                                  color: Colors.white12,
                                  border: true,
                                  onTap: _showAddBikeDialog,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Live Rental Activity',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_recentActivities.isNotEmpty)
                                Text(
                                  'See all',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _recentActivities.isEmpty
                              ? const EmptyActivityState()
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _recentActivities.length,
                                  itemBuilder: (context, index) {
                                    final activity = _recentActivities[index];
                                    final riderProfile = activity['profiles']
                                        as Map<String, dynamic>?;
                                    final riderName =
                                        riderProfile?['full_name'] ?? 'Rider';
                                    final bikeObj = activity['bikes']
                                        as Map<String, dynamic>?;
                                    final bikeId =
                                        bikeObj?['identifier'] ?? 'Bike';
                                    final status =
                                        activity['status'] as String? ??
                                            'ongoing';
                                    final startTimeStr =
                                        activity['start_time'] as String?;

                                    String relativeTime = 'Just now';
                                    if (startTimeStr != null) {
                                      try {
                                        final startTime =
                                            DateTime.parse(startTimeStr)
                                                .toLocal();
                                        final diff = DateTime.now()
                                            .difference(startTime);
                                        if (diff.inMinutes < 60) {
                                          relativeTime =
                                              '${diff.inMinutes} mins ago';
                                        } else if (diff.inHours < 24) {
                                          relativeTime =
                                              '${diff.inHours} hrs ago';
                                        } else {
                                          relativeTime =
                                              DateFormat('MMM dd, hh:mm a')
                                                  .format(startTime);
                                        }
                                      } catch (_) {}
                                    }

                                    return ActivityItem(
                                      title: 'Bike #$bikeId',
                                      subtitle: 'By $riderName · $relativeTime',
                                      statusColor: status == 'ongoing'
                                          ? Colors.white54
                                          : AppColors.green,
                                      statusText: status == 'ongoing'
                                          ? 'Ongoing'
                                          : 'Completed',
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
