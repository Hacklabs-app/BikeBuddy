import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl(this._client);

  @override
  Future<void> signIn({required String email, required String password}) async {
    debugPrint('[API REQUEST] Method: signIn, Email: $email');
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      debugPrint('[API RESPONSE] Method: signIn, Status: SUCCESS');
    } catch (e) {
      debugPrint('[API RESPONSE] Method: signIn, Status: FAILED, Error: $e');
      rethrow;
    }
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    debugPrint('[API REQUEST] Method: signUp, Email: $email, Name: $fullName');
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: 'bikebuddy://login-callback',
      );

      final identities = res.user?.identities;
      if (res.user != null && identities != null && identities.isEmpty) {
        throw const AuthException(
          'An account with this email already exists. Please log in instead.',
          statusCode: '400',
        );
      }

      debugPrint('[API RESPONSE] Method: signUp, Status: SUCCESS');
      return res;
    } catch (e) {
      debugPrint('[API RESPONSE] Method: signUp, Status: FAILED, Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    debugPrint('[API REQUEST] Method: signInWithGoogle');
    try {
      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId: SupabaseConstants.googleWebClientId,
      );

      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Google Sign-In failed: Missing ID Token';
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      debugPrint('[API RESPONSE] Method: signInWithGoogle, Status: SUCCESS');
    } catch (e) {
      debugPrint(
          '[API RESPONSE] Method: signInWithGoogle, Status: FAILED, Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeRiderRegistration({
    required String idNumber,
    String? phoneNumber,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    debugPrint(
        '[API REQUEST] Method: completeRiderRegistration, User: ${user.id}, ID: $idNumber, Phone: $phoneNumber');
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? '',
        'role': 'customer',
        'id_number': idNumber,
        'phone_number': phoneNumber,
      });
      debugPrint(
          '[API RESPONSE] Method: completeRiderRegistration, Status: SUCCESS');
    } catch (e) {
      debugPrint(
          '[API RESPONSE] Method: completeRiderRegistration, Status: FAILED, Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeOwnerRegistration({
    required String stationName,
    required String phoneNumber,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    debugPrint(
        '[API REQUEST] Method: completeOwnerRegistration, User: ${user.id}, Station: $stationName, Phone: $phoneNumber');
    try {
      // 1. Upsert Profile Role
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? '',
        'role': 'owner',
        'phone_number': phoneNumber,
      });

      // 2. Create Initial Shop Entry
      await _client.from('shops').upsert({
        'owner_id': user.id,
        'name': stationName,
        'address': 'Pending Setup',
      }, onConflict: 'owner_id');
      debugPrint(
          '[API RESPONSE] Method: completeOwnerRegistration, Status: SUCCESS');
    } catch (e) {
      debugPrint(
          '[API RESPONSE] Method: completeOwnerRegistration, Status: FAILED, Error: $e');
      rethrow;
    }
  }

  @override
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
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    debugPrint(
        '[API REQUEST] Method: setupShop, User: ${user.id}, Shop: $name, Phone: $phoneNumber');
    try {
      final shopRes = await _client.from('shops').upsert({
        'owner_id': user.id,
        'name': name,
        'phone_number': phoneNumber,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'operating_hours_open': operatingHoursOpen,
        'operating_hours_close': operatingHoursClose,
        if (totalBikes != null) 'total_bikes': totalBikes,
      }, onConflict: 'owner_id').select('id').maybeSingle();

      if (shopRes != null && ratePerHour != null) {
        final shopId = shopRes['id'];
        await _client.from('shop_rates').upsert({
          'shop_id': shopId,
          'rate_per_hour': ratePerHour,
        }, onConflict: 'shop_id');
      }
      debugPrint('[API RESPONSE] Method: setupShop, Status: SUCCESS');
    } catch (e) {
      debugPrint('[API RESPONSE] Method: setupShop, Status: FAILED, Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    debugPrint('[API REQUEST] Method: sendPasswordReset, Email: $email');
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'bikebuddy://login-callback',
      );
      debugPrint('[API RESPONSE] Method: sendPasswordReset, Status: SUCCESS');
    } catch (e) {
      debugPrint(
          '[API RESPONSE] Method: sendPasswordReset, Status: FAILED, Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    debugPrint('[API REQUEST] Method: updatePassword');
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      debugPrint('[API RESPONSE] Method: updatePassword, Status: SUCCESS');
    } catch (e) {
      debugPrint(
          '[API RESPONSE] Method: updatePassword, Status: FAILED, Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    debugPrint('[API REQUEST] Method: signOut');
    try {
      await _client.auth.signOut();
      debugPrint('[API RESPONSE] Method: signOut, Status: SUCCESS');
    } catch (e) {
      debugPrint('[API RESPONSE] Method: signOut, Status: FAILED, Error: $e');
      rethrow;
    }
  }

  @override
  User? get currentUser => _client.auth.currentUser;
}
