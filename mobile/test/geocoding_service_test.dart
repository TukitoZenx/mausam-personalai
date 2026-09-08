import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/geocoding_service.dart';
import 'package:mobile/theme/environment_theme.dart';

void main() {
  group('GeocodedPlace parsing', () {
    test('parses numeric and string coordinates from geocoding payloads', () {
      final place = GeocodedPlace.fromJson({
        'name': 'London',
        'display_name': 'London, England, United Kingdom',
        'latitude': '51.5074',
        'longitude': -0.1278,
        'city': 'London',
        'state': 'England',
        'country': 'United Kingdom',
      });

      expect(place.isValid, isTrue);
      expect(place.name, 'London');
      expect(place.latitude, closeTo(51.5074, 0.0001));
      expect(place.longitude, closeTo(-0.1278, 0.0001));
    });

    test('rejects null-island coordinates', () {
      final place = GeocodedPlace.fromJson({
        'name': 'Nowhere',
        'display_name': 'Nowhere',
        'latitude': 0,
        'longitude': 0,
      });
      expect(place.isValid, isFalse);
    });
  });

  group('Time-of-day drawer states', () {
    test('maps local hours onto Dawn → Night including Evening', () {
      expect(EnvironmentTheme.periodForHour(6), TimeOfDayPeriod.morning);
      expect(EnvironmentTheme.periodForHour(9), TimeOfDayPeriod.morning);
      expect(EnvironmentTheme.periodForHour(13), TimeOfDayPeriod.afternoon);
      expect(EnvironmentTheme.periodForHour(17), TimeOfDayPeriod.evening);
      expect(EnvironmentTheme.periodForHour(20), TimeOfDayPeriod.evening);
      expect(EnvironmentTheme.periodForHour(23), TimeOfDayPeriod.night);
    });
  });
}
