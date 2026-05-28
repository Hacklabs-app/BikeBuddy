import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../state/auth_state.dart';

class OwnerSignUpScreen extends ConsumerStatefulWidget {
  const OwnerSignUpScreen({super.key});

  @override
  ConsumerState<OwnerSignUpScreen> createState() => _OwnerSignUpScreenState();
}

class _OwnerSignUpScreenState extends ConsumerState<OwnerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _stationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _stationController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAction() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authState = ref.read(authStateProvider).valueOrNull;
      final isLoggedIn = authState != null;
      bool success = false;

      final stationName = _stationController.text.trim();
      final normalizedPhone = Formatters.normalizePhoneNumber(_phoneController.text.trim()) ?? '';

      debugPrint('[UI LOG] Attempting to save Owner data:');
      debugPrint('│ Station: $stationName');
      debugPrint('│ Phone: $normalizedPhone');

      if (isLoggedIn) {
        // CASE: GOOGLE INTERCEPTOR or Manual signup without shop
        success = await ref
            .read(authNotifierProvider.notifier)
            .completeOwnerRegistration(
              stationName: stationName,
              phoneNumber: normalizedPhone,
            );
      } else {
        // CASE: MANUAL SIGN UP
        final created = await ref.read(authNotifierProvider.notifier).signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _nameController.text.trim(),
            );

        if (created) {
          success = await ref
              .read(authNotifierProvider.notifier)
              .completeOwnerRegistration(
                stationName: stationName,
                phoneNumber: normalizedPhone,
              );
        }
      }

      if (success && mounted) {
        context.go('/admin'); // Owners go to Admin/Dashboard
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authNotifierState = ref.watch(authNotifierProvider);
    final userSession = ref.watch(authStateProvider).valueOrNull;
    final isGoogleUser = userSession != null;

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  isGoogleUser ? 'Register Station' : 'Join as an Owner',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Set up your station and start managing rentals.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 40),
                if (!isGoogleUser) ...[
                  AuthTextField(
                    label: 'Full Name',
                    hint: 'Enter your name',
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (val) => (val == null || val.isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: 'Email',
                    hint: 'owner@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(val)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                AuthTextField(
                  label: 'Station Name',
                  hint: 'e.g. Central Park Bikes',
                  controller: _stationController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'Station name is required'
                      : null,
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  label: 'Phone Number',
                  hint: '+254...',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: !isGoogleUser
                      ? TextInputAction.next
                      : TextInputAction.done,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!Formatters.isValidPhoneNumber(val)) {
                      return 'Enter a valid phone number (e.g. 0701234567)';
                    }
                    return null;
                  },
                ),
                if (!isGoogleUser) ...[
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: 'Password',
                    hint: 'Min. 6 characters',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    validator: (val) => (val == null || val.length < 6)
                        ? 'At least 6 characters'
                        : null,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white24,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (val != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed:
                        authNotifierState.isLoading ? null : _handleAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authNotifierState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2),
                          )
                        : Text(
                            'Launch Station',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
