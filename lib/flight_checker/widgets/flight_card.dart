import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../models/flight_info.dart';
import '../services/flight_service.dart';
import 'flight_segment_timeline.dart';

/// Single flight result card adhering to Vercel Web Interface Guidelines.
/// Supports instant client-side currency repainting via [displayPrice].
/// Strictly under 500 lines (Hard limit: 500 lines)
class FlightCard extends StatefulWidget {
  final FlightInfo flight;
  final String? displayPrice;
  final VoidCallback? onSelect;

  const FlightCard({
    super.key,
    required this.flight,
    this.displayPrice,
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
    final activePrice = widget.displayPrice ?? flight.price;

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = _isHovered
        ? AppColors.iosBlue.withValues(alpha: 0.5)
        : (isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4);

    return Semantics(
      label: '${flight.airline}, $activePrice, ${flight.duration}, ${flight.stops}',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 6),
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Flight duration & path icon
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Text(
                          flight.duration,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.flight_takeoff_rounded,
                                size: 14,
                                color: AppColors.iosBlue,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4,
                              ),
                            ),
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
                            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Price & Interactive Expand Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activePrice,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.iosBlue,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'Total estimated fare',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Expand / Collapse Segment Details
                      TextButton.icon(
                        onPressed: () => setState(() => _isExpanded = !_isExpanded),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          foregroundColor: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                        ),
                        icon: Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _isExpanded ? 'Hide' : 'Details',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          if (widget.onSelect != null) {
                            widget.onSelect!();
                          } else {
                            FlightService.launchFlightUrl(flight.deepLink);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.iosBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'View Deal ↗',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 4. Expanded Segment Breakdown & Itinerary Timeline
              if (_isExpanded)
                FlightSegmentTimeline(
                  segments: flight.segments,
                  layovers: flight.layovers,
                  isDark: isDark,
                ),
            ],
                ),
              ),
            ),
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
}
