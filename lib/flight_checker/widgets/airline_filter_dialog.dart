import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Modal dialog for multi-selecting airlines to filter flight results
/// Strictly under 500 lines (Hard limit: 500 lines)
class AirlineFilterDialog extends StatefulWidget {
  final List<String> availableAirlines;
  final Map<String, int>? airlineCounts;
  final Set<String> initialSelectedAirlines;
  final int totalCount;
  final bool isDark;

  const AirlineFilterDialog({
    super.key,
    required this.availableAirlines,
    this.airlineCounts,
    required this.initialSelectedAirlines,
    required this.totalCount,
    required this.isDark,
  });

  @override
  State<AirlineFilterDialog> createState() => _AirlineFilterDialogState();
}

class _AirlineFilterDialogState extends State<AirlineFilterDialog> {
  late Set<String> _selectedAirlines;

  @override
  void initState() {
    super.initState();
    _selectedAirlines = Set<String>.from(widget.initialSelectedAirlines);
  }

  void _toggleAirline(String airline) {
    setState(() {
      if (_selectedAirlines.contains(airline)) {
        _selectedAirlines.remove(airline);
      } else {
        _selectedAirlines.add(airline);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedAirlines.length == widget.availableAirlines.length) {
        _selectedAirlines.clear();
      } else {
        _selectedAirlines = Set<String>.from(widget.availableAirlines);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedAirlines.clear();
    });
  }

  int _calculateSelectedFlightCount() {
    if (_selectedAirlines.isEmpty || _selectedAirlines.length == widget.availableAirlines.length) {
      return widget.totalCount;
    }
    int total = 0;
    for (final a in _selectedAirlines) {
      total += widget.airlineCounts?[a] ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final secondaryTextColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final dividerColor = isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4;

    final allSelected = _selectedAirlines.length == widget.availableAirlines.length;
    final selectedCount = _calculateSelectedFlightCount();

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
              child: Row(
                children: [
                  Icon(Icons.flight_takeoff_rounded, size: 20, color: AppColors.iosBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Filter Airlines',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selectAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      allSelected ? 'Deselect All' : 'Select All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.iosBlue),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: dividerColor),

            // 2. Checkbox List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: widget.availableAirlines.length,
                itemBuilder: (context, index) {
                  final airline = widget.availableAirlines[index];
                  final isChecked = _selectedAirlines.contains(airline);
                  final count = widget.airlineCounts?[airline];

                  return InkWell(
                    onTap: () => _toggleAirline(airline),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            onChanged: (_) => _toggleAirline(airline),
                            activeColor: AppColors.iosBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              airline,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                                color: isChecked ? AppColors.iosBlue : textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (count != null)
                            Text(
                              '$count flight${count > 1 ? 's' : ''}',
                              style: TextStyle(fontSize: 11.5, color: secondaryTextColor),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1, color: dividerColor),

            // 3. Footer actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _selectedAirlines.isNotEmpty ? _clearAll : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _selectedAirlines.isNotEmpty
                            ? AppColors.iosRed
                            : secondaryTextColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      // If all are selected, treat as no filter (empty set)
                      final result = allSelected ? <String>{} : _selectedAirlines;
                      Navigator.pop(context, result);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.iosBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      _selectedAirlines.isEmpty || allSelected
                          ? 'Show All (${widget.totalCount})'
                          : 'Apply ($selectedCount)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
}
