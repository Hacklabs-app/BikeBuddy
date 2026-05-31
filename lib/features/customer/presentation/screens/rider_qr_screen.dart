import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/qr_encryption_helper.dart';
import '../../../../core/widgets/floating_bottom_nav.dart';
import '../../../../shared/providers/auth_provider.dart';

class RiderQrScreen extends ConsumerWidget {
  const RiderQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Rider Pass',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          userAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            ),
            error: (err, _) => Center(
              child: Text(
                'Failed to load profile details.',
                style: GoogleFonts.inter(color: Colors.redAccent),
              ),
            ),
            data: (user) {
              if (user == null) {
                return Center(
                  child: Text(
                    'No active profile found.',
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                );
              }

              // Generate encrypted payload with rider details
              final encryptedPayload = QrEncryptionHelper.encryptRiderPayload(
                id: user.id,
                name: user.fullName,
                phone: user.phoneNumber ?? '',
              );

              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                key: const Key('rider_qr_content'),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Beautiful translucent premium card container for QR code
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.05),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Subtly glowing outer border for QR
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: encryptedPayload,
                              version: QrVersions.auto,
                              size: 220,
                              gapless: false,
                              embeddedImage: const AssetImage('assets/images/logo.png'),
                              embeddedImageStyle: const QrEmbeddedImageStyle(
                                size: Size(44, 44),
                              ),
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            user.fullName,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                            Text(
                              user.phoneNumber!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Quick Lease Attendant Scan',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Present this secure QR code to the station attendant. They will scan it to immediately lease your bicycle offline or online!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              );
            },
          ),
          const Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: FloatingBottomNav(activeTab: FloatingNavTab.scan),
          ),
        ],
      ),
    );
  }
}
