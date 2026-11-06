import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
class AuthException implements Exception {
  AuthException(this.message);

  final String message;
}

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth
          .signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      debugPrint('Sign-in timed out');
      throw AuthException('Check your internet connection and try again.');
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase sign-in error: ${e.code} - ${e.message}');
      throw AuthException(_messageFor(e.code));
    } catch (e) {
      debugPrint('Sign-in error: $e');
      throw AuthException('Something went wrong. Please try again.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth
          .sendPasswordResetEmail(email: email.trim())
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      debugPrint('Password reset timed out');
      throw AuthException('Check your internet connection and try again.');
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase reset error: ${e.code} - ${e.message}');
      // Email registered na ho to bhi koi farq nahi dikhana.
      if (e.code == 'user-not-found') {
        return;
      }
      throw AuthException(_messageFor(e.code));
    } catch (e) {
      debugPrint('Password reset error: $e');
      throw AuthException('Something went wrong. Please try again.');
    }
  }


  String _messageFor(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Incorrect email or password.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}