import 'auth_service.dart';

Future<AuthUser> signInWithGoogleDesktopPlatform({
  required String clientId,
  required String clientSecret,
  required String firebaseApiKey,
}) async {
  throw UnsupportedError('Desktop OAuth is not supported on web.');
}
