import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Capture Chat Screen and Reminder Flow Screenshots', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/chat');

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('capture_root'),
        child: ProviderScope(
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Simulate sending weather query
    final inputField = find.byKey(const Key('chat_input_field'));
    expect(inputField, findsOneWidget);
    await tester.enterText(inputField, "What's the weather today in Bengaluru?");
    await tester.pump();

    final sendBtn = find.byKey(const Key('chat_send_button'));
    await tester.tap(sendBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Capture Frame 1: Weather query exchange
    await tester.pumpAndSettle();
    final boundaryFinder = find.byKey(const Key('capture_root'));
    final RenderRepaintBoundary boundary = tester.renderObject(boundaryFinder);
    final ui.Image image1 = await boundary.toImage(pixelRatio: 2.0);
    final byteData1 = await image1.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes1 = byteData1!.buffer.asUint8List();

    const artifactDir = '/home/tukitozenx/.gemini/antigravity-ide/brain/16547291-5a51-4191-bb19-d04c14de50e6';
    final file1 = File('$artifactDir/chat_weather_exchange.png');
    await file1.writeAsBytes(pngBytes1);
    debugPrint('Saved Frame 1: ${file1.path} (${pngBytes1.length} bytes)');

    // 2. Open Set Reminder Modal
    final reminderBtn = find.byKey(const Key('chat_reminder_button'));
    await tester.tap(reminderBtn);
    await tester.pumpAndSettle();

    // Capture Frame 2: Reminder modal flow
    final ui.Image image2 = await boundary.toImage(pixelRatio: 2.0);
    final byteData2 = await image2.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes2 = byteData2!.buffer.asUint8List();

    final file2 = File('$artifactDir/chat_reminder_flow.png');
    await file2.writeAsBytes(pngBytes2);
    debugPrint('Saved Frame 2: ${file2.path} (${pngBytes2.length} bytes)');
  });
}
