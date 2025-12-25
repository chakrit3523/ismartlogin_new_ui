import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Model to hold social auth result
class SocialAuthResult {
  final String? email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String provider; // 'google' or 'apple'

  SocialAuthResult({
    this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    required this.provider,
  });
}

/// Service to handle Google and Apple Sign-In
class SocialAuthService {
  static final SocialAuthService _instance = SocialAuthService._internal();
  factory SocialAuthService() => _instance;
  SocialAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google
  Future<SocialAuthResult?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        return null;
      }

      // Split display name into first and last name
      String? firstName;
      String? lastName;
      if (account.displayName != null) {
        final nameParts = account.displayName!.split(' ');
        firstName = nameParts.isNotEmpty ? nameParts.first : null;
        lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;
      }

      return SocialAuthResult(
        email: account.email,
        displayName: account.displayName,
        firstName: firstName,
        lastName: lastName,
        provider: 'google',
      );
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  /// Generate random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Hash nonce for Apple Sign-In
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign in with Apple
  Future<SocialAuthResult?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      return SocialAuthResult(
        email: credential.email,
        displayName:
            credential.givenName != null && credential.familyName != null
                ? '${credential.givenName} ${credential.familyName}'
                : null,
        firstName: credential.givenName,
        lastName: credential.familyName,
        provider: 'apple',
      );
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      return null;
    }
  }
}
