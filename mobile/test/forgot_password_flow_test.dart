import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService implements AuthService {
  String? lastResetEmailSent;
  Exception? exceptionToThrow;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<AuthUser> signInWithEmail({required String email, required String password}) async {
    return AuthUser(uid: 'mock_uid', email: email);
  }

  @override
  Future<AuthUser> registerWithEmail({required String email, required String password}) async {
    return AuthUser(uid: 'mock_uid', email: email);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    lastResetEmailSent = email;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    return const AuthUser(uid: 'google_uid', email: 'test@example.com');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => 'mock_token';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Forgot Password Flow Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    testWidgets('sends reset email directly when email field is filled with valid address', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Enter valid email in main email field
      await tester.enterText(find.byKey(const Key('login_email_field')), 'user@example.com');
      await tester.pump();

      // Tap Forgot password?
      await tester.tap(find.text('Forgot password?'));
      await tester.pump(); // starts submitting
      await tester.pump(const Duration(milliseconds: 100)); // completes async call

      expect(mockAuthService.lastResetEmailSent, equals('user@example.com'));
      expect(find.textContaining('Password reset link sent to user@example.com'), findsOneWidget);
    });

    testWidgets('opens Reset Password dialog when email field is empty, allows submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Email field is empty initially
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.byKey(const Key('forgot_password_dialog_email_field')), findsOneWidget);
      expect(find.byKey(const Key('send_reset_link_button')), findsOneWidget);

      // Enter email in dialog and submit
      await tester.enterText(
        find.byKey(const Key('forgot_password_dialog_email_field')),
        'dialoguser@example.com',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('send_reset_link_button')));
      await tester.pump(); // dialog closes, starts submitting
      await tester.pump(const Duration(milliseconds: 100)); // completes async call

      expect(mockAuthService.lastResetEmailSent, equals('dialoguser@example.com'));
      expect(find.textContaining('Password reset link sent to dialoguser@example.com'), findsOneWidget);
    });

    testWidgets('displays user-friendly error when Firebase reports user-not-found', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockAuthService.exceptionToThrow = FirebaseAuthException(code: 'user-not-found');

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('login_email_field')), 'nonexistent@example.com');
      await tester.pump();

      await tester.tap(find.text('Forgot password?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No account found with this email address.'), findsOneWidget);
    });
  });
}
