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
    final initialOrigin = AirportHelper.findBestAirport(widget.initialParams.origin);
    final initialDest = AirportHelper.findBestAirport(widget.initialParams.destination);

    _originController = TextEditingController(text: initialOrigin.isNotEmpty ? initialOrigin : widget.initialParams.origin);
    _destinationController = TextEditingController(text: initialDest.isNotEmpty ? initialDest : widget.initialParams.destination);

    _tripType = widget.initialParams.tripType;
    _departureDate = DateTime.tryParse(widget.initialParams.departureDate) ??
        DateTime.now().add(const Duration(days: 14));
    if (widget.initialParams.returnDate != null && widget.initialParams.returnDate!.isNotEmpty) {
      _returnDate = DateTime.tryParse(widget.initialParams.returnDate!);
    }
    _returnDate ??= _departureDate.add(const Duration(days: 7));
    _adults = widget.initialParams.adults.clamp(1, 9);
    _children = widget.initialParams.children.clamp(0, 8);
    _cabinClass = widget.initialParams.cabinClass;
    _currency = widget.initialParams.currency.isNotEmpty ? widget.initialParams.currency : 'MYR';

    _multiCityLegs = (widget.initialParams.multiCityLegs?.isNotEmpty ?? false)
        ? widget.initialParams.multiCityLegs!
            .map((l) => EditableTripLeg(
                  origin: l.origin,
                  destination: l.destination,
                  date: DateTime.tryParse(l.date) ?? DateTime.now().add(const Duration(days: 14)),
                ))
            .toList()
        : [
            EditableTripLeg(
              origin: initialOrigin.isNotEmpty ? initialOrigin : widget.initialParams.origin,
              destination: initialDest.isNotEmpty ? initialDest : widget.initialParams.destination,
              date: _departureDate,
            ),
            EditableTripLeg(
              origin: initialDest.isNotEmpty ? initialDest : widget.initialParams.destination,
              destination: initialOrigin.isNotEmpty ? initialOrigin : widget.initialParams.origin,
              date: _returnDate ?? _departureDate.add(const Duration(days: 7)),
            ),
          ];
  }

  @override
  void dispose() {
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
    if (_multiCityLegs.length <= 2) return;
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
    setState(() {
      final temp = leg.originController.text;
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
        if (_returnDate!.isBefore(_departureDate)) {
          _returnDate = _departureDate.add(const Duration(days: 7));
        }
      }
    });
    widget.onTripTypeChanged?.call(key);
  }

  void _swapLocations() {
    setState(() {
      final temp = _originController.text;
      _originController.text = _destinationController.text;
      _destinationController.text = temp;
    });
  }

  Future<void> _pickDate({required bool isReturn}) async {
    final now = DateTime.now();
    final initial = isReturn
        ? (_returnDate ?? _departureDate.add(const Duration(days: 7)))
        : _departureDate;
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
          if (_returnDate != null && _returnDate!.isBefore(_departureDate)) {
            _returnDate = _departureDate.add(const Duration(days: 7));
          }
        }
      });
    }
  }

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

    widget.onSearch(FlightSearchParams(
      origin: _originController.text.trim(),
      destination: _destinationController.text.trim(),
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
              final isCompact = constraints.maxWidth < 380 ||
                  (constraints.maxWidth < 460 && textScale > 1.15);

              final fromField = AirportAutocompleteField(
                controller: _originController,
                label: 'From',
                hint: 'Origin city or airport…',
                icon: Icons.flight_takeoff_rounded,
                bg: fieldBg,
                isDark: isDark,
              );

              final toField = AirportAutocompleteField(
                controller: _destinationController,
                label: 'To',
                hint: 'Destination city or airport…',
                icon: Icons.flight_land_rounded,
                bg: fieldBg,
                isDark: isDark,
              );

              if (isCompact) {
                return Column(
                  children: [
                    fromField,
                    const SizedBox(height: 6),
                    Center(
                      child: InkWell(
                        onTap: _swapLocations,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.iosBlue.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_vert_rounded, size: 15, color: AppColors.iosBlue),
                              const SizedBox(width: 4),
                              Text('Swap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.iosBlue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    toField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: fromField),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    tooltip: 'Swap locations',
                    onPressed: _swapLocations,
                    color: AppColors.iosBlue,
                  ),
                  Expanded(child: toField),
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

            if (isNarrow) {
              return Column(
                children: [
                  passTile,
                  const SizedBox(height: 10),
                  if (isVeryNarrow) ...[
                    classDrop,
                    const SizedBox(height: 10),
                    currDrop,
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: classDrop),
                        const SizedBox(width: 8),
                        Expanded(child: currDrop),
                      ],
                    ),
                  ],
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 3, child: passTile),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: classDrop),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: currDrop),
              ],
            );
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
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.iosBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: widget.isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.search_rounded, size: 18),
          label: Text(
            widget.isLoading ? 'Searching flights…' : 'Find Flights',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
