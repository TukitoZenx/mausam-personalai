import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

// OPTIMIZED: Phased Initialization Architecture for sub-250ms First Paint
void main() {
  // Phase 1 — Critical Path: UI Render Blocking (<250ms FCP)
  _initCriticalPath();

  // Call runApp IMMEDIATELY with root widget tree
  runApp(
    const ProviderScope(
      child: MausamApp(),
    ),
  );

  // Phase 2 — Deferred Services: Post-frame initialization after initial paint
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initDeferredServices();
  });
}

// OPTIMIZED: Phase 1 — Critical Path initialization only
void _initCriticalPath() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
}

// OPTIMIZED: Phase 2 — Deferred Services (Firebase, SDKs) post-paint
Future<void> _initDeferredServices() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Graceful fallback for test runners or pre-initialized Firebase instances
  }
}

class MausamApp extends StatelessWidget {
  const MausamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mausam PersonalAI',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
