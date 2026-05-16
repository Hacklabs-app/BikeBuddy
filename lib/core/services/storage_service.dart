import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  StorageService(this._prefs);
  final SharedPreferences _prefs;

  static const _onboardingKey = 'has_seen_onboarding';

  bool hasSeenOnboarding() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setHasSeenOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
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
