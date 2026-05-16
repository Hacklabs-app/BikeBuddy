import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp(
      {required String email,
      required String password,
      required String fullName});
  Future<void> signInWithGoogle();
  Future<void> completeRiderRegistration({
    required String idNumber,
    String? phoneNumber,
  });
  Future<void> completeOwnerRegistration({
    required String stationName,
    required String phoneNumber,
  });
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String newPassword);
  Future<void> signOut();
  User? get currentUser;
}
