import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Top action and count bar for flight search results.
/// Displays total flights found, global Expand/Collapse toggle for roundtrips & multi-trips,
/// and external link to Google Flights. Strictly < 500 lines.
class FlightResultsHeaderBar extends StatelessWidget {
  final int totalFoundCount;
  final bool isRoundTrip;
  final bool isMultiTrip;
  final bool isAllExpanded;
  final VoidCallback? onToggleAllExpanded;
  final VoidCallback onOpenGoogleFlights;
  final bool isDark;

  const FlightResultsHeaderBar({
    super.key,
    required this.totalFoundCount,
    required this.isRoundTrip,
    this.isMultiTrip = false,
    required this.isAllExpanded,
    this.onToggleAllExpanded,
    required this.onOpenGoogleFlights,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          'Found $totalFoundCount Flights',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          ),
        ),
        TextButton.icon(
          onPressed: onOpenGoogleFlights,
          icon: const Icon(Icons.open_in_new_rounded, size: 14),
          label: const Text(
            'Open in Google Flights',
            style: TextStyle(fontSize: 12),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

/// Summary card banner displayed at the top of Multi-Trip search results,
/// summarizing total combined price across all legs and leg details.
class FlightMultiTripSummaryBanner extends StatelessWidget {
  final double totalFare;
  final String currency;
  final List<String> legSummaries;
  final bool isDark;

  const FlightMultiTripSummaryBanner({
    super.key,
    required this.totalFare,
    required this.currency,
    required this.legSummaries,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasTotal = totalFare > 0;
    final formattedTotal = hasTotal
        ? '$currency ${totalFare.toStringAsFixed(0)}'
        : 'See individual trips';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.iosBlue.withValues(alpha: 0.12)
            : AppColors.iosBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.iosBlue.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Icon(
                    Icons.connecting_airports_rounded,
                    size: 18,
                    color: isDark ? AppColors.iosBlueLight : AppColors.iosBlue,
                  ),
                  Text(
                    'Multi-Trip Itinerary',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.iosBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${legSummaries.length} ${legSummaries.length == 1 ? 'Trip' : 'Trips'}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.iosBlueLight : AppColors.iosBlue,
                      ),
                    ),
                  ),
                ],
              ),
              if (hasTotal)
                Text(
                  'Total from $formattedTotal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.iosGreen,
                  ),
                ),
            ],
          ),
          if (legSummaries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: legSummaries.map((summary) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4,
                    ),
                  ),
                  child: Text(
                    summary,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
