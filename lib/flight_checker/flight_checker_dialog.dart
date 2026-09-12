import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'models/flight_info.dart';
import 'services/flight_service.dart';
import 'utils/currency_helper.dart';
import 'widgets/flight_card.dart';
import 'widgets/flight_search_form.dart';

/// Modal dialog for querying flight prices with Google Flights fallback
class FlightCheckerDialog extends StatefulWidget {
  final String? initialOrigin;
  final String? initialDestination;
  final DateTime? initialDate;

  const FlightCheckerDialog({
    super.key,
    this.initialOrigin,
    this.initialDestination,
    this.initialDate,
  });

  @override
  State<FlightCheckerDialog> createState() => _FlightCheckerDialogState();
}

class _FlightCheckerDialogState extends State<FlightCheckerDialog> {
  late FlightSearchParams _currentParams;
  bool _isLoading = false;
  FlightSearchResponse? _response;
  String? _errorMessage;
  final Map<String, FlightSearchResponse> _currencyCache = {};
  final GlobalKey _cheapestCardKey = GlobalKey();
  String? _expandedFlightKeyId;

  @override
  void initState() {
    super.initState();
    final depDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 14));
    final depStr = '${depDate.year}-${depDate.month.toString().padLeft(2, '0')}-${depDate.day.toString().padLeft(2, '0')}';

    _currentParams = FlightSearchParams(
      origin: widget.initialOrigin ?? '',
      destination: widget.initialDestination ?? '',
      departureDate: depStr,
    );

    // Auto-trigger search if both origin and destination were passed
    if ((widget.initialOrigin ?? '').isNotEmpty && (widget.initialDestination ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(_currentParams);
      });
    }
  }

  void _exploreLowestFare(FlightInfo? cheapest) {
    if (cheapest == null) return;
    final keyId = '${cheapest.airline}-${cheapest.departure.time}-${cheapest.priceNumeric}';
    setState(() {
      if (_expandedFlightKeyId == keyId) {
        _expandedFlightKeyId = null;
      } else {
        _expandedFlightKeyId = keyId;
      }
    });

    if (_expandedFlightKeyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_cheapestCardKey.currentContext != null) {
          Scrollable.ensureVisible(
            _cheapestCardKey.currentContext!,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: 0.1,
          );
        }
      });
    }
  }

  void _handleCurrencyChanged(String newCurrency) {
    if (newCurrency == _currentParams.currency) return;
    final updated = _currentParams.copyWith(currency: newCurrency);
    _currentParams = updated;
    _expandedFlightKeyId = null;

    // Instant 0ms repaint if this currency was already retrieved
    if (_currencyCache.containsKey(newCurrency)) {
      setState(() {
        _response = _currencyCache[newCurrency];
        _isLoading = false;
        _errorMessage = null;
      });
    } else if (_response != null && _response!.flights.isNotEmpty) {
      // Query Google Flights live in the new currency for 100% genuine airline quotes
      _performSearch(updated);
    }
  }

  Future<void> _performSearch(FlightSearchParams params) async {
    setState(() {
      _currentParams = params;
      _isLoading = true;
      _errorMessage = null;
      _expandedFlightKeyId = null;
    });

    final res = await FlightService.searchFlights(params);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _response = res;
        if (res.success && res.flights.isNotEmpty) {
          _currencyCache[params.currency] = res;
        }
        if (!res.success && !res.isMultiCity) {
          _errorMessage = res.error ?? 'Could not retrieve flights at this time.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    return Dialog(
      backgroundColor: dialogBg,
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 32,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          children: [
            // 1. Dialog Header with solid opaque background
            _buildHeader(isDark, dialogBg),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? AppColors.darkElevatedHighest : AppColors.iosGray5,
            ),

            // 2. Scrollable Body with strict clipping
            Expanded(
              child: ClipRect(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FlightSearchForm(
                        initialParams: _currentParams,
                        isLoading: _isLoading,
                        onSearch: _performSearch,
                        onCurrencyChanged: _handleCurrencyChanged,
                      ),
                      const SizedBox(height: 20),
                      _buildResultsSection(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color bgColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.iosBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.flight_takeoff_rounded, color: AppColors.iosBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flight Price Checker',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live estimates with Google Flights fallback',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close dialog',
            onPressed: () => Navigator.pop(context),
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(bool isDark) {
    if (_isLoading) {
      return _buildLoadingState(isDark);
    }

    if (_errorMessage != null) {
      return _buildErrorFallback(isDark);
    }

    if (_response == null) {
      return const SizedBox.shrink();
    }

    if (_response!.flights.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final priceRange = CurrencyHelper.calculatePriceRange(
      _response!.flights,
      _currentParams.currency,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (priceRange != null) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _exploreLowestFare(priceRange.cheapestFlight),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.iosBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insights_rounded, size: 18, color: AppColors.iosBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price Range: ${priceRange.minFormatted} – ${priceRange.maxFormatted}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lowest fare from ${priceRange.bestAirline} · Typical: ~${priceRange.avgFormatted}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.iosBlue.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.iosBlue.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Explore Lowest',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.iosBlue,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expandedFlightKeyId ==
                                    '${priceRange.cheapestFlight?.airline}-${priceRange.cheapestFlight?.departure.time}-${priceRange.cheapestFlight?.priceNumeric}'
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: AppColors.iosBlue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Found ${_response!.flights.length} Flights',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => FlightService.launchFlightUrl(_response!.fallbackUrl),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text('Open in Google Flights', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._response!.flights.map((flight) {
          final isCheapest = priceRange != null && flight.priceNumeric == priceRange.min;
          final keyId = '${flight.airline}-${flight.departure.time}-${flight.priceNumeric}';
          final isExpanded = _expandedFlightKeyId == keyId;

          return FlightCard(
            key: isCheapest ? _cheapestCardKey : null,
            flight: flight,
            isLowestFare: isCheapest,
            initiallyExpanded: isExpanded,
          );
        }),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 24),
        CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.iosBlue),
        const SizedBox(height: 14),
        Text(
          'Searching live flight prices…',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Checking airlines and fares',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildErrorFallback(bool isDark, {String? title, String? message}) {
    final fallbackUrl = _response?.fallbackUrl ?? FlightService.buildGoogleFlightsFallbackUrl(_currentParams);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.airplane_ticket_outlined, size: 36, color: AppColors.iosBlue),
          const SizedBox(height: 10),
          Text(title ?? 'Live Preview Unavailable', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            message ?? 'We couldn’t fetch real-time previews for this route, but you can view full live fares directly on Google Flights.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _performSearch(_currentParams),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.iosBlue,
                  side: BorderSide(color: AppColors.iosBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton.icon(
                onPressed: () => FlightService.launchFlightUrl(fallbackUrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.iosBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('View on Google Flights ↗', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return _buildErrorFallback(
      isDark,
      title: 'No Live Estimates Found',
      message: 'No flights were matched for this date and route. Try selecting another date or check live schedules directly.',
    );
  }
}

/// Helper function to open FlightCheckerDialog
void showFlightCheckerDialog(
  BuildContext context, {
  String? origin,
  String? destination,
  DateTime? date,
}) {
  showDialog(
    context: context,
    builder: (context) => FlightCheckerDialog(
      initialOrigin: origin,
      initialDestination: destination,
      initialDate: date,
    ),
  );
}
