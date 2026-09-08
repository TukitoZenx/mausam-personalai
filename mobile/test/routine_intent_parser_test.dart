import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/routine_intent_parser.dart';

void main() {
  group('RoutineIntentParser', () {
    test('parses exact user prompt: Every day at 9:00 PM, remind me what time I should go walking tomorrow.', () {
      const query = 'Every day at 9:00 PM, remind me what time I should go walking tomorrow.';
      final result = RoutineIntentParser.parse(query);

      expect(result.type, equals(RoutineIntentType.reminderAndRecommendation));
      expect(result.activity, equals('walking'));
      expect(result.reminderHour, equals(21));
      expect(result.reminderMinute, equals(0));
      expect(result.targetPeriod, equals('morning'));
      expect(result.isDaily, isTrue);
      expect(result.isReminderIntent, isTrue);
      expect(result.isRecommendationIntent, isTrue);
    });

    test('parses variants: remind me every day at 8:30pm when to run tomorrow morning', () {
      const query = 'remind me every day at 8:30pm when to run tomorrow morning';
      final result = RoutineIntentParser.parse(query);

      expect(result.type, equals(RoutineIntentType.reminderAndRecommendation));
      expect(result.activity, equals('running'));
      expect(result.reminderHour, equals(20));
      expect(result.reminderMinute, equals(30));
      expect(result.targetPeriod, equals('morning'));
      expect(result.isDaily, isTrue);
    });

    test('parses evening activity target period: remind me at 6 PM when to walk tomorrow evening', () {
      const query = 'remind me at 6 PM when to walk tomorrow evening';
      final result = RoutineIntentParser.parse(query);

      expect(result.type, equals(RoutineIntentType.reminderAndRecommendation));
      expect(result.activity, equals('walking'));
      expect(result.reminderHour, equals(18));
      expect(result.reminderMinute, equals(0));
      expect(result.targetPeriod, equals('evening'));
    });

    test('parses createReminderOnly without recommendation keywords', () {
      const query = 'Set a daily reminder at 9 PM for walking';
      final result = RoutineIntentParser.parse(query);

      expect(result.type, equals(RoutineIntentType.createReminderOnly));
      expect(result.activity, equals('walking'));
      expect(result.reminderHour, equals(21));
      expect(result.reminderMinute, equals(0));
      expect(result.isDaily, isTrue);
      expect(result.isReminderIntent, isTrue);
      expect(result.isRecommendationIntent, isFalse);
    });

    test('parses recommendationOnly without reminder keywords', () {
      const query = 'What time should I go walking tomorrow?';
      final result = RoutineIntentParser.parse(query);

      expect(result.type, equals(RoutineIntentType.recommendationOnly));
      expect(result.activity, equals('walking'));
      expect(result.reminderHour, isNull);
      expect(result.reminderMinute, isNull);
      expect(result.isRecommendationIntent, isTrue);
      expect(result.isReminderIntent, isFalse);
    });

    test('parses listReminders intent', () {
      final queries = [
        'Show my reminders',
        'List my active reminders',
        'View reminder',
        'What are my reminders',
      ];
      for (final q in queries) {
        final result = RoutineIntentParser.parse(q);
        expect(result.type, equals(RoutineIntentType.listReminders), reason: 'Failed on $q');
      }
    });

    test('parses deleteReminder intent', () {
      final queries = [
        'Delete reminder',
        'Cancel my walking reminder',
        'Remove reminder',
      ];
      for (final q in queries) {
        final result = RoutineIntentParser.parse(q);
        expect(result.type, equals(RoutineIntentType.deleteReminder), reason: 'Failed on $q');
      }
    });

    test('returns none for regular weather queries', () {
      expect(RoutineIntentParser.parse('Will it rain today?').type, equals(RoutineIntentType.none));
      expect(RoutineIntentParser.parse('What is the temperature?').type, equals(RoutineIntentType.none));
      expect(RoutineIntentParser.parse('Carry an umbrella?').type, equals(RoutineIntentType.none));
    });
  });
}
