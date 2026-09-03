import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  Future<void> signOut();
  Future<String?> getIdToken({bool forceRefresh = false});
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? _safeGetAuth();

  static FirebaseAuth? _safeGetAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  final FirebaseAuth? _auth;

  @override
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  @override
  User? get currentUser => _auth?.currentUser;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) throw Exception('Firebase is uninitialized on this platform.');
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Sign-in succeeded but no user was returned.',
      );
    }
    final token = await user.getIdToken();
    return AuthUser(uid: user.uid, email: user.email ?? email, idToken: token);
  }

  @override
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) throw Exception('Firebase is uninitialized on this platform.');
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Registration succeeded but no user was returned.',
      );
    }
    final token = await user.getIdToken();
    return AuthUser(uid: user.uid, email: user.email ?? email, idToken: token);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) throw Exception('Firebase is uninitialized on this platform.');
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final UserCredential userCredential = await auth.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Google Sign-In succeeded but no user was returned.',
          );
        }
        final token = await user.getIdToken();
        return AuthUser(uid: user.uid, email: user.email ?? '', idToken: token);
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Google Sign-In was cancelled by user.',
        );
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Google Sign-In succeeded but no user was returned.',
        );
      }
      final token = await user.getIdToken();
      return AuthUser(uid: user.uid, email: user.email ?? googleUser.email, idToken: token);
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'ERROR_ABORTED_BY_USER') {
        rethrow;
      }
      try {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final UserCredential userCredential = await auth.signInWithProvider(googleProvider);
        final user = userCredential.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Google Sign-In succeeded but no user was returned.',
          );
        }
        final token = await user.getIdToken();
        return AuthUser(uid: user.uid, email: user.email ?? '', idToken: token);
      } catch (fallbackError) {
        if (e is FirebaseAuthException) {
          rethrow;
        }
        throw FirebaseAuthException(
          code: 'google-sign-in-failed',
          message: e.toString(),
        );
      }
    }
  }

  @override
  Future<void> signOut() async {
    await _auth?.signOut();
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth?.currentUser;
    if (user == null) return null;
    return await user.getIdToken(forceRefresh);
  }
}
