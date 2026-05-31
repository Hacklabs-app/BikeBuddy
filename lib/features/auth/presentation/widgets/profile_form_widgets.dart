import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/skeleton_block.dart';

class ProfileSectionHeader extends StatelessWidget {
  final String title;

  const ProfileSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    );
  }
}

class ProfileCardContainer extends StatelessWidget {
  final List<Widget> children;

  const ProfileCardContainer({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white30, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class ProfileBusinessDetailsSection extends StatelessWidget {
  final TextEditingController shopNameController;
  final TextEditingController shopPhoneController;
  final TextEditingController shopAddressController;
  final TextEditingController rateController;
  final TextEditingController totalBikesController;
  final TimeOfDay shopOpenTime;
  final TimeOfDay shopCloseTime;
  final VoidCallback onSelectOpenTime;
  final VoidCallback onSelectCloseTime;
  final String Function(TimeOfDay) formatTime;

  const ProfileBusinessDetailsSection({
    super.key,
    required this.shopNameController,
    required this.shopPhoneController,
    required this.shopAddressController,
    required this.rateController,
    required this.totalBikesController,
    required this.shopOpenTime,
    required this.shopCloseTime,
    required this.onSelectOpenTime,
    required this.onSelectCloseTime,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileCardContainer(
      children: [
        ProfileTextField(
          controller: shopNameController,
          labelText: 'Station Name',
          icon: Icons.storefront_outlined,
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Please enter station name'
              : null,
        ),
        const SizedBox(height: 16),
        ProfileTextField(
          controller: shopPhoneController,
          labelText: 'Station Phone',
          icon: Icons.contact_phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        ProfileTextField(
          controller: shopAddressController,
          labelText: 'Address / Landmark',
          icon: Icons.location_on_outlined,
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Please enter address' : null,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProfileTextField(
                controller: rateController,
                labelText: 'Amount/Hr (KES)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null || parsed < 0) return 'Invalid';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfileTextField(
                controller: totalBikesController,
                labelText: 'Total Bikes',
                icon: Icons.pedal_bike_rounded,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null || parsed < 0) return 'Invalid';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onSelectOpenTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Opens At',
                              style: GoogleFonts.inter(
                                  color: AppColors.textMuted, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(formatTime(shopOpenTime),
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Icon(Icons.access_time_rounded,
                          color: Colors.white30, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onSelectCloseTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Closes At',
                              style: GoogleFonts.inter(
                                  color: AppColors.textMuted, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(formatTime(shopCloseTime),
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Icon(Icons.access_time_rounded,
                          color: Colors.white30, size: 18),
                    ],
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

class ProfileSkeletonLoading extends StatelessWidget {
  const ProfileSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 150, height: 18),
          SizedBox(height: 12),
          ProfileCardContainer(children: [
            SkeletonBlock(width: double.infinity, height: 48, borderRadius: 12),
            SizedBox(height: 16),
            SkeletonBlock(width: double.infinity, height: 48, borderRadius: 12),
          ]),
          SizedBox(height: 28),
          SkeletonBlock(width: 180, height: 18),
          SizedBox(height: 12),
          ProfileCardContainer(children: [
            SkeletonBlock(width: double.infinity, height: 48, borderRadius: 12),
            SizedBox(height: 16),
            SkeletonBlock(width: double.infinity, height: 48, borderRadius: 12),
            SizedBox(height: 16),
            SkeletonBlock(width: double.infinity, height: 48, borderRadius: 12),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: SkeletonBlock(
                        width: double.infinity, height: 48, borderRadius: 12)),
                SizedBox(width: 12),
                Expanded(
                    child: SkeletonBlock(
                        width: double.infinity, height: 48, borderRadius: 12)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: SkeletonBlock(
                        width: double.infinity, height: 48, borderRadius: 12)),
                SizedBox(width: 12),
                Expanded(
                    child: SkeletonBlock(
                        width: double.infinity, height: 48, borderRadius: 12)),
              ],
            ),
          ]),
          SizedBox(height: 32),
          SkeletonBlock(width: double.infinity, height: 52, borderRadius: 14),
          SizedBox(height: 20),
          SkeletonBlock(width: double.infinity, height: 52, borderRadius: 14),
        ],
      ),
    );
  }
}

class ProfilePersonalDetailsSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController? idNumberController;
  final bool isCustomer;

  const ProfilePersonalDetailsSection({
    super.key,
    required this.nameController,
    required this.phoneController,
    this.idNumberController,
    required this.isCustomer,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileCardContainer(children: [
      ProfileTextField(
        controller: nameController,
        labelText: 'Full Name',
        icon: Icons.person_outline_rounded,
        validator: (val) =>
            val == null || val.trim().isEmpty ? 'Please enter your name' : null,
      ),
      const SizedBox(height: 16),
      ProfileTextField(
        controller: phoneController,
        labelText: 'Phone Number',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
      ),
      if (isCustomer && idNumberController != null) ...[
        const SizedBox(height: 16),
        ProfileTextField(
          controller: idNumberController!,
          labelText: 'National ID Number',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          validator: (val) => val == null || val.trim().isEmpty
              ? 'ID number is required'
              : null,
        ),
      ],
    ]);
  }
}
