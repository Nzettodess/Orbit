import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../models/flight_info.dart';
import '../services/flight_service.dart';
import '../utils/flight_filter_helper.dart';
import 'flight_segment_timeline.dart';

/// Single flight result card adhering to Vercel Web Interface Guidelines.
/// Supports instant client-side currency repainting via [displayPrice].
/// Strictly under 500 lines (Hard limit: 500 lines)
class FlightCard extends StatefulWidget {
  final FlightInfo flight;
  final String? displayPrice;
  final VoidCallback? onSelect;
  final bool isLowestFare;
  final bool isBest;
  final bool initiallyExpanded;

  const FlightCard({
    super.key,
    required this.flight,
    this.displayPrice,
    this.onSelect,
    this.isLowestFare = false,
    this.isBest = false,
    this.initiallyExpanded = false,
  });

  @override
  State<FlightCard> createState() => _FlightCardState();
}

class _FlightCardState extends State<FlightCard> {
  bool _isHovered = false;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(FlightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flight = widget.flight;
    final computedStops = flight.layovers.isNotEmpty
        ? flight.layovers.length
        : (flight.segments.length > 1
            ? flight.segments.length - 1
            : (flight.stops.toLowerCase().contains('nonstop') ? 0 : 1));
    final isNonstop = computedStops == 0;
    final stopsText = isNonstop ? 'Nonstop' : '$computedStops stop${computedStops > 1 ? 's' : ''}';
    final activePrice = widget.displayPrice ?? flight.price;

    FlightLayover? longLayover;
    for (final lay in flight.layovers) {
      final m = lay.durationMinutes > 0 ? lay.durationMinutes : FlightFilterHelper.parseDurationMinutes(lay.duration);
      if (m > 300) { longLayover = lay; break; }
    }
    final hasLongLayover = longLayover != null;

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final hasSpecialBadge = widget.isLowestFare || widget.isBest;
    final borderWidth = hasSpecialBadge ? 2.0 : (_isHovered ? 1.5 : 1.0);
    final borderColor = widget.isLowestFare
        ? AppColors.iosGreen.withValues(alpha: _isHovered ? 1.0 : 0.85)
        : (widget.isBest
            ? AppColors.iosBlue.withValues(alpha: _isHovered ? 1.0 : 0.85)
            : (_isHovered ? AppColors.iosBlue.withValues(alpha: 0.5) : (isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4)));

    return Semantics(
      label:
          '${flight.airline}, $activePrice, ${flight.duration}, ${flight.stops}',
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
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: _isHovered
                ? [BoxShadow(color: (widget.isLowestFare ? AppColors.iosGreen : AppColors.iosBlue).withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))]
                : (widget.isLowestFare ? [BoxShadow(color: AppColors.iosGreen.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))] : null),
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
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isBest) ...[
                          _buildTopBadge(
                            text: 'Best',
                            icon: Icons.thumb_up_alt_rounded,
                            color: AppColors.iosBlue,
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (widget.isLowestFare) ...[
                          _buildTopBadge(
                            text: 'Lowest Fare',
                            icon: Icons.bolt_rounded,
                            color: AppColors.iosGreen,
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (hasLongLayover) ...[
                          _buildTopBadge(
                            text: 'Long wait time',
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.iosRed,
                          ),
                          const SizedBox(width: 6),
                        ],
                        _buildStopsBadge(
                          isNonstop: isNonstop,
                          text: stopsText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 2. Flight Journey Timeline: Departure ──[Duration]──► Arrival
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildEndpoint(flight.departure.time, flight.departure.airport, isDark),
                        _buildDurationAndPath(flight, longLayover, isNonstop, isDark),
                        _buildEndpoint(flight.arrival.time, flight.arrival.airport, isDark, isEnd: true),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. Price & Interactive Expand Action
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(activePrice, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.iosBlue, fontFeatures: const [FontFeature.tabularFigures()])),
                              Text('Total estimated fare', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () => setState(() => _isExpanded = !_isExpanded),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, foregroundColor: isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
                              icon: Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 18),
                              label: Text(_isExpanded ? 'Hide' : 'Details', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton(
                              onPressed: () => widget.onSelect != null ? widget.onSelect!() : FlightService.launchFlightUrl(flight.deepLink),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.iosBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: const Size(0, 34), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                              child: const Text('View Deal ↗', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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

  Widget _buildEndpoint(String time, String airport, bool isDark, {bool isEnd = false}) {
    return Expanded(
      flex: 4,
      child: Column(
        crossAxisAlignment: isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            time.isNotEmpty ? time : (isEnd ? 'Arrive' : 'Depart'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            airport,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: isEnd ? TextAlign.end : TextAlign.start,
          ),
        ],
      ),
    );
  }

  Widget _buildDurationAndPath(FlightInfo flight, FlightLayover? longLayover, bool isNonstop, bool isDark) {
    final dividerColor = isDark ? AppColors.darkElevatedHighest : AppColors.iosGray4;
    return Expanded(
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
              Expanded(child: Container(height: 1.5, color: dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.flight_takeoff_rounded, size: 14, color: AppColors.iosBlue),
              ),
              Expanded(child: Container(height: 1.5, color: dividerColor)),
            ],
          ),
          if (longLayover != null) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 11, color: AppColors.iosRed),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${longLayover.duration} ${longLayover.airportCode}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.iosRed,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else if (!isNonstop && flight.layovers.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${flight.layovers.first.duration} ${flight.layovers.first.airportCode}',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
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
      child: const Icon(
        Icons.flight_rounded,
        size: 14,
        color: AppColors.iosBlue,
      ),
    );
  }

  Widget _buildStopsBadge({
    required bool isNonstop,
    required String text,
  }) {
    final color = isNonstop ? AppColors.iosGreen : AppColors.iosOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTopBadge({
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
