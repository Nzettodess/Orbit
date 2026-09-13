import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:whereabouts/flight_checker/utils/airport_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestSnackBarHarness({
    required String country,
    String? state,
    required DateTime startDate,
    required DateTime endDate,
    required String userHome,
    required Function(String dest, DateTime date, DateTime? returnDate) onFlightAction,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                final dayCount = endDate.difference(startDate).inDays + 1;
                final dateRange = dayCount == 1
                    ? DateFormat('MMM dd, yyyy').format(startDate)
                    : "${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}";

                final destStr = state != null && state.isNotEmpty ? '$country, $state' : country;
                final hasAirport = AirportHelper.hasKnownAirport(destStr);
                final userHomeAirport = AirportHelper.findBestAirport(userHome);
                final targetAirport = AirportHelper.findBestAirport(destStr);
                final isSameAsHome = userHomeAirport.isNotEmpty &&
                    targetAirport.isNotEmpty &&
                    userHomeAirport == targetAirport;

                final showFlightAction = hasAirport && !isSameAsHome;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Location set to ${state != null ? '$state, ' : ''}$country for $dateRange"),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 6),
                    action: showFlightAction
                        ? SnackBarAction(
                            label: 'Check Flights ✈',
                            textColor: Colors.white,
                            onPressed: () {
                              onFlightAction(
                                destStr,
                                startDate,
                                dayCount > 1 ? endDate : null,
                              );
                            },
                          )
                        : null,
                  ),
                );
              },
              child: const Text('Trigger Save'),
            );
          },
        ),
      ),
    );
  }

  group('Location Saved SnackBar Tests', () {
    testWidgets('Shows Check Flights action for New York with multi-day returnDate', (tester) async {
      String? clickedDest;
      DateTime? clickedDate;
      DateTime? clickedReturnDate;

      final start = DateTime(2026, 10, 10);
      final end = DateTime(2026, 10, 20);

      await tester.pumpWidget(
        buildTestSnackBarHarness(
          country: 'United States',
          state: 'New York',
          startDate: start,
          endDate: end,
          userHome: 'Malaysia, Penang',
          onFlightAction: (dest, date, retDate) {
            clickedDest = dest;
            clickedDate = date;
            clickedReturnDate = retDate;
          },
        ),
      );

      // Tap button to trigger SnackBar
      await tester.tap(find.text('Trigger Save'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 750)); // Settle SnackBar

      // Verify SnackBar content and action button are displayed
      expect(find.text('Location set to New York, United States for Oct 10 - Oct 20, 2026'), findsOneWidget);
      expect(find.text('Check Flights ✈'), findsOneWidget);

      // Tap Check Flights
      await tester.tap(find.text('Check Flights ✈'));
      await tester.pump();

      expect(clickedDest, equals('United States, New York'));
      expect(clickedDate, equals(start));
      expect(clickedReturnDate, equals(end));
    });

    testWidgets('Shows Check Flights action for lowercase newyork shorthand', (tester) async {
      String? clickedDest;
      DateTime? clickedDate;
      DateTime? clickedReturnDate;

      final start = DateTime(2026, 11, 5);
      final end = DateTime(2026, 11, 5); // 1-day trip

      await tester.pumpWidget(
        buildTestSnackBarHarness(
          country: 'newyork',
          state: null,
          startDate: start,
          endDate: end,
          userHome: 'Kuala Lumpur',
          onFlightAction: (dest, date, retDate) {
            clickedDest = dest;
            clickedDate = date;
            clickedReturnDate = retDate;
          },
        ),
      );

      await tester.tap(find.text('Trigger Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Location set to newyork for Nov 05, 2026'), findsOneWidget);
      expect(find.text('Check Flights ✈'), findsOneWidget);

      await tester.tap(find.text('Check Flights ✈'));
      await tester.pump();

      expect(clickedDest, equals('newyork'));
      expect(clickedDate, equals(start));
      expect(clickedReturnDate, isNull); // 1-day trip has null returnDate (One-Way)
    });

    testWidgets('Suppresses Check Flights action when destination has no airport', (tester) async {
      final start = DateTime(2026, 10, 10);
      final end = DateTime(2026, 10, 12);

      await tester.pumpWidget(
        buildTestSnackBarHarness(
          country: 'Local Meeting Room',
          state: null,
          startDate: start,
          endDate: end,
          userHome: 'Penang',
          onFlightAction: (_, __, ___) {},
        ),
      );

      await tester.tap(find.text('Trigger Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Check Flights ✈'), findsNothing);
    });

    testWidgets('Suppresses Check Flights action when destination is same as user home airport', (tester) async {
      final start = DateTime(2026, 10, 10);
      final end = DateTime(2026, 10, 12);

      await tester.pumpWidget(
        buildTestSnackBarHarness(
          country: 'Malaysia',
          state: 'Penang',
          startDate: start,
          endDate: end,
          userHome: 'Malaysia, Penang',
          onFlightAction: (_, __, ___) {},
        ),
      );

      await tester.tap(find.text('Trigger Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Check Flights ✈'), findsNothing);
    });
  });
}
