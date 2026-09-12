import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../utils/airport_data.dart';

/// Autocomplete input for airport / city selection
class AirportAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color bg;
  final bool isDark;

  const AirportAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.bg,
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
        Autocomplete<AirportOption>(
          initialValue: TextEditingValue(text: controller.text),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<AirportOption>.empty();
            }
            return AirportHelper.searchAirports(textEditingValue.text);
          },
          displayStringForOption: (AirportOption option) => option.shortLabel,
          onSelected: (AirportOption selection) {
            controller.text = selection.shortLabel;
          },
          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
            // Keep external controller and internal autocomplete controller in sync
            controller.addListener(() {
              if (textController.text != controller.text) {
                textController.text = controller.text;
              }
            });
            textController.addListener(() {
              controller.text = textController.text;
            });

            return TextField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkPlaceholder : AppColors.lightPlaceholder,
                ),
                prefixIcon: Icon(icon, size: 18, color: AppColors.iosBlue),
                filled: true,
                fillColor: bg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: isDark ? AppColors.darkElevated : AppColors.lightSurface,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, maxWidth: 320),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5,
                    ),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Icon(Icons.flight_rounded, size: 16, color: AppColors.iosBlue),
                        title: Text(
                          option.shortLabel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${option.name}, ${option.country}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
