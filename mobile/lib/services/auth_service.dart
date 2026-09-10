import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import 'desktop_oauth_stub.dart'
    if (dart.library.io) 'desktop_oauth.dart';
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
  String? _cachedRestIdToken;

  static const String _identityToolkitBase =
      'https://identitytoolkit.googleapis.com/v1/accounts';

  String get _firebaseApiKey => DefaultFirebaseOptions.currentPlatform.apiKey;

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

  FirebaseAuthException _mapRestError(String message) {
    if (message.contains('PASSWORD_LOGIN_DISABLED') ||
        message.contains('OPERATION_NOT_ALLOWED')) {
      return FirebaseAuthException(
        code: 'operation-not-allowed',
        message:
            'Email/Password sign-in is disabled in your Firebase project. Please enable it in the Firebase Console under Authentication > Sign-in method.',
      );
    }
    if (message.contains('EMAIL_NOT_FOUND')) {
      return FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account found with this email. Tap "Create an account" to register.',
      );
    }
    if (message.contains('INVALID_PASSWORD') ||
        message.contains('INVALID_LOGIN_CREDENTIALS')) {
      return FirebaseAuthException(
        code: 'wrong-password',
        message: 'Incorrect email or password. Please try again or tap "Forgot password?".',
      );
    }
    if (message.contains('EMAIL_EXISTS')) {
      return FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'An account already exists with this email address. Please sign in instead.',
      );
    }
    if (message.contains('WEAK_PASSWORD')) {
      return FirebaseAuthException(
        code: 'weak-password',
        message: 'Password is too weak. Please use at least 6 characters.',
      );
    }
    if (message.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
      return FirebaseAuthException(
        code: 'too-many-requests',
        message: 'Too many attempts. Please wait a few minutes and try again.',
      );
    }
    if (message.contains('USER_DISABLED')) {
      return FirebaseAuthException(
        code: 'user-disabled',
        message: 'This user account has been disabled.',
      );
    }
    if (message.contains('INVALID_EMAIL')) {
      return FirebaseAuthException(
        code: 'invalid-email',
        message: 'The email address is invalid.',
      );
    }
    return FirebaseAuthException(
      code: 'auth-error',
      message: message,
    );
  }

  Future<AuthUser> _restSignInWithEmail({
    required String email,
    required String password,
  }) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_identityToolkitBase:signInWithPassword?key=$_firebaseApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'returnSecureToken': true,
        }),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Network connection failed. Please check your internet connection.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final errorMsg = data['error']?['message']?.toString() ?? 'Failed to sign in';
      throw _mapRestError(errorMsg);
    }
    final token = data['idToken'] as String?;
    _cachedRestIdToken = token;
    return AuthUser(
      uid: data['localId'] as String? ?? '',
      email: data['email'] as String? ?? email,
      idToken: token,
    );
  }

  Future<AuthUser> _restSignUpWithEmail({
    required String email,
    required String password,
  }) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_identityToolkitBase:signUp?key=$_firebaseApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'returnSecureToken': true,
        }),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Network connection failed. Please check your internet connection.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final errorMsg = data['error']?['message']?.toString() ?? 'Failed to register';
      throw _mapRestError(errorMsg);
    }
    final token = data['idToken'] as String?;
    _cachedRestIdToken = token;
    return AuthUser(
      uid: data['localId'] as String? ?? '',
      email: data['email'] as String? ?? email,
      idToken: token,
    );
  }

  Future<void> _restSendPasswordResetEmail(String email) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_identityToolkitBase:sendOobCode?key=$_firebaseApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': email.trim(),
        }),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Network connection failed. Please check your internet connection.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final errorMsg =
          data['error']?['message']?.toString() ?? 'Failed to send reset email';
      throw _mapRestError(errorMsg);
    }
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
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    if (isDesktop) {
      return await _restSignInWithEmail(email: email, password: password);
    }

    try {
      final auth = await _requireAuth();
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _fromUser(credential.user, fallbackEmail: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw FirebaseAuthException(
          code: 'operation-not-allowed',
          message:
              'Email/Password sign-in is disabled in your Firebase project. Please enable it in the Firebase Console under Authentication > Sign-in method.',
        );
      }
      if (e.code == 'channel-error' || e.code == 'unknown') {
        return await _restSignInWithEmail(email: email, password: password);
      }
      rethrow;
    } catch (e) {
      return await _restSignInWithEmail(email: email, password: password);
    }
  }

  @override
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    if (isDesktop) {
      return await _restSignUpWithEmail(email: email, password: password);
    }

    try {
      final auth = await _requireAuth();
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _fromUser(credential.user, fallbackEmail: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw FirebaseAuthException(
          code: 'operation-not-allowed',
          message:
              'Email/Password sign-in is disabled in your Firebase project. Please enable it in the Firebase Console under Authentication > Sign-in method.',
        );
      }
      if (e.code == 'channel-error' || e.code == 'unknown') {
        return await _restSignUpWithEmail(email: email, password: password);
      }
      rethrow;
    } catch (e) {
      return await _restSignUpWithEmail(email: email, password: password);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    if (isDesktop) {
      await _restSendPasswordResetEmail(email);
      return;
    }

    try {
      final auth = await _requireAuth();
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw FirebaseAuthException(
          code: 'operation-not-allowed',
          message:
              'Password reset is disabled in your Firebase project. Please enable Email/Password provider in the Firebase Console.',
        );
      }
      if (e.code == 'channel-error' || e.code == 'unknown') {
        await _restSendPasswordResetEmail(email);
        return;
      }
      rethrow;
    } catch (e) {
      await _restSendPasswordResetEmail(email);
      return;
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      final user = await signInWithGoogleDesktopPlatform(
        clientId: DefaultFirebaseOptions.googleDesktopClientId,
        clientSecret: DefaultFirebaseOptions.googleDesktopClientSecret,
        firebaseApiKey: _firebaseApiKey,
      );
      _cachedRestIdToken = user.idToken;
      return user;
    }

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
      if (e is FirebaseAuthException) {
        rethrow;
      }
      final errStr = e.toString();
      if (errStr.contains('MissingPluginException') ||
          errStr.contains('No implementation found')) {
        throw FirebaseAuthException(
          code: 'unsupported-desktop-platform',
          message:
              'Google Sign-In is not supported on this platform. Please sign in with Email & Password or Continue as Guest.',
        );
      }
      try {
        final googleProvider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final userCredential = await auth.signInWithProvider(googleProvider);
        return await _fromUser(userCredential.user, fallbackEmail: '');
      } catch (_) {
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
    _cachedRestIdToken = null;
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
      if (user != null) {
        return await user.getIdToken(forceRefresh);
      }
    } catch (_) {}
    return _cachedRestIdToken;
  }
}
