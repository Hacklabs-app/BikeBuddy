import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/manual_rental.dart';
import '../providers/manual_rental_provider.dart';
import '../widgets/active_manual_rental_tile.dart';

class ManualRentalScreen extends ConsumerStatefulWidget {
  const ManualRentalScreen({super.key});

  @override
  ConsumerState<ManualRentalScreen> createState() => _ManualRentalScreenState();
}

class _ManualRentalScreenState extends ConsumerState<ManualRentalScreen> {


  @override
  Widget build(BuildContext context) {
    final activeRentals = ref.watch(activeManualRentalsProvider);
    final completedRentals = ref.watch(completedManualRentalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Activity',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Active Rentals',
                            value: '${activeRentals.length}',
                            color: AppColors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Completed Today',
                            value: '${completedRentals.length}',
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      title: 'Active Rentals',
                      badgeCount: activeRentals.length,
                    ),
                    const SizedBox(height: 12),
                    if (activeRentals.isEmpty)
                      _buildEmptyState(
                        icon: Icons.timer_outlined,
                        title: 'No Active Rentals',
                        subtitle: 'Use the button below to register a customer and start timing.',
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeRentals.length,
                        itemBuilder: (context, index) {
                          final rental = activeRentals[index];
                          return ActiveManualRentalTile(rental: rental);
                        },
                      ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      title: 'Recent Activity Logs',
                      badgeCount: completedRentals.length,
                    ),
                    const SizedBox(height: 12),
                    if (completedRentals.isEmpty)
                      _buildEmptyState(
                        icon: Icons.history_rounded,
                        title: 'Activity Log Empty',
                        subtitle: 'Completed transactions will appear here.',
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: completedRentals.length,
                        itemBuilder: (context, index) {
                          final rental = completedRentals[index];
                          final formattedTime = DateFormat('MMM d, h:mm a')
                              .format(rental.startTime);
                          final durationStr = _getDurationString(
                              rental.startTime, rental.endTime);

                           return Dismissible(
                            key: Key('rental_${rental.id}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: AppColors.surfaceDark,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Text(
                                      'Delete Activity Log?',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to permanently delete the rental record for ${rental.customerName}? This action cannot be undone.',
                                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              return result ?? false;
                            },
                            onDismissed: (direction) {
                              ref.read(manualRentalsProvider.notifier).deleteRental(rental.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Rental record deleted.',
                                    style: GoogleFonts.inter(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () => _showContactOptionsBottomSheet(context, rental),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.03)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rental.customerName,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${rental.bikeLabel} · $durationStr',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          if (rental.nationalId.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'ID/Adm: ${rental.nationalId} · ${rental.customerPhone}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white30,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 2),
                                          Text(
                                            formattedTime,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: Colors.white30,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Ksh ${rental.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () => _showDeleteConfirmation(context, rental),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactOptionsBottomSheet(BuildContext context, ManualRental rental) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF141419),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(color: Colors.white10),
            ),
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
              Text(
                rental.customerName,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Completed Rental Details',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number',
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rental.customerPhone,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse('tel:${rental.customerPhone}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not initiate call to ${rental.customerPhone}')),
                          );
                        }
                      }
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_rounded, color: AppColors.green, size: 20),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID / Admission Number',
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rental.nationalId.isNotEmpty ? rental.nationalId : 'None provided',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bicycle Label / ID',
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rental.bikeLabel,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, ManualRental rental) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Activity Log?',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete the rental record for ${rental.customerName}? This action cannot be undone.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(manualRentalsProvider.notifier).deleteRental(rental.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Rental record deleted.',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required int badgeCount}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$badgeCount',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white30,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _getDurationString(DateTime start, DateTime? end) {
    final diff = (end ?? DateTime.now()).difference(start);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins';
    } else {
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      return '${hours}h ${mins}m';
    }
  }
}


