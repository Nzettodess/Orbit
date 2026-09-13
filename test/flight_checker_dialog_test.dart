import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whereabouts/flight_checker/flight_checker_dialog.dart';
import 'package:whereabouts/flight_checker/models/flight_info.dart';
import 'package:whereabouts/flight_checker/widgets/flight_card.dart';
import 'package:whereabouts/flight_checker/widgets/flight_leg_section_header.dart';
import 'package:whereabouts/flight_checker/widgets/flight_leg_tab_bar.dart';
import 'package:whereabouts/flight_checker/utils/flight_filter_helper.dart';
import 'package:whereabouts/flight_checker/widgets/flight_filter_bar.dart';
import 'package:whereabouts/flight_checker/widgets/flight_results_header_bar.dart';

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

    testWidgets('Trip type selector provides Round-Trip, One-Way, and Multi-Trip dynamically', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlightCheckerDialog(
              initialOrigin: 'KUL',
              initialDestination: 'SIN',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final roundTripTab = find.text('Round-Trip');
      final oneWayTab = find.text('One-Way');
      final multiTripTab = find.text('Multi-Trip');

      expect(roundTripTab, findsOneWidget);
      expect(oneWayTab, findsOneWidget);
      expect(multiTripTab, findsOneWidget);

      // Tap Round-Trip and verify Return date field appears
      await tester.tap(roundTripTab);
      await tester.pumpAndSettle();
      expect(find.text('Return'), findsOneWidget);

      // Tap One-Way and verify Return date field disappears
      await tester.tap(oneWayTab);
      await tester.pumpAndSettle();
      expect(find.text('Return'), findsNothing);

      // Tap Multi-Trip and verify Trip 1 and Add Flight (Trip 2) appear
      await tester.tap(multiTripTab);
      await tester.pumpAndSettle();
      expect(find.text('Trip 1'), findsOneWidget);

      final addBtn2 = find.text('Add Flight (Trip 2)');
      expect(addBtn2, findsOneWidget);

      // Scroll and tap Add Flight and verify Trip 2 is added
      await tester.ensureVisible(addBtn2);
      await tester.pumpAndSettle();
      await tester.tap(addBtn2);
      await tester.pumpAndSettle();
      expect(find.text('Trip 2'), findsOneWidget);
      expect(find.text('Add Flight (Trip 3)'), findsOneWidget);
    });
  });

  group('FlightLegTabBar & Round-Trip Multi-Leg Tests', () {
    test('FlightSearchResponse correctly parses multiCityLegs and isMultiCity', () {
      final json = {
        'success': true,
        'tripType': 'multicity',
        'isMultiCity': true,
        'count': 2,
        'multiCityLegs': [
          {
            'legIndex': 0,
            'title': 'Trip 1',
            'origin': 'KUL',
            'destination': 'SIN',
            'date': '2026-10-15',
            'flights': [mockFlight1.toJson()],
          },
          {
            'legIndex': 1,
            'title': 'Trip 2',
            'origin': 'SIN',
            'destination': 'NRT',
            'date': '2026-10-20',
            'flights': [mockFlight2.toJson()],
          },
        ],
        'flights': [mockFlight1.toJson(), mockFlight2.toJson()],
        'fallbackUrl': 'https://google.com',
      };

      final response = FlightSearchResponse.fromJson(json);
      expect(response.success, isTrue);
      expect(response.isMultiCity, isTrue);
      expect(response.multiCityLegs.length, equals(2));
      expect(response.multiCityLegs[0].title, equals('Trip 1'));
      expect(response.multiCityLegs[1].title, equals('Trip 2'));
    });
    test('FlightSearchResponse correctly parses outboundFlights, returnFlights, and tripType', () {
      final json = {
        'success': true,
        'tripType': 'roundtrip',
        'count': 2,
        'outboundFlights': [mockFlight1.toJson()],
        'returnFlights': [mockFlight2.toJson()],
        'flights': [mockFlight1.toJson()],
        'fallbackUrl': 'https://google.com',
      };

      final response = FlightSearchResponse.fromJson(json);
      expect(response.success, isTrue);
      expect(response.isRoundTrip, isTrue);
      expect(response.outboundFlights.length, equals(1));
      expect(response.returnFlights.length, equals(1));
      expect(response.outboundFlights.first.airline, equals('AirAsia'));
      expect(response.returnFlights.first.airline, equals('Scoot'));
    });

    testWidgets('FlightLegTabBar renders legs, combined total, and handles tab switching', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FlightLegTabBar(
                  selectedIndex: selected,
                  onTabSelected: (idx) => setState(() => selected = idx),
                  outboundFlights: [mockFlight1],
                  returnFlights: [mockFlight2],
                  origin: 'KUL',
                  destination: 'SIN',
                  departureDate: '2026-10-15',
                  returnDate: '2026-10-22',
                  currency: 'MYR',
                  isDark: false,
                );
              },
            ),
          ),
        ),
      );

      // Verify Departing and Returning tabs rendered
      expect(find.text('Departing'), findsOneWidget);
      expect(find.text('Returning'), findsOneWidget);
      expect(find.text('KUL → SIN'), findsOneWidget);
      expect(find.text('SIN → KUL'), findsOneWidget);

      // Verify combined price banner: mockFlight1 (120) + mockFlight2 (120) = 240
      expect(find.text('Estimated Round-Trip Total: '), findsOneWidget);
      expect(find.text('RM 240'), findsOneWidget);

      // Tap Returning tab
      await tester.tap(find.text('Returning'));
      await tester.pumpAndSettle();

      expect(selected, equals(1));
    });
  });

  group('FlightLegSectionHeader & Separator Tests', () {
    testWidgets('FlightLegSectionHeader renders route, count, and lowest price correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlightLegSectionHeader(
              title: 'Departing Flights',
              routeSubtitle: 'PEN → PVG',
              date: '2026-10-15',
              count: 13,
              lowestPrice: 608,
              currency: 'MYR',
              icon: Icons.flight_takeoff_rounded,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Departing Flights'), findsOneWidget);
      expect(find.text('13 options'), findsOneWidget);
      expect(find.text('PEN → PVG · 2026-10-15'), findsOneWidget);
      expect(find.text('RM 608'), findsOneWidget);
      expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);
    });

    testWidgets('FlightLegSeparator renders label and sync icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlightLegSeparator(
              label: 'RETURNING OPTIONS (PVG → PEN)',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('RETURNING OPTIONS (PVG → PEN)'), findsOneWidget);
      expect(find.byIcon(Icons.sync_alt_rounded), findsOneWidget);
    });

    testWidgets('FlightLegSectionHeader supports collapsible toggle callback', (tester) async {
      bool toggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightLegSectionHeader(
              title: 'Returning Flights',
              routeSubtitle: 'PVG → PEN',
              date: '2026-10-22',
              count: 6,
              lowestPrice: 400,
              currency: 'MYR',
              icon: Icons.flight_land_rounded,
              isDark: false,
              isCollapsible: true,
              isExpanded: true,
              onToggleExpand: () => toggled = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
      await tester.tap(find.text('Returning Flights'));
      await tester.pumpAndSettle();
      expect(toggled, isTrue);
    });

    testWidgets('FlightResultsHeaderBar renders Found count and triggers Google Flights callback', (tester) async {
      bool googleFlightsClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightResultsHeaderBar(
              totalFoundCount: 24,
              isRoundTrip: true,
              isAllExpanded: true,
              onOpenGoogleFlights: () => googleFlightsClicked = true,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Found 24 Flights'), findsOneWidget);
      expect(find.text('Open in Google Flights'), findsOneWidget);

      await tester.tap(find.text('Open in Google Flights'));
      await tester.pumpAndSettle();
      expect(googleFlightsClicked, isTrue);
    });

    testWidgets('FlightFilterBar renders Showing count and Collapse/Expand button on same row', (tester) async {
      bool toggleClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightFilterBar(
              criteria: const FlightFilterCriteria(),
              onChanged: (_) {},
              availableAirlines: const ['AirAsia', 'MAS'],
              totalCount: 30,
              visibleCount: 30,
              isDark: false,
              isAllExpanded: true,
              onToggleAllExpanded: () => toggleClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Showing 30 of 30'), findsOneWidget);
      expect(find.text('Collapse'), findsOneWidget);

      await tester.tap(find.text('Collapse'));
      await tester.pumpAndSettle();
      expect(toggleClicked, isTrue);
    });

    testWidgets('FlightLegSection animates SizeTransition correctly on collapse and expand', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FlightLegSection(
                title: 'Departing Flights',
                routeSubtitle: 'KUL → SIN',
                date: '2026-10-15',
                count: 1,
                currency: 'MYR',
                icon: Icons.flight_takeoff_rounded,
                isDark: false,
                isCollapsible: true,
                isExpanded: true,
                flights: [mockFlight1],
                bestFlight: mockFlight1,
                legPrefix: 'outbound',
                legName: 'departing',
              ),
            ),
          ),
        ),
      );

      expect(find.text('AirAsia'), findsOneWidget);

      // Now rebuild with isExpanded = false
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FlightLegSection(
                title: 'Departing Flights',
                routeSubtitle: 'KUL → SIN',
                date: '2026-10-15',
                count: 1,
                currency: 'MYR',
                icon: Icons.flight_takeoff_rounded,
                isDark: false,
                isCollapsible: true,
                isExpanded: false,
                flights: [mockFlight1],
                bestFlight: mockFlight1,
                legPrefix: 'outbound',
                legName: 'departing',
              ),
            ),
          ),
        ),
      );

      // Wait for SizeTransition animation to finish smoothly
      await tester.pumpAndSettle();

      // Find the SizeTransition widget and assert its sizeFactor is 0.0
      final sizeTransitionFinder = find.byType(SizeTransition);
      expect(sizeTransitionFinder, findsOneWidget);
      final sizeTransitionWidget = tester.widget<SizeTransition>(sizeTransitionFinder);
      expect(sizeTransitionWidget.sizeFactor.value, equals(0.0));
    });
  });
}

