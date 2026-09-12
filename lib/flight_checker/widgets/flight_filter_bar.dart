import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../utils/flight_filter_helper.dart';

/// Modern iOS/Vercel-inspired filter and sorting control bar
/// Strictly under 500 lines (Hard limit: 500 lines)
class FlightFilterBar extends StatelessWidget {
  final FlightFilterCriteria criteria;
  final ValueChanged<FlightFilterCriteria> onChanged;
  final List<String> availableAirlines;
  final int totalCount;
  final int visibleCount;
  final bool isDark;

  const FlightFilterBar({
    super.key,
    required this.criteria,
    required this.onChanged,
    required this.availableAirlines,
    required this.totalCount,
    required this.visibleCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chipBg = isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg;
    final borderColor = isDark
        ? AppColors.darkElevatedHighest
        : AppColors.iosGray4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Sort Popup Button + Reset Filters (if active)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PopupMenuButton<FlightSortBy>(
              initialValue: criteria.sortBy,
              tooltip: 'Sort flights',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              elevation: 4,
              onSelected: (val) {
                onChanged(criteria.copyWith(sortBy: val));
              },
              itemBuilder: (context) {
                return FlightSortBy.values.map((sort) {
                  final isSelected = sort == criteria.sortBy;
                  return PopupMenuItem<FlightSortBy>(
                    value: sort,
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: isSelected
                              ? AppColors.iosBlue
                              : (isDark
                                    ? AppColors.darkSecondary
                                    : AppColors.lightSecondary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          sort.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.iosBlue
                                : (isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.iosBlue.withValues(alpha: 0.35),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_vert_rounded,
                      size: 15,
                      color: AppColors.iosBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      criteria.sortBy.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: AppColors.iosBlue,
                    ),
                  ],
                ),
              ),
            ),
            if (criteria.isFiltered)
              TextButton.icon(
                onPressed: () {
                  onChanged(const FlightFilterCriteria());
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.clear_rounded, size: 13),
                label: const Text(
                  'Reset',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              )
            else
              Text(
                'Showing $visibleCount of $totalCount',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkSecondary
                      : AppColors.lightSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. Filter Chips: Stops & Airlines
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Stops filters
              _buildFilterChip(
                label: 'All Stops',
                isSelected: criteria.stopsFilter == FlightStopsFilter.all,
                onTap: () => onChanged(
                  criteria.copyWith(stopsFilter: FlightStopsFilter.all),
                ),
                chipBg: chipBg,
                borderColor: borderColor,
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: 'Nonstop Only',
                isSelected:
                    criteria.stopsFilter == FlightStopsFilter.nonstopOnly,
                onTap: () => onChanged(
                  criteria.copyWith(stopsFilter: FlightStopsFilter.nonstopOnly),
                ),
                chipBg: chipBg,
                borderColor: borderColor,
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: '≤ 1 Stop',
                isSelected:
                    criteria.stopsFilter == FlightStopsFilter.maxOneStop,
                onTap: () => onChanged(
                  criteria.copyWith(stopsFilter: FlightStopsFilter.maxOneStop),
                ),
                chipBg: chipBg,
                borderColor: borderColor,
              ),

              // Airline filters (only displayed when 2 or more airlines operate route)
              if (availableAirlines.length >= 2) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    height: 16,
                    width: 1,
                    color: isDark
                        ? AppColors.darkElevatedHighest
                        : AppColors.iosGray4,
                  ),
                ),
                _buildFilterChip(
                  label: 'All Airlines',
                  isSelected:
                      criteria.selectedAirline == null ||
                      criteria.selectedAirline == 'ALL',
                  onTap: () => onChanged(criteria.copyWith(clearAirline: true)),
                  chipBg: chipBg,
                  borderColor: borderColor,
                ),
                for (final airline in availableAirlines) ...[
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: airline,
                    isSelected: criteria.selectedAirline == airline,
                    onTap: () =>
                        onChanged(criteria.copyWith(selectedAirline: airline)),
                    chipBg: chipBg,
                    borderColor: borderColor,
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color chipBg,
    required Color borderColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.iosBlue : chipBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.iosBlue : borderColor,
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.darkSecondary
                        : AppColors.lightSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
