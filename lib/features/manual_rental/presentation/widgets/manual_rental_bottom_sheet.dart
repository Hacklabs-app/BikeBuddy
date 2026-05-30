import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/manual_rental_provider.dart';

class ManualRentalBottomSheet extends ConsumerStatefulWidget {
  const ManualRentalBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ManualRentalBottomSheet(),
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
              Text(
                'Manual Rental Check-In',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                style: GoogleFonts.inter(color: Colors.white),
                decoration: _buildInputDecoration(
                  labelText: 'Customer Full Name',
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
                  icon: Icons.badge_outlined,
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'ID / Admission Number is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bikeController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: _buildInputDecoration(
                  labelText: 'Bicycle Label (Optional)',
                  icon: Icons.directions_bike_rounded,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ref.read(manualRentalsProvider.notifier).startRental(
                            customerName: _nameController.text.trim(),
                            customerPhone: _phoneController.text.trim(),
                            nationalId: _idController.text.trim(),
                            bikeLabel: _bikeController.text.trim().isNotEmpty
                                ? _bikeController.text.trim()
                                : 'Bike',
                          );
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
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Start Counting',
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
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.green, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
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
