import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../models/flight_info.dart';
import '../utils/currency_helper.dart';

/// Modular segmented tab bar for switching between Departing and Returning flight legs.
/// Includes combined round-trip pricing estimate summary card.
/// Strictly under 500 lines (Hard limit: 500 lines).
class FlightLegTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<FlightInfo> outboundFlights;
  final List<FlightInfo> returnFlights;
  final String origin;
  final String destination;
  final String departureDate;
  final String returnDate;
  final String currency;
  final bool isDark;

  const FlightLegTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.outboundFlights,
    required this.returnFlights,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.returnDate,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final lowestOutbound = _findLowestPrice(outboundFlights);
    final lowestReturn = _findLowestPrice(returnFlights);
    final combinedTotal = (lowestOutbound != null && lowestReturn != null)
        ? lowestOutbound + lowestReturn
        : null;

    final bgCard = isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg;
    final borderColor = isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Combined Trip Price Banner (if both legs available)
        if (combinedTotal != null && combinedTotal > 0) ...[
          FlightRoundTripSummaryBanner(
            combinedTotal: combinedTotal,
            lowestOutbound: lowestOutbound!,
            lowestReturn: lowestReturn!,
            currency: currency,
            isDark: isDark,
          ),
        ],

        // 2. iOS Segmented Leg Selection Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabItem(
                  index: 0,
                  title: 'Departing',
                  subtitle: '$origin → $destination',
                  date: departureDate,
                  count: outboundFlights.length,
                  lowestPrice: lowestOutbound,
                  icon: Icons.flight_takeoff_rounded,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildTabItem(
                  index: 1,
                  title: 'Returning',
                  subtitle: '$destination → $origin',
                  date: returnDate,
                  count: returnFlights.length,
                  lowestPrice: lowestReturn,
                  icon: Icons.flight_land_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabItem({
    required int index,
    required String title,
    required String subtitle,
    required String date,
    required int count,
    required int? lowestPrice,
    required IconData icon,
  }) {
    final isSelected = selectedIndex == index;
    final activeBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final activeColor = AppColors.iosBlue;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title flight leg. $subtitle, $count flights found.',
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: isSelected
                ? Border.all(color: activeColor.withValues(alpha: 0.35), width: 1.2)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected
                        ? activeColor
                        : (isDark ? AppColors.darkTertiary : AppColors.lightTertiary),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                          : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? activeColor
                            : (isDark ? AppColors.darkTertiary : AppColors.lightTertiary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (lowestPrice != null && lowestPrice > 0)
                    Text(
                      CurrencyHelper.formatAmount(lowestPrice, currency),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.iosGreen
                            : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _findLowestPrice(List<FlightInfo> flights) {
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
}

/// Standalone combined round-trip price banner widget.
class FlightRoundTripSummaryBanner extends StatelessWidget {
  final int combinedTotal;
  final int lowestOutbound;
  final int lowestReturn;
  final String currency;
  final bool isDark;

  const FlightRoundTripSummaryBanner({
    super.key,
    required this.combinedTotal,
    required this.lowestOutbound,
    required this.lowestReturn,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.iosBlue.withValues(alpha: 0.12)
            : AppColors.iosBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.iosBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.iosBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sync_alt_rounded,
              size: 16,
              color: AppColors.iosBlue,
            ),
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
                      'Estimated Round-Trip Total: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSecondary
                            : AppColors.lightSecondary,
                      ),
                    ),
                    Text(
                      CurrencyHelper.formatAmount(combinedTotal, currency),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.iosBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Outbound from ${CurrencyHelper.formatAmount(lowestOutbound, currency)} + Return from ${CurrencyHelper.formatAmount(lowestReturn, currency)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTertiary
                        : AppColors.lightTertiary,
                  ),
                  maxLines: 1,
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

