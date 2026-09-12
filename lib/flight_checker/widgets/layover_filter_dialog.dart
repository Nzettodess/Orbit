import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Modal dialog for filtering flights by layover duration
/// Mimics Google Flights' "Connecting airports -> Layover duration" filter
/// Strictly under 500 lines (Hard limit: 500 lines)
class LayoverFilterDialog extends StatefulWidget {
  final int? initialMaxMinutes;
  final bool isDark;

  const LayoverFilterDialog({
    super.key,
    required this.initialMaxMinutes,
    required this.isDark,
  });

  @override
  State<LayoverFilterDialog> createState() => _LayoverFilterDialogState();
}

class _LayoverFilterDialogState extends State<LayoverFilterDialog> {
  late int? _maxMinutes;

  static const List<int> _presets = [120, 240, 360, 480];

  @override
  void initState() {
    super.initState();
    _maxMinutes = widget.initialMaxMinutes;
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h hr';
    return '$h hr $m min';
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final chipBg = widget.isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg;
    final borderColor = widget.isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_bottom_rounded, size: 20, color: AppColors.iosBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Layover Duration',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: widget.isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Show flights where each layover is within this limit. Nonstop flights are always included.',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),

              // Current Selection Display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.darkElevated : AppColors.iosGray6,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _maxMinutes != null
                        ? AppColors.iosBlue.withValues(alpha: 0.5)
                        : borderColor,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Max layover:',
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                      ),
                    ),
                    Text(
                      _maxMinutes != null ? '< ${_formatDuration(_maxMinutes!)}' : 'Any layover',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _maxMinutes != null
                            ? AppColors.iosBlue
                            : (widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Quick Presets
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetChip(
                    label: 'Any',
                    isSelected: _maxMinutes == null,
                    onTap: () => setState(() => _maxMinutes = null),
                    chipBg: chipBg,
                    borderColor: borderColor,
                  ),
                  for (final p in _presets)
                    _buildPresetChip(
                      label: '< ${_formatDuration(p)}',
                      isSelected: _maxMinutes == p,
                      onTap: () => setState(() => _maxMinutes = p),
                      chipBg: chipBg,
                      borderColor: borderColor,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Fine-tuning Slider (1 hr to 12 hrs, or Any above 12 hrs)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.iosBlue,
                  thumbColor: AppColors.iosBlue,
                  overlayColor: AppColors.iosBlue.withValues(alpha: 0.15),
                  inactiveTrackColor: borderColor,
                  trackHeight: 3,
                ),
                child: Slider(
                  min: 60,
                  max: 750,
                  divisions: 23, // 30-min steps from 60 to 750
                  value: (_maxMinutes ?? 750).toDouble().clamp(60, 750),
                  onChanged: (val) {
                    setState(() {
                      if (val >= 750) {
                        _maxMinutes = null;
                      } else {
                        _maxMinutes = val.round();
                      }
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 hr', style: TextStyle(fontSize: 11, color: widget.isDark ? AppColors.darkTertiary : AppColors.lightTertiary)),
                    Text('6 hr', style: TextStyle(fontSize: 11, color: widget.isDark ? AppColors.darkTertiary : AppColors.lightTertiary)),
                    Text('Any', style: TextStyle(fontSize: 11, color: widget.isDark ? AppColors.darkTertiary : AppColors.lightTertiary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons: Reset & Apply
              Row(
                children: [
                  if (_maxMinutes != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _maxMinutes = null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.iosBlue,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (_maxMinutes != null) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_maxMinutes),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.iosBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Apply Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color chipBg,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.iosBlue : chipBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.iosBlue : borderColor,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
          ),
        ),
      ),
    );
  }
}
