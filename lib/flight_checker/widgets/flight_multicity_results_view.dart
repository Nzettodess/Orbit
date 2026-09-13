import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../models/flight_info.dart';
import '../services/flight_service.dart';
import '../utils/flight_filter_helper.dart';
import 'flight_checker_status_views.dart';
import 'flight_filter_bar.dart';
import 'flight_leg_section_header.dart';
import 'flight_results_header_bar.dart';

/// Renders the multi-trip flight search results with trip-by-trip collapsible sections,
/// combined total pricing banner, and global collapse/expand synchronization.
/// Strictly < 500 lines (Hard limit: 500 lines).
class FlightMultiCityResultsView extends StatelessWidget {
  final List<FlightMultiCityLegGroup> multiCityLegs;
  final Map<int, bool> expandedMap;
  final ValueChanged<int> onToggleLeg;
  final VoidCallback onToggleAllLegs;
  final FlightFilterCriteria filterCriteria;
  final ValueChanged<FlightFilterCriteria> onFilterChanged;
  final String currency;
  final String fallbackUrl;
  final bool isDark;

  const FlightMultiCityResultsView({
    super.key,
    required this.multiCityLegs,
    required this.expandedMap,
    required this.onToggleLeg,
    required this.onToggleAllLegs,
    required this.filterCriteria,
    required this.onFilterChanged,
    required this.currency,
    required this.fallbackUrl,
    required this.isDark,
  });

  static const List<Color> _legAccentColors = [
    AppColors.iosBlue,
    AppColors.iosPurple,
    AppColors.iosGreen,
    AppColors.iosOrange,
  ];

  @override
  Widget build(BuildContext context) {
    final allFlights = multiCityLegs.expand((l) => l.flights).toList();
    final totalFoundCount = allFlights.length;
    final availableAirlines = FlightFilterHelper.getAvailableAirlines(allFlights);
    final airlineCounts = FlightFilterHelper.getAirlineCounts(allFlights);

    final filteredLegFlights = <int, List<FlightInfo>>{};
    final lowestLegPrices = <int, int?>{};
    final bestLegFlights = <int, FlightInfo?>{};

    for (final leg in multiCityLegs) {
      filteredLegFlights[leg.legIndex] = FlightFilterHelper.applyFiltersAndSort(
        leg.flights,
        filterCriteria,
      );
      lowestLegPrices[leg.legIndex] = FlightLegSectionHeader.findLowestPrice(leg.flights);
      bestLegFlights[leg.legIndex] = FlightFilterHelper.findBestFlight(leg.flights);
    }

    final totalVisibleCount = filteredLegFlights.values.fold(0, (sum, list) => sum + list.length);

    int totalCombinedFare = 0;
    bool hasAllLowest = true;
    for (final leg in multiCityLegs) {
      final lowest = lowestLegPrices[leg.legIndex];
      if (lowest == null || lowest <= 0) {
        hasAllLowest = false;
        break;
      }
      totalCombinedFare += lowest;
    }

    final legSummaries = multiCityLegs.map((leg) {
      final lowest = lowestLegPrices[leg.legIndex];
      final priceStr = lowest != null ? ' ($currency $lowest)' : '';
      return '${leg.title}: ${leg.origin} → ${leg.destination}$priceStr';
    }).toList();

    final isAllExpanded = multiCityLegs.any((leg) => expandedMap[leg.legIndex] ?? true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlightMultiTripSummaryBanner(
          totalFare: hasAllLowest ? totalCombinedFare.toDouble() : 0.0,
          currency: currency,
          legSummaries: legSummaries,
          isDark: isDark,
        ),
        FlightResultsHeaderBar(
          totalFoundCount: totalFoundCount,
          isRoundTrip: false,
          isMultiTrip: true,
          isAllExpanded: isAllExpanded,
          onToggleAllExpanded: onToggleAllLegs,
          onOpenGoogleFlights: () => FlightService.launchFlightUrl(fallbackUrl),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        FlightFilterBar(
          criteria: filterCriteria,
          onChanged: onFilterChanged,
          availableAirlines: availableAirlines,
          airlineCounts: airlineCounts,
          totalCount: totalFoundCount,
          visibleCount: totalVisibleCount,
          isDark: isDark,
          isAllExpanded: isAllExpanded,
          onToggleAllExpanded: onToggleAllLegs,
        ),
        const SizedBox(height: 10),
        if (totalVisibleCount == 0)
          FlightCheckerEmptyFilterView(
            isDark: isDark,
            onReset: () => onFilterChanged(const FlightFilterCriteria()),
          )
        else
          ..._buildLegSections(filteredLegFlights, lowestLegPrices, bestLegFlights),
      ],
    );
  }

  List<Widget> _buildLegSections(
    Map<int, List<FlightInfo>> filteredLegFlights,
    Map<int, int?> lowestLegPrices,
    Map<int, FlightInfo?> bestLegFlights,
  ) {
    final widgets = <Widget>[];

    for (int i = 0; i < multiCityLegs.length; i++) {
      final leg = multiCityLegs[i];
      final filtered = filteredLegFlights[leg.legIndex] ?? const [];
      final isExpanded = expandedMap[leg.legIndex] ?? true;
      final accentColor = _legAccentColors[i % _legAccentColors.length];

      if (i > 0) {
        widgets.add(
          FlightLegSeparator(
            label: '${leg.title.toUpperCase()} (${leg.origin} → ${leg.destination})',
            isDark: isDark,
          ),
        );
      }

      widgets.add(
        FlightLegSection(
          title: leg.title,
          routeSubtitle: '${leg.origin} → ${leg.destination}',
          date: leg.date,
          count: filtered.length,
          lowestPrice: lowestLegPrices[leg.legIndex],
          currency: currency,
          icon: Icons.flight_takeoff_rounded,
          accentColor: accentColor,
          isDark: isDark,
          isCollapsible: true,
          isExpanded: isExpanded,
          onToggleExpand: () => onToggleLeg(leg.legIndex),
          flights: filtered,
          bestFlight: bestLegFlights[leg.legIndex],
          legPrefix: 'multicity_${leg.legIndex}',
          legName: leg.title.toLowerCase(),
        ),
      );
    }

    return widgets;
  }
}
