import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../utils/currency_helper.dart';

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
                    const Icon(Icons.check_rounded, size: 16, color: AppColors.iosBlue),
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

/// Date tile picker field
class FlightDateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final Color fieldBg;
  final bool isDark;

  const FlightDateTile({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
    required this.fieldBg,
    required this.isDark,
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.iosBlue),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Class selection dropdown
class FlightClassDropdown extends StatelessWidget {
  final String cabinClass;
  final ValueChanged<String> onSelected;
  final Color bg;
  final bool isDark;

  const FlightClassDropdown({
    super.key,
    required this.cabinClass,
    required this.onSelected,
    required this.bg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      {'value': 'economy', 'label': 'Economy'},
      {'value': 'premiumeconomy', 'label': 'Premium'},
      {'value': 'business', 'label': 'Business'},
      {'value': 'first', 'label': 'First'},
    ];
    final display = items.firstWhere((i) => i['value'] == cabinClass, orElse: () => items.first)['label']!;
    return PopupSelectorField(
      label: 'Class',
      value: cabinClass,
      displayLabel: display,
      items: items,
      onSelected: onSelected,
      bg: bg,
      isDark: isDark,
    );
  }
}

/// Currency selection dropdown
class FlightCurrencyDropdown extends StatelessWidget {
  final String currency;
  final ValueChanged<String> onSelected;
  final Color bg;
  final bool isDark;

  const FlightCurrencyDropdown({
    super.key,
    required this.currency,
    required this.onSelected,
    required this.bg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final items = CurrencyHelper.supportedCurrencies
        .map((c) => {'value': c['code']!, 'label': c['label']!})
        .toList();
    return PopupSelectorField(
      label: 'Currency',
      value: currency,
      displayLabel: CurrencyHelper.getLabel(currency),
      items: items,
      onSelected: onSelected,
      bg: bg,
      isDark: isDark,
    );
  }
}
