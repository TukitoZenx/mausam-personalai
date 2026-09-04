import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'router/app_router.dart';
import 'services/firebase_bootstrap.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  // Start Firebase immediately without blocking first paint. Auth waits on this future.
  unawaited(_initDeferredServices());

  runApp(
    const ProviderScope(
      child: MausamApp(),
    ),
  );
}

Future<void> _initDeferredServices() async {
  try {
    await FirebaseBootstrap.ensureInitialized();
  } catch (e) {
    debugPrint('Firebase bootstrap failed: $e');
  }

  try {
    await NotificationService.init();
  } catch (_) {}
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
