import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../state/auth_state.dart';
import '../widgets/profile_form_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();

  final _shopNameController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _rateController = TextEditingController();
  final _totalBikesController = TextEditingController();

  TimeOfDay _shopOpenTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _shopCloseTime = const TimeOfDay(hour: 18, minute: 0);

  Map<String, dynamic>? _shopDetails;
  bool _isShopLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phoneNumber ?? '';
      _idNumberController.text = user.idNumber ?? '';
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _shopNameController.dispose();
    _shopPhoneController.dispose();
    _shopAddressController.dispose();
    _rateController.dispose();
    _totalBikesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    if (user.role == UserRole.owner) {
      setState(() => _isShopLoading = true);
      try {
        final client = Supabase.instance.client;
        final shop = await client
            .from('shops')
            .select()
            .eq('owner_id', user.id)
            .maybeSingle();

        if (shop != null && mounted) {
          _shopDetails = shop;
          _shopNameController.text = shop['name'] ?? '';
          _shopPhoneController.text = shop['phone_number'] ?? '';
          _shopAddressController.text = shop['address'] ?? '';
          _totalBikesController.text = (shop['total_bikes'] ?? 0).toString();

          if (shop['operating_hours_open'] != null) {
            final parts = (shop['operating_hours_open'] as String).split(':');
            if (parts.length >= 2) {
              _shopOpenTime = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 8,
                minute: int.tryParse(parts[1]) ?? 0,
              );
            }
          }

          if (shop['operating_hours_close'] != null) {
            final parts = (shop['operating_hours_close'] as String).split(':');
            if (parts.length >= 2) {
              _shopCloseTime = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 18,
                minute: int.tryParse(parts[1]) ?? 0,
              );
            }
          }

          final rateRes = await client
              .from('shop_rates')
              .select('rate_per_hour')
              .eq('shop_id', shop['id'])
              .maybeSingle();

          if (rateRes != null && mounted) {
            _rateController.text = (rateRes['rate_per_hour'] ?? 0).toString();
          } else {
            _rateController.text = '0';
          }
        }
      } catch (e) {
        debugPrint('[PROFILE ERROR] Failed to fetch shop details: $e');
      } finally {
        if (mounted) {
          setState(() => _isShopLoading = false);
        }
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(BuildContext context, bool isOpenTime) async {
    final initialTime = isOpenTime ? _shopOpenTime : _shopCloseTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.green,
              onPrimary: Colors.white,
              surface: AppColors.surfaceDark,
              onSurface: AppColors.textLight,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _shopOpenTime = picked;
        } else {
          _shopCloseTime = picked;
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    try {
      final client = Supabase.instance.client;

      final profilePayload = {
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        if (user.role == UserRole.customer)
          'id_number': _idNumberController.text.trim(),
      };

      await client.from('profiles').update(profilePayload).eq('id', user.id);

      if (user.role == UserRole.owner && _shopDetails != null) {
        final shopName = _shopNameController.text.trim();
        final shopTotalBikes =
            int.tryParse(_totalBikesController.text.trim()) ?? 0;

        final shopPayload = {
          'name': shopName,
          'phone_number': _shopPhoneController.text.trim(),
          'address': _shopAddressController.text.trim(),
          'total_bikes': shopTotalBikes,
          'operating_hours_open': _formatTime(_shopOpenTime),
          'operating_hours_close': _formatTime(_shopCloseTime),
        };

        await client.from('shops').update(shopPayload).eq('owner_id', user.id);

        final rateText = _rateController.text.trim();
        if (rateText.isNotEmpty) {
          final rateVal = int.tryParse(rateText) ?? 0;
          await client.from('shop_rates').upsert({
            'shop_id': _shopDetails!['id'],
            'rate_per_hour': rateVal,
          }, onConflict: 'shop_id');
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_shop_name', shopName);
          await prefs.setInt('cached_shop_total_bikes', shopTotalBikes);
        } catch (_) {}
      }

      final updatedUser = user.copyWith(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        idNumber: user.role == UserRole.customer
            ? _idNumberController.text.trim()
            : user.idNumber,
      );
      ref.read(currentUserProvider.notifier).updateLocalUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile and settings updated successfully!',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('[PROFILE ERROR] Failed to save changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user != null) {
        if (_nameController.text != user.fullName) {
          _nameController.text = user.fullName;
        }
        if (_phoneController.text != (user.phoneNumber ?? '')) {
          _phoneController.text = user.phoneNumber ?? '';
        }
        if (_idNumberController.text != (user.idNumber ?? '')) {
          _idNumberController.text = user.idNumber ?? '';
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
        ),
        title: Text(
          'Profile Settings',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: user == null || (user.role == UserRole.owner && _isShopLoading)
          ? const ProfileSkeletonLoading()
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ProfileSectionHeader(title: 'Personal Information'),
                    const SizedBox(height: 12),
                    ProfileCardContainer(children: [
                      ProfileTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      ProfileTextField(
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      if (user.role == UserRole.customer) ...[
                        const SizedBox(height: 16),
                        ProfileTextField(
                          controller: _idNumberController,
                          labelText: 'National ID Number',
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'ID number is required'
                              : null,
                        ),
                      ],
                    ]),
                    const SizedBox(height: 28),
                    if (user.role == UserRole.owner) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const ProfileSectionHeader(
                              title: 'Business / Station Details'),
                          if (_isShopLoading)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(AppColors.green),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ProfileBusinessDetailsSection(
                        shopNameController: _shopNameController,
                        shopPhoneController: _shopPhoneController,
                        shopAddressController: _shopAddressController,
                        rateController: _rateController,
                        totalBikesController: _totalBikesController,
                        shopOpenTime: _shopOpenTime,
                        shopCloseTime: _shopCloseTime,
                        onSelectOpenTime: () => _selectTime(context, true),
                        onSelectCloseTime: () => _selectTime(context, false),
                        formatTime: _formatTime,
                      ),
                      const SizedBox(height: 32),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.green.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Save Settings',
                                style: GoogleFonts.inter(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.surfaceDark,
                              title: Text('Sign Out',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              content: Text(
                                  'Are you sure you want to sign out of BikeBuddy?',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textMuted)),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('Cancel',
                                      style: GoogleFonts.inter(
                                          color: Colors.white54)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white),
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            await ref
                                .read(authNotifierProvider.notifier)
                                .signOut();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Colors.redAccent, width: 0.8),
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Sign Out',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
