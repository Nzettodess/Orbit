import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'models/flight_info.dart';
import 'services/flight_service.dart';
import 'utils/currency_helper.dart';
import 'utils/flight_filter_helper.dart';
import 'widgets/flight_card.dart';
import 'widgets/flight_checker_status_views.dart';
import 'widgets/flight_filter_bar.dart';
import 'widgets/flight_leg_section_header.dart';
import 'widgets/flight_leg_tab_bar.dart';
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
  FlightFilterCriteria _filterCriteria = const FlightFilterCriteria();

  @override
  void initState() {
    super.initState();
    final depDate =
        widget.initialDate ?? DateTime.now().add(const Duration(days: 14));
    final depStr =
        '${depDate.year}-${depDate.month.toString().padLeft(2, '0')}-${depDate.day.toString().padLeft(2, '0')}';
    final retDate = depDate.add(const Duration(days: 7));
    final retStr =
        '${retDate.year}-${retDate.month.toString().padLeft(2, '0')}-${retDate.day.toString().padLeft(2, '0')}';

    _currentParams = FlightSearchParams(
      origin: widget.initialOrigin ?? '',
      destination: widget.initialDestination ?? '',
      departureDate: depStr,
      returnDate: retStr,
      tripType: 'roundtrip',
    );

    // Auto-trigger search if both origin and destination were passed
    if ((widget.initialOrigin ?? '').isNotEmpty &&
        (widget.initialDestination ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(_currentParams);
      });
    }
  }

  void _handleCurrencyChanged(String newCurrency) {
    if (newCurrency == _currentParams.currency) return;
    final updated = _currentParams.copyWith(currency: newCurrency);
    _currentParams = updated;
    _filterCriteria = const FlightFilterCriteria();

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

  void _handleTripTypeChanged(String newTripType) {
    if (newTripType == _currentParams.tripType) return;
    setState(() {
      String? returnDate = _currentParams.returnDate;
      if (newTripType == 'roundtrip' && (returnDate == null || returnDate.isEmpty)) {
        final dep = DateTime.tryParse(_currentParams.departureDate) ??
            DateTime.now().add(const Duration(days: 14));
        final ret = dep.add(const Duration(days: 7));
        returnDate =
            '${ret.year}-${ret.month.toString().padLeft(2, '0')}-${ret.day.toString().padLeft(2, '0')}';
      }
      _currentParams = _currentParams.copyWith(
        tripType: newTripType,
        returnDate: newTripType == 'roundtrip' ? returnDate : null,
      );
    });
  }

  Future<void> _performSearch(FlightSearchParams params) async {
    setState(() {
      _currentParams = params;
      _isLoading = true;
      _errorMessage = null;
      _filterCriteria = const FlightFilterCriteria();
    });

    final res = await FlightService.searchFlights(params);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _response = res;
        if (res.success && res.flights.isNotEmpty) {
          _currencyCache[params.currency] = res;
        }
        if (!res.success) {
          _errorMessage =
              res.error ?? 'Could not retrieve flights at this time.';
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
              color: isDark
                  ? AppColors.darkElevatedHighest
                  : AppColors.iosGray5,
            ),

            // 2. Scrollable Body with strict clipping
            Expanded(
              child: ClipRect(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 12 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FlightSearchForm(
                        initialParams: _currentParams,
                        isLoading: _isLoading,
                        onSearch: _performSearch,
                        onCurrencyChanged: _handleCurrencyChanged,
                        onTripTypeChanged: _handleTripTypeChanged,
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
            child: Icon(
              Icons.flight_takeoff_rounded,
              color: AppColors.iosBlue,
              size: 20,
            ),
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
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live estimates with Google Flights fallback',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTertiary
                        : AppColors.lightTertiary,
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

    return _buildFlightResults(isDark);
  }

  Widget _buildFlightResults(bool isDark) {
    final isRoundTrip = _response?.isRoundTrip == true || _currentParams.tripType == 'roundtrip';

    final outboundFlights = isRoundTrip
        ? (_response!.outboundFlights.isNotEmpty ? _response!.outboundFlights : _response!.flights)
        : _response!.flights;
    final returnFlights = isRoundTrip ? _response!.returnFlights : const <FlightInfo>[];
    final allFlights = isRoundTrip ? [...outboundFlights, ...returnFlights] : outboundFlights;

    final priceRange = CurrencyHelper.calculatePriceRange(
      allFlights,
      _currentParams.currency,
    );

    final availableAirlines = FlightFilterHelper.getAvailableAirlines(allFlights);
    final airlineCounts = FlightFilterHelper.getAirlineCounts(allFlights);

    final filteredOutbound = FlightFilterHelper.applyFiltersAndSort(
      outboundFlights,
      _filterCriteria,
    );
    final filteredReturn = isRoundTrip
        ? FlightFilterHelper.applyFiltersAndSort(returnFlights, _filterCriteria)
        : const <FlightInfo>[];

    final lowestOutbound = _findLowestPrice(outboundFlights);
    final lowestReturn = isRoundTrip ? _findLowestPrice(returnFlights) : null;
    final combinedTotal = (lowestOutbound != null && lowestReturn != null)
        ? lowestOutbound + lowestReturn
        : null;

    final bestOutbound = FlightFilterHelper.findBestFlight(outboundFlights);
    final bestReturn = isRoundTrip ? FlightFilterHelper.findBestFlight(returnFlights) : null;

    final totalFoundCount = outboundFlights.length + returnFlights.length;
    final totalVisibleCount = filteredOutbound.length + filteredReturn.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRoundTrip && combinedTotal != null && combinedTotal > 0) ...[
          FlightRoundTripSummaryBanner(
            combinedTotal: combinedTotal,
            lowestOutbound: lowestOutbound!,
            lowestReturn: lowestReturn!,
            currency: _currentParams.currency,
            isDark: isDark,
          ),
          const SizedBox(height: 6),
        ] else if (priceRange != null) ...[
          FlightPriceRangeInsight(priceRange: priceRange, isDark: isDark),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Found $totalFoundCount Flights',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () =>
                  FlightService.launchFlightUrl(_response!.fallbackUrl),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text(
                'Open in Google Flights',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FlightFilterBar(
          criteria: _filterCriteria,
          onChanged: (updated) => setState(() => _filterCriteria = updated),
          availableAirlines: availableAirlines,
          airlineCounts: airlineCounts,
          totalCount: totalFoundCount,
          visibleCount: totalVisibleCount,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        if (totalVisibleCount == 0)
          FlightCheckerEmptyFilterView(
            isDark: isDark,
            onReset: () =>
                setState(() => _filterCriteria = const FlightFilterCriteria()),
          )
        else ...[
          if (isRoundTrip) ...[
            FlightLegSectionHeader(
              title: 'Departing Flights',
              routeSubtitle: '${_currentParams.origin} → ${_currentParams.destination}',
              date: _currentParams.departureDate,
              count: filteredOutbound.length,
              lowestPrice: lowestOutbound,
              currency: _currentParams.currency,
              icon: Icons.flight_takeoff_rounded,
              accentColor: AppColors.iosBlue,
              isDark: isDark,
            ),
            const SizedBox(height: 6),
          ],
          if (filteredOutbound.isEmpty)
            FlightEmptyLegNotice(legName: 'departing', isDark: isDark)
          else
            ..._buildFlightCards(
              flights: filteredOutbound,
              lowestPrice: lowestOutbound,
              bestFlight: bestOutbound,
              legPrefix: 'outbound',
            ),
          if (isRoundTrip) ...[
            FlightLegSeparator(
              label: 'RETURNING OPTIONS (${_currentParams.destination} → ${_currentParams.origin})',
              isDark: isDark,
            ),
            FlightLegSectionHeader(
              title: 'Returning Flights',
              routeSubtitle: '${_currentParams.destination} → ${_currentParams.origin}',
              date: _currentParams.returnDate ?? '',
              count: filteredReturn.length,
              lowestPrice: lowestReturn,
              currency: _currentParams.currency,
              icon: Icons.flight_land_rounded,
              accentColor: AppColors.iosPurple,
              isDark: isDark,
            ),
            const SizedBox(height: 6),
            if (filteredReturn.isEmpty)
              FlightEmptyLegNotice(legName: 'returning', isDark: isDark)
            else
              ..._buildFlightCards(
                flights: filteredReturn,
                lowestPrice: lowestReturn,
                bestFlight: bestReturn,
                legPrefix: 'return',
              ),
          ],
        ],
      ],
    );
  }

  List<Widget> _buildFlightCards({
    required List<FlightInfo> flights,
    required int? lowestPrice,
    required FlightInfo? bestFlight,
    required String legPrefix,
  }) {
    return flights.map((flight) {
      final isLowestPrice = lowestPrice != null && flight.priceNumeric == lowestPrice;
      final isBest = bestFlight != null &&
          flight.airline == bestFlight.airline &&
          flight.priceNumeric == bestFlight.priceNumeric &&
          flight.departure.time == bestFlight.departure.time;
      final keyId = 'flight_${legPrefix}_${flight.airline}_${flight.departure.time}_${flight.priceNumeric}';

      return FlightCard(
        key: ValueKey(keyId),
        flight: flight,
        isLowestFare: isLowestPrice,
        isBest: isBest,
      );
    }).toList();
  }

  int? _findLowestPrice(List<FlightInfo> flights) {
    int? minPrice;
    for (final f in flights) {
      if (f.priceNumeric > 0) {
        if (minPrice == null || f.priceNumeric < minPrice) {
          minPrice = f.priceNumeric;
        }
      }
    }
    return minPrice;
  }

  Widget _buildLoadingState(bool isDark) =>
      FlightCheckerLoadingView(isDark: isDark);

  Widget _buildErrorFallback(bool isDark, {String? title, String? message}) =>
      FlightCheckerFallbackView(
        isDark: isDark,
        fallbackUrl: _response?.fallbackUrl ??
            FlightService.buildGoogleFlightsFallbackUrl(_currentParams),
        title: title,
        message: message,
        onRetry: () => _performSearch(_currentParams),
        onOpenFallback: FlightService.launchFlightUrl,
      );

  Widget _buildEmptyState(bool isDark) => _buildErrorFallback(
        isDark,
        title: 'No Live Estimates Found',
        message:
            'No flights were matched for this date and route. Try selecting another date or check live schedules directly.',
      );
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
