import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'models/flight_info.dart';
import 'services/flight_service.dart';
import 'utils/currency_helper.dart';
import 'utils/flight_filter_helper.dart';
import 'widgets/flight_checker_dialog_header.dart';
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
  bool _isDepartingExpanded = true;
  bool _isReturningExpanded = true;

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
      _isDepartingExpanded = true;
      _isReturningExpanded = true;
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
            FlightCheckerDialogHeader(
              isDark: isDark,
              bgColor: dialogBg,
              onClose: () => Navigator.pop(context),
            ),
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

    final lowestOutbound = FlightLegSectionHeader.findLowestPrice(outboundFlights);
    final lowestReturn = isRoundTrip ? FlightLegSectionHeader.findLowestPrice(returnFlights) : null;
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
              child: Row(
                children: [
                  Text(
                    'Found $totalFoundCount Flights',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isRoundTrip) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        final anyOpen = _isDepartingExpanded || _isReturningExpanded;
                        setState(() {
                          _isDepartingExpanded = !anyOpen;
                          _isReturningExpanded = !anyOpen;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (_isDepartingExpanded || _isReturningExpanded)
                                  ? Icons.unfold_less_rounded
                                  : Icons.unfold_more_rounded,
                              size: 13,
                              color: AppColors.iosBlue,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              (_isDepartingExpanded || _isReturningExpanded)
                                  ? 'Collapse'
                                  : 'Expand',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.iosBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
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
          if (isRoundTrip)
            FlightLegSection(
              title: 'Departing Flights',
              routeSubtitle: '${_currentParams.origin} → ${_currentParams.destination}',
              date: _currentParams.departureDate,
              count: filteredOutbound.length,
              lowestPrice: lowestOutbound,
              currency: _currentParams.currency,
              icon: Icons.flight_takeoff_rounded,
              accentColor: AppColors.iosBlue,
              isDark: isDark,
              isCollapsible: true,
              isExpanded: _isDepartingExpanded,
              onToggleExpand: () =>
                  setState(() => _isDepartingExpanded = !_isDepartingExpanded),
              flights: filteredOutbound,
              bestFlight: bestOutbound,
              legPrefix: 'outbound',
              legName: 'departing',
            )
          else if (filteredOutbound.isEmpty)
            FlightEmptyLegNotice(legName: 'departing', isDark: isDark)
          else
            FlightLegCardsList(
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
            FlightLegSection(
              title: 'Returning Flights',
              routeSubtitle: '${_currentParams.destination} → ${_currentParams.origin}',
              date: _currentParams.returnDate ?? '',
              count: filteredReturn.length,
              lowestPrice: lowestReturn,
              currency: _currentParams.currency,
              icon: Icons.flight_land_rounded,
              accentColor: AppColors.iosPurple,
              isDark: isDark,
              isCollapsible: true,
              isExpanded: _isReturningExpanded,
              onToggleExpand: () =>
                  setState(() => _isReturningExpanded = !_isReturningExpanded),
              flights: filteredReturn,
              bestFlight: bestReturn,
              legPrefix: 'return',
              legName: 'returning',
            ),
          ],
        ],
      ],
    );
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
