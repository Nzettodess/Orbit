import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whereabouts/flight_checker/models/flight_info.dart';
import 'package:whereabouts/flight_checker/widgets/flight_search_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleParamsOneWay = FlightSearchParams(
    origin: 'Kuala Lumpur (KUL)',
    destination: 'Singapore (SIN)',
    departureDate: '2026-10-15',
    tripType: 'oneway',
    adults: 1,
    children: 0,
    cabinClass: 'economy',
    currency: 'MYR',
  );

  final sampleParamsRoundTrip = FlightSearchParams(
    origin: 'Penang (PEN)',
    destination: 'Tokyo (NRT)',
    departureDate: '2026-11-01',
    returnDate: '2026-11-10',
    tripType: 'roundtrip',
    adults: 2,
    children: 1,
    cabinClass: 'business',
    currency: 'USD',
  );

  final sampleParamsMultiCity = FlightSearchParams(
    origin: 'KUL',
    destination: 'SIN',
    departureDate: '2026-10-15',
    tripType: 'multicity',
    adults: 1,
    children: 0,
    cabinClass: 'economy',
    currency: 'MYR',
    multiCityLegs: const [
      FlightLegParam(origin: 'KUL', destination: 'SIN', date: '2026-10-15'),
      FlightLegParam(origin: 'SIN', destination: 'NRT', date: '2026-10-20'),
    ],
  );

  group('FlightSearchSummaryCard Formatting & Unit Tests', () {
    test('formatRoute generates clean readable route representation', () {
      expect(
        FlightSearchSummaryCard.formatRoute(sampleParamsOneWay),
        equals('Kuala Lumpur (KUL) → Singapore (SIN)'),
      );
      expect(
        FlightSearchSummaryCard.formatRoute(sampleParamsRoundTrip),
        equals('Penang (PEN) ⇄ Tokyo (NRT)'),
      );
      expect(
        FlightSearchSummaryCard.formatRoute(sampleParamsMultiCity),
        equals('2 Trips: KUL→SIN · SIN→NRT'),
      );
    });

    test('formatDates formats single date and date ranges correctly', () {
      expect(
        FlightSearchSummaryCard.formatDates(sampleParamsOneWay),
        equals('15 Oct 2026'),
      );
      expect(
        FlightSearchSummaryCard.formatDates(sampleParamsRoundTrip),
        equals('1 Nov – 10 Nov 2026'),
      );
    });

    test('formatMeta formats passenger counts, cabin class, and currency', () {
      expect(
        FlightSearchSummaryCard.formatMeta(sampleParamsOneWay),
        equals('1 Passenger · Economy · MYR'),
      );
      expect(
        FlightSearchSummaryCard.formatMeta(sampleParamsRoundTrip),
        equals('3 Passengers · Business · USD'),
      );
    });
  });

  group('FlightSearchSummaryCard Widget Tests', () {
    testWidgets('Collapsed viewing mode renders summary bar and invokes onToggleExpand on tap', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightSearchSummaryCard(
              currentParams: sampleParamsOneWay,
              isExpanded: false,
              onToggleExpand: () => toggled = true,
              onSearch: (_) {},
              isLoading: false,
              hasResults: true,
              isDark: false,
            ),
          ),
        ),
      );

      // Collapsed bar is visible
      expect(find.byKey(const ValueKey('search_card_collapsed_bar')), findsOneWidget);
      expect(find.text('Kuala Lumpur (KUL) → Singapore (SIN)'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      // Tap on Edit button / collapsed bar
      await tester.tap(find.byKey(const ValueKey('search_card_collapsed_bar')));
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
    });

    testWidgets('Expanded edit mode renders full form and Collapse button when hasResults is true', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FlightSearchSummaryCard(
                currentParams: sampleParamsOneWay,
                isExpanded: true,
                onToggleExpand: () => toggled = true,
                onSearch: (_) {},
                isLoading: false,
                hasResults: true,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Trip Search & Details'), findsOneWidget);
      final collapseBtn = find.byKey(const ValueKey('search_card_collapse_btn'));
      expect(collapseBtn, findsOneWidget);
      expect(find.text('Collapse'), findsOneWidget);

      await tester.tap(collapseBtn);
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
    });
  });
}
