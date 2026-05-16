import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});
  Future<void> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String newPassword);
  Future<void> signOut();
  User? get currentUser;
}
