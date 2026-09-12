import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../utils/flight_filter_helper.dart';

/// Modern iOS/Vercel-inspired filter and sorting control bar
/// Strictly under 500 lines (Hard limit: 500 lines)
class FlightFilterBar extends StatelessWidget {
  final FlightFilterCriteria criteria;
  final ValueChanged<FlightFilterCriteria> onChanged;
  final List<String> availableAirlines;
  final Map<String, int>? airlineCounts;
  final int totalCount;
  final int visibleCount;
  final bool isDark;

  const FlightFilterBar({
    super.key,
    required this.criteria,
    required this.onChanged,
    required this.availableAirlines,
    this.airlineCounts,
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
        // 1. Dropdowns Row: Sort By + Airline Dropdown (if >= 2) + Reset Action
        Row(
          children: [
            _buildSortDropdown(chipBg),
            if (availableAirlines.length >= 2) ...[
              const SizedBox(width: 8),
              _buildAirlineDropdown(chipBg, borderColor),
            ],
            const Spacer(),
            if (criteria.isFiltered)
              TextButton.icon(
                onPressed: () => onChanged(const FlightFilterCriteria()),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.iosBlue,
                ),
                icon: const Icon(Icons.clear_rounded, size: 13),
                label: const Text(
                  'Reset',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. Stops Segments + Showing X of Y count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
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
                    criteria.copyWith(
                      stopsFilter: FlightStopsFilter.nonstopOnly,
                    ),
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
                    criteria.copyWith(
                      stopsFilter: FlightStopsFilter.maxOneStop,
                    ),
                  ),
                  chipBg: chipBg,
                  borderColor: borderColor,
                ),
              ],
            ),
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
      ],
    );
  }

  Widget _buildSortDropdown(Color chipBg) {
    return PopupMenuButton<FlightSortBy>(
      initialValue: criteria.sortBy,
      tooltip: 'Sort flights',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            Icon(Icons.swap_vert_rounded, size: 15, color: AppColors.iosBlue),
            const SizedBox(width: 6),
            Text(
              criteria.sortBy.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
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
    );
  }

  Widget _buildAirlineDropdown(Color chipBg, Color borderColor) {
    final hasSelectedAirline =
        criteria.selectedAirline != null &&
        criteria.selectedAirline!.isNotEmpty &&
        criteria.selectedAirline != 'ALL';

    final activeBg = hasSelectedAirline
        ? AppColors.iosBlue.withValues(alpha: 0.12)
        : chipBg;
    final activeBorder = hasSelectedAirline
        ? AppColors.iosBlue
        : AppColors.iosBlue.withValues(alpha: 0.35);

    return Container(
      decoration: BoxDecoration(
        color: activeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: activeBorder, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            tooltip: 'Filter by airline',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            elevation: 4,
            constraints: const BoxConstraints(maxHeight: 320, minWidth: 220),
            onSelected: (val) {
              if (val.isEmpty || val == 'ALL') {
                onChanged(criteria.copyWith(clearAirline: true));
              } else {
                onChanged(criteria.copyWith(selectedAirline: val));
              }
            },
            itemBuilder: (context) {
              final isAllSelected = !hasSelectedAirline;
              return [
                PopupMenuItem<String>(
                  value: '',
                  child: Row(
                    children: [
                      Icon(
                        isAllSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: isAllSelected
                            ? AppColors.iosBlue
                            : (isDark
                                  ? AppColors.darkSecondary
                                  : AppColors.lightSecondary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'All Airlines',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isAllSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isAllSelected
                                ? AppColors.iosBlue
                                : (isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary),
                          ),
                        ),
                      ),
                      Text(
                        '($totalCount)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkSecondary
                              : AppColors.lightSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ...availableAirlines.map((airline) {
                  final isSelected = criteria.selectedAirline == airline;
                  final count = airlineCounts?[airline];
                  return PopupMenuItem<String>(
                    value: airline,
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
                        Expanded(
                          child: Text(
                            airline,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (count != null)
                          Text(
                            '($count)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkSecondary
                                  : AppColors.lightSecondary,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ];
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: 10,
                right: hasSelectedAirline ? 4 : 8,
                top: 6,
                bottom: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flight_rounded,
                    size: 14,
                    color: AppColors.iosBlue,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(
                      hasSelectedAirline
                          ? criteria.selectedAirline!
                          : 'Airlines: All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasSelectedAirline
                            ? AppColors.iosBlue
                            : (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          if (hasSelectedAirline)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(criteria.copyWith(clearAirline: true)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 8, 6),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 15,
                  color: AppColors.iosBlue,
                ),
              ),
            ),
        ],
      ),
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
