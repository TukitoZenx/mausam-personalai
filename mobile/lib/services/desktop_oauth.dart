import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'auth_service.dart';

Future<void> _launchBrowser(Uri url) async {
  try {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (launched) return;
  } catch (_) {}

  final urlString = url.toString();
  if (Platform.isWindows) {
    // 1. Primary fallback: explorer.exe directly delegates to Windows ShellExecute.
    // Instant launch with 0ms cold-start, handles '&' without cmd shell parsing,
    // and detached mode prevents hanging on browser lifetime.
    try {
      await Process.start(
        'explorer.exe',
        [urlString],
        mode: ProcessStartMode.detached,
      );
      return;
    } catch (_) {}

    // 2. Fallback: cmd.exe start
    try {
      await Process.start(
        'cmd.exe',
        ['/c', 'start', '', urlString],
        mode: ProcessStartMode.detached,
      );
      return;
    } catch (_) {}

    // 3. Fallback: PowerShell Start-Process
    try {
      await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-NonInteractive',
          '-WindowStyle',
          'Hidden',
          '-Command',
          'Start-Process',
          '"$urlString"',
        ],
        mode: ProcessStartMode.detached,
      );
      return;
    } catch (_) {}
  } else if (Platform.isMacOS) {
    await Process.start('open', [urlString], mode: ProcessStartMode.detached);
  } else {
    await Process.start('xdg-open', [urlString], mode: ProcessStartMode.detached);
  }
}

