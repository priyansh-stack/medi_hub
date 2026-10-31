import 'package:flutter_test/flutter_test.dart';
import 'package:medi_hub/core/constants/location_catalog.dart';

void main() {
  group('LocationCatalog Tests', () {
    test('contains primary supported countries', () {
      expect(LocationCatalog.countries, contains('India'));
      expect(LocationCatalog.countries, contains('United States'));
      expect(LocationCatalog.countries, contains('United Kingdom'));
      expect(LocationCatalog.countries, contains('Canada'));
      expect(LocationCatalog.countries, contains('Australia'));
      expect(LocationCatalog.countries, contains('United Arab Emirates'));
      expect(LocationCatalog.countries, contains('Singapore'));
      expect(LocationCatalog.countries, contains('Germany'));
      expect(LocationCatalog.countries, contains('France'));
    });

    test('validates countries correctly', () {
      expect(LocationCatalog.isValidCountry('India'), isTrue);
      expect(LocationCatalog.isValidCountry('United States'), isTrue);
      expect(LocationCatalog.isValidCountry('Narnia'), isFalse);
      expect(LocationCatalog.isValidCountry(null), isFalse);
      expect(LocationCatalog.isValidCountry(''), isFalse);
    });

    test('returns registered states for India', () {
      final states = LocationCatalog.getStatesForCountry('India');
      expect(states, contains('Karnataka'));
      expect(states, contains('Maharashtra'));
      expect(states, contains('Delhi'));
      expect(states, contains('Tamil Nadu'));
      expect(states, contains('Uttar Pradesh'));
      expect(states.length, greaterThanOrEqualTo(28));
    });

    test('returns registered states for United States', () {
      final states = LocationCatalog.getStatesForCountry('United States');
      expect(states, contains('California'));
      expect(states, contains('New York'));
      expect(states, contains('Texas'));
      expect(states, contains('Washington'));
      expect(states.length, equals(51)); // 50 states + DC
    });

    test('validates state for country correctly', () {
      expect(LocationCatalog.isValidState('India', 'Karnataka'), isTrue);
      expect(LocationCatalog.isValidState('India', 'California'), isFalse);
      expect(LocationCatalog.isValidState('United States', 'California'), isTrue);
      expect(LocationCatalog.isValidState('United States', 'Karnataka'), isFalse);
      expect(LocationCatalog.isValidState('India', 'Unknown State'), isFalse);
      expect(LocationCatalog.isValidState(null, 'Karnataka'), isFalse);
      expect(LocationCatalog.isValidState('India', null), isFalse);
    });

    test('defaults match supported values', () {
      expect(LocationCatalog.isValidCountry(LocationCatalog.defaultCountry), isTrue);
      expect(
        LocationCatalog.isValidState(LocationCatalog.defaultCountry, LocationCatalog.defaultState),
        isTrue,
      );
    });
  });
}

