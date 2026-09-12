import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../utils/flight_filter_helper.dart';
import 'airline_filter_dialog.dart';
import 'layover_filter_dialog.dart';

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
    final borderColor = isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Dropdowns: Sort By + Airline Dropdown (if >= 2) + Layover + Reset Action
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildSortDropdown(chipBg),
            if (availableAirlines.length >= 2)
              _buildAirlineDropdown(context, chipBg, borderColor),
            _buildLayoverDropdown(context, chipBg, borderColor),
            if (criteria.isFiltered)
              TextButton.icon(
                onPressed: () => onChanged(const FlightFilterCriteria()),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.iosBlue,
                ),
                icon: const Icon(Icons.clear_rounded, size: 13),
                label: const Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. Stops Segments + Showing X of Y count
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterChip(
                    label: 'All Stops',
                    isSelected: criteria.stopsFilter == FlightStopsFilter.all,
                    onTap: () => onChanged(criteria.copyWith(stopsFilter: FlightStopsFilter.all)),
                    chipBg: chipBg,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Nonstop Only',
                    isSelected: criteria.stopsFilter == FlightStopsFilter.nonstopOnly,
                    onTap: () => onChanged(criteria.copyWith(stopsFilter: FlightStopsFilter.nonstopOnly)),
                    chipBg: chipBg,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: '≤ 1 Stop',
                    isSelected: criteria.stopsFilter == FlightStopsFilter.maxOneStop,
                    onTap: () => onChanged(criteria.copyWith(stopsFilter: FlightStopsFilter.maxOneStop)),
                    chipBg: chipBg,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),
            Text(
              'Showing $visibleCount of $totalCount',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
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
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected ? AppColors.iosBlue : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
                ),
                const SizedBox(width: 10),
                Text(
                  sort.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.iosBlue : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
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
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.iosBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildAirlineDropdown(BuildContext context, Color chipBg, Color borderColor) {
    final count = criteria.selectedAirlines.length;
    final hasSelectedAirlines = count > 0;

    final String label;
    if (count == 0) {
      label = 'Airlines: All';
    } else if (count == 1) {
      label = criteria.selectedAirlines.first;
    } else {
      label = '$count Airlines';
    }

    final activeBg = hasSelectedAirlines ? AppColors.iosBlue.withValues(alpha: 0.12) : chipBg;
    final activeBorder = hasSelectedAirlines ? AppColors.iosBlue : AppColors.iosBlue.withValues(alpha: 0.35);

    return Container(
      decoration: BoxDecoration(
        color: activeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: activeBorder, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final result = await showDialog<Set<String>>(
                context: context,
                builder: (ctx) => AirlineFilterDialog(
                  availableAirlines: availableAirlines,
                  airlineCounts: airlineCounts,
                  initialSelectedAirlines: criteria.selectedAirlines,
                  totalCount: totalCount,
                  isDark: isDark,
                ),
              );
              if (result != null) {
                onChanged(criteria.copyWith(selectedAirlines: result));
              }
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: 10,
                right: hasSelectedAirlines ? 4 : 8,
                top: 6,
                bottom: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flight_rounded, size: 14, color: AppColors.iosBlue),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasSelectedAirlines ? AppColors.iosBlue : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.iosBlue),
                ],
              ),
            ),
          ),
          if (hasSelectedAirlines)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(criteria.copyWith(clearAirlines: true)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 8, 6),
                child: Icon(Icons.cancel_rounded, size: 15, color: AppColors.iosBlue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLayoverDropdown(BuildContext context, Color chipBg, Color borderColor) {
    final hasLayoverFilter = criteria.maxLayoverMinutes != null;

    final String label;
    if (hasLayoverFilter) {
      final m = criteria.maxLayoverMinutes!;
      final h = m ~/ 60;
      final min = m % 60;
      label = min == 0 ? 'Layover: < ${h}h' : 'Layover: < ${h}h${min}m';
    } else {
      label = 'Layover';
    }

    final activeBg = hasLayoverFilter ? AppColors.iosBlue.withValues(alpha: 0.12) : chipBg;
    final activeBorder = hasLayoverFilter ? AppColors.iosBlue : AppColors.iosBlue.withValues(alpha: 0.35);

    return Container(
      decoration: BoxDecoration(
        color: activeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: activeBorder, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final result = await showDialog<int?>(
                context: context,
                builder: (ctx) => LayoverFilterDialog(
                  initialMaxMinutes: criteria.maxLayoverMinutes,
                  isDark: isDark,
                ),
              );
              if (result != criteria.maxLayoverMinutes) {
                onChanged(criteria.copyWith(
                  maxLayoverMinutes: result,
                  clearMaxLayover: result == null,
                ));
              }
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: 10,
                right: hasLayoverFilter ? 4 : 8,
                top: 6,
                bottom: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_bottom_rounded, size: 14, color: AppColors.iosBlue),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasLayoverFilter ? AppColors.iosBlue : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.iosBlue),
                ],
              ),
            ),
          ),
          if (hasLayoverFilter)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(criteria.copyWith(clearMaxLayover: true)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 8, 6),
                child: Icon(Icons.cancel_rounded, size: 15, color: AppColors.iosBlue),
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
              color: isSelected ? Colors.white : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
