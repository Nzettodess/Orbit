import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whereabouts/flight_checker/flight_checker_dialog.dart';
import 'package:whereabouts/flight_checker/models/flight_info.dart';
import 'package:whereabouts/flight_checker/widgets/flight_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockFlight1 = FlightInfo(
    airline: 'AirAsia',
    stops: 'Nonstop',
    duration: '1 hr 10 min',
    price: 'RM 120',
    priceNumeric: 120,
    departure: const FlightEndpoint(
      airport: 'Kuala Lumpur (KUL)',
      time: '08:00',
      date: '2026-10-15',
    ),
    arrival: const FlightEndpoint(
      airport: 'Singapore (SIN)',
      time: '09:10',
      date: '2026-10-15',
    ),
    deepLink: 'https://www.google.com/travel/flights',
  );

  final mockFlight2 = FlightInfo(
    airline: 'Scoot',
    stops: 'Nonstop',
    duration: '1 hr 15 min',
    price: 'RM 120',
    priceNumeric: 120, // Identical lowest fare as mockFlight1
    departure: const FlightEndpoint(
      airport: 'Kuala Lumpur (KUL)',
      time: '14:00',
      date: '2026-10-15',
    ),
    arrival: const FlightEndpoint(
      airport: 'Singapore (SIN)',
      time: '15:15',
      date: '2026-10-15',
    ),
    deepLink: 'https://www.google.com/travel/flights',
  );

  final mockFlight3 = FlightInfo(
    airline: 'Malaysia Airlines',
    stops: 'Nonstop',
    duration: '1 hr 10 min',
    price: 'RM 250',
    priceNumeric: 250,
    departure: const FlightEndpoint(
      airport: 'Kuala Lumpur (KUL)',
      time: '19:00',
      date: '2026-10-15',
    ),
    arrival: const FlightEndpoint(
      airport: 'Singapore (SIN)',
      time: '20:10',
      date: '2026-10-15',
    ),
    deepLink: 'https://www.google.com/travel/flights',
  );

  group('Duplicate Lowest Fare & Unique GlobalKey Safety Tests', () {
    testWidgets('Renders multiple flights with identical lowest prices without duplicate key errors', (tester) async {
      final cheapestKey = GlobalKey();
      // Build a column simulating the dialog results list with two identical lowest prices
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  FlightCard(
                    key: cheapestKey,
                    flight: mockFlight1,
                    isLowestFare: true,
                  ),
                  FlightCard(
                    key: const ValueKey('flight_card_1'),
                    flight: mockFlight2,
                    isLowestFare: true,
                  ),
                  FlightCard(
                    key: const ValueKey('flight_card_2'),
                    flight: mockFlight3,
                    isLowestFare: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify no duplicate key exception and all cards rendered
      expect(find.byType(FlightCard), findsNWidgets(3));
      expect(find.text('Lowest Fare'), findsNWidgets(2));
      expect(find.text('RM 120'), findsNWidgets(2));
      expect(find.text('RM 250'), findsOneWidget);
    });
  });
}
