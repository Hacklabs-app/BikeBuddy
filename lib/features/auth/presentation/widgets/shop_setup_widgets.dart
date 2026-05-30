import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class ShopSetupOperatingHours extends StatelessWidget {
  final TimeOfDay openTime;
  final TimeOfDay closeTime;
  final VoidCallback onSelectOpenTime;
  final VoidCallback onSelectCloseTime;
  final String Function(TimeOfDay) formatTime;

  const ShopSetupOperatingHours({
    super.key,
    required this.openTime,
    required this.closeTime,
    required this.onSelectOpenTime,
    required this.onSelectCloseTime,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Opening Time',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: onSelectOpenTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatTime(openTime),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const Icon(
                        Icons.access_time,
                        color: AppColors.green,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Closing Time',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: onSelectCloseTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatTime(closeTime),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const Icon(
                        Icons.access_time,
                        color: AppColors.green,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ShopSetupLocationPicker extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final bool isLocatingGps;
  final VoidCallback onGetCurrentLocation;
  final VoidCallback onChooseOnMap;

  const ShopSetupLocationPicker({
    super.key,
    this.latitude,
    this.longitude,
    required this.isLocatingGps,
    required this.onGetCurrentLocation,
    required this.onChooseOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latitude != null && longitude != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.green, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Location Selected!',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Where are you now?',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLocatingGps ? null : onGetCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  foregroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: AppColors.green.withValues(alpha: 0.3)),
                  ),
                  elevation: 0,
                ),
                icon: isLocatingGps
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.green),
                        ),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(
                  isLocatingGps ? 'Locating...' : 'At Station',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onChooseOnMap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  foregroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: AppColors.green.withValues(alpha: 0.3)),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.map, size: 18),
                label: Text(
                  'Choose on Map',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
