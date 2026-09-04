import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyDYUBT_3uSGOGJGaLStQ3leffVDBc907po',
  );

  /// Web OAuth client ID — required on Android so Google Sign-In returns an ID token.
  static const String googleWebClientId =
      '814019640083-ajua9p9tjqj6q1r2k3tittc3hqo114ra.apps.googleusercontent.com';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:814019640083:web:8c5b98f21e041d8e',
    messagingSenderId: '814019640083',
    projectId: 'mausam-personalai-3cabb',
    authDomain: 'mausam-personalai-3cabb.firebaseapp.com',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:814019640083:android:e802ab14c3c42838be38e6',
    messagingSenderId: '814019640083',
    projectId: 'mausam-personalai-3cabb',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:814019640083:ios:8c5b98f21e041d8e',
    messagingSenderId: '814019640083',
    projectId: 'mausam-personalai-3cabb',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
    iosBundleId: 'com.mausam.mobile',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:814019640083:ios:8c5b98f21e041d8e',
    messagingSenderId: '814019640083',
    projectId: 'mausam-personalai-3cabb',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
    iosBundleId: 'com.mausam.mobile',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:814019640083:web:8c5b98f21e041d8e',
    messagingSenderId: '814019640083',
    projectId: 'mausam-personalai-3cabb',
    authDomain: 'mausam-personalai-3cabb.firebaseapp.com',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:814019640083:web:8c5b98f21e041d8e',
    messagingSenderId: '814019640083',
    projectId: 'mausam-personalai-3cabb',
    authDomain: 'mausam-personalai-3cabb.firebaseapp.com',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
  );
}
