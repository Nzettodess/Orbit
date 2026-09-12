import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../models/flight_info.dart';
import '../services/flight_service.dart';

/// Single flight result card adhering to Vercel Web Interface Guidelines
class FlightCard extends StatefulWidget {
  final FlightInfo flight;
  final VoidCallback? onSelect;

  const FlightCard({
    super.key,
    required this.flight,
    this.onSelect,
  });

  @override
  State<FlightCard> createState() => _FlightCardState();
}

class _FlightCardState extends State<FlightCard> {
  bool _isHovered = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flight = widget.flight;
    final isNonstop = flight.stops.toLowerCase().contains('nonstop');

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = _isHovered
        ? AppColors.iosBlue.withValues(alpha: 0.5)
        : (isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4);

    return Semantics(
      label: '${flight.airline}, ${flight.price}, ${flight.duration}, ${flight.stops}',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: _isHovered ? 1.5 : 1),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.iosBlue.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Airline Logo + Name + Stops Badge
              Row(
                children: [
                  _buildAirlineLogo(flight.logoUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      flight.airline,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStopsBadge(isNonstop, flight.stops),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Flight Journey Timeline: Departure ──[Duration]──► Arrival
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Departure
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flight.departure.time.isNotEmpty ? flight.departure.time : 'Depart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          flight.departure.airport,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Center Duration & Plane icon
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Text(
                          flight.duration,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(child: Divider(color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4, height: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.flight_takeoff_rounded, size: 14, color: AppColors.iosBlue),
                            ),
                            Expanded(child: Divider(color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4, height: 1)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrival
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          flight.arrival.time.isNotEmpty ? flight.arrival.time : 'Arrive',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          flight.arrival.airport,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Footer: Price & Actions (Toggle details + Book deal)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    flight.price,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: AppColors.iosBlue,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _isExpanded = !_isExpanded),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _isExpanded ? 'Hide' : 'Details',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        onPressed: () => FlightService.launchFlightUrl(flight.deepLink),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.iosBlue,
                          side: BorderSide(color: AppColors.iosBlue.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 13),
                        label: const Text('View Deal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
              if (_isExpanded) _buildExpandedDetails(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAirlineLogo(String? logoUrl) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          placeholder: (_, __) => _buildFallbackLogo(),
          errorWidget: (_, __, ___) => _buildFallbackLogo(),
        ),
      );
    }
    return _buildFallbackLogo();
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.iosBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.flight_rounded, size: 14, color: AppColors.iosBlue),
    );
  }

  Widget _buildStopsBadge(bool isNonstop, String text) {
    final color = isNonstop ? AppColors.iosGreen : AppColors.iosOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildExpandedDetails(bool isDark) {
    final segments = widget.flight.segments;
    final layovers = widget.flight.layovers;

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
          _buildSegmentView(segments[i], isDark),
          if (i < layovers.length)
            _buildLayoverBanner(layovers[i], isDark)
          else if (i < segments.length - 1)
            _buildGenericLayover(segments[i], segments[i + 1], isDark),
        ],
        if (segments.isEmpty && layovers.isNotEmpty)
          for (final lay in layovers) _buildLayoverBanner(lay, isDark),
      ],
    );
  }

  Widget _buildSegmentView(FlightSegment seg, bool isDark) {
    final subColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final detailColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;

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
                    if (seg.legroom.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.iosBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          seg.legroom,
                          style: TextStyle(fontSize: 10, color: AppColors.iosBlue, fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (seg.emissions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.iosGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          seg.emissions,
                          style: TextStyle(fontSize: 10, color: AppColors.iosGreen, fontWeight: FontWeight.w600),
                        ),
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

  Widget _buildLayoverBanner(FlightLayover lay, bool isDark) {
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericLayover(FlightSegment prev, FlightSegment next, bool isDark) {
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
