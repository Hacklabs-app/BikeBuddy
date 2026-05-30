import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/manual_rental_provider.dart';

class ManualRentalBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onQuickLease;
  const ManualRentalBottomSheet({super.key, this.onQuickLease});

  static void show(BuildContext context, {VoidCallback? onQuickLease}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManualRentalBottomSheet(onQuickLease: onQuickLease),
    );
  }

  @override
  ConsumerState<ManualRentalBottomSheet> createState() => _ManualRentalBottomSheetState();
}

class _ManualRentalBottomSheetState extends ConsumerState<ManualRentalBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _bikeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _bikeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
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
                    Expanded(
                      child: Text(
                        'Lease a Bike',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.onQuickLease != null) {
                            widget.onQuickLease!();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Launch Bike QR scanner to initiate checkout...',
                                  style: GoogleFonts.inter(color: Colors.white),
                                ),
                                backgroundColor: AppColors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.qr_code_scanner_rounded, color: AppColors.green, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Quick Lease',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Direct manual rental registration. Starts counting duration immediately.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: _buildInputDecoration(
                    labelText: 'Customer Full Name',
                    hintText: 'Enter customer\'s name',
                    icon: Icons.person_outline_rounded,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  style: GoogleFonts.inter(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. 0712345678',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Phone is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idController,
                  style: GoogleFonts.inter(color: Colors.white),
                  keyboardType: TextInputType.text,
                  decoration: _buildInputDecoration(
                    labelText: 'ID / Admission Number',
                    hintText: 'Enter National ID or Admin No.',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'ID / Admission Number is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bikeController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: _buildInputDecoration(
                    labelText: 'Bicycle Label (Optional)',
                    hintText: 'e.g. Red-03, Blue-01',
                    icon: Icons.directions_bike_rounded,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final prefs = await SharedPreferences.getInstance();
                        final totalBikes = prefs.getInt('cached_shop_total_bikes') ?? 0;
                        final activeDbCount = prefs.getInt('cached_active_database_rentals') ?? 0;
                        final activeManualCount = ref.read(activeManualRentalsProvider).length;
                        
                        final totalActive = activeDbCount + activeManualCount;
                        if (totalBikes > 0 && totalActive >= totalBikes) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'All $totalBikes bicycles are currently checked out. Cannot rent more!',
                                  style: GoogleFonts.inter(color: Colors.white),
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          return;
                        }

                        ref.read(manualRentalsProvider.notifier).startRental(
                              customerName: _nameController.text.trim(),
                              customerPhone: _phoneController.text.trim(),
                              nationalId: _idController.text.trim(),
                              bikeLabel: _bikeController.text.trim().isNotEmpty
                                  ? _bikeController.text.trim()
                                  : 'Bike',
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Manual rental started for ${_nameController.text.trim()}!',
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                              backgroundColor: AppColors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Lease Bike',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
      hintText: hintText,
      hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.green, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white10),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.green),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
