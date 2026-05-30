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

  void _showActivityDetails(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String title;
        String subtitle;
        String statusText;
        Color statusColor;
        List<Widget> details = [];

        if (item is ManualRental) {
          title = item.customerName;
          subtitle = 'Manual Rental';
          statusText = item.status == ManualRentalStatus.active ? 'Ongoing' : 'Completed';
          statusColor = item.status == ManualRentalStatus.active ? Colors.white54 : AppColors.green;

          details = [
            _buildDetailRow('Customer Name', item.customerName),
            _buildDetailRow('Phone Number', item.customerPhone),
            _buildDetailRow('ID / Admission Number', item.nationalId.isNotEmpty ? item.nationalId : 'None provided'),
            _buildDetailRow('Bicycle Label', item.bikeLabel),
            _buildDetailRow('Start Time', DateFormat('MMM dd, yyyy · hh:mm a').format(item.startTime)),
            if (item.endTime != null)
              _buildDetailRow('End Time', DateFormat('MMM dd, yyyy · hh:mm a').format(item.endTime!)),
            if (item.totalAmount != null)
              _buildDetailRow('Amount Paid', 'Ksh. ${item.totalAmount!.toStringAsFixed(2)}'),
          ];
        } else {
          final profile = item['profiles'] as Map<String, dynamic>?;
          final riderName = profile?['full_name'] ?? 'Rider';
          final bikeObj = item['bikes'] as Map<String, dynamic>?;
          final bikeId = bikeObj?['identifier'] ?? 'Bike';
          final status = item['status'] as String? ?? 'ongoing';
          final isOngoing = status == 'ongoing';

          title = riderName;
          subtitle = 'App Rental';
          statusText = isOngoing ? 'Ongoing' : 'Completed';
          statusColor = isOngoing ? Colors.white54 : AppColors.green;

          final startTimeStr = item['start_time'] as String?;
          String startTimeFormatted = 'Unknown';
          if (startTimeStr != null) {
            try {
              startTimeFormatted = DateFormat('MMM dd, yyyy · hh:mm a').format(DateTime.parse(startTimeStr).toLocal());
            } catch (_) {}
          }

          final endTimeStr = item['end_time'] as String?;
          String endTimeFormatted = 'Ongoing';
          if (endTimeStr != null) {
            try {
              endTimeFormatted = DateFormat('MMM dd, yyyy · hh:mm a').format(DateTime.parse(endTimeStr).toLocal());
            } catch (_) {}
          }

          final totalAmt = item['total_amount'];
          final amountStr = totalAmt != null ? 'Ksh. ${(totalAmt as num).toStringAsFixed(2)}' : 'Ongoing';

          details = [
            _buildDetailRow('Rider Name', riderName),
            _buildDetailRow('Bicycle ID', 'Bike $bikeId'),
            _buildDetailRow('Start Time', startTimeFormatted),
            _buildDetailRow('End Time', endTimeFormatted),
            _buildDetailRow('Amount Paid', amountStr),
            if (item['notes'] != null && item['notes'].toString().isNotEmpty)
              _buildDetailRow('Notes', item['notes'].toString()),
          ];
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF141419),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      statusText.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...details,
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
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
        
        // Watch active manual rentals to combine them dynamically into the dashboard metrics
        final activeManualRentals = ref.watch(activeManualRentalsProvider);
        final activeManualCount = activeManualRentals.length;
        final manualRentals = ref.watch(manualRentalsProvider);
        
        final totalActiveRentals = _activeRentalsCount + activeManualCount;
        final availableBikes = (totalBikes - totalActiveRentals).clamp(0, totalBikes);

        // Combine database activities and local manual rentals into a sorted list
        final List<dynamic> unifiedActivities = [...manualRentals];
        for (final act in _recentActivities) {
          final id = act['id'];
          if (!manualRentals.any((m) => m.id == id)) {
            unifiedActivities.add(act);
          }
        }
        unifiedActivities.sort((a, b) {
          final DateTime timeA = a is ManualRental ? a.startTime : DateTime.parse(a['start_time']);
          final DateTime timeB = b is ManualRental ? b.startTime : DateTime.parse(b['start_time']);
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
                          left: 20, right: 20, top: 16, bottom: 80), // extra padding for FAB
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
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, idx) {
                                final rental = activeManualRentals[idx];
                                return ActiveManualRentalTile(rental: rental);
                              },
                            ),
                          ],

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
                              if (unifiedActivities.isNotEmpty)
                                GestureDetector(
                                  onTap: () => context.push(AppRoutes.manualRental),
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
                                      isOngoing = item.status == ManualRentalStatus.active;
                                      
                                      final diff = DateTime.now().difference(item.startTime);
                                      if (diff.inMinutes < 60) {
                                        relativeTime = '${diff.inMinutes} mins ago';
                                      } else if (diff.inHours < 24) {
                                        relativeTime = '${diff.inHours} hrs ago';
                                      } else {
                                        relativeTime = DateFormat('MMM dd, hh:mm a').format(item.startTime);
                                      }
                                    } else {
                                      final riderProfile = item['profiles'] as Map<String, dynamic>?;
                                      riderName = riderProfile?['full_name'] ?? 'Rider';
                                      final bikeObj = item['bikes'] as Map<String, dynamic>?;
                                      bikeId = bikeObj?['identifier'] ?? 'Bike';
                                      final status = item['status'] as String? ?? 'ongoing';
                                      isOngoing = status == 'ongoing';
                                      
                                      final startTimeStr = item['start_time'] as String?;
                                      if (startTimeStr != null) {
                                        try {
                                          final startTime = DateTime.parse(startTimeStr).toLocal();
                                          final diff = DateTime.now().difference(startTime);
                                          if (diff.inMinutes < 60) {
                                            relativeTime = '${diff.inMinutes} mins ago';
                                          } else if (diff.inHours < 24) {
                                            relativeTime = '${diff.inHours} hrs ago';
                                          } else {
                                            relativeTime = DateFormat('MMM dd, hh:mm a').format(startTime);
                                          }
                                        } catch (_) {}
                                      }
                                    }

                                    return GestureDetector(
                                      onTap: () => _showActivityDetails(context, item),
                                      child: ActivityItem(
                                        title: bikeId.startsWith('#') || int.tryParse(bikeId) != null ? 'Bike $bikeId' : bikeId,
                                        subtitle: 'By $riderName · $relativeTime',
                                        statusColor: isOngoing ? Colors.white54 : AppColors.green,
                                        statusText: isOngoing ? 'Ongoing' : 'Completed',
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
            onPressed: () => ManualRentalBottomSheet.show(context),
            backgroundColor: AppColors.green,
            icon: const Icon(Icons.add, color: Colors.black),
            label: Text(
              'Manual Rent',
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
