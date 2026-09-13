import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Segmented selector for flight trip types: One-Way, Round-Trip, Multi-Trip.
/// Strictly < 500 lines.
class FlightTripTypeSelector extends StatelessWidget {
  final String selectedTripType;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const FlightTripTypeSelector({
    super.key,
    required this.selectedTripType,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildSegment(context, 'oneway', 'One-Way'),
          _buildSegment(context, 'roundtrip', 'Round-Trip'),
          _buildSegment(context, 'multicity', 'Multi-Trip'),
        ],
      ),
    );
  }

  Widget _buildSegment(BuildContext context, String key, String title) {
    final isSelected = selectedTripType == key;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.iosBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
