import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whereabouts/flight_checker/models/flight_info.dart';
import 'package:whereabouts/flight_checker/services/flight_service.dart';
import 'package:whereabouts/flight_checker/utils/airport_data.dart';
import 'package:whereabouts/flight_checker/utils/currency_helper.dart';
import 'package:whereabouts/flight_checker/widgets/flight_card.dart';
import 'package:whereabouts/flight_checker/widgets/flight_segment_timeline.dart';
import 'package:whereabouts/flight_checker/widgets/passenger_selector.dart';
import 'package:whereabouts/flight_checker/widgets/popup_selector_field.dart';

void main() {
  group('Flight Models & Serialization Tests', () {
    test('FlightEndpoint serializes and deserializes correctly', () {
      final endpoint = const FlightEndpoint(
        airport: 'Singapore Changi Airport',
        time: '8:30 AM',
        date: 'Thursday, October 15',
      );

      final json = endpoint.toJson();
      final fromJson = FlightEndpoint.fromJson(json);

      expect(fromJson.airport, equals('Singapore Changi Airport'));
      expect(fromJson.time, equals('8:30 AM'));
      expect(fromJson.date, equals('Thursday, October 15'));
    });

    test('FlightInfo parses JSON correctly', () {
      final flight = FlightInfo.fromJson({
        'airline': 'AirAsia',
        'logoUrl': 'https://www.gstatic.com/flights/airline_logos/70px/AK.png',
        'stops': 'Nonstop',
        'duration': '1 hr 10 min',
        'price': '118 Malaysian ringgits',
        'priceNumeric': 118,
        'departure': {'airport': 'Kuala Lumpur International Airport', 'time': '8:30 AM', 'date': 'Thursday, October 15'},
        'arrival': {'airport': 'Singapore Changi Airport', 'time': '9:40 AM', 'date': 'Thursday, October 15'},
        'deepLink': 'https://www.google.com/travel/flights?q=test',
      });
      expect(flight.airline, equals('AirAsia'));
      expect(flight.logoUrl, contains('AK.png'));
      expect(flight.stops, equals('Nonstop'));
      expect(flight.duration, equals('1 hr 10 min'));
      expect(flight.priceNumeric, equals(118));
    });

    test('FlightSearchResponse parses flights array correctly', () {
      final res = FlightSearchResponse.fromJson({
        'success': true,
        'count': 1,
        'flights': [{'airline': 'Scoot', 'stops': 'Nonstop', 'duration': '1 hr 15 min', 'price': 'MYR 135', 'priceNumeric': 135, 'departure': {'airport': 'KUL', 'time': '5:00 PM', 'date': '2026-10-15'}, 'arrival': {'airport': 'SIN', 'time': '6:15 PM', 'date': '2026-10-15'}, 'deepLink': 'https://google.com'}],
        'fallbackUrl': 'https://google.com/fallback',
      });
      expect(res.success, isTrue);
      expect(res.count, equals(1));
      expect(res.flights.first.airline, equals('Scoot'));
      expect(res.fallbackUrl, equals('https://google.com/fallback'));
    });

    test('FlightInfo parses segments and layovers correctly', () {
      final json = {
        'airline': 'Vietjet',
        'stops': '1 stop',
        'duration': '10 hr 25 min',
        'price': 'RM 829',
        'priceNumeric': 829,
        'departure': {'airport': 'KUL', 'time': '1:35 PM', 'date': '2026-10-15'},
        'arrival': {'airport': 'HND', 'time': '1:00 AM', 'date': '2026-10-16'},
        'deepLink': 'https://google.com',
        'layovers': [
          {
            'duration': '2 hr 10 min',
            'airportCode': 'SGN',
            'city': 'Ho Chi Minh City',
            'text': '2 hr 10 min layover · Ho Chi Minh City (SGN)',
          }
        ],
        'segments': [
          {
            'departureAirport': 'Kuala Lumpur International Airport',
            'departureCode': 'KUL',
            'departureTime': '1:35 PM',
            'arrivalAirport': 'Tan Son Nhat International Airport',
            'arrivalCode': 'SGN',
            'arrivalTime': '2:20 PM',
            'duration': '1 hr 45 min',
            'legroom': '28 in legroom',
            'aircraft': 'Airbus A321',
            'flightNumber': 'VJ 826',
            'airline': 'Vietjet',
            'emissions': '102 kg CO2e',
          },
          {
            'departureAirport': 'Tan Son Nhat International Airport',
            'departureCode': 'SGN',
            'departureTime': '4:30 PM',
            'arrivalAirport': 'Haneda Airport',
            'arrivalCode': 'HND',
            'arrivalTime': '1:00 AM',
            'duration': '6 hr 30 min',
            'legroom': '28 in legroom',
            'aircraft': 'Airbus A321',
            'flightNumber': 'VJ 820',
            'airline': 'Vietjet',
            'emissions': '329 kg CO2e',
          }
        ],
      };

      final flight = FlightInfo.fromJson(json);

      expect(flight.segments.length, equals(2));
      expect(flight.segments[0].flightNumber, equals('VJ 826'));
      expect(flight.segments[0].aircraft, equals('Airbus A321'));
      expect(flight.segments[0].legroom, equals('28 in legroom'));
      expect(flight.layovers.length, equals(1));
      expect(flight.layovers[0].airportCode, equals('SGN'));
      expect(flight.layovers[0].duration, equals('2 hr 10 min'));
    });
  });

  group('FlightService Fallback URL Construction Tests', () {
    test('builds valid one-way URL', () {
      const params = FlightSearchParams(
        origin: 'KUL',
        destination: 'SIN',
        departureDate: '2026-10-15',
        tripType: 'oneway',
        currency: 'MYR',
      );

      final url = FlightService.buildGoogleFlightsFallbackUrl(params);

      expect(url, startsWith('https://www.google.com/travel/flights?q='));
      expect(url, contains('curr=MYR'));
      expect(url, contains('hl=en'));
      expect(Uri.decodeComponent(url), contains('Flights to SIN from KUL on 2026-10-15 one way'));
    });

    test('builds valid round-trip URL with passengers and class', () {
      const params = FlightSearchParams(
        origin: 'Kuala Lumpur',
        destination: 'Tokyo',
        departureDate: '2026-11-01',
        returnDate: '2026-11-08',
        tripType: 'roundtrip',
        adults: 2,
        children: 1,
        cabinClass: 'business',
        currency: 'USD',
      );

      final url = FlightService.buildGoogleFlightsFallbackUrl(params);
      final decoded = Uri.decodeComponent(url);

      expect(decoded, contains('Flights to Tokyo from Kuala Lumpur on 2026-11-01 through 2026-11-08'));
      expect(decoded, contains('business class'));
      expect(decoded, contains('2 adults'));
      expect(decoded, contains('1 children'));
      expect(url, contains('curr=USD'));
    });

    test('builds clean URL stripping parenthetical airport codes', () {
      const params = FlightSearchParams(
        origin: 'Penang (PEN)',
        destination: 'Singapore (SIN)',
        departureDate: '2026-10-15',
        currency: 'MYR',
      );

      final url = FlightService.buildGoogleFlightsFallbackUrl(params);
      final decoded = Uri.decodeComponent(url);

      expect(decoded, contains('Flights to Singapore from Penang on 2026-10-15 one way'));
      expect(decoded, isNot(contains('(PEN)')));
      expect(decoded, isNot(contains('(SIN)')));
    });

    test('AirportHelper.cleanLocationName strips airport codes correctly', () {
      expect(AirportHelper.cleanLocationName('Penang (PEN)'), equals('Penang'));
      expect(AirportHelper.cleanLocationName('Tokyo (HND)'), equals('Tokyo'));
      expect(AirportHelper.cleanLocationName('Singapore'), equals('Singapore'));
      expect(AirportHelper.cleanLocationName(''), equals(''));
      expect(AirportHelper.cleanLocationName(null), equals(''));
    });
  });

  group('CurrencyHelper Formatting & Price Range Tests', () {
    test('formats various currencies with standard symbols', () {
      expect(CurrencyHelper.formatAmount(1365, 'MYR'), equals('RM 1,365'));
      expect(CurrencyHelper.formatAmount(340, 'USD'), equals('\$340'));
      expect(CurrencyHelper.formatAmount(180, 'SGD'), equals('S\$180'));
      expect(CurrencyHelper.formatAmount(290, 'EUR'), equals('€290'));
      expect(CurrencyHelper.formatAmount(250, 'GBP'), equals('£250'));
      expect(CurrencyHelper.formatAmount(48000, 'JPY'), equals('¥48,000'));
      expect(CurrencyHelper.formatAmount(1500000, 'IDR'), equals('Rp 1,500,000'));
    });

    test('calculates accurate live price range from flight results', () {
      const dep = FlightEndpoint(airport: 'KUL', time: '8:00 AM', date: '2026-10-15');
      const arr = FlightEndpoint(airport: 'SIN', time: '9:15 AM', date: '2026-10-15');

      final flights = [
        const FlightInfo(
          airline: 'AirAsia',
          stops: 'Nonstop',
          duration: '1 hr 15 min',
          price: 'RM 118',
          priceNumeric: 118,
          departure: dep,
          arrival: arr,
          deepLink: '',
        ),
        const FlightInfo(
          airline: 'Scoot',
          stops: 'Nonstop',
          duration: '1 hr 10 min',
          price: 'RM 145',
          priceNumeric: 145,
          departure: dep,
          arrival: arr,
          deepLink: '',
        ),
        const FlightInfo(
          airline: 'Singapore Airlines',
          stops: 'Nonstop',
          duration: '1 hr 15 min',
          price: 'RM 450',
          priceNumeric: 450,
          departure: dep,
          arrival: arr,
          deepLink: '',
        ),
      ];

      final range = CurrencyHelper.calculatePriceRange(flights, 'MYR');
      expect(range, isNotNull);
      expect(range!.min, equals(118));
      expect(range.max, equals(450));
      expect(range.minFormatted, equals('RM 118'));
      expect(range.maxFormatted, equals('RM 450'));
      expect(range.bestAirline, equals('AirAsia'));
      expect(range.cheapestFlight?.priceNumeric, equals(118));
      expect(range.cheapestFlight?.airline, equals('AirAsia'));
      expect(range.average, equals(238)); // (118 + 145 + 450) / 3 = 237.66 -> 238
      expect(range.avgFormatted, equals('RM 238'));
    });
  });

  group('Legroom Label Formatting Tests', () {
    test('ensures clear units for ambiguous numeric strings', () {
      // String with pair of numbers like "18 23"
      expect(FlightSegmentTimeline.formatLegroomLabel('18 23'), equals('18–23 in legroom'));
      // Single number like "28"
      expect(FlightSegmentTimeline.formatLegroomLabel('28'), equals('28 in legroom'));
      // Already has unit
      expect(FlightSegmentTimeline.formatLegroomLabel('28 in'), equals('28 in legroom'));
      expect(FlightSegmentTimeline.formatLegroomLabel('31 inches'), equals('31 inches legroom'));
      expect(FlightSegmentTimeline.formatLegroomLabel('76 cm'), equals('76 cm legroom'));
      // Empty
      expect(FlightSegmentTimeline.formatLegroomLabel(''), equals(''));
    });
  });

  group('Passenger Control Widget Tests', () {
    testWidgets('PassengerControlPanel decrements and increments correctly within safe bounds', (tester) async {
      int adults = 1;
      int children = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PassengerControlPanel(
                  adults: adults,
                  children: children,
                  onChanged: (a, c) {
                    setState(() {
                      adults = a;
                      children = c;
                    });
                  },
                  onDone: () {},
                  isDark: false,
                );
              },
            ),
          ),
        ),
      );

      // Verify initial display
      expect(find.text('1'), findsOneWidget); // Adults
      expect(find.text('0'), findsOneWidget); // Children

      // Try decrementing adults below 1 (should be blocked / no effect)
      final decAdults = find.byTooltip('Decrease Adults');
      await tester.tap(decAdults);
      await tester.pumpAndSettle();
      expect(adults, equals(1)); // Must still be 1! Never 0 or negative

      // Try decrementing children below 0 (should be blocked / no effect)
      final decChildren = find.byTooltip('Decrease Children');
      await tester.tap(decChildren);
      await tester.pumpAndSettle();
      expect(children, equals(0)); // Must still be 0! Never negative

      // Increment adults to 2
      final incAdults = find.byTooltip('Increase Adults');
      await tester.tap(incAdults);
      await tester.pumpAndSettle();
      expect(adults, equals(2));

      // Increment children to 1
      final incChildren = find.byTooltip('Increase Children');
      await tester.tap(incChildren);
      await tester.pumpAndSettle();
      expect(children, equals(1));
    });
  });

  group('FlightCard Whole-Card Click Interaction Tests', () {
    const mockFlight = FlightInfo(
      airline: 'AirAsia',
      stops: 'Nonstop',
      duration: '1 hr 15 min',
      price: 'RM 188',
      priceNumeric: 188,
      departure: FlightEndpoint(airport: 'Penang (PEN)', time: '8:00 AM', date: '2026-10-15'),
      arrival: FlightEndpoint(airport: 'Kuala Lumpur (KUL)', time: '9:15 AM', date: '2026-10-15'),
      deepLink: 'https://google.com/flights',
      segments: [
        FlightSegment(
          airline: 'AirAsia',
          flightNumber: 'AK 6112',
          aircraft: 'Airbus A320',
          departureTime: '8:00 AM',
          departureAirport: 'Penang',
          departureCode: 'PEN',
          arrivalTime: '9:15 AM',
          arrivalAirport: 'Kuala Lumpur',
          arrivalCode: 'KUL',
          duration: '1 hr 15 min',
          legroom: '29 in',
        ),
      ],
    );

    testWidgets('Tapping anywhere on flight card body toggles expanded details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlightCard(flight: mockFlight),
          ),
        ),
      );

      // Initially, details should be collapsed (AK 6112 segment not yet in view)
      expect(find.text('Details'), findsOneWidget);
      expect(find.textContaining('AK 6112'), findsNothing);

      // Tap on the card body (e.g. on the airline name "AirAsia")
      await tester.tap(find.text('AirAsia').first);
      await tester.pumpAndSettle();

      // Card should now be expanded!
      expect(find.text('Hide'), findsOneWidget);
      expect(find.textContaining('AK 6112'), findsOneWidget);

      // Tap again on the card body to collapse
      await tester.tap(find.text('AirAsia').first);
      await tester.pumpAndSettle();

      // Card should be collapsed again
      expect(find.text('Details'), findsOneWidget);
      expect(find.textContaining('AK 6112'), findsNothing);
    });

    testWidgets('Tapping Details / Hide button explicitly also toggles expansion', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlightCard(flight: mockFlight),
          ),
        ),
      );

      // Tap the "Details" button
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      expect(find.text('Hide'), findsOneWidget);
      expect(find.textContaining('AK 6112'), findsOneWidget);

      // Tap the "Hide" button
      await tester.tap(find.text('Hide'));
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
      expect(find.textContaining('AK 6112'), findsNothing);
    });

    testWidgets('Renders Lowest Fare and Best badges when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlightCard(flight: mockFlight, isLowestFare: true, isBest: true),
          ),
        ),
      );

      expect(find.text('Lowest Fare'), findsOneWidget);
      expect(find.text('Best'), findsOneWidget);
    });

    testWidgets('Renders red hazard warning icon and badge for layover >= 3h', (tester) async {
      const longLayoverFlight = FlightInfo(
        airline: 'China Southern',
        stops: '1 stop',
        duration: '12 hr 35 min',
        price: 'RM 1,250',
        priceNumeric: 1250,
        departure: FlightEndpoint(airport: 'Kuala Lumpur (KUL)', time: '9:00 AM', date: '2026-10-15'),
        arrival: FlightEndpoint(airport: 'Tokyo (NRT)', time: '11:35 PM', date: '2026-10-15'),
        deepLink: 'https://google.com',
        layovers: [
          FlightLayover(duration: '6 hr 25 min', durationMinutes: 385, airportCode: 'CAN', city: 'Guangzhou', text: '6 hr 25 min layover CAN'),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FlightCard(flight: longLayoverFlight))),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2));
      expect(find.text('6 hr 25 min CAN'), findsOneWidget);
      expect(find.text('1 stop'), findsOneWidget);
    });
  });

  group('PopupSelectorField Widget Tests', () {
    testWidgets('renders display label and opens popup menu on tap', (tester) async {
      String selected = 'MYR';
      final items = [
        {'value': 'MYR', 'label': 'MYR (RM)'},
        {'value': 'USD', 'label': 'USD (\$)'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PopupSelectorField(
                  label: 'Currency',
                  value: selected,
                  displayLabel: 'MYR (RM)',
                  items: items,
                  onSelected: (val) => setState(() => selected = val),
                  bg: Colors.grey.shade200,
                  isDark: false,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('MYR (RM)'), findsOneWidget);

      // Tap the popup field to open options
      await tester.tap(find.text('MYR (RM)'));
      await tester.pumpAndSettle();

      // Options should now be visible in popup menu
      expect(find.text('USD (\$)'), findsOneWidget);

      // Select USD
      await tester.tap(find.text('USD (\$)'));
      await tester.pumpAndSettle();

      expect(selected, equals('USD'));
    });
  });
}