const _kSuccessHtml = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Signed in to Mausam</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #0d1117;
      color: #f0f6fc;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 16px;
      padding: 40px 32px;
      text-align: center;
      max-width: 440px;
      width: 100%;
      box-shadow: 0 16px 32px rgba(0, 0, 0, 0.4);
    }
    .icon {
      width: 64px;
      height: 64px;
      background: #238636;
      border-radius: 50%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 20px;
      font-size: 32px;
      color: #ffffff;
    }
    h1 {
      font-size: 22px;
      font-weight: 600;
      margin-bottom: 12px;
      color: #ffffff;
    }
    p {
      color: #8b949e;
      font-size: 15px;
      line-height: 1.5;
      margin-bottom: 24px;
    }
    .badge {
      display: inline-block;
      background: #21262d;
      border: 1px solid #30363d;
      color: #58a6ff;
      padding: 8px 20px;
      border-radius: 20px;
      font-size: 14px;
      font-weight: 500;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">&#10003;</div>
    <h1>Sign-in Successful</h1>
    <p>You have successfully signed in with Google.<br>You can close this window and return to <strong>Mausam</strong>.</p>
    <div class="badge">Return to Mausam</div>
  </div>
</body>
</html>''';

const _kErrorHtml = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sign-in Failed</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #0d1117;
      color: #f0f6fc;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 16px;
      padding: 40px 32px;
      text-align: center;
      max-width: 440px;
      width: 100%;
      box-shadow: 0 16px 32px rgba(0, 0, 0, 0.4);
    }
    .icon {
      width: 64px;
      height: 64px;
      background: #da3633;
      border-radius: 50%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 20px;
      font-size: 32px;
      color: #ffffff;
    }
    h1 {
      font-size: 22px;
      font-weight: 600;
      margin-bottom: 12px;
      color: #ffffff;
    }
    p {
      color: #8b949e;
      font-size: 15px;
      line-height: 1.5;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">&#10005;</div>
    <h1>Sign-in Cancelled</h1>
    <p>Google sign-in was not completed.<br>Please return to Mausam and try again.</p>
  </div>
</body>
</html>''';

Future<AuthUser> signInWithGoogleDesktopPlatform({
  required String clientId,
  required String clientSecret,
  required String firebaseApiKey,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final redirectUri = 'http://127.0.0.1:${server.port}';

  final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
    'client_id': clientId,
    'redirect_uri': redirectUri,
    'response_type': 'code',
    'scope': 'openid email profile',
    'access_type': 'offline',
    'prompt': 'select_account',
  });

  try {
    await _launchBrowser(authUrl);
  } catch (e) {
    await server.close(force: true);
    throw FirebaseAuthException(
      code: 'browser-launch-failed',
      message: 'Failed to open browser for Google Sign-In: $e',
    );
  }

  HttpRequest? callbackRequest;
  try {
    await for (final req in server.timeout(const Duration(seconds: 120))) {
      if (req.uri.path == '/favicon.ico') {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        continue;
      }
      callbackRequest = req;
      break;
    }
  } on TimeoutException {
    await server.close(force: true);
    throw FirebaseAuthException(
      code: 'ERROR_ABORTED_BY_USER',
      message: 'Google Sign-In timed out. Please try again.',
    );
  }

  if (callbackRequest == null) {
    await server.close(force: true);
    throw FirebaseAuthException(
      code: 'ERROR_ABORTED_BY_USER',
      message: 'Google Sign-In was interrupted.',
    );
  }

  final error = callbackRequest.uri.queryParameters['error'];
  final code = callbackRequest.uri.queryParameters['code'];

  if (error != null) {
    callbackRequest.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(_kErrorHtml);
    await callbackRequest.response.close();
    await server.close(force: true);

    if (error == 'access_denied') {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Google Sign-In was cancelled by user.',
      );
    }
    throw FirebaseAuthException(
      code: 'google-oauth-error',
      message: 'Google Sign-In error: $error',
    );
  }

  if (code == null || code.isEmpty) {
    callbackRequest.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(_kErrorHtml);
    await callbackRequest.response.close();
    await server.close(force: true);

    throw FirebaseAuthException(
      code: 'missing-code',
      message: 'Google Sign-In did not return an authorization code.',
    );
  }

  callbackRequest.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.html
    ..write(_kSuccessHtml);
  await callbackRequest.response.close();
  await server.close(force: true);

  // Exchange auth code for Google tokens
  final http.Response tokenResponse;
  try {
    tokenResponse = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
    );
  } catch (e) {
    throw FirebaseAuthException(
      code: 'network-request-failed',
      message: 'Failed to connect to Google OAuth server. Check your connection.',
    );
  }

  final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
  if (tokenResponse.statusCode != 200) {
    final errDesc = tokenData['error_description'] ?? tokenData['error'] ?? 'Token exchange failed';
    throw FirebaseAuthException(
      code: 'token-exchange-failed',
      message: 'Failed to exchange Google authorization code: $errDesc',
    );
  }

  final googleIdToken = tokenData['id_token'] as String?;
  final googleAccessToken = tokenData['access_token'] as String?;

  if (googleIdToken == null || googleIdToken.isEmpty) {
    throw FirebaseAuthException(
      code: 'missing-google-id-token',
      message: 'Google did not return an ID token.',
    );
  }

  // Exchange Google ID token with Firebase Identity Toolkit
  final http.Response idpResponse;
  try {
    idpResponse = await http.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$firebaseApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'postBody': 'id_token=$googleIdToken&providerId=google.com',
        'requestUri': 'http://localhost',
        'returnSecureToken': true,
      }),
    );
  } catch (e) {
    throw FirebaseAuthException(
      code: 'network-request-failed',
      message: 'Failed to connect to Firebase. Check your connection.',
    );
  }

  final idpData = jsonDecode(idpResponse.body) as Map<String, dynamic>;
  if (idpResponse.statusCode != 200) {
    final errorMsg = idpData['error']?['message']?.toString() ?? 'Firebase sign-in failed';
    throw FirebaseAuthException(
      code: 'firebase-idp-failed',
      message: errorMsg,
    );
  }

  final localId = idpData['localId'] as String? ?? '';
  final email = idpData['email'] as String? ?? '';
  final firebaseIdToken = idpData['idToken'] as String?;

  // Also try to update local FirebaseAuth instance if supported
  try {
    final credential = GoogleAuthProvider.credential(
      idToken: googleIdToken,
      accessToken: googleAccessToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (_) {}

  return AuthUser(
    uid: localId,
    email: email,
    idToken: firebaseIdToken,
  );
}
