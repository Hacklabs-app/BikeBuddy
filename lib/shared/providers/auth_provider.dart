import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/user_model.dart';

final supabaseProvider = Provider((ref) => Supabase.instance.client);

// Watches Supabase auth state changes in real-time
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange.map(
        (event) => event.session?.user,
      );
});

// Fetches the full user profile (including role) from your `profiles` table
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(supabaseProvider).auth.currentUser;
  if (user == null) return null;

  final data = await ref
      .watch(supabaseProvider)
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return UserModel.fromMap(data);
});