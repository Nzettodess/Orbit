import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whereabouts/flight_checker/models/flight_info.dart';
import 'package:whereabouts/flight_checker/utils/flight_filter_helper.dart';
import 'package:whereabouts/flight_checker/widgets/flight_card.dart';
import 'package:whereabouts/flight_checker/widgets/flight_multicity_results_view.dart';
import 'package:whereabouts/flight_checker/widgets/flight_results_header_bar.dart';
import 'package:whereabouts/flight_checker/widgets/flight_leg_section_header.dart';

void main() {
  final sampleFlight1 = FlightInfo(
    airline: 'AirAsia',
    stops: 'Nonstop',
    duration: '1h 10m',
    price: 'RM 150',
    priceNumeric: 150,
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
    deepLink: 'https://google.com/travel/flights',
  );

  final sampleFlight2 = FlightInfo(
    airline: 'Scoot',
    stops: 'Nonstop',
    duration: '6h 30m',
    price: 'RM 850',
    priceNumeric: 850,
    departure: const FlightEndpoint(
      airport: 'Singapore (SIN)',
      time: '14:00',
      date: '2026-10-20',
    ),
    arrival: const FlightEndpoint(
      airport: 'Tokyo (NRT)',
      time: '21:30',
      date: '2026-10-20',
    ),
    deepLink: 'https://google.com/travel/flights',
  );

  final sampleFlight3 = FlightInfo(
    airline: 'ANA',
    stops: 'Nonstop',
    duration: '7h 30m',
    price: 'RM 1200',
    priceNumeric: 1200,
    departure: const FlightEndpoint(
      airport: 'Tokyo (HND)',
      time: '10:00',
      date: '2026-10-28',
    ),
    arrival: const FlightEndpoint(
      airport: 'Kuala Lumpur (KUL)',
      time: '16:30',
      date: '2026-10-28',
    ),
    deepLink: 'https://google.com/travel/flights',
  );

  final multiCityLegs = [
    FlightMultiCityLegGroup(
      legIndex: 0,
      title: 'Trip 1',
      origin: 'KUL',
      destination: 'SIN',
      date: '2026-10-15',
      flights: [sampleFlight1],
    ),
    FlightMultiCityLegGroup(
      legIndex: 1,
      title: 'Trip 2',
      origin: 'SIN',
      destination: 'NRT',
      date: '2026-10-20',
      flights: [sampleFlight2],
    ),
    FlightMultiCityLegGroup(
      legIndex: 2,
      title: 'Trip 3',
      origin: 'HND',
      destination: 'KUL',
      date: '2026-10-28',
      flights: [sampleFlight3],
    ),
  ];

  group('FlightMultiTripSummaryBanner Tests', () {
    testWidgets('renders total fare, leg count badge, and summary line', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlightMultiTripSummaryBanner(
              totalFare: 2200,
              currency: 'MYR',
              legSummaries: [
                'Trip 1: KUL → SIN (MYR 150)',
                'Trip 2: SIN → NRT (MYR 850)',
                'Trip 3: HND → KUL (MYR 1200)',
              ],
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Estimated Multi-Trip Total: '), findsOneWidget);
      expect(find.text('3 Trips'), findsOneWidget);
      expect(find.text('MYR 2200'), findsOneWidget);
      expect(find.text('Trip 1: KUL → SIN (MYR 150) + Trip 2: SIN → NRT (MYR 850) + Trip 3: HND → KUL (MYR 1200)'), findsOneWidget);
    });

    testWidgets('FlightMultiTripSummaryBanner on iPhone SE width (320px) wraps without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FlightMultiTripSummaryBanner(
                totalFare: 5491,
                currency: 'MYR',
                legSummaries: [
                  'Trip 1: PEN → MUC (MYR 1837)',
                  'Trip 2: MUC → BKK (MYR 1499)',
                  'Trip 3: BKK → PEK (MYR 2155)',
                ],
                isDark: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Estimated Multi-Trip Total: '), findsOneWidget);
      expect(find.text('3 Trips'), findsOneWidget);
      expect(find.text('MYR 5491'), findsOneWidget);
    });
  });

  group('FlightMultiCityResultsView Tests', () {
    testWidgets('renders all trips with collapsible sections and headers', (tester) async {
      int toggledLegIndex = -1;
      bool allToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FlightMultiCityResultsView(
                multiCityLegs: multiCityLegs,
                expandedMap: const {0: true, 1: true, 2: true},
                onToggleLeg: (idx) => toggledLegIndex = idx,
                onToggleAllLegs: () => allToggled = true,
                filterCriteria: const FlightFilterCriteria(),
                onFilterChanged: (_) {},
                currency: 'MYR',
                fallbackUrl: 'https://google.com',
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Trip 1'), findsOneWidget);
      expect(find.text('Trip 2'), findsOneWidget);
      expect(find.text('Trip 3'), findsOneWidget);
      expect(find.text('AirAsia'), findsOneWidget);
      expect(find.text('Scoot'), findsOneWidget);
      expect(find.text('ANA'), findsOneWidget);

      expect(find.text('Found 3 Flights'), findsOneWidget);
      expect(find.text('Collapse'), findsOneWidget);

      await tester.tap(find.text('Collapse'));
      await tester.pumpAndSettle();
      expect(allToggled, isTrue);

      await tester.tap(find.text('Trip 2'));
      await tester.pumpAndSettle();
      expect(toggledLegIndex, equals(1));
    });
  });

  group('Compact Mobile UI Overflow Tests', () {
    testWidgets('FlightResultsHeaderBar on narrow mobile screen (<420px) wraps without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightResultsHeaderBar(
              totalFoundCount: 15,
              isRoundTrip: false,
              isMultiTrip: true,
              isAllExpanded: true,
              onToggleAllExpanded: () {},
              onOpenGoogleFlights: () {},
              isDark: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Found 15 Flights'), findsOneWidget);
      expect(find.text('Open in Google Flights'), findsOneWidget);
    });

    testWidgets('FlightCard on narrow screen wraps auxiliary badges without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final longWaitFlight = FlightInfo(
        airline: 'Emirates With A Very Long Name Airlines',
        stops: '2 stops',
        duration: '16h 30m',
        price: 'RM 3,500',
        priceNumeric: 3500,
        departure: const FlightEndpoint(
          airport: 'Dubai (DXB)',
          time: '02:00',
          date: '2026-10-15',
        ),
        arrival: const FlightEndpoint(
          airport: 'London Heathrow (LHR)',
          time: '14:30',
          date: '2026-10-15',
        ),
        deepLink: 'https://google.com/travel/flights',
        layovers: const [
          FlightLayover(
            airportCode: 'DOH',
            duration: '6h 15m',
            durationMinutes: 375,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FlightCard(
                flight: longWaitFlight,
                isLowestFare: true,
                isBest: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Best'), findsOneWidget);
      expect(find.text('Lowest Fare'), findsOneWidget);
      expect(find.text('Long wait time'), findsOneWidget);
    });

    testWidgets('FlightLegCardsList renders identical flights in multi-city Trip 6 without duplicate keys', (tester) async {
      final flightA = FlightInfo(
        airline: 'Air France',
        stops: '1 stop',
        duration: '14h 20m',
        price: 'RM 2,943',
        priceNumeric: 2943,
        departure: const FlightEndpoint(
          airport: 'Paris (CDG)',
          time: '12:40 AM',
          date: '2026-10-30',
        ),
        arrival: const FlightEndpoint(
          airport: 'New York (JFK)',
          time: '03:00 PM',
          date: '2026-10-30',
        ),
        deepLink: 'https://google.com/travel/flights',
      );

      final flightB = FlightInfo(
        airline: 'Air France',
        stops: '1 stop',
        duration: '15h 10m',
        price: 'RM 2,943',
        priceNumeric: 2943,
        departure: const FlightEndpoint(
          airport: 'Paris (CDG)',
          time: '12:40 AM',
          date: '2026-10-30',
        ),
        arrival: const FlightEndpoint(
          airport: 'New York (JFK)',
          time: '03:50 PM',
          date: '2026-10-30',
        ),
        deepLink: 'https://google.com/travel/flights',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FlightLegCardsList(
                flights: [flightA, flightB],
                lowestPrice: 2943,
                bestFlight: null,
                legPrefix: 'multicity_5',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FlightCard), findsNWidgets(2));
      expect(find.text('Air France'), findsNWidgets(2));
      expect(find.text('12:40 AM'), findsNWidgets(2));
      expect(find.text('RM 2,943'), findsNWidgets(2));
    });
  });
}
