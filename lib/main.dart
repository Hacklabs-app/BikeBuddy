import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/constants/supabase_constants.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle all unhandled async errors globally (such as background deep link/auth errors or timeouts)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[GLOBAL ERROR] Intercepted: $error');

    final errorStr = error.toString();
    // Silently suppress background Supabase token-refresh network failures while offline
    final isOfflineAuthRetry = errorStr.contains('AuthRetryableFetchException') ||
        (errorStr.contains('refresh_token') &&
            (errorStr.contains('SocketException') ||
                errorStr.contains('Failed host lookup') ||
                errorStr.contains('ClientException')));

    if (isOfflineAuthRetry) {
      debugPrint('[GLOBAL ERROR] Gracefully suppressed background auth offline retry.');
      return true; // Marked as handled (silently swallowed)
    }

    if (error is AuthException) {
      final message = error.message.replaceAll('+', ' ');
      final code = error.code;
      final statusCode = error.statusCode;

      String displayMessage = message;
      if (statusCode == 'otp_expired' ||
          (code == 'access_denied' &&
              message.toLowerCase().contains('expired'))) {
        displayMessage =
            'The verification link has expired or already been used. Please request a new link.';
      } else if (code == 'bad_code_verifier') {
        displayMessage =
            'The login verification has expired. Please try signing in again.';
      }

      _showGlobalSnackBar(displayMessage, isError: true);
      return true; // Marked as handled
    } else if (error is SocketException || error is TimeoutException) {
      _showGlobalSnackBar(
          'Connection error. Please check your internet connection and try again.',
          isError: true);
      return true; // Handled
    }

    return false; // Propagate other system errors naturally
  };

  final prefs = await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  runApp(
    // Riverpod wraps everything — all providers available app-wide
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(StorageService(prefs)),
      ],
      child: const BikeBuddyApp(),
    ),
  );
}

void _showGlobalSnackBar(String message, {bool isError = false}) {
  scaffoldMessengerKey.currentState?.clearSnackBars();
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: isError ? Colors.redAccent : const Color(0xFF00B248),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E1E24),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      duration: const Duration(seconds: 4),
    ),
  );
}
