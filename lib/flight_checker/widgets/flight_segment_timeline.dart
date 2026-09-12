import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../models/flight_info.dart';

/// Segment-by-segment vertical timeline displaying flights, layovers, aircraft, and legroom.
/// Strictly under 500 lines (Hard limit: 500 lines)
class FlightSegmentTimeline extends StatelessWidget {
  final List<FlightSegment> segments;
  final List<FlightLayover> layovers;
  final bool isDark;

  const FlightSegmentTimeline({
    super.key,
    required this.segments,
    required this.layovers,
    required this.isDark,
  });

  /// Ensures any legroom string has clear, unambiguous units for users
  static String formatLegroomLabel(String raw) {
    if (raw.trim().isEmpty) return '';
    var s = raw.trim();

    // If already contains "in", "inches", or "cm"
    if (RegExp(r'in(ch(es)?)?|cm', caseSensitive: false).hasMatch(s)) {
      if (!s.toLowerCase().contains('legroom')) {
        return '$s legroom';
      }
      return s;
    }

    // Bare numbers like "18 23" or "28"
    final matches = RegExp(r'\d+(?:\.\d+)?').allMatches(s).map((m) => m.group(0)!).toList();
    if (matches.length == 1) {
      final n = double.tryParse(matches[0]) ?? 0;
      return n > 50 ? '${matches[0]} cm legroom' : '${matches[0]} in legroom';
    } else if (matches.length >= 2) {
      final n1 = double.tryParse(matches[0]) ?? 0;
      final n2 = double.tryParse(matches[1]) ?? 0;
      if (n1 < 25 && n2 >= 25) {
        return '${matches[1]} in legroom (${matches[0]} in width)';
      }
      return '${matches[0]}–${matches[1]} in legroom';
    }

    return '$s legroom';
  }

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty && layovers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'Detailed segment breakdown is available directly via Google Flights deal link.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Divider(
          height: 1,
          color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5,
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < segments.length; i++) ...[
          _buildSegmentView(segments[i]),
          if (i < layovers.length)
            _buildLayoverBanner(layovers[i])
          else if (i < segments.length - 1)
            _buildGenericLayover(segments[i], segments[i + 1]),
        ],
        if (segments.isEmpty && layovers.isNotEmpty)
          for (final lay in layovers) _buildLayoverBanner(lay),
      ],
    );
  }

  Widget _buildSegmentView(FlightSegment seg) {
    final subColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final detailColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;
    final cleanLegroom = formatLegroomLabel(seg.legroom);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              children: [
                Icon(Icons.radio_button_unchecked_rounded, size: 12, color: AppColors.iosBlue),
                Container(
                  width: 1.5,
                  height: 48,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4,
                ),
                Icon(Icons.circle_rounded, size: 10, color: AppColors.iosBlue),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      seg.departureTime.isNotEmpty ? seg.departureTime : 'Depart',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    const Text('·', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${seg.departureAirport}${seg.departureCode.isNotEmpty ? ' (${seg.departureCode})' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Travel time: ${seg.duration.isNotEmpty ? seg.duration : 'Direct'}',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      seg.arrivalTime.isNotEmpty ? seg.arrivalTime : 'Arrive',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    const Text('·', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${seg.arrivalAirport}${seg.arrivalCode.isNotEmpty ? ' (${seg.arrivalCode})' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (seg.airline.isNotEmpty || seg.flightNumber.isNotEmpty || seg.aircraft.isNotEmpty)
                      Text(
                        [
                          if (seg.airline.isNotEmpty) seg.airline,
                          if (seg.aircraft.isNotEmpty) seg.aircraft,
                          if (seg.flightNumber.isNotEmpty) seg.flightNumber,
                        ].join(' · '),
                        style: TextStyle(fontSize: 11, color: detailColor, fontWeight: FontWeight.w500),
                      ),
                    if (cleanLegroom.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.iosBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.airline_seat_legroom_normal_rounded,
                              size: 13,
                              color: AppColors.iosBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cleanLegroom,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.iosBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final amenity in seg.amenities)
                      _buildAmenityChip(
                        _amenityIcon(amenity),
                        amenity,
                        detailColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  IconData _amenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wi-fi') || lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('power') || lower.contains('usb')) return Icons.power_rounded;
    if (lower.contains('video') || lower.contains('entertainment')) return Icons.ondemand_video_rounded;
    if (lower.contains('seat') || lower.contains('reclin')) return Icons.airline_seat_recline_extra_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Widget _buildLayoverBanner(FlightLayover lay) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.iosGray6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 14, color: AppColors.iosOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lay.text.isNotEmpty
                  ? lay.text
                  : '${lay.duration} layover · ${lay.city.isNotEmpty ? lay.city : lay.airportName} (${lay.airportCode})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericLayover(FlightSegment prev, FlightSegment next) {
    final airport = prev.arrivalAirport.isNotEmpty ? prev.arrivalAirport : prev.arrivalCode;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.iosGray6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 14, color: AppColors.iosOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Layover at $airport',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
