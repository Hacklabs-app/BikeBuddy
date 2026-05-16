import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../state/discovery_state.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onNearestSelected,
  });

  final ShopFilter selectedFilter;
  final Function(ShopFilter) onFilterSelected;
  final VoidCallback onNearestSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterChip(
            label: 'Available',
            icon: Icons.electric_bike_rounded,
            isSelected: selectedFilter == ShopFilter.stock,
            onTap: () => onFilterSelected(ShopFilter.stock),
          ),
          _FilterChip(
            label: 'Price',
            icon: Icons.payments_outlined,
            isSelected: selectedFilter == ShopFilter.price,
            onTap: () => onFilterSelected(ShopFilter.price),
          ),
          _FilterChip(
            label: 'Rating',
            icon: Icons.star_outline_rounded,
            isSelected: selectedFilter == ShopFilter.rating,
            onTap: () => onFilterSelected(ShopFilter.rating),
          ),
          _FilterChip(
            label: 'Nearest',
            icon: Icons.near_me_outlined,
            isSelected: selectedFilter == ShopFilter.nearest,
            onTap: onNearestSelected,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.green : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
