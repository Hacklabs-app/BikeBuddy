import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/discovery_shop.dart';
import 'glass_container.dart';

class ShopDetailSheet extends StatelessWidget {
  const ShopDetailSheet({super.key, required this.shop});
  final DiscoveryShop shop;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_US');

    // In the future, this will be calculated from backend hours
    final bool isOpen = DateTime.now().hour >= 8 && DateTime.now().hour < 20;

    return GlassContainer(
      borderRadius: 32,
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Store Name
          Text(
            shop.name,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            shop.address,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 48),

          // THE POWER ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PowerData(
                label: 'BIKES AVAILABLE',
                value: shop.availableBikes.toString(),
                color: shop.availableBikes < 5
                    ? const Color(0xFFFF5252)
                    : AppColors.green,
              ),
              _PowerData(
                label: 'HOURLY RATE',
                value: currencyFormat.format(shop.ratePerHour),
                color: Colors.white,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // THE STATUS LINE
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal:
                    BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatusText(
                  text: isOpen ? 'OPEN NOW' : 'CLOSED',
                  color: isOpen ? AppColors.green : Colors.white24,
                ),
                const _DotSeparator(),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFD700), size: 16),
                    const SizedBox(width: 4),
                    _StatusText(
                      text: shop.rating.toStringAsFixed(1),
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ],
                ),
                if (shop.distanceKm != null) ...[
                  const _DotSeparator(),
                  _StatusText(
                      text: '${shop.distanceKm!.toStringAsFixed(1)} KM AWAY'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerData extends StatelessWidget {
  const _PowerData(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1.0,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.text, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: color ?? Colors.white.withValues(alpha: 0.4),
      ),
    );
  }
}

class _DotSeparator extends StatelessWidget {
  const _DotSeparator();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
