import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../utils/currency_helper.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        ],
      ),
    );
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
