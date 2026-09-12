import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Loading indicator state view for flight search
/// Strictly under 500 lines (Hard limit: 500 lines)
class FlightCheckerLoadingView extends StatelessWidget {
  final bool isDark;

  const FlightCheckerLoadingView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.iosBlue),
        const SizedBox(height: 14),
        Text(
          'Searching live flight prices…',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Checking airlines and fares',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Fallback or error card with actionable retry and Google Flights external link
class FlightCheckerFallbackView extends StatelessWidget {
  final bool isDark;
  final String fallbackUrl;
  final String? title;
  final String? message;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenFallback;

  const FlightCheckerFallbackView({
    super.key,
    required this.isDark,
    required this.fallbackUrl,
    required this.onRetry,
    required this.onOpenFallback,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            Icons.airplane_ticket_outlined,
            size: 36,
            color: AppColors.iosBlue,
          ),
          const SizedBox(height: 10),
          Text(
            title ?? 'Live Preview Unavailable',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            message ??
                'We couldn’t fetch real-time previews for this route, but you can view full live fares directly on Google Flights.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkSecondary
                  : AppColors.lightSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.iosBlue,
                  side: BorderSide(color: AppColors.iosBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => onOpenFallback(fallbackUrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.iosBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text(
                  'View on Google Flights ↗',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Empty state when no flights match user-applied filters
class FlightCheckerEmptyFilterView extends StatelessWidget {
  final bool isDark;
  final VoidCallback onReset;

  const FlightCheckerEmptyFilterView({
    super.key,
    required this.isDark,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.filter_alt_off_rounded,
            size: 36,
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            'No flights match the active filters',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try selecting another airline or removing the stops filter',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark
                  ? AppColors.darkSecondary
                  : AppColors.lightSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Reset Filters', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
