import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/manual_rental.dart';
import '../providers/manual_rental_provider.dart';

class ActiveManualRentalTile extends ConsumerStatefulWidget {
  final ManualRental rental;
  const ActiveManualRentalTile({super.key, required this.rental});

  @override
  ConsumerState<ActiveManualRentalTile> createState() => _ActiveManualRentalTileState();
}

class _ActiveManualRentalTileState extends ConsumerState<ActiveManualRentalTile> {
  Timer? _timer;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = DateTime.now().difference(widget.rental.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration = DateTime.now().difference(widget.rental.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                'Contact & Rental Info',
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
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showReturnConfirmation(context, rental, _duration);
                  },
                  icon: const Icon(Icons.assignment_return_outlined, size: 18),
                  label: Text(
                    'Return Bike',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours = _duration.inHours;
    final minutes = _duration.inMinutes.remainder(60);
    final seconds = _duration.inSeconds.remainder(60);
    final timeStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _showContactOptionsBottomSheet(context, widget.rental),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.rental.customerName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID/Admission: ${widget.rental.nationalId} · Phone: ${widget.rental.customerPhone}',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: AppColors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: GoogleFonts.outfit(
                          color: AppColors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _showReturnConfirmation(context, widget.rental, _duration),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green.withValues(alpha: 0.1),
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Return Bike',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReturnConfirmation(BuildContext context, ManualRental rental, Duration duration) {
    final minutes = duration.inMinutes.clamp(1, double.infinity);
    final hours = minutes / 60.0;
    final totalAmount = double.parse((hours * rental.hourlyRate).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Confirm Return',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to return the bike for ${rental.customerName}?',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Duration:', style: GoogleFonts.inter(color: AppColors.textMuted)),
                  Text('${duration.inMinutes} mins', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rate:', style: GoogleFonts.inter(color: AppColors.textMuted)),
                  Text('Ksh. ${rental.hourlyRate}/hr', style: GoogleFonts.inter(color: Colors.white)),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AMOUNT DUE:', style: GoogleFonts.inter(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                  Text('Ksh. $totalAmount', style: GoogleFonts.outfit(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(manualRentalsProvider.notifier).endRental(rental.id);
                Navigator.pop(context);
                
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surfaceDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      'Receipt Printed',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Rental registration completed successfully! Collect Ksh. $totalAmount from ${rental.customerName}.',
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                        child: const Text('OK', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.black,
              ),
              child: const Text('Complete Rental'),
            ),
          ],
        );
      },
    );
  }
}
