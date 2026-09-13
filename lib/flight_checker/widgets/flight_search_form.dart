import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../models/flight_info.dart';
import '../utils/airport_data.dart';
import 'airport_autocomplete_field.dart';
import 'flight_multicity_input_list.dart';
import 'flight_trip_type_selector.dart';
import 'passenger_selector.dart';
import 'popup_selector_field.dart';

/// Flight search form component adhering to Vercel Web Interface Guidelines
class FlightSearchForm extends StatefulWidget {
  final FlightSearchParams initialParams;
  final ValueChanged<FlightSearchParams> onSearch;
  final ValueChanged<String>? onCurrencyChanged;
  final ValueChanged<String>? onTripTypeChanged;
  final bool isLoading;

  const FlightSearchForm({
    super.key,
    required this.initialParams,
    required this.onSearch,
    this.onCurrencyChanged,
    this.onTripTypeChanged,
    required this.isLoading,
  });

  @override
  State<FlightSearchForm> createState() => _FlightSearchFormState();
}

class _FlightSearchFormState extends State<FlightSearchForm> {
  late TextEditingController _originController;
  late TextEditingController _destinationController;
  late String _tripType;
  late DateTime _departureDate;
  DateTime? _returnDate;
  late int _adults;
  late int _children;
  late String _cabinClass;
  late String _currency;
  bool _showPassengerPicker = false;
  late List<EditableTripLeg> _multiCityLegs;

