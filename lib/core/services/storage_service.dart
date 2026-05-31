import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

class StorageService {
  StorageService(this._prefs);
  final SharedPreferences _prefs;

  static const _onboardingKey = 'has_seen_onboarding';
  static const _pendingRoleKey = 'pending_registration_role';
  static const _cachedUserKey = 'cached_user_profile';

  bool hasSeenOnboarding() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setHasSeenOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  String? getPendingRegistrationRole() {
    return _prefs.getString(_pendingRoleKey);
  }

  Future<void> setPendingRegistrationRole(String role) async {
    await _prefs.setString(_pendingRoleKey, role);
  }

  Future<void> clearPendingRegistrationRole() async {
    await _prefs.remove(_pendingRoleKey);
  }

  UserModel? getCachedUser() {
    final userJson = _prefs.getString(_cachedUserKey);
    if (userJson == null) return null;
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> setCachedUser(UserModel user) async {
    final userJson = jsonEncode(user.toMap());
    await _prefs.setString(_cachedUserKey, userJson);
  }

  Future<void> clearCachedUser() async {
    await _prefs.remove(_cachedUserKey);
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'storageServiceProvider must be overridden in ProviderScope',
  );
});

final hasSeenOnboardingProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.hasSeenOnboarding();
});

final pendingRegistrationRoleProvider = StateProvider<String?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getPendingRegistrationRole();
});
