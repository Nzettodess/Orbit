import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Top header bar for the FlightCheckerDialog.
/// Strictly under 500 lines (Hard limit: 500 lines).
class FlightCheckerDialogHeader extends StatelessWidget {
  final bool isDark;
  final Color bgColor;
  final VoidCallback onClose;

  const FlightCheckerDialogHeader({
    super.key,
    required this.isDark,
    required this.bgColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.iosBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: AppColors.iosBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flight Price Checker',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Search real-time flight fares and schedules',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close dialog',
            onPressed: onClose,
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          ),
        ],
      ),
    );
  }
}
