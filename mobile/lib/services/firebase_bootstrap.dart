import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Single in-flight Firebase initialization. Auth and bootstrap both wait on this
/// so Google sign-in never races a deferred [Firebase.initializeApp] call.
class FirebaseBootstrap {
  static Future<FirebaseApp>? _inFlight;

  static Future<FirebaseApp> ensureInitialized() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _initialize();
    _inFlight = future;
    return future;
  }

  static Future<FirebaseApp> _initialize() async {
    if (Firebase.apps.isNotEmpty) {
      return Firebase.app();
    }
    try {
      return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, st) {
      debugPrint('Firebase.initializeApp failed: $e\n$st');
      if (Firebase.apps.isNotEmpty) {
        return Firebase.app();
      }
      rethrow;
    }
  }
}
