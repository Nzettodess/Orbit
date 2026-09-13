import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whereabouts/flight_checker/flight_checker_dialog.dart';
import 'package:whereabouts/flight_checker/utils/airport_data.dart';
import 'package:whereabouts/models.dart';
import 'package:whereabouts/widgets/event_detail_dialog.dart';

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

    test('Resolves newyork, nyc, and city abbreviations to known airports', () {
      expect(AirportHelper.hasKnownAirport('newyork'), isTrue);
      expect(AirportHelper.hasKnownAirport('New York'), isTrue);
      expect(AirportHelper.hasKnownAirport('New York City'), isTrue);
      expect(AirportHelper.hasKnownAirport('United States, New York'), isTrue);
      expect(AirportHelper.hasKnownAirport('nyc'), isTrue);
      expect(AirportHelper.hasKnownAirport('NYC'), isTrue);
      expect(AirportHelper.hasKnownAirport('kl'), isTrue);
      expect(AirportHelper.hasKnownAirport('sf'), isTrue);
      expect(AirportHelper.hasKnownAirport('la'), isTrue);
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

  group('EventDetailDialog Flight Touchpoint Tests', () {
    testWidgets('Renders Check Flights to Venue tile when venue has an airport and date is in future', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final event = GroupEvent(
        id: 'event_future',
        groupId: 'g1',
        creatorId: 'u1',
        title: 'Tech Conference',
        description: 'Annual summit',
        venue: 'Tokyo Big Sight, Tokyo',
        date: futureDate,
        rsvps: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventDetailDialog(
              event: event,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check Flights to Venue ↗'), findsOneWidget);
    });

    testWidgets('Hides Check Flights to Venue tile when event date is in the past', (tester) async {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final event = GroupEvent(
        id: 'event_past',
        groupId: 'g1',
        creatorId: 'u1',
        title: 'Past Expo',
        description: 'Closed summit',
        venue: 'Tokyo Big Sight, Tokyo',
        date: pastDate,
        rsvps: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventDetailDialog(
              event: event,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check Flights to Venue ↗'), findsNothing);
    });

    testWidgets('Hides Check Flights to Venue tile when venue has no recognized airport', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final event = GroupEvent(
        id: 'event_local',
        groupId: 'g1',
        creatorId: 'u1',
        title: 'Internal Sync',
        description: 'Weekly team meeting',
        venue: 'Meeting Room B, 2nd Floor',
        date: futureDate,
        rsvps: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventDetailDialog(
              event: event,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check Flights to Venue ↗'), findsNothing);
    });

    testWidgets('Hides Check Flights to Venue tile when venue is the same as user home airport', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final event = GroupEvent(
        id: 'event_same_home',
        groupId: 'g1',
        creatorId: 'u1',
        title: 'Tokyo Meetup',
        description: 'Local gathering',
        venue: 'Tokyo Big Sight, Tokyo',
        date: futureDate,
        rsvps: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventDetailDialog(
              event: event,
              userHomeAirport: 'Tokyo (HND)',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check Flights to Venue ↗'), findsNothing);
    });

    testWidgets('Pre-fills user home airport and passes it when flight tile is tapped', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final event = GroupEvent(
        id: 'event_diff_home',
        groupId: 'g1',
        creatorId: 'u1',
        title: 'Tokyo Summit',
        description: 'Overseas summit',
        venue: 'Tokyo Big Sight, Tokyo',
        date: futureDate,
        rsvps: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventDetailDialog(
              event: event,
              userHomeAirport: 'Kuala Lumpur (KUL)',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check Flights to Venue ↗'), findsOneWidget);
      await tester.tap(find.text('Check Flights to Venue ↗'));
      await tester.pumpAndSettle();

      // FlightCheckerDialog opened with KUL pre-filled
      expect(find.text('Kuala Lumpur (KUL)'), findsWidgets);
    });
  });

  group('AirportHelper.isSameLocation Tests', () {
    test('Correctly identifies matching locations across variations and codes', () {
      expect(AirportHelper.isSameLocation('Penang (PEN)', 'Penang'), isTrue);
      expect(AirportHelper.isSameLocation('KUL', 'Kuala Lumpur (KUL)'), isTrue);
      expect(AirportHelper.isSameLocation('Penang', 'penang'), isTrue);
      expect(AirportHelper.isSameLocation('Tokyo', 'Tokyo (HND)'), isTrue);
      expect(AirportHelper.isSameLocation('SIN', 'Singapore (SIN)'), isTrue);
      expect(AirportHelper.isSameLocation('JFK', 'New York'), isTrue);
      expect(AirportHelper.isSameLocation('Malaysia, Penang', 'Penang (PEN)'), isTrue);
    });

    test('Correctly identifies non-matching locations', () {
      expect(AirportHelper.isSameLocation('Kuala Lumpur (KUL)', 'Tokyo (HND)'), isFalse);
      expect(AirportHelper.isSameLocation('Penang (PEN)', 'Singapore (SIN)'), isFalse);
      expect(AirportHelper.isSameLocation(null, 'KUL'), isFalse);
      expect(AirportHelper.isSameLocation('', 'KUL'), isFalse);
      expect(AirportHelper.isSameLocation('KUL', ''), isFalse);
    });
  });

  group('Flight Same-Location Search Validation Tests', () {
    testWidgets('Prevents search and displays error banner when origin and destination are the same', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlightCheckerDialog(
              initialOrigin: 'Penang (PEN)',
              initialDestination: 'Penang',
              autoSearch: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Error banner is displayed under the From and To fields
      expect(find.text('Origin and destination cannot be the same airport'), findsOneWidget);
      // "Find Flights" button is visible and search was prevented
      expect(find.text('Find Flights'), findsOneWidget);
      // Error icon is shown
      expect(find.byIcon(Icons.error_outline_rounded), findsWidgets);
    });
  });
}
