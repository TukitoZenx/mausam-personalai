import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/navigation/fading_indexed_stack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FadingIndexedStack Widget Tests', () {
    testWidgets('renders active child and keeps inactive children offstage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadingIndexedStack(
              index: 0,
              children: [
                Text('Page 0 Content'),
                Text('Page 1 Content'),
                Text('Page 2 Content'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Page 0 Content'), findsOneWidget);

      // Verify that offstage pages are rendered in tree but marked offstage
      final offstageWidgets = tester.widgetList<Offstage>(find.byType(Offstage));
      expect(offstageWidgets.any((w) => w.offstage == false), isTrue);
      expect(offstageWidgets.any((w) => w.offstage == true), isTrue);
    });

    testWidgets('preserves internal state across tab switches', (tester) async {
      int activeIndex = 0;
      late StateSetter setParentState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setParentState = setState;
                return FadingIndexedStack(
                  index: activeIndex,
                  children: const [
                    _CounterTestWidget(title: 'Tab 0'),
                    _CounterTestWidget(title: 'Tab 1'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Increment counter on Tab 0
      expect(find.text('Tab 0: 0'), findsOneWidget);
      await tester.tap(find.text('Increment Tab 0'));
      await tester.pump();
      expect(find.text('Tab 0: 1'), findsOneWidget);

      // Switch to Tab 1
      setParentState(() => activeIndex = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Tab 1: 0'), findsOneWidget);

      // Switch back to Tab 0: Counter state must be preserved at 1!
      setParentState(() => activeIndex = 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Tab 0: 1'), findsOneWidget);
    });

    testWidgets('never disposes or double-initializes child state across transitions', (tester) async {
      int tab0Inits = 0;
      int tab0Disposes = 0;
      int tab1Inits = 0;
      int tab1Disposes = 0;

      int activeIndex = 0;
      late StateSetter setParentState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setParentState = setState;
                return FadingIndexedStack(
                  index: activeIndex,
                  children: [
                    _LifecycleTrackerWidget(
                      title: 'Tab 0',
                      onInit: () => tab0Inits++,
                      onDispose: () => tab0Disposes++,
                    ),
                    _LifecycleTrackerWidget(
                      title: 'Tab 1',
                      onInit: () => tab1Inits++,
                      onDispose: () => tab1Disposes++,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initial state: Tab 0 initialized once, Tab 1 initialized once into offstage
      expect(tab0Inits, 1);
      expect(tab0Disposes, 0);
      expect(tab1Inits, 1);
      expect(tab1Disposes, 0);

      // Switch to Tab 1
      setParentState(() => activeIndex = 1);
      await tester.pump();
      // Mid-animation
      await tester.pump(const Duration(milliseconds: 90));
      // End animation
      await tester.pump(const Duration(milliseconds: 150));

      // Neither tab should have been disposed or re-initialized!
      expect(tab0Inits, 1);
      expect(tab0Disposes, 0);
      expect(tab1Inits, 1);
      expect(tab1Disposes, 0);

      // Switch back to Tab 0
      setParentState(() => activeIndex = 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tab0Inits, 1);
      expect(tab0Disposes, 0);
      expect(tab1Inits, 1);
      expect(tab1Disposes, 0);
    });
  });
}

class _CounterTestWidget extends StatefulWidget {
  final String title;

  const _CounterTestWidget({required this.title});

  @override
  State<_CounterTestWidget> createState() => _CounterTestWidgetState();
}

class _CounterTestWidgetState extends State<_CounterTestWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('${widget.title}: $_count'),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: Text('Increment ${widget.title}'),
        ),
      ],
    );
  }
}

class _LifecycleTrackerWidget extends StatefulWidget {
  final String title;
  final VoidCallback onInit;
  final VoidCallback onDispose;

  const _LifecycleTrackerWidget({
    required this.title,
    required this.onInit,
    required this.onDispose,
  });

  @override
  State<_LifecycleTrackerWidget> createState() => _LifecycleTrackerWidgetState();
}

class _LifecycleTrackerWidgetState extends State<_LifecycleTrackerWidget> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(widget.title);
  }
}
