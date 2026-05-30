import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});
  Future<AuthResponse> signUp(
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
  Future<void> setupShop({
    required String name,
    required String phoneNumber,
    required String address,
    required double latitude,
    required double longitude,
    required String operatingHoursOpen,
    required String operatingHoursClose,
    int? totalBikes,
    int? ratePerHour,
  });
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String newPassword);
  Future<void> signOut();
  User? get currentUser;
}
