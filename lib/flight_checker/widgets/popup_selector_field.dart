import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable popup menu field styled to match iOS/Vercel design system.
/// Avoids Flutter Web DropdownButton overlay persistence and clipping escape bugs.
/// Strictly under 500 lines (Hard limit: 500 lines)
class PopupSelectorField extends StatelessWidget {
  final String label;
  final String value;
  final String displayLabel;
  final List<Map<String, String>> items;
  final ValueChanged<String> onSelected;
  final Color bg;
  final bool isDark;
  final String? tooltip;

  const PopupSelectorField({
    super.key,
    required this.label,
    required this.value,
    required this.displayLabel,
    required this.items,
    required this.onSelected,
    required this.bg,
    required this.isDark,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          ),
        ),
        const SizedBox(height: 4),
        PopupMenuButton<String>(
          initialValue: value,
          tooltip: tooltip ?? 'Select $label',
          onSelected: onSelected,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isDark ? AppColors.darkElevated : AppColors.lightSurface,
          itemBuilder: (context) => items.map((item) {
            final isSelected = item['value'] == value;
            return PopupMenuItem<String>(
              value: item['value']!,
              height: 38,
              child: Row(
                children: [
                  Text(
                    item['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppColors.iosBlue
                          : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, size: 16, color: AppColors.iosBlue),
                  ],
                ],
              ),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
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
