import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/weather_palette.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxInit = LinuxInitializationSettings(
        defaultActionName: 'Open Mausam',
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
        linux: linuxInit,
      );

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      // Request Android 13+ permission
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }

      _initialized = true;
      debugPrint('NotificationService initialized successfully.');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  static Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();

    try {
      const androidDetails = AndroidNotificationDetails(
        'mausam_weather_alerts',
        'Mausam Severe Weather Alerts',
        channelDescription: 'Real-time weather warning and AQI advisories',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const linuxDetails = LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
        linux: linuxDetails,
      );

      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing system notification bar notification: $e');
    }
  }

  static Future<void> showTestNotification(BuildContext context) async {
    // 1. Trigger Native System OS Notification Bar Notification
    await showSystemNotification(
      title: '⚡ Mausam Weather Alert',
      body: 'Precipitation Advisory: Rain expected in your area. Carry an umbrella.',
    );

    // 2. Show In-App Atmospheric SnackBar Toast
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: MausamPalette.accentAmber.withValues(alpha: 0.6)),
          ),
          backgroundColor: MausamPalette.cardSurface,
          elevation: 8,
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MausamPalette.accentAmber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: MausamPalette.accentAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚡ NOTIFICATION SENT TO SYSTEM BAR',
                      style: GoogleFonts.inter(
                        color: MausamPalette.accentAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Check your phone/device top notification bar for the alert!',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  static Future<void> showAlertNotification(
    BuildContext context, {
    required String title,
    required String message,
    required bool isSevere,
    VoidCallback? onViewAlerts,
  }) async {
    // 1. Send native OS system bar notification
    await showSystemNotification(
      title: isSevere ? '🚨 $title' : '⚠️ $title',
      body: message,
    );

    // 2. In-App Banner
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSevere
                ? MausamPalette.accentRed.withValues(alpha: 0.8)
                : MausamPalette.accentAmber.withValues(alpha: 0.6),
          ),
        ),
        backgroundColor: MausamPalette.cardSurface,
        elevation: 10,
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSevere
                    ? MausamPalette.accentRed.withValues(alpha: 0.2)
                    : MausamPalette.accentAmber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSevere ? Icons.warning_amber_rounded : Icons.notifications_active_rounded,
                color: isSevere ? MausamPalette.accentRed : MausamPalette.accentAmber,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: isSevere ? MausamPalette.accentRed : MausamPalette.accentAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: MausamPalette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onViewAlerts != null)
              TextButton(
                onPressed: onViewAlerts,
                style: TextButton.styleFrom(
                  foregroundColor: isSevere ? MausamPalette.accentRed : MausamPalette.accentAmber,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'VIEW',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