  @override
  void initState() {
    super.initState();
    final p = widget.initialParams;
    final from = AirportHelper.findBestAirport(p.origin);
    final to = AirportHelper.findBestAirport(p.destination);

    _originController = TextEditingController(text: from.isNotEmpty ? from : p.origin);
    _destinationController = TextEditingController(text: to.isNotEmpty ? to : p.destination);
    _tripType = p.tripType;
    _departureDate = DateTime.tryParse(p.departureDate) ?? DateTime.now().add(const Duration(days: 14));
    if (p.returnDate != null && p.returnDate!.isNotEmpty) {
      _returnDate = DateTime.tryParse(p.returnDate!);
    }
    _returnDate ??= _departureDate.add(const Duration(days: 7));
    _adults = p.adults.clamp(1, 9);
    _children = p.children.clamp(0, 8);
    _cabinClass = p.cabinClass;
    _currency = p.currency.isNotEmpty ? p.currency : 'MYR';

    _multiCityLegs = (p.multiCityLegs?.isNotEmpty ?? false)
        ? p.multiCityLegs!.map((l) => EditableTripLeg(
              origin: l.origin,
              destination: l.destination,
              date: DateTime.tryParse(l.date) ?? DateTime.now().add(const Duration(days: 14)),
            )).toList()
        : [EditableTripLeg(origin: from.isNotEmpty ? from : p.origin, destination: to.isNotEmpty ? to : p.destination, date: _departureDate)];

    _originController.addListener(_onLocationChanged);
    _destinationController.addListener(_onLocationChanged);
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant FlightSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialParams.origin != oldWidget.initialParams.origin &&
        _originController.text.trim() != widget.initialParams.origin) {
      final newOrigin = AirportHelper.findBestAirport(widget.initialParams.origin);
      _originController.text = newOrigin.isNotEmpty ? newOrigin : widget.initialParams.origin;
    }
    if (widget.initialParams.destination != oldWidget.initialParams.destination &&
        _destinationController.text.trim() != widget.initialParams.destination) {
      final newDest = AirportHelper.findBestAirport(widget.initialParams.destination);
      _destinationController.text = newDest.isNotEmpty ? newDest : widget.initialParams.destination;
    }
  }

  @override
  void dispose() {
    _originController.removeListener(_onLocationChanged);
    _destinationController.removeListener(_onLocationChanged);
    _originController.dispose();
    _destinationController.dispose();
    for (final l in _multiCityLegs) {
      l.dispose();
    }
    super.dispose();
  }

  void _handleAddMultiCityLeg() {
    if (_multiCityLegs.length >= 6) return;
    setState(() {
      final lastLeg = _multiCityLegs.isNotEmpty ? _multiCityLegs.last : null;
      final nextOrigin = lastLeg?.destController.text.trim() ?? '';
      final nextDate = lastLeg != null
          ? lastLeg.date.add(const Duration(days: 3))
          : _departureDate.add(const Duration(days: 10));
      _multiCityLegs.add(EditableTripLeg(origin: nextOrigin, destination: '', date: nextDate));
    });
  }

  void _handleRemoveMultiCityLeg(int index) {
    if (_multiCityLegs.length <= 1) return;
    setState(() => _multiCityLegs.removeAt(index).dispose());
  }

  Future<void> _handlePickMultiCityDate(int index) async {
    final leg = _multiCityLegs[index];
    final now = DateTime.now();
    final first = index > 0 ? _multiCityLegs[index - 1].date : now;
    final initial = leg.date.isBefore(first) ? first : leg.date;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => leg.date = picked);
    }
  }

  void _handleSwapMultiCityLocations(int index) {
    final leg = _multiCityLegs[index];
    final temp = leg.originController.text;
    setState(() {
      leg.originController.text = leg.destController.text;
      leg.destController.text = temp;
    });
  }

  void _handleTripTypeChanged(String key) {
    if (key == _tripType) return;
    setState(() {
      _tripType = key;
      if (key == 'roundtrip') {
        _returnDate ??= _departureDate.add(const Duration(days: 7));
        if (_returnDate!.isBefore(_departureDate)) _returnDate = _departureDate.add(const Duration(days: 7));
      } else if (key == 'multicity' && _multiCityLegs.isNotEmpty) {
        if (_multiCityLegs[0].originController.text.isEmpty && _originController.text.isNotEmpty) {
          _multiCityLegs[0].originController.text = _originController.text;
        }
        if (_multiCityLegs[0].destController.text.isEmpty && _destinationController.text.isNotEmpty) {
          _multiCityLegs[0].destController.text = _destinationController.text;
        }
      }
    });
    widget.onTripTypeChanged?.call(key);
  }

  void _swapLocations() {
    final temp = _originController.text;
    setState(() {
      _originController.text = _destinationController.text;
      _destinationController.text = temp;
    });
  }

  Future<void> _pickDate({required bool isReturn}) async {
    final now = DateTime.now();
    final initial = isReturn ? (_returnDate ?? _departureDate.add(const Duration(days: 7))) : _departureDate;
    final first = isReturn ? _departureDate : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isReturn) {
          _returnDate = picked;
        } else {
          _departureDate = picked;
          if (_returnDate != null && _returnDate!.isBefore(_departureDate)) _returnDate = _departureDate.add(const Duration(days: 7));
        }
      });
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating));

  void _submit() {
    final depStr = DateFormat('yyyy-MM-dd').format(_departureDate);
    final effectiveReturn = _returnDate ?? _departureDate.add(const Duration(days: 7));
    final retStr = DateFormat('yyyy-MM-dd').format(effectiveReturn);

    if (_tripType == 'multicity') {
      final legs = _multiCityLegs
          .map((l) => FlightLegParam(
                origin: l.originController.text.trim(),
                destination: l.destController.text.trim(),
                date: DateFormat('yyyy-MM-dd').format(l.date),
              ))
          .toList();

      for (int i = 0; i < legs.length; i++) {
        final leg = legs[i];
        if (AirportHelper.isSameLocation(leg.origin, leg.destination)) {
          final display = AirportHelper.findBestAirport(leg.origin);
          _showError('Trip ${i + 1}: Origin and destination cannot be the same airport (${display.isNotEmpty ? display : leg.origin}).');
          return;
        }
      }

      final firstLeg = legs.isNotEmpty ? legs.first : null;
      final lastLeg = legs.length > 1 ? legs.last : firstLeg;

      widget.onSearch(FlightSearchParams(
        origin: firstLeg?.origin ?? _originController.text.trim(),
        destination: lastLeg?.destination ?? _destinationController.text.trim(),
        departureDate: firstLeg?.date ?? depStr,
        returnDate: null,
        tripType: 'multicity',
        adults: _adults,
        children: _children,
        cabinClass: _cabinClass,
        currency: _currency,
        multiCityLegs: legs,
      ));
      return;
    }

    final fromText = _originController.text.trim();
    final toText = _destinationController.text.trim();
    if (AirportHelper.isSameLocation(fromText, toText)) {
      final display = AirportHelper.findBestAirport(fromText);
      _showError('Origin and destination cannot be the same airport (${display.isNotEmpty ? display : fromText}).');
      return;
    }

    widget.onSearch(FlightSearchParams(
      origin: fromText,
      destination: toText,
      departureDate: depStr,
      returnDate: _tripType == 'roundtrip' ? retStr : null,
      tripType: _tripType,
      adults: _adults,
      children: _children,
      cabinClass: _cabinClass,
      currency: _currency,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Trip Type Segmented Control
        FlightTripTypeSelector(
          selectedTripType: _tripType,
          onChanged: _handleTripTypeChanged,
          isDark: isDark,
        ),
        const SizedBox(height: 14),

        if (_tripType == 'multicity') ...[
          FlightMultiCityInputList(
            legs: _multiCityLegs,
            onAddLeg: _handleAddMultiCityLeg,
            onRemoveLeg: _handleRemoveMultiCityLeg,
            onPickDate: _handlePickMultiCityDate,
            onSwapLocations: _handleSwapMultiCityLocations,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
        ] else ...[
          // Origin & Destination with Autocomplete and Swap button (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final isCompact = constraints.maxWidth < 380 || (constraints.maxWidth < 460 && textScale > 1.15);
              final hasSameError = _originController.text.trim().isNotEmpty &&
                  _destinationController.text.trim().isNotEmpty &&
                  AirportHelper.isSameLocation(_originController.text.trim(), _destinationController.text.trim());

              final fromField = AirportAutocompleteField(
                controller: _originController,
                label: 'From',
                hint: 'Origin city or airport…',
                icon: Icons.flight_takeoff_rounded,
                bg: fieldBg,
                isDark: isDark,
                hasError: hasSameError,
              );

              final toField = AirportAutocompleteField(
                controller: _destinationController,
                label: 'To',
                hint: 'Destination city or airport…',
                icon: Icons.flight_land_rounded,
                bg: fieldBg,
                isDark: isDark,
                hasError: hasSameError,
              );

              final errorBanner = hasSameError
                  ? Padding(
                      padding: const EdgeInsets.only(top: 5, left: 2),
                      child: Row(
                        children: const [
                          Icon(Icons.error_outline_rounded, size: 13, color: AppColors.iosRed),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Origin and destination cannot be the same airport',
                              style: TextStyle(fontSize: 11, color: AppColors.iosRed, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink();

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    fromField,
                    const SizedBox(height: 6),
                    Center(
                      child: InkWell(
                        onTap: _swapLocations,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.iosBlue.withValues(alpha: 0.3))),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_vert_rounded, size: 15, color: AppColors.iosBlue),
                              SizedBox(width: 4),
                              Text('Swap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.iosBlue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    toField,
                    errorBanner,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: fromField),
                      IconButton(icon: const Icon(Icons.swap_horiz_rounded), tooltip: 'Swap locations', onPressed: _swapLocations, color: AppColors.iosBlue),
                      Expanded(child: toField),
                    ],
                  ),
                  errorBanner,
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Date Pickers Row
          Row(
            children: [
              Expanded(
                child: FlightDateTile(
                  label: 'Departure',
                  date: _departureDate,
                  onTap: () => _pickDate(isReturn: false),
                  fieldBg: fieldBg,
                  isDark: isDark,
                ),
              ),
              if (_tripType == 'roundtrip') ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FlightDateTile(
                    label: 'Return',
                    date: _returnDate ?? _departureDate.add(const Duration(days: 7)),
                    onTap: () => _pickDate(isReturn: true),
                    fieldBg: fieldBg,
                    isDark: isDark,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Passengers, Class & Currency Row (Responsive for mobile viewports)
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final isVeryNarrow = constraints.maxWidth < 340 || textScale > 1.2;
            final isNarrow = constraints.maxWidth < 450;
            final passTile = PassengerTile(
              adults: _adults,
              children: _children,
              isExpanded: _showPassengerPicker,
              onTap: () => setState(() => _showPassengerPicker = !_showPassengerPicker),
              bg: fieldBg,
              isDark: isDark,
            );
            final classDrop = FlightClassDropdown(
              cabinClass: _cabinClass,
              onSelected: (val) => setState(() => _cabinClass = val),
              bg: fieldBg,
              isDark: isDark,
            );
            final currDrop = FlightCurrencyDropdown(
              currency: _currency,
              onSelected: (val) {
                setState(() => _currency = val);
                widget.onCurrencyChanged?.call(val);
              },
              bg: fieldBg,
              isDark: isDark,
            );

            return isNarrow
                ? Column(children: [
                    passTile,
                    const SizedBox(height: 10),
                    if (isVeryNarrow) ...[classDrop, const SizedBox(height: 10), currDrop]
                    else Row(children: [Expanded(child: classDrop), const SizedBox(width: 8), Expanded(child: currDrop)]),
                  ])
                : Row(children: [
                    Expanded(flex: 3, child: passTile),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: classDrop),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: currDrop),
                  ]);
          },
        ),
        if (_showPassengerPicker) ...[
          const SizedBox(height: 10),
          PassengerControlPanel(
            adults: _adults,
            children: _children,
            onChanged: (a, c) => setState(() {
              _adults = a;
              _children = c;
            }),
            onDone: () => setState(() => _showPassengerPicker = false),
            isDark: isDark,
          ),
        ],
        const SizedBox(height: 16),

        // Search Button
        ElevatedButton.icon(
          onPressed: widget.isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.iosBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
          icon: widget.isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.search_rounded, size: 18),
          label: Text(widget.isLoading ? 'Searching flights…' : 'Find Flights', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ],
    );
  }
}
