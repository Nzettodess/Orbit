import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'airport_autocomplete_field.dart';

/// Data holder for an editable multi-city leg in the form
class EditableTripLeg {
  final TextEditingController originController;
  final TextEditingController destController;
  DateTime date;

  EditableTripLeg({
    required String origin,
    required String destination,
    required this.date,
  })  : originController = TextEditingController(text: origin),
        destController = TextEditingController(text: destination);

  void dispose() {
    originController.dispose();
    destController.dispose();
  }
}

/// Dynamic input list for Multi-Trip itineraries (Trip 1, Trip 2, Trip 3...).
/// Allows adding/removing departing legs. Strictly < 500 lines.
class FlightMultiCityInputList extends StatelessWidget {
  final List<EditableTripLeg> legs;
  final VoidCallback onAddLeg;
  final ValueChanged<int> onRemoveLeg;
  final ValueChanged<int> onPickDate;
  final ValueChanged<int> onSwapLocations;
  final bool isDark;

  const FlightMultiCityInputList({
    super.key,
    required this.legs,
    required this.onAddLeg,
    required this.onRemoveLeg,
    required this.onPickDate,
    required this.onSwapLocations,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fieldBg = isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg;
    final borderColor = isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < legs.length; i++) ...[
          _buildLegCard(context, i, fieldBg, borderColor),
          const SizedBox(height: 10),
        ],
        if (legs.length < 6)
          OutlinedButton.icon(
            onPressed: onAddLeg,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.iosBlue,
              side: const BorderSide(color: AppColors.iosBlue, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(
              'Add Flight (Trip ${legs.length + 1})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildLegCard(BuildContext context, int index, Color fieldBg, Color borderColor) {
    final leg = legs[index];
    final dateStr = DateFormat('EEE, d MMM yyyy').format(leg.date);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fieldBg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.iosBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flight_takeoff_rounded, size: 13, color: AppColors.iosBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Trip ${index + 1}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.iosBlue),
                    ),
                  ],
                ),
              ),
              if (legs.length > 1)
                IconButton(
                  onPressed: () => onRemoveLeg(index),
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.iosRed),
                  tooltip: 'Remove Trip ${index + 1}',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AirportAutocompleteField(
            controller: leg.originController,
            label: 'From (Trip ${index + 1})',
            hint: 'Departure city or airport…',
            icon: Icons.flight_takeoff_rounded,
            bg: fieldBg,
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          Center(
            child: InkWell(
              onTap: () => onSwapLocations(index),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.iosBlue.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.iosBlue),
              ),
            ),
          ),
          const SizedBox(height: 6),
          AirportAutocompleteField(
            controller: leg.destController,
            label: 'To (Trip ${index + 1})',
            hint: 'Arrival city or airport…',
            icon: Icons.flight_land_rounded,
            bg: fieldBg,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => onPickDate(index),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.iosBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flight Date', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary)),
                        Text(dateStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, size: 18, color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
