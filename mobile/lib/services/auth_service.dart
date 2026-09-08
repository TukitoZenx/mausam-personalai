import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import 'firebase_bootstrap.dart';

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.idToken,
  });

  final String uid;
  final String email;
  final String? idToken;
}

abstract class AuthService {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithEmail({required String email, required String password});
  Future<AuthUser> registerWithEmail({required String email, required String password});
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<String?> getIdToken({bool forceRefresh = false});
}

class FirebaseAuthService implements AuthService {
  FirebaseAuth? _auth;

  Future<FirebaseAuth> _requireAuth() async {
    await FirebaseBootstrap.ensureInitialized();
    try {
      _auth ??= FirebaseAuth.instance;
    } catch (e) {
      throw Exception('Firebase Auth is unavailable: $e');
    }
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase Auth did not start. Please restart Mausam and try again.');
    }
    return auth;
  }

  @override
  Stream<User?> get authStateChanges async* {
    try {
      final auth = await _requireAuth();
      yield* auth.authStateChanges();
    } catch (_) {
      yield null;
    }
  }

  @override
  User? get currentUser {
    try {
      if (_auth != null) return _auth!.currentUser;
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance.currentUser;
    } catch (_) {}
    return null;
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = await _requireAuth();
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fromUser(credential.user, fallbackEmail: email);
  }

  @override
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = await _requireAuth();
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fromUser(credential.user, fallbackEmail: email);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = await _requireAuth();
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final auth = await _requireAuth();
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final credential = await auth.signInWithPopup(googleProvider);
        return await _fromUser(credential.user, fallbackEmail: '');
      }

      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: DefaultFirebaseOptions.googleWebClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Google Sign-In was cancelled by user.',
        );
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google Sign-In did not return a token.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await auth.signInWithCredential(credential);
      return await _fromUser(userCredential.user, fallbackEmail: googleUser.email);
    } catch (e) {
      if (e is FirebaseAuthException &&
          (e.code == 'ERROR_ABORTED_BY_USER' || e.code == '12501')) {
        rethrow;
      }
      try {
        final googleProvider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final userCredential = await auth.signInWithProvider(googleProvider);
        return await _fromUser(userCredential.user, fallbackEmail: '');
      } catch (_) {
        if (e is FirebaseAuthException) rethrow;
        throw FirebaseAuthException(
          code: 'google-sign-in-failed',
          message: e.toString(),
        );
      }
    }
  }

  Future<AuthUser> _fromUser(User? user, {required String fallbackEmail}) async {
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Sign-in succeeded but no user was returned.',
      );
    }
    final token = await user.getIdToken();
    return AuthUser(uid: user.uid, email: user.email ?? fallbackEmail, idToken: token);
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      final auth = await _requireAuth();
      await auth.signOut();
    } catch (_) {}
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final auth = await _requireAuth();
      final user = auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken(forceRefresh);
    } catch (_) {
      return null;
    }
  }
}
