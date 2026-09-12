import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../models/flight_info.dart';
import '../utils/currency_helper.dart';
import 'flight_card.dart';

/// Distinct section header for flight legs (Departing vs. Returning).
/// Strictly under 500 lines (Hard limit: 500 lines).
class FlightLegSectionHeader extends StatelessWidget {
  final String title;
  final String routeSubtitle;
  final String date;
  final int count;
  final int? lowestPrice;
  final String currency;
  final IconData icon;
  final Color accentColor;
  final bool isDark;
  final bool isCollapsible;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const FlightLegSectionHeader({
    super.key,
    required this.title,
    required this.routeSubtitle,
    required this.date,
    required this.count,
    this.lowestPrice,
    required this.currency,
    required this.icon,
    this.accentColor = AppColors.iosBlue,
    required this.isDark,
    this.isCollapsible = false,
    this.isExpanded = true,
    this.onToggleExpand,
  });

  static int? findLowestPrice(List<FlightInfo> flights) {
    int? minPrice;
    for (final f in flights) {
      if (f.priceNumeric > 0) {
        if (minPrice == null || f.priceNumeric < minPrice) {
          minPrice = f.priceNumeric;
        }
      }
    }
    return minPrice;
  }

  @override
  Widget build(BuildContext context) {
    final headerContent = Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count option${count == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$routeSubtitle · $date',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (lowestPrice != null && lowestPrice! > 0) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'from',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                  ),
                ),
                Text(
                  CurrencyHelper.formatAmount(lowestPrice!, currency),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.iosGreen,
                  ),
                ),
              ],
            ),
          ],
          if (isCollapsible) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5,
                borderRadius: BorderRadius.circular(6),
              ),
              child: AnimatedRotation(
                turns: isExpanded ? 0.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (isCollapsible && onToggleExpand != null) {
      return InkWell(
        onTap: onToggleExpand,
        borderRadius: BorderRadius.circular(10),
        child: headerContent,
      );
    }

    return headerContent;
  }
}

/// Stylish divider separating Departing and Returning flight legs.
class FlightLegSeparator extends StatelessWidget {
  final String label;
  final bool isDark;

  const FlightLegSeparator({
    super.key,
    this.label = 'RETURN JOURNEY',
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: dividerColor)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevated : AppColors.iosGray6,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dividerColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync_alt_rounded, size: 12, color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Container(height: 1, color: dividerColor)),
        ],
      ),
    );
  }
}

/// Price range insight card for one-way flight search results.
class FlightPriceRangeInsight extends StatelessWidget {
  final PriceRange priceRange;
  final bool isDark;

  const FlightPriceRangeInsight({
    super.key,
    required this.priceRange,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.iosBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, size: 18, color: AppColors.iosBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Range: ${priceRange.minFormatted} – ${priceRange.maxFormatted}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lowest fare from ${priceRange.bestAirline} · Typical: ~${priceRange.avgFormatted}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty leg filter notice when filter criteria hides all flights for one leg.
class FlightEmptyLegNotice extends StatelessWidget {
  final String legName;
  final bool isDark;

  const FlightEmptyLegNotice({
    super.key,
    required this.legName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        'No $legName flights match the active filter criteria.',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
        ),
      ),
    );
  }
}

/// Renders a list of FlightCards for a specific flight leg.
class FlightLegCardsList extends StatelessWidget {
  final List<FlightInfo> flights;
  final int? lowestPrice;
  final FlightInfo? bestFlight;
  final String legPrefix;

  const FlightLegCardsList({
    super.key,
    required this.flights,
    required this.lowestPrice,
    required this.bestFlight,
    required this.legPrefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: flights.map((flight) {
        final isLowest = lowestPrice != null && flight.priceNumeric == lowestPrice;
        final isBest = bestFlight != null &&
            flight.airline == bestFlight!.airline &&
            flight.priceNumeric == bestFlight!.priceNumeric &&
            flight.departure.time == bestFlight!.departure.time;
        final keyId = 'flight_${legPrefix}_${flight.airline}_${flight.departure.time}_${flight.priceNumeric}';
        return FlightCard(
          key: ValueKey(keyId),
          flight: flight,
          isLowestFare: isLowest,
          isBest: isBest,
        );
      }).toList(),
    );
  }
}

/// Composite expandable/collapsible flight leg section with smooth transition.
class FlightLegSection extends StatelessWidget {
  final String title;
  final String routeSubtitle;
  final String date;
  final int count;
  final int? lowestPrice;
  final String currency;
  final IconData icon;
  final Color accentColor;
  final bool isDark;
  final bool isCollapsible;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final List<FlightInfo> flights;
  final FlightInfo? bestFlight;
  final String legPrefix;
  final String legName;

  const FlightLegSection({
    super.key,
    required this.title,
    required this.routeSubtitle,
    required this.date,
    required this.count,
    this.lowestPrice,
    required this.currency,
    required this.icon,
    this.accentColor = AppColors.iosBlue,
    required this.isDark,
    this.isCollapsible = false,
    this.isExpanded = true,
    this.onToggleExpand,
    required this.flights,
    this.bestFlight,
    required this.legPrefix,
    required this.legName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FlightLegSectionHeader(
          title: title,
          routeSubtitle: routeSubtitle,
          date: date,
          count: count,
          lowestPrice: lowestPrice,
          currency: currency,
          icon: icon,
          accentColor: accentColor,
          isDark: isDark,
          isCollapsible: isCollapsible,
          isExpanded: isExpanded,
          onToggleExpand: onToggleExpand,
        ),
        const SizedBox(height: 6),
        if (isCollapsible)
          AnimatedCrossFade(
            firstChild: flights.isEmpty
                ? FlightEmptyLegNotice(legName: legName, isDark: isDark)
                : FlightLegCardsList(
                    flights: flights,
                    lowestPrice: lowestPrice,
                    bestFlight: bestFlight,
                    legPrefix: legPrefix,
                  ),
            secondChild: const SizedBox(width: double.infinity, height: 0),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOutQuad,
            secondCurve: Curves.easeInQuad,
            sizeCurve: Curves.fastOutSlowIn,
          )
        else
          flights.isEmpty
              ? FlightEmptyLegNotice(legName: legName, isDark: isDark)
              : FlightLegCardsList(
                  flights: flights,
                  lowestPrice: lowestPrice,
                  bestFlight: bestFlight,
                  legPrefix: legPrefix,
                ),
      ],
    );
  }
}
