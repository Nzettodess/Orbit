import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Top action and count bar for flight search results.
/// Displays total flights found, global Expand/Collapse toggle for roundtrips,
/// and external link to Google Flights. Strictly < 500 lines.
class FlightResultsHeaderBar extends StatelessWidget {
  final int totalFoundCount;
  final bool isRoundTrip;
  final bool isAllExpanded;
  final VoidCallback? onToggleAllExpanded;
  final VoidCallback onOpenGoogleFlights;
  final bool isDark;

  const FlightResultsHeaderBar({
    super.key,
    required this.totalFoundCount,
    required this.isRoundTrip,
    required this.isAllExpanded,
    this.onToggleAllExpanded,
    required this.onOpenGoogleFlights,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                'Found $totalFoundCount Flights',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (isRoundTrip) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onToggleAllExpanded,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAllExpanded
                              ? Icons.unfold_less_rounded
                              : Icons.unfold_more_rounded,
                          size: 13,
                          color: AppColors.iosBlue,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          isAllExpanded ? 'Collapse' : 'Expand',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.iosBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onOpenGoogleFlights,
          icon: const Icon(Icons.open_in_new_rounded, size: 14),
          label: const Text(
            'Open in Google Flights',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
