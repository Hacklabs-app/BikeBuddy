import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/auth_text_field.dart';
import '../state/auth_state.dart';
import 'package:url_launcher/url_launcher.dart';

class RiderSignUpScreen extends ConsumerStatefulWidget {
  const RiderSignUpScreen({super.key});

  @override
  ConsumerState<RiderSignUpScreen> createState() => _RiderSignUpScreenState();
}

class _RiderSignUpScreenState extends ConsumerState<RiderSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _idController.dispose();
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

      final normalizedPhone = Formatters.normalizePhoneNumber(_phoneController.text);

      if (isLoggedIn) {
        // CASE: GOOGLE INTERCEPTOR
        // User already has an account, just saving missing profile data
        success = await ref
            .read(authNotifierProvider.notifier)
            .completeRiderRegistration(
              idNumber: _idController.text.trim(),
              phoneNumber: normalizedPhone,
            );
      } else {
        final response = await ref.read(authNotifierProvider.notifier).signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _nameController.text.trim(),
            );

        if (response != null) {
          final isEmailVerificationRequired = response.session == null;
          if (!isEmailVerificationRequired) {
            // 2. Profile is auto-created by DB trigger, now update the ID number
            success = await ref
                .read(authNotifierProvider.notifier)
                .completeRiderRegistration(
                  idNumber: _idController.text.trim(),
                  phoneNumber: normalizedPhone,
                );
          } else {
            // Email verification is required, so user is not logged in yet.
            await ref.read(storageServiceProvider).setPendingRegistrationRole('customer');
            ref.read(pendingRegistrationRoleProvider.notifier).state = 'customer';
            if (mounted) {
              context.go('/email-verification');
              return;
            }
          }
        }
      }

      if (success && mounted) {
        // Router will naturally redirect to /home once the ID number resolves in profiles
        context.go('/home');
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
                  isGoogleUser ? 'One Last Step' : 'Create Rider Profile',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isGoogleUser
                      ? 'Please provide your ID to start riding.'
                      : 'Enter your details to start pedaling.',
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
                    hint: 'name@example.com',
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
                if (isGoogleUser) ...[
                  AuthTextField(
                    label: 'ID / Admission Number',
                    hint: 'Registration number',
                    controller: _idController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'ID / Admission number is required';
                      }
                      if (!Formatters.isValidIdOrAdmission(val)) {
                        return 'Enter a valid ID (7-9 digits) or Admission number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: 'Phone (Optional)',
                    hint: '+254...',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    validator: (val) {
                      if (val != null && val.isNotEmpty && !Formatters.isValidPhoneNumber(val)) {
                        return 'Enter a valid phone number (e.g. 0701234567)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],
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
                  const SizedBox(height: 24),
                  FormField<bool>(
                    initialValue: _acceptedTerms,
                    validator: (value) {
                      if (value != true) {
                        return 'You must accept the terms and conditions to proceed';
                      }
                      return null;
                    },
                    builder: (state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: state.value ?? false,
                                  onChanged: (val) {
                                    state.didChange(val);
                                    setState(() {
                                      _acceptedTerms = val ?? false;
                                    });
                                  },
                                  activeColor: AppColors.green,
                                  checkColor: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final url = Uri.parse('https://www.freeprivacypolicy.com/live/e7a1012e-6a5c-406e-bd69-a6d7fa307f02');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                      children: [
                                        const TextSpan(text: 'I accept the '),
                                        TextSpan(
                                          text: 'Terms and Conditions',
                                          style: GoogleFonts.inter(
                                            color: AppColors.green,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (state.hasError) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 36),
                              child: Text(
                                state.errorText ?? '',
                                style: GoogleFonts.inter(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
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
                      backgroundColor: AppColors.green,
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
                            isGoogleUser
                                ? 'Finish Setup'
                                : 'Complete Registration',
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
