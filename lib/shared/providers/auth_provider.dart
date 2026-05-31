import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/user_model.dart';
import '../../core/services/storage_service.dart';

// Streams the current Supabase User — emits null when logged out.
// Yields the cached session user first so the router doesn't flash /login
// on cold-start when the user is already authenticated.
final authStateProvider = StreamProvider<User?>((ref) async* {
  final client = Supabase.instance.client;
  yield client.auth.currentUser;
  await for (final event in client.auth.onAuthStateChange) {
    yield event.session?.user;
  }
});

class CurrentUserNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final user = ref.watch(authStateProvider).valueOrNull;
    final storage = ref.read(storageServiceProvider);

    if (user == null) {
      // If offline/disconnected, check if there's a cached session profile on-device
      final cached = storage.getCachedUser();
      if (cached != null) {
        debugPrint(
            '[OFFLINE] Decoupled session. Active cached profile loaded: ${cached.id} (${cached.role})');
        return cached;
      }
      return null;
    }

    // Cache-First (SWR) Retrieval: if cache exists, load instantly and sync in the background
    final cached = storage.getCachedUser();
    if (cached != null && cached.id == user.id) {
      debugPrint(
          '[SWR] Instant load cached profile for ${cached.id} (${cached.role})');
      _syncProfileInBackground(user, cached);
      return cached;
    }

    // No cache exists yet (cold-start with new user): perform synchronous blocking network fetch
    return _fetchProfileFromNetwork(user);
  }

  Future<UserModel?> _fetchProfileFromNetwork(User user) async {
    final client = Supabase.instance.client;
    final storage = ref.read(storageServiceProvider);

    debugPrint('[API REQUEST] Fetching profile for user: ${user.id}');
    final data =
        await client.from('profiles').select().eq('id', user.id).maybeSingle();

    if (data == null) {
      debugPrint('[API RESPONSE] Profile not found for user: ${user.id}');
      return null;
    }

    debugPrint('[API RESPONSE] Profile fetched successfully: ${data['role']}');
    String? shopId;
    if (data['role'] == 'owner') {
      debugPrint('[API REQUEST] User is owner, fetching shop details...');
      final shopData = await client
          .from('shops')
          .select('id')
          .eq('owner_id', user.id)
          .maybeSingle();
      shopId = shopData?['id'] as String?;
      debugPrint('[API RESPONSE] Shop ID: $shopId');
    }

    final fetchedUser =
        UserModel.fromMap({...data, 'email': user.email, 'shop_id': shopId});
    await storage.setCachedUser(fetchedUser);
    return fetchedUser;
  }

  Future<void> _syncProfileInBackground(User user, UserModel cached) async {
    try {
      final updatedUser = await _fetchProfileFromNetwork(user);
      if (updatedUser != null && _isProfileChanged(cached, updatedUser)) {
        debugPrint(
            '[SYNC] Detected profile updates from remote. Updating state silently.');
        state = AsyncValue.data(updatedUser);
      }
    } catch (e) {
      debugPrint('[BACKGROUND SYNC SILENT ERROR] Failed to sync profile: $e');
    }
  }

  bool _isProfileChanged(UserModel a, UserModel b) {
    return a.id != b.id ||
        a.email != b.email ||
        a.fullName != b.fullName ||
        a.role != b.role ||
        a.shopId != b.shopId ||
        a.idNumber != b.idNumber ||
        a.phoneNumber != b.phoneNumber;
  }

  void updateLocalUser(UserModel updated) {
    state = AsyncValue.data(updated);
    ref.read(storageServiceProvider).setCachedUser(updated);
  }
}

final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserModel?>(
        CurrentUserNotifier.new);
