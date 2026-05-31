import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../manual_rental/domain/models/manual_rental.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class DashboardActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool border;
  final VoidCallback onTap;

  const DashboardActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.border = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: border ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(14),
          border: border ? Border.all(color: Colors.white10) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: border ? AppColors.green : Colors.black, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: border ? Colors.white70 : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyActivityState extends StatelessWidget {
  const EmptyActivityState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_rounded, size: 48, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            'No live rental activity',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Active and completed rentals from your station will appear here in real-time.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color statusColor;
  final String statusText;

  const ActivityItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusColor,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityDetailsBottomSheet extends StatelessWidget {
  final dynamic item;

  const ActivityDetailsBottomSheet({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    String statusText;
    Color statusColor;
    List<Widget> details = [];

    if (item is ManualRental) {
      final rental = item as ManualRental;
      title = rental.customerName;
      subtitle = 'Manual Rental';
      statusText =
          rental.status == ManualRentalStatus.active ? 'Ongoing' : 'Completed';
      statusColor = rental.status == ManualRentalStatus.active
          ? Colors.white54
          : AppColors.green;

      details = [
        _buildDetailRow('Customer Name', rental.customerName),
        _buildDetailRow('Phone Number', rental.customerPhone),
        _buildDetailRow('ID / Admission Number',
            rental.nationalId.isNotEmpty ? rental.nationalId : 'None provided'),
        _buildDetailRow('Bicycle Label', rental.bikeLabel),
        _buildDetailRow('Start Time',
            DateFormat('MMM dd, yyyy · hh:mm a').format(rental.startTime)),
        if (rental.endTime != null)
          _buildDetailRow('End Time',
              DateFormat('MMM dd, yyyy · hh:mm a').format(rental.endTime!)),
        if (rental.totalAmount != null)
          _buildDetailRow(
              'Amount Paid', 'Ksh. ${rental.totalAmount!.toStringAsFixed(2)}'),
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
          startTimeFormatted = DateFormat('MMM dd, yyyy · hh:mm a')
              .format(DateTime.parse(startTimeStr).toLocal());
        } catch (_) {}
      }

      final endTimeStr = item['end_time'] as String?;
      String endTimeFormatted = 'Ongoing';
      if (endTimeStr != null) {
        try {
          endTimeFormatted = DateFormat('MMM dd, yyyy · hh:mm a')
              .format(DateTime.parse(endTimeStr).toLocal());
        } catch (_) {}
      }

      final totalAmt = item['total_amount'];
      final amountStr = totalAmt != null
          ? 'Ksh. ${(totalAmt as num).toStringAsFixed(2)}'
          : 'Ongoing';

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
}

class AddBikesDialog extends StatefulWidget {
  final Function(int) onAdd;

  const AddBikesDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddBikesDialog> createState() => _AddBikesDialogState();
}

class _AddBikesDialogState extends State<AddBikesDialog> {
  final _countController = TextEditingController(text: '1');

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _countController,
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
            final countText = _countController.text.trim();
            final count = int.tryParse(countText) ?? 0;
            if (count > 0) {
              Navigator.pop(context);
              widget.onAdd(count);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Add Bikes'),
        ),
      ],
    );
  }
}
