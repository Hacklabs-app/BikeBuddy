import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/user_model.dart';

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

// Fetches the full app profile (role, shopId, etc.) for the signed-in user.
// Re-runs automatically whenever authStateProvider emits a new value.
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;

  final client = Supabase.instance.client;

  final data = await client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (data == null) return null;

  String? shopId;
  if (data['role'] == 'owner') {
    final shopData = await client
        .from('shops')
        .select('id')
        .eq('owner_id', user.id)
        .maybeSingle();
    shopId = shopData?['id'] as String?;
  }

  return UserModel.fromMap({
    ...data,
    'email': user.email,
    'shop_id': shopId,
  });
});
