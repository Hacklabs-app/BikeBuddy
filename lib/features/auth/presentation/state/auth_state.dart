import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

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

  AuthNotifier(this._repository) : super(const AuthState());

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isEmailLoading: true, error: null);
    try {
      await _repository.signIn(email: email, password: password);
      state = state.copyWith(isEmailLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isEmailLoading: false, error: _mapAuthError(e.message));
      return false;
    } catch (e) {
      state = state.copyWith(isEmailLoading: false, error: 'Connection failed. Check your network.');
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isGoogleLoading: true, error: null);
    try {
      await _repository.signInWithGoogle();
      // On success, the app will either redirect or the auth listener will trigger
      state = state.copyWith(isGoogleLoading: false);
    } catch (e) {
      state = state.copyWith(isGoogleLoading: false, error: 'Google sign-in failed.');
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isEmailLoading: true, error: null);
    try {
      await _repository.sendPasswordReset(email);
      state = state.copyWith(isEmailLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isEmailLoading: false, error: 'Could not send reset email.');
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    state = state.copyWith(isEmailLoading: true, error: null);
    try {
      await _repository.updatePassword(newPassword);
      state = state.copyWith(isEmailLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isEmailLoading: false, error: 'Could not update password.');
      return false;
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) return 'Incorrect email or password.';
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
  return AuthNotifier(repository);
});
