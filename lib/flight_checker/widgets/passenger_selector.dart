import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Compact display tile for current passenger count
class PassengerTile extends StatelessWidget {
  final int adults;
  final int children;
  final bool isExpanded;
  final VoidCallback onTap;
  final Color bg;
  final bool isDark;

  const PassengerTile({
    super.key,
    required this.adults,
    required this.children,
    required this.isExpanded,
    required this.onTap,
    required this.bg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final safeAdults = adults.clamp(1, 9);
    final safeChildren = children.clamp(0, 8);
    final summary = '$safeAdults adult${safeAdults > 1 ? 's' : ''}'
        '${safeChildren > 0 ? ', $safeChildren child${safeChildren > 1 ? 'ren' : ''}' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passengers',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: isExpanded
                  ? Border.all(color: AppColors.iosBlue.withValues(alpha: 0.6), width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded, size: 16, color: AppColors.iosBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Reactive passenger adjustment panel with strict limits:
/// - Adults: 1 to 9 (cannot be 0 or negative)
/// - Children: 0 to 8 (cannot be negative)
/// - Total passengers: 1 to 9
class PassengerControlPanel extends StatelessWidget {
  final int adults;
  final int children;
  final void Function(int adults, int children) onChanged;
  final VoidCallback onDone;
  final bool isDark;

  const PassengerControlPanel({
    super.key,
    required this.adults,
    required this.children,
    required this.onChanged,
    required this.onDone,
    required this.isDark,
  });

  void _updateAdults(int delta) {
    final currentAdults = adults.clamp(1, 9);
    final currentChildren = children.clamp(0, 8);
    final newAdults = (currentAdults + delta).clamp(1, 9);

    if (newAdults + currentChildren <= 9 && newAdults >= 1) {
      onChanged(newAdults, currentChildren);
    }
  }

  void _updateChildren(int delta) {
    final currentAdults = adults.clamp(1, 9);
    final currentChildren = children.clamp(0, 8);
    final newChildren = (currentChildren + delta).clamp(0, 8);

    if (currentAdults + newChildren <= 9 && newChildren >= 0) {
      onChanged(currentAdults, newChildren);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeAdults = adults.clamp(1, 9);
    final safeChildren = children.clamp(0, 8);
    final total = safeAdults + safeChildren;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Adults row (minimum 1, max 9)
          _buildRow(
            title: 'Adults',
            subtitle: 'Age 12+',
            count: safeAdults,
            canDecrement: safeAdults > 1,
            canIncrement: total < 9,
            onDecrement: () => _updateAdults(-1),
            onIncrement: () => _updateAdults(1),
            isDark: isDark,
          ),
          Divider(
            height: 18,
            color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5,
          ),
          // Children row (minimum 0, max 8)
          _buildRow(
            title: 'Children',
            subtitle: 'Age 2–11',
            count: safeChildren,
            canDecrement: safeChildren > 0,
            canIncrement: total < 9,
            onDecrement: () => _updateChildren(-1),
            onIncrement: () => _updateChildren(1),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Max 9 passengers per search',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                ),
              ),
              TextButton(
                onPressed: onDone,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  foregroundColor: AppColors.iosBlue,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String title,
    required String subtitle,
    required int count,
    required bool canDecrement,
    required bool canIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBtn(
              icon: Icons.remove_rounded,
              enabled: canDecrement,
              tooltip: 'Decrease $title',
              onTap: onDecrement,
              isDark: isDark,
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            _buildBtn(
              icon: Icons.add_rounded,
              enabled: canIncrement,
              tooltip: 'Increase $title',
              onTap: onIncrement,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBtn({
    required IconData icon,
    required bool enabled,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final btnBg = isDark ? AppColors.darkElevatedHighest : AppColors.iosGray6;
    final iconColor = enabled
        ? (isDark ? Colors.white : AppColors.lightPrimary)
        : (isDark ? AppColors.darkTertiary : AppColors.lightTertiary);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: enabled ? btnBg : btnBg.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4,
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
