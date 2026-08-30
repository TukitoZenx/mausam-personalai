import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('HomeScreen displays title text', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Mausam PersonalAI'), findsAtLeastNWidgets(1));
  });
}
