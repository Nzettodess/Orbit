import 'package:flutter_test/flutter_test.dart';
import 'package:whereabouts/flight_checker/models/flight_info.dart';
import 'package:whereabouts/flight_checker/utils/flight_filter_helper.dart';

void main() {
  group('FlightFilterHelper Unit Tests', () {
    final f1 = FlightInfo(
      airline: 'AirAsia',
      stops: 'Nonstop',
      duration: '1 hr 10 min',
      price: 'RM 120',
      priceNumeric: 120,
      departure: const FlightEndpoint(
        airport: 'PEN',
        time: '08:00',
        date: '2026-10-15',
      ),
      arrival: const FlightEndpoint(
        airport: 'KUL',
        time: '09:10',
        date: '2026-10-15',
      ),
      deepLink: 'https://example.com',
    );

    final f2 = FlightInfo(
      airline: 'Malaysia Airlines',
      stops: 'Nonstop',
      duration: '55 min',
      price: 'RM 250',
      priceNumeric: 250,
      departure: const FlightEndpoint(
        airport: 'PEN',
        time: '14:30',
        date: '2026-10-15',
      ),
      arrival: const FlightEndpoint(
        airport: 'KUL',
        time: '15:25',
        date: '2026-10-15',
      ),
      deepLink: 'https://example.com',
    );

    final f3 = FlightInfo(
      airline: 'Scoot',
      stops: '1 stop',
      duration: '3 hr 20 min',
      price: 'RM 95',
      priceNumeric: 95,
      departure: const FlightEndpoint(
        airport: 'PEN',
        time: '06:15',
        date: '2026-10-15',
      ),
      arrival: const FlightEndpoint(
        airport: 'KUL',
        time: '09:35',
        date: '2026-10-15',
      ),
      deepLink: 'https://example.com',
    );

    final f4 = FlightInfo(
      airline: 'Batik Air',
      stops: '2 stops',
      duration: '5 hr 00 min',
      price: 'RM 180',
      priceNumeric: 180,
      departure: const FlightEndpoint(
        airport: 'PEN',
        time: '11:00',
        date: '2026-10-15',
      ),
      arrival: const FlightEndpoint(
        airport: 'KUL',
        time: '16:00',
        date: '2026-10-15',
      ),
      deepLink: 'https://example.com',
    );

    final allFlights = [f1, f2, f3, f4];

    test('parseDurationMinutes handles various formats', () {
      expect(
        FlightFilterHelper.parseDurationMinutes('1 hr 10 min'),
        equals(70),
      );
      expect(FlightFilterHelper.parseDurationMinutes('55 min'), equals(55));
      expect(FlightFilterHelper.parseDurationMinutes('2 hr'), equals(120));
      expect(
        FlightFilterHelper.parseDurationMinutes('2 hr 00 min'),
        equals(120),
      );
      expect(FlightFilterHelper.parseDurationMinutes(''), equals(0));
    });

    test('parseTimeToMinutes handles 24-hr and 12-hr formats', () {
      expect(FlightFilterHelper.parseTimeToMinutes('08:00'), equals(480));
      expect(FlightFilterHelper.parseTimeToMinutes('14:30'), equals(870));
      expect(FlightFilterHelper.parseTimeToMinutes('8:00 AM'), equals(480));
      expect(FlightFilterHelper.parseTimeToMinutes('2:30 PM'), equals(870));
      expect(FlightFilterHelper.parseTimeToMinutes('12:00 AM'), equals(0));
      expect(FlightFilterHelper.parseTimeToMinutes('12:00 PM'), equals(720));
    });

    test(
      'getAvailableAirlines extracts unique airlines in appearance order',
      () {
        final airlines = FlightFilterHelper.getAvailableAirlines(allFlights);
        expect(
          airlines,
          equals(['AirAsia', 'Malaysia Airlines', 'Scoot', 'Batik Air']),
        );
      },
    );

    test('getAirlineCounts returns accurate frequency count map', () {
      final counts = FlightFilterHelper.getAirlineCounts(allFlights);
      expect(counts['AirAsia'], equals(1));
      expect(counts['Malaysia Airlines'], equals(1));
      expect(counts['Scoot'], equals(1));
      expect(counts['Batik Air'], equals(1));
    });

    test('Sorting by Price: Low to High', () {
      final sorted = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(sortBy: FlightSortBy.priceLowToHigh),
      );
      expect(
        sorted.map((f) => f.priceNumeric).toList(),
        equals([95, 120, 180, 250]),
      );
    });

    test('Sorting by Duration: Shortest', () {
      final sorted = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(sortBy: FlightSortBy.durationShortest),
      );
      expect(sorted.first.airline, equals('Malaysia Airlines')); // 55 min
      expect(sorted[1].airline, equals('AirAsia')); // 70 min
    });

    test('Sorting by Departure: Earliest', () {
      final sorted = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(sortBy: FlightSortBy.departureEarliest),
      );
      expect(sorted.first.departure.time, equals('06:15'));
      expect(sorted.last.departure.time, equals('14:30'));
    });

    test('Sorting by Departure: Latest', () {
      final sorted = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(sortBy: FlightSortBy.departureLatest),
      );
      expect(sorted.first.departure.time, equals('14:30'));
      expect(sorted.last.departure.time, equals('06:15'));
    });

    test('Sorting by Nonstop First', () {
      final sorted = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(sortBy: FlightSortBy.nonstopFirst),
      );
      expect(sorted[0].stops.toLowerCase(), contains('nonstop'));
      expect(sorted[1].stops.toLowerCase(), contains('nonstop'));
      expect(sorted.last.stops, equals('2 stops'));
    });

    test('Filter by Nonstop Only', () {
      final filtered = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(stopsFilter: FlightStopsFilter.nonstopOnly),
      );
      expect(filtered.length, equals(2));
      expect(
        filtered.every((f) => f.stops.toLowerCase().contains('nonstop')),
        isTrue,
      );
    });

    test('Filter by max 1 stop', () {
      final filtered = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(stopsFilter: FlightStopsFilter.maxOneStop),
      );
      expect(filtered.length, equals(3));
      expect(filtered.any((f) => f.stops == '2 stops'), isFalse);
    });

    test('Filter by Single Airline', () {
      final filtered = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(selectedAirlines: {'AirAsia'}),
      );
      expect(filtered.length, equals(1));
      expect(filtered.first.airline, equals('AirAsia'));
      expect(
        const FlightFilterCriteria(selectedAirlines: {'AirAsia'}).selectedAirline,
        equals('AirAsia'),
      );
    });

    test('Filter by Multiple Airlines', () {
      final filtered = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(selectedAirlines: {'AirAsia', 'Scoot'}),
      );
      expect(filtered.length, equals(2));
      expect(filtered.map((f) => f.airline).toSet(), equals({'AirAsia', 'Scoot'}));
      expect(
        const FlightFilterCriteria(selectedAirlines: {'AirAsia', 'Scoot'}).selectedAirline,
        isNull,
      );
    });

    test('Empty airline filter returns all flights', () {
      final filtered = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(selectedAirlines: {}),
      );
      expect(filtered.length, equals(4));
    });

    test('Combined filter: Nonstop + Price Low to High', () {
      final result = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(
          stopsFilter: FlightStopsFilter.nonstopOnly,
          sortBy: FlightSortBy.priceLowToHigh,
        ),
      );
      expect(result.length, equals(2));
      expect(result[0].priceNumeric, equals(120)); // AirAsia
      expect(result[1].priceNumeric, equals(250)); // Malaysia Airlines
    });

    test('Filter by Layover Duration excludes flights with long layovers', () {
      final flightWithShortLayover = FlightInfo(
        airline: 'Singapore Airlines',
        stops: '1 stop',
        duration: '4 hr',
        price: 'RM 500',
        priceNumeric: 500,
        departure: const FlightEndpoint(airport: 'PEN', time: '10:00', date: '2026-10-15'),
        arrival: const FlightEndpoint(airport: 'NRT', time: '18:00', date: '2026-10-15'),
        deepLink: 'https://example.com',
        layovers: const [FlightLayover(duration: '1 hr 30 min', durationMinutes: 90)],
      );

      final flightWithLongLayover = FlightInfo(
        airline: 'Cathay Pacific',
        stops: '1 stop',
        duration: '8 hr',
        price: 'RM 450',
        priceNumeric: 450,
        departure: const FlightEndpoint(airport: 'PEN', time: '10:00', date: '2026-10-15'),
        arrival: const FlightEndpoint(airport: 'NRT', time: '22:00', date: '2026-10-15'),
        deepLink: 'https://example.com',
        layovers: const [FlightLayover(duration: '5 hr', durationMinutes: 300)],
      );

      final testFlights = [f1, flightWithShortLayover, flightWithLongLayover];

      // Max layover 2 hr (120 min) -> keeps nonstop f1 and flightWithShortLayover (90 min), drops flightWithLongLayover (300 min)
      final filtered = FlightFilterHelper.applyFiltersAndSort(
        testFlights,
        const FlightFilterCriteria(maxLayoverMinutes: 120),
      );

      expect(filtered.length, equals(2));
      expect(filtered.contains(f1), isTrue); // Nonstop is kept
      expect(filtered.contains(flightWithShortLayover), isTrue);
      expect(filtered.contains(flightWithLongLayover), isFalse);
    });

    test('FlightFilterCriteria layover duration state & isFiltered', () {
      const criteria = FlightFilterCriteria(maxLayoverMinutes: 180);
      expect(criteria.isFiltered, isTrue);
      expect(criteria.maxLayoverMinutes, equals(180));

      final cleared = criteria.copyWith(clearMaxLayover: true);
      expect(cleared.isFiltered, isFalse);
      expect(cleared.maxLayoverMinutes, isNull);
    });

    test('findBestFlight balances price and convenience', () {
      // f1 (AirAsia, RM 120, nonstop, 70m) vs f3 (Scoot, RM 95, 1 stop, 200m)
      final best = FlightFilterHelper.findBestFlight(allFlights);
      expect(best, isNotNull);
      expect(best!.airline, equals('AirAsia')); // Nonstop & fast beats slower 1-stop
    });

    test('Sorting by Best Flights ranks best trade-off first', () {
      final sorted = FlightFilterHelper.applyFiltersAndSort(
        allFlights,
        const FlightFilterCriteria(sortBy: FlightSortBy.best),
      );
      expect(sorted.first.airline, equals('AirAsia'));
    });
  });
}
