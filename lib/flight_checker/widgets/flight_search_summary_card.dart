import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../models/flight_info.dart';
import 'flight_search_form.dart';

/// Collapsible search card that renders a sleek compact summary bar when viewing
/// results, and smoothly expands into the full FlightSearchForm when editing.
class FlightSearchSummaryCard extends StatelessWidget {
  final FlightSearchParams currentParams;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<FlightSearchParams> onSearch;
  final ValueChanged<String>? onCurrencyChanged;
  final ValueChanged<String>? onTripTypeChanged;
  final bool isLoading;
  final bool hasResults;
  final bool isDark;

  const FlightSearchSummaryCard({
    super.key,
    required this.currentParams,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onSearch,
    this.onCurrencyChanged,
    this.onTripTypeChanged,
    required this.isLoading,
    required this.hasResults,
    required this.isDark,
  });

  static String _shortAirport(String loc) {
    final match = RegExp(r'\(([A-Z0-9]{3})\)').firstMatch(loc);
    if (match != null) return match.group(1)!;
    return loc;
  }

  static String formatRoute(FlightSearchParams params) {
    if (params.tripType == 'multicity') {
      final legs = params.multiCityLegs;
      if (legs != null && legs.isNotEmpty) {
        if (legs.length == 1) {
          final l = legs.first;
          final from = l.origin.isNotEmpty ? _shortAirport(l.origin) : 'Origin';
          final to = l.destination.isNotEmpty ? _shortAirport(l.destination) : 'Destination';
          return 'Trip 1: $from → $to';
        }
        final summary = legs
            .map((l) => '${l.origin.isNotEmpty ? _shortAirport(l.origin) : "?"}→${l.destination.isNotEmpty ? _shortAirport(l.destination) : "?"}')
            .join(' · ');
        return '${legs.length} Trips: $summary';
      }
      return 'Multi-Trip Itinerary';
    }
    final from = params.origin.isNotEmpty ? params.origin : 'Origin';
    final to = params.destination.isNotEmpty ? params.destination : 'Destination';
    final arrow = params.tripType == 'roundtrip' ? '⇄' : '→';
    return '$from $arrow $to';
  }

  static String formatDates(FlightSearchParams params) {
    final dep = DateTime.tryParse(params.departureDate);
    if (dep == null) return params.departureDate;
    if (params.tripType == 'roundtrip' && params.returnDate != null && params.returnDate!.isNotEmpty) {
      final ret = DateTime.tryParse(params.returnDate!);
      if (ret != null) {
        if (dep.year == ret.year) {
          return '${DateFormat('d MMM').format(dep)} – ${DateFormat('d MMM yyyy').format(ret)}';
        }
        return '${DateFormat('d MMM yyyy').format(dep)} – ${DateFormat('d MMM yyyy').format(ret)}';
      }
    }
    return DateFormat('d MMM yyyy').format(dep);
  }

  static String formatCabinClass(String cabinClass) {
    switch (cabinClass.toLowerCase()) {
      case 'premiumeconomy':
        return 'Premium Economy';
      case 'business':
        return 'Business';
      case 'first':
        return 'First Class';
      case 'economy':
      default:
        return 'Economy';
    }
  }

  static String formatMeta(FlightSearchParams params) {
    final totalPassengers = params.adults + params.children;
    final passStr = totalPassengers == 1 ? '1 Passenger' : '$totalPassengers Passengers';
    final classStr = formatCabinClass(params.cabinClass);
    final currStr = params.currency.isNotEmpty ? params.currency : 'MYR';
    return '$passStr · $classStr · $currStr';
  }

  Widget _buildCollapsedBar(BuildContext context) {
    final routeText = formatRoute(currentParams);
    final datesText = formatDates(currentParams);
    final metaText = formatMeta(currentParams);

    return InkWell(
      key: const ValueKey('search_card_collapsed_bar'),
      onTap: onToggleExpand,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.iosBlue.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                currentParams.tripType == 'multicity'
                    ? Icons.alt_route_rounded
                    : (currentParams.tripType == 'roundtrip'
                        ? Icons.sync_alt_rounded
                        : Icons.flight_takeoff_rounded),
                size: 16,
                color: AppColors.iosBlue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    routeText,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 280) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              datesText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              metaText,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                              ),
                            ),
                          ],
                        );
                      }
                      return Text(
                        '$datesText · $metaText',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.iosGray6,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 12, color: AppColors.iosBlue),
                  const SizedBox(width: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.iosBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCard(BuildContext context) {
    return Container(
      key: const ValueKey('search_card_expanded_form'),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: AppColors.iosBlue),
              const SizedBox(width: 6),
              Text(
                'Trip Search & Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
              ),
              const Spacer(),
              if (hasResults)
                InkWell(
                  key: const ValueKey('search_card_collapse_btn'),
                  onTap: onToggleExpand,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Collapse',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 16,
                          color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FlightSearchForm(
            initialParams: currentParams,
            isLoading: isLoading,
            onSearch: onSearch,
            onCurrencyChanged: onCurrencyChanged,
            onTripTypeChanged: onTripTypeChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: _buildCollapsedBar(context),
      secondChild: _buildExpandedCard(context),
      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 240),
      firstCurve: Curves.easeInOutCubic,
      secondCurve: Curves.easeInOutCubic,
      sizeCurve: Curves.easeInOutCubic,
    );
  }
}
