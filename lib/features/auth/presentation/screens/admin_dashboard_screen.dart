import 'dart:async';
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
import '../../../manual_rental/domain/models/manual_rental.dart';
import '../../../manual_rental/presentation/providers/manual_rental_provider.dart';
import '../../../manual_rental/presentation/widgets/active_manual_rental_tile.dart';
import '../../../manual_rental/presentation/widgets/manual_rental_bottom_sheet.dart';

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
      final cachedId = prefs.getString('cached_shop_id');
      final cachedTotalBikes = prefs.getInt('cached_shop_total_bikes') ?? 0;
      if (cachedName != null && mounted) {
        setState(() {
          _shopDetails = {
            'id': cachedId,
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

        final activeRentalsRes = await client
            .from('rentals')
            .select('id')
            .eq('shop_id', shopId)
            .eq('status', 'ongoing');

        final activeCount = (activeRentalsRes as List).length;

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_shop_id', shop['id'] ?? '');
          await prefs.setString('cached_shop_name', shop['name'] ?? '');
          await prefs.setInt(
              'cached_shop_total_bikes', shop['total_bikes'] ?? 0);
          await prefs.setInt('cached_active_database_rentals', activeCount);
        } catch (_) {}

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
      final isOfflineError = e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('ClientException');

      if (isOfflineError) {
        debugPrint(
            '[OFFLINE] Network failed when adding bikes. Registering bike locally. Error: $e');
        if (mounted) {
          // Perform local-only inventory register so station owners remain fully operational offline!
          final currentTotal = _shopDetails?['total_bikes'] ?? 0;
          final newTotal = currentTotal + count;

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('cached_shop_total_bikes', newTotal);
          } catch (_) {}

          if (!mounted) return;

          setState(() {
            if (_shopDetails != null) {
              final updatedShop = Map<String, dynamic>.from(_shopDetails!);
              updatedShop['total_bikes'] = newTotal;
              _shopDetails = updatedShop;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Offline Mode: Added $count new bike(s) to local inventory!',
                  style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: AppColors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

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
    showDialog(
      context: context,
      builder: (context) => AddBikesDialog(
        onAdd: (count) => _registerNewBikes(count),
      ),
    );
  }

  void _showActivityDetails(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityDetailsBottomSheet(item: item),
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

        // Watch active manual rentals to combine them dynamically into the dashboard metrics
        final activeManualRentals = ref.watch(activeManualRentalsProvider);
        final activeManualCount = activeManualRentals.length;
        final manualRentals = ref.watch(manualRentalsProvider);

        final totalActiveRentals = _activeRentalsCount + activeManualCount;
        final availableBikes =
            (totalBikes - totalActiveRentals).clamp(0, totalBikes);

        // Combine database activities and local manual rentals into a sorted list
        final List<dynamic> unifiedActivities = [...manualRentals];
        for (final act in _recentActivities) {
          final id = act['id'];
          if (!manualRentals.any((m) => m.id == id)) {
            unifiedActivities.add(act);
          }
        }
        unifiedActivities.sort((a, b) {
          final DateTime timeA =
              a is ManualRental ? a.startTime : DateTime.parse(a['start_time']);
          final DateTime timeB =
              b is ManualRental ? b.startTime : DateTime.parse(b['start_time']);
          return timeB.compareTo(timeA);
        });

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
                      padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 16,
                          bottom: 80), // extra padding for FAB
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
                                  value: '$totalActiveRentals',
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
                                  label: 'Quick Lease',
                                  icon: Icons.qr_code_scanner_rounded,
                                  color: AppColors.green,
                                  onTap: () => context.push(AppRoutes.adminScan),
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

                          // Dynamic Active Rentals List
                          if (activeManualRentals.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            Text(
                              'Active Rentals (${activeManualRentals.length})',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activeManualRentals.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, idx) {
                                final rental = activeManualRentals[idx];
                                return ActiveManualRentalTile(rental: rental);
                              },
                            ),
                          ],

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
                              if (unifiedActivities.isNotEmpty)
                                GestureDetector(
                                  onTap: () =>
                                      context.push(AppRoutes.manualRental),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'See all',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          unifiedActivities.isEmpty
                              ? const EmptyActivityState()
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: unifiedActivities.length,
                                  itemBuilder: (context, index) {
                                    final item = unifiedActivities[index];

                                    String bikeId;
                                    String riderName;
                                    String relativeTime = 'Just now';
                                    bool isOngoing;

                                    if (item is ManualRental) {
                                      bikeId = item.bikeLabel;
                                      riderName = item.customerName;
                                      isOngoing = item.status ==
                                          ManualRentalStatus.active;

                                      final diff = DateTime.now()
                                          .difference(item.startTime);
                                      if (diff.inMinutes < 60) {
                                        relativeTime =
                                            '${diff.inMinutes} mins ago';
                                      } else if (diff.inHours < 24) {
                                        relativeTime =
                                            '${diff.inHours} hrs ago';
                                      } else {
                                        relativeTime =
                                            DateFormat('MMM dd, hh:mm a')
                                                .format(item.startTime);
                                      }
                                    } else {
                                      final riderProfile = item['profiles']
                                          as Map<String, dynamic>?;
                                      riderName =
                                          riderProfile?['full_name'] ?? 'Rider';
                                      final bikeObj = item['bikes']
                                          as Map<String, dynamic>?;
                                      bikeId = bikeObj?['identifier'] ?? 'Bike';
                                      final status =
                                          item['status'] as String? ??
                                              'ongoing';
                                      isOngoing = status == 'ongoing';

                                      final startTimeStr =
                                          item['start_time'] as String?;
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
                                    }

                                    final bikeDisplayName =
                                        bikeId.startsWith('#') ||
                                                int.tryParse(bikeId) != null
                                            ? 'Bike $bikeId'
                                            : bikeId;

                                    return GestureDetector(
                                      onTap: () =>
                                          _showActivityDetails(context, item),
                                      child: ActivityItem(
                                        title: riderName,
                                        subtitle:
                                            '${isOngoing ? 'Leased' : 'Returned'} $bikeDisplayName · $relativeTime',
                                        statusColor: isOngoing
                                            ? Colors.white54
                                            : AppColors.green,
                                        statusText:
                                            isOngoing ? 'Ongoing' : 'Completed',
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              if (availableBikes <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'No available bikes in inventory! Add new bikes or complete active checkouts to lease.',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              ManualRentalBottomSheet.show(
                context,
                onQuickLease: () => context.push(AppRoutes.adminScan),
              );
            },
            backgroundColor: AppColors.green,
            icon: const Icon(Icons.add, color: Colors.black),
            label: Text(
              'Lease',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
