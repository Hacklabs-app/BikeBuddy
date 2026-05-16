import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../shared/providers/auth_provider.dart';

class AuthState {
  final bool isEmailLoading;
  final bool isGoogleLoading;
  final String? error;

  const AuthState({
    this.isEmailLoading = false,
    this.isGoogleLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isEmailLoading,
    bool? isGoogleLoading,
    String? error,
  }) {
    return AuthState(
      isEmailLoading: isEmailLoading ?? this.isEmailLoading,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      error: error,
    );
  }

  bool get isLoading => isEmailLoading || isGoogleLoading;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(const AuthState());

  Future<bool> signIn(String email, String password) async {
    debugPrint('[AUTH] Attempting sign in for: $email');
    state = state.copyWith(isEmailLoading: true, error: null);
    try {
      await _repository.signIn(email: email, password: password);
      debugPrint('[AUTH] Sign in successful!');
      if (!mounted) return true;
      state = state.copyWith(isEmailLoading: false);
      return true;
    } on AuthException catch (e) {
      debugPrint('[AUTH] Sign in failed (AuthException): ${e.message}');
      if (!mounted) return false;
      state = state.copyWith(isEmailLoading: false, error: _mapAuthError(e.message));
      return false;
    } catch (e) {
      debugPrint('[AUTH] Sign in failed (Unknown): $e');
      if (!mounted) return false;
      state = state.copyWith(isEmailLoading: false, error: 'Connection failed. Check your network.');
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    debugPrint('[AUTH] Attempting sign up for: $email');
    state = state.copyWith(isEmailLoading: true, error: null);
    try {
      await _repository.signUp(email: email, password: password, fullName: fullName);
      debugPrint('[AUTH] Sign up successful!');
      if (!mounted) return true;
      state = state.copyWith(isEmailLoading: false);
      return true;
    } on AuthException catch (e) {
      debugPrint('[AUTH] Sign up failed (AuthException): ${e.message}');
      if (!mounted) return false;
      state = state.copyWith(isEmailLoading: false, error: e.message);
      return false;
    } catch (e) {
      debugPrint('[AUTH] Sign up failed (Unknown): $e');
      if (!mounted) return false;
      state = state.copyWith(isEmailLoading: false, error: 'Registration failed.');
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    debugPrint('[AUTH] Starting Google Auth flow...');
    state = state.copyWith(isGoogleLoading: true, error: null);
    try {
      await _repository.signInWithGoogle();
      debugPrint('[AUTH] Google Auth completed.');
      if (!mounted) return;
      state = state.copyWith(isGoogleLoading: false);
    } catch (e) {
      debugPrint('[AUTH] Google Auth failed: $e');
      if (!mounted) return;
      state = state.copyWith(isGoogleLoading: false, error: 'Google sign-in failed.');
    }
  }

  Future<bool> completeRiderRegistration({
    required String idNumber,
    String? phoneNumber,
  }) async {
    debugPrint('[AUTH] Completing Rider registration. ID: $idNumber');
    state = state.copyWith(isEmailLoading: true, error: null);
    try {
      await _repository.completeRiderRegistration(
        idNumber: idNumber,
        phoneNumber: phoneNumber,
      );
      
      debugPrint('[AUTH] Invalidation profile cache to reflect new role...');
      _ref.invalidate(currentUserProvider);
      
      debugPrint('[AUTH] Rider registration saved to database.');
      if (!mounted) return true;
      state = state.copyWith(isEmailLoading: false);
      return true;
    } catch (e) {
      debugPrint('[AUTH] Rider registration failed: $e');
      if (!mounted) return false;
      state = state.copyWith(isEmailLoading: false, error: 'Could not save profile details.');
      return false;
    }
  }

  Future<bool> completeOwnerRegistration({
    required String stationName,
    required String phoneNumber,
  }) async {
    debugPrint('[AUTH] Completing Owner registration. Station: $stationName');
    state = state.copyWith(isEmailLoading: true, error: null);
    try {
      await _repository.completeOwnerRegistration(
        stationName: stationName,
        phoneNumber: phoneNumber,
      );

      debugPrint('[AUTH] Invalidation profile cache to reflect new role...');
      _ref.invalidate(currentUserProvider);

      debugPrint('[AUTH] Owner registration and shop entry created.');
      if (!mounted) return true;
      state = state.copyWith(isEmailLoading: false);
      return true;
    } catch (e) {
      debugPrint('[AUTH] Owner registration failed: $e');
      if (!mounted) return false;
      state = state.copyWith(isEmailLoading: false, error: 'Could not save station details.');
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    debugPrint('[AUTH] Sending password reset link to: $email');
    state = state.copyWith(isEmailLoading: true, error: null);
    try {
      await _repository.sendPasswordReset(email);
      debugPrint('[AUTH] Reset email sent.');
      if (!mounted) return true;
      state = state.copyWith(isEmailLoading: false);
      return true;
    } catch (e) {
      debugPrint('[AUTH] Reset email failed: $e');
      if (!mounted) return false;
      state = state.copyWith(isEmailLoading: false, error: 'Could not send reset email.');
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    debugPrint('[AUTH] Attempting password update...');
    state = state.copyWith(isEmailLoading: true, error: null);
    try {
      await _repository.updatePassword(newPassword);
      debugPrint('[AUTH] Password updated successfully.');
      if (!mounted) return true;
      state = state.copyWith(isEmailLoading: false);
      return true;
    } catch (e) {
      debugPrint('[AUTH] Password update failed: $e');
      if (!mounted) return false;
      state = state.copyWith(isEmailLoading: false, error: 'Could not update password.');
      return false;
    }
  }

  Future<void> signOut() async {
    debugPrint('[AUTH] Signing out user...');
    state = state.copyWith(isEmailLoading: true, error: null);
    try {
      await _repository.signOut();
      debugPrint('[AUTH] User signed out.');
      if (!mounted) return;
      state = state.copyWith(isEmailLoading: false);
    } catch (e) {
      debugPrint('[AUTH] Sign out failed: $e');
      if (!mounted) return;
      state = state.copyWith(isEmailLoading: false, error: 'Could not sign out.');
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Incorrect email/password or account not found.';
    }
    if (message.contains('Email not confirmed')) return 'Please verify your email address.';
    if (message.contains('rate limit')) return 'Too many attempts. Try again later.';
    return message;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(Supabase.instance.client);
});

final authNotifierProvider = StateNotifierProvider.autoDispose<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, ref);
});
