import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) {
    return AuthState(isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.signIn(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e.message));
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Connection failed. Check your network.',
      );
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.signInWithGoogle();
      // No need to set isLoading false here as page will redirect or re-emit auth state
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google sign-in failed.');
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.sendPasswordReset(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not send reset email. Try again.',
      );
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updatePassword(newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not update password.',
      );
      return false;
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Please verify your email address.';
    }
    if (message.contains('rate limit')) {
      return 'Too many attempts. Try again later.';
    }
    return message;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(Supabase.instance.client);
});

final authNotifierProvider =
    StateNotifierProvider.autoDispose<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
