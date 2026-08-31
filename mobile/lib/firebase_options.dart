import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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
    apiKey: 'YOUR_FIREBASE_API_KEY_PLACEHOLDER',
    appId: '1:YOUR_PROJECT_NUMBER:web:YOUR_APP_ID_PLACEHOLDER',
    messagingSenderId: 'YOUR_PROJECT_NUMBER_PLACEHOLDER',
    projectId: 'mausam-personalai-3cabb',
    authDomain: 'mausam-personalai-3cabb.firebaseapp.com',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY_PLACEHOLDER',
    appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID_PLACEHOLDER',
    messagingSenderId: 'YOUR_PROJECT_NUMBER_PLACEHOLDER',
    projectId: 'mausam-personalai-3cabb',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY_PLACEHOLDER',
    appId: '1:YOUR_PROJECT_NUMBER:ios:YOUR_APP_ID_PLACEHOLDER',
    messagingSenderId: 'YOUR_PROJECT_NUMBER_PLACEHOLDER',
    projectId: 'mausam-personalai-3cabb',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
    iosBundleId: 'com.mausam.mobile',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY_PLACEHOLDER',
    appId: '1:YOUR_PROJECT_NUMBER:ios:YOUR_APP_ID_PLACEHOLDER',
    messagingSenderId: 'YOUR_PROJECT_NUMBER_PLACEHOLDER',
    projectId: 'mausam-personalai-3cabb',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
    iosBundleId: 'com.mausam.mobile',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY_PLACEHOLDER',
    appId: '1:YOUR_PROJECT_NUMBER:web:YOUR_APP_ID_PLACEHOLDER',
    messagingSenderId: 'YOUR_PROJECT_NUMBER_PLACEHOLDER',
    projectId: 'mausam-personalai-3cabb',
    authDomain: 'mausam-personalai-3cabb.firebaseapp.com',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY_PLACEHOLDER',
    appId: '1:YOUR_PROJECT_NUMBER:web:YOUR_APP_ID_PLACEHOLDER',
    messagingSenderId: 'YOUR_PROJECT_NUMBER_PLACEHOLDER',
    projectId: 'mausam-personalai-3cabb',
    authDomain: 'mausam-personalai-3cabb.firebaseapp.com',
    storageBucket: 'mausam-personalai-3cabb.firebasestorage.app',
  );
}
