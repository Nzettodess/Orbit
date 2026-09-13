import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whereabouts/flight_checker/flight_checker_dialog.dart';
import 'package:whereabouts/flight_checker/utils/airport_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AirportHelper.hasKnownAirport Tests', () {
    test('Identifies known airports and airport codes correctly', () {
      expect(AirportHelper.hasKnownAirport('Penang (PEN)'), isTrue);
      expect(AirportHelper.hasKnownAirport('Kuala Lumpur (KUL)'), isTrue);
      expect(AirportHelper.hasKnownAirport('Tokyo (HND)'), isTrue);
      expect(AirportHelper.hasKnownAirport('Singapore (SIN)'), isTrue);
      expect(AirportHelper.hasKnownAirport('Bangkok (BKK)'), isTrue);
      expect(AirportHelper.hasKnownAirport('London (LHR)'), isTrue);
      expect(AirportHelper.hasKnownAirport('Subang (SZB)'), isTrue);
    });

    test('Identifies cities with known airports without explicit IATA code', () {
      expect(AirportHelper.hasKnownAirport('Penang, Malaysia'), isTrue);
      expect(AirportHelper.hasKnownAirport('Tokyo'), isTrue);
      expect(AirportHelper.hasKnownAirport('Singapore'), isTrue);
      expect(AirportHelper.hasKnownAirport('Seoul'), isTrue);
      expect(AirportHelper.hasKnownAirport('Melbourne'), isTrue);
      expect(AirportHelper.hasKnownAirport('Paris'), isTrue);
    });

    test('Returns false for null, empty strings, and generic non-airport locations', () {
      expect(AirportHelper.hasKnownAirport(null), isFalse);
      expect(AirportHelper.hasKnownAirport(''), isFalse);
      expect(AirportHelper.hasKnownAirport('   '), isFalse);
      expect(AirportHelper.hasKnownAirport('Home'), isFalse);
      expect(AirportHelper.hasKnownAirport('Office Floor 3'), isFalse);
      expect(AirportHelper.hasKnownAirport('Starbucks Coffee'), isFalse);
      expect(AirportHelper.hasKnownAirport('Meeting Room B'), isFalse);
      expect(AirportHelper.hasKnownAirport('No location selected'), isFalse);
    });
  });

  group('FlightCheckerDialog Touchpoint Parameters Tests', () {
    testWidgets('Initializes in Round-Trip mode when initialReturnDate is provided', (tester) async {
      final depDate = DateTime(2026, 11, 10);
      final retDate = DateTime(2026, 11, 20);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightCheckerDialog(
              initialOrigin: 'KUL',
              initialDestination: 'SIN',
              initialDate: depDate,
              initialReturnDate: retDate,
              autoSearch: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Return date field should be rendered because Round-Trip mode is automatically selected
      expect(find.text('Return'), findsOneWidget);
      expect(find.text('Nov 20, 2026'), findsOneWidget);
      expect(find.text('Nov 10, 2026'), findsOneWidget);
    });

    testWidgets('Defaults to One-Way mode when initialReturnDate is null', (tester) async {
      final depDate = DateTime(2026, 11, 10);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightCheckerDialog(
              initialOrigin: 'KUL',
              initialDestination: 'SIN',
              initialDate: depDate,
              initialReturnDate: null,
              autoSearch: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Return date field should not be present in One-Way mode
      expect(find.text('Return'), findsNothing);
      expect(find.text('Nov 10, 2026'), findsOneWidget);
    });

    testWidgets('Respects autoSearch false without triggering immediate network calls', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlightCheckerDialog(
              initialOrigin: 'KUL',
              initialDestination: 'SIN',
              autoSearch: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Form is displayed and Find Flights button is present
      expect(find.text('Find Flights'), findsOneWidget);
    });
  });
}
