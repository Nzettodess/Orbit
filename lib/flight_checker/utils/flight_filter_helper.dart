import '../models/flight_info.dart';

/// Available sorting modes for flight search results
enum FlightSortBy {
  priceLowToHigh('Price: Low to High'),
  durationShortest('Duration: Shortest'),
  departureEarliest('Departure: Earliest'),
  departureLatest('Departure: Latest'),
  nonstopFirst('Stops: Nonstop First');

  final String label;
  const FlightSortBy(this.label);
}

/// Stops filter criteria
enum FlightStopsFilter {
  all('All Flights'),
  nonstopOnly('Nonstop Only'),
  maxOneStop('≤ 1 Stop');

  final String label;
  const FlightStopsFilter(this.label);
}

/// Filter & sort state for flight results
class FlightFilterCriteria {
  final FlightSortBy sortBy;
  final FlightStopsFilter stopsFilter;
  final Set<String> selectedAirlines;

  const FlightFilterCriteria({
    this.sortBy = FlightSortBy.priceLowToHigh,
    this.stopsFilter = FlightStopsFilter.all,
    this.selectedAirlines = const <String>{},
  });

  /// Single airline backward compatibility getter
  String? get selectedAirline =>
      selectedAirlines.length == 1 ? selectedAirlines.first : null;

  bool get isFiltered =>
      stopsFilter != FlightStopsFilter.all || selectedAirlines.isNotEmpty;

  FlightFilterCriteria copyWith({
    FlightSortBy? sortBy,
    FlightStopsFilter? stopsFilter,
    Set<String>? selectedAirlines,
    String? selectedAirline,
    bool clearAirlines = false,
    bool clearAirline = false,
  }) {
    Set<String> newAirlines;
    if (clearAirlines || clearAirline) {
      newAirlines = const <String>{};
    } else if (selectedAirlines != null) {
      newAirlines = selectedAirlines;
    } else if (selectedAirline != null) {
      newAirlines = selectedAirline.isNotEmpty && selectedAirline != 'ALL'
          ? {selectedAirline}
          : const <String>{};
    } else {
      newAirlines = this.selectedAirlines;
    }

    return FlightFilterCriteria(
      sortBy: sortBy ?? this.sortBy,
      stopsFilter: stopsFilter ?? this.stopsFilter,
      selectedAirlines: newAirlines,
    );
  }
}

/// Pure helper functions for sorting and filtering flight search results
/// Strictly under 500 lines (Hard limit: 500 lines)
class FlightFilterHelper {
  /// Parse flight duration string (e.g. "1 hr 10 min", "55 min", "2 hr") into integer minutes
  static int parseDurationMinutes(String duration) {
    int total = 0;
    final hrMatch = RegExp(
      r'(\d+)\s*hr',
      caseSensitive: false,
    ).firstMatch(duration);
    if (hrMatch != null) {
      total += (int.tryParse(hrMatch.group(1)!) ?? 0) * 60;
    }
    final minMatch = RegExp(
      r'(\d+)\s*min',
      caseSensitive: false,
    ).firstMatch(duration);
    if (minMatch != null) {
      total += int.tryParse(minMatch.group(1)!) ?? 0;
    }
    return total;
  }

  /// Parse flight departure time (e.g. "10:35 PM", "8:30 AM", "14:20") into minutes from midnight
  static int parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    final match = RegExp(
      r'(\d+):(\d+)\s*(AM|PM)?',
      caseSensitive: false,
    ).firstMatch(timeStr);
    if (match == null) return 0;

    int hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    final ampm = match.group(3)?.toUpperCase();

    if (ampm == 'PM' && hour < 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;

    return hour * 60 + minute;
  }

  /// Get stops count from stops string (e.g. "Nonstop" -> 0, "1 stop" -> 1)
  static int getStopsCount(String stops) {
    final lower = stops.toLowerCase();
    if (lower.contains('nonstop')) return 0;
    final match = RegExp(r'(\d+)').firstMatch(lower);
    if (match != null) return int.tryParse(match.group(1)!) ?? 1;
    return 1;
  }

  /// Extract unique airline names in original appearance order
  static List<String> getAvailableAirlines(List<FlightInfo> flights) {
    final seen = <String>{};
    final list = <String>[];
    for (final f in flights) {
      final name = f.airline.trim();
      if (name.isNotEmpty && !seen.contains(name)) {
        seen.add(name);
        list.add(name);
      }
    }
    return list;
  }

  /// Extract frequency count of each airline across all returned flights
  static Map<String, int> getAirlineCounts(List<FlightInfo> flights) {
    final counts = <String, int>{};
    for (final f in flights) {
      final name = f.airline.trim();
      if (name.isNotEmpty) {
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Apply active stops filter, airline filter, and sort order to flight list
  static List<FlightInfo> applyFiltersAndSort(
    List<FlightInfo> flights,
    FlightFilterCriteria criteria,
  ) {
    // 1. Filtering
    var list = flights.where((f) {
      // Stops filter
      if (criteria.stopsFilter == FlightStopsFilter.nonstopOnly) {
        if (getStopsCount(f.stops) > 0) return false;
      } else if (criteria.stopsFilter == FlightStopsFilter.maxOneStop) {
        if (getStopsCount(f.stops) > 1) return false;
      }

      // Airline filter (multi-select)
      if (criteria.selectedAirlines.isNotEmpty) {
        final matches = criteria.selectedAirlines.any((sel) =>
            sel.trim().toLowerCase() == f.airline.trim().toLowerCase());
        if (!matches) return false;
      }

      return true;
    }).toList();

    // 2. Sorting
    switch (criteria.sortBy) {
      case FlightSortBy.priceLowToHigh:
        list.sort((a, b) {
          final pA = a.priceNumeric > 0 ? a.priceNumeric : 9999999;
          final pB = b.priceNumeric > 0 ? b.priceNumeric : 9999999;
          return pA.compareTo(pB);
        });
        break;

      case FlightSortBy.durationShortest:
        list.sort((a, b) {
          final dA = parseDurationMinutes(a.duration);
          final dB = parseDurationMinutes(b.duration);
          final durCompare = dA.compareTo(dB);
          if (durCompare != 0) return durCompare;
          return a.priceNumeric.compareTo(b.priceNumeric);
        });
        break;

      case FlightSortBy.departureEarliest:
        list.sort((a, b) {
          final tA = parseTimeToMinutes(a.departure.time);
          final tB = parseTimeToMinutes(b.departure.time);
          final timeCompare = tA.compareTo(tB);
          if (timeCompare != 0) return timeCompare;
          return a.priceNumeric.compareTo(b.priceNumeric);
        });
        break;

      case FlightSortBy.departureLatest:
        list.sort((a, b) {
          final tA = parseTimeToMinutes(a.departure.time);
          final tB = parseTimeToMinutes(b.departure.time);
          final timeCompare = tB.compareTo(tA);
          if (timeCompare != 0) return timeCompare;
          return a.priceNumeric.compareTo(b.priceNumeric);
        });
        break;

      case FlightSortBy.nonstopFirst:
        list.sort((a, b) {
          final sA = getStopsCount(a.stops);
          final sB = getStopsCount(b.stops);
          final stopCompare = sA.compareTo(sB);
          if (stopCompare != 0) return stopCompare;
          return a.priceNumeric.compareTo(b.priceNumeric);
        });
        break;
    }

    return list;
  }
}
