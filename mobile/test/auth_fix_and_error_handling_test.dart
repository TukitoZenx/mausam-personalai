import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpyingAuthService implements AuthService {
  bool signInWithEmailCalled = false;
  bool registerWithEmailCalled = false;
  bool signInWithGoogleCalled = false;
  FirebaseAuthException? exceptionToThrow;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<AuthUser> signInWithEmail({required String email, required String password}) async {
    signInWithEmailCalled = true;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return AuthUser(uid: 'mock_uid', email: email);
  }

  @override
  Future<AuthUser> registerWithEmail({required String email, required String password}) async {
    registerWithEmailCalled = true;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return AuthUser(uid: 'mock_uid', email: email);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    signInWithGoogleCalled = true;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return const AuthUser(uid: 'google_uid', email: 'test@example.com');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => 'mock_token';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Auth Fix and Platform Error Handling Tests', () {
    late SpyingAuthService authService;

    setUp(() {
      authService = SpyingAuthService();
    });

    Widget createWidgetUnderTest({AuthViewMode mode = AuthViewMode.signIn}) {
      return ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
        ],
        child: MaterialApp(
          home: LoginScreen(initialMode: mode),
        ),
      );
    }

    testWidgets('Google sign-in error shows friendly desktop message when unsupported', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      authService.exceptionToThrow = FirebaseAuthException(
        code: 'unsupported-desktop-platform',
        message: 'Google Sign-In is not supported on Windows desktop.',
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byKey(const Key('google_sign_in_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authService.signInWithGoogleCalled, isTrue);
      expect(
        find.textContaining('Google Sign-In is only available on Mobile'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Google sign-in success calls signInWithGoogle', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byKey(const Key('google_sign_in_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authService.signInWithGoogleCalled, isTrue);
    });

    testWidgets('Sign In failure with operation-not-allowed informs user about Firebase Console', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      authService.exceptionToThrow = FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Password sign-in is disabled.',
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('login_email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(const Key('continue_with_email_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authService.signInWithEmailCalled, isTrue);
      expect(authService.registerWithEmailCalled, isFalse);
      expect(
        find.textContaining('Email/Password sign-in is disabled in your Firebase project'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Sign In does NOT silently auto-register on invalid-credential', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      authService.exceptionToThrow = FirebaseAuthException(
        code: 'invalid-credential',
        message: 'The email or password is invalid.',
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('login_email_field')), 'existing@example.com');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'wrongpass');
      await tester.pump();

      await tester.tap(find.byKey(const Key('continue_with_email_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authService.signInWithEmailCalled, isTrue);
      expect(authService.registerWithEmailCalled, isFalse);
      expect(
        find.textContaining('Invalid email or password'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Create Account with operation-not-allowed displays Firebase Console guidance', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      authService.exceptionToThrow = FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Sign-up disabled.',
      );

      await tester.pumpWidget(createWidgetUnderTest(mode: AuthViewMode.createAccount));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('login_email_field')), 'newuser@example.com');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');
      final passwordFields = find.byType(TextField);
      expect(passwordFields, findsNWidgets(4));
      await tester.enterText(passwordFields.at(3), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(const Key('continue_with_email_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authService.registerWithEmailCalled, isTrue);
      expect(
        find.textContaining('Email/Password sign-in is disabled in your Firebase project'),
        findsAtLeastNWidgets(1),
      );
    });

    test('UserNotifier persists and restores auth session', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProvider.notifier);
      notifier.setAuthenticated(
        userId: 'test_uid_123',
        email: 'persisted@example.com',
        displayName: 'Test User',
        idToken: 'persisted_token_xyz',
      );

      // Allow async SharedPreferences write to finish
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify immediate state
      expect(container.read(userProvider).isAuthenticated, isTrue);
      expect(container.read(userProvider).userId, equals('test_uid_123'));
      expect(container.read(userProvider).email, equals('persisted@example.com'));

      // Create new container simulating app restart
      final newContainer = ProviderContainer();
      addTearDown(newContainer.dispose);

      final newNotifier = newContainer.read(userProvider.notifier);
      final restored = await newNotifier.restoreAuthSession();

      expect(restored, isTrue);
      expect(newContainer.read(userProvider).isAuthenticated, isTrue);
      expect(newContainer.read(userProvider).userId, equals('test_uid_123'));
      expect(newContainer.read(userProvider).email, equals('persisted@example.com'));
      expect(newContainer.read(userProvider).idToken, equals('persisted_token_xyz'));

      // Sign out clears persisted auth session
      newNotifier.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(newContainer.read(userProvider).isAuthenticated, isFalse);

      final thirdContainer = ProviderContainer();
      addTearDown(thirdContainer.dispose);
      final restoredAfterSignOut = await thirdContainer.read(userProvider.notifier).restoreAuthSession();
      expect(restoredAfterSignOut, isFalse);
    });
  });
}
