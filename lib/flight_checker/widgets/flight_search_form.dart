import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../models/flight_info.dart';
import '../services/flight_service.dart';
import '../utils/airport_data.dart';
import '../utils/currency_helper.dart';
import 'airport_autocomplete_field.dart';
import 'passenger_selector.dart';
import 'popup_selector_field.dart';

/// Flight search form component adhering to Vercel Web Interface Guidelines
class FlightSearchForm extends StatefulWidget {
  final FlightSearchParams initialParams;
  final ValueChanged<FlightSearchParams> onSearch;
  final ValueChanged<String>? onCurrencyChanged;
  final bool isLoading;

  const FlightSearchForm({
    super.key,
    required this.initialParams,
    required this.onSearch,
    this.onCurrencyChanged,
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

  @override
  void initState() {
    super.initState();
    final initialOrigin = AirportHelper.findBestAirport(widget.initialParams.origin);
    final initialDest = AirportHelper.findBestAirport(widget.initialParams.destination);

    _originController = TextEditingController(
      text: initialOrigin.isNotEmpty ? initialOrigin : widget.initialParams.origin,
    );
    _destinationController = TextEditingController(
      text: initialDest.isNotEmpty ? initialDest : widget.initialParams.destination,
    );

    _tripType = widget.initialParams.tripType;
    _departureDate = DateTime.tryParse(widget.initialParams.departureDate) ??
        DateTime.now().add(const Duration(days: 14));
    if (widget.initialParams.returnDate != null && widget.initialParams.returnDate!.isNotEmpty) {
      _returnDate = DateTime.tryParse(widget.initialParams.returnDate!);
    } else if (_tripType == 'roundtrip') {
      _returnDate = _departureDate.add(const Duration(days: 7));
    }
    _adults = widget.initialParams.adults.clamp(1, 9);
    _children = widget.initialParams.children.clamp(0, 8);
    _cabinClass = widget.initialParams.cabinClass;
    _currency = widget.initialParams.currency.isNotEmpty ? widget.initialParams.currency : 'MYR';
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
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
    final retStr = _returnDate != null ? DateFormat('yyyy-MM-dd').format(_returnDate!) : null;

    final params = FlightSearchParams(
      origin: _originController.text.trim(),
      destination: _destinationController.text.trim(),
      departureDate: depStr,
      returnDate: _tripType == 'roundtrip' ? retStr : null,
      tripType: _tripType,
      adults: _adults,
      children: _children,
      cabinClass: _cabinClass,
      currency: _currency,
    );

    widget.onSearch(params);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Trip Type Segmented Control
        _buildTripTypeSelector(isDark),
        const SizedBox(height: 14),

        // 2. If Multi-City, show specialized handoff notice
        if (_tripType == 'multicity') ...[
          _buildMultiCityBanner(isDark),
        ] else ...[
          // Origin & Destination with Autocomplete and Swap button
          Row(
            children: [
              Expanded(
                child: AirportAutocompleteField(
                  controller: _originController,
                  label: 'From',
                  hint: 'Origin city or airport…',
                  icon: Icons.flight_takeoff_rounded,
                  bg: fieldBg,
                  isDark: isDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded),
                tooltip: 'Swap locations',
                onPressed: _swapLocations,
                color: AppColors.iosBlue,
              ),
              Expanded(
                child: AirportAutocompleteField(
                  controller: _destinationController,
                  label: 'To',
                  hint: 'Destination city or airport…',
                  icon: Icons.flight_land_rounded,
                  bg: fieldBg,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date Pickers Row
          Row(
            children: [
              Expanded(
                child: _buildDateTile(
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
                  child: _buildDateTile(
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

          // Passengers, Class & Currency Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: PassengerTile(
                  adults: _adults,
                  children: _children,
                  isExpanded: _showPassengerPicker,
                  onTap: () => setState(() => _showPassengerPicker = !_showPassengerPicker),
                  bg: fieldBg,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _buildClassDropdown(fieldBg, isDark)),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _buildCurrencyDropdown(fieldBg, isDark)),
            ],
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
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.search_rounded, size: 18),
            label: Text(
              widget.isLoading ? 'Searching flights…' : 'Find Flights',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTripTypeSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightSecondaryBg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildSegment('oneway', 'One-Way'),
          _buildSegment('roundtrip', 'Round-Trip'),
          _buildSegment('multicity', 'Multi-City'),
        ],
      ),
    );
  }

  Widget _buildSegment(String key, String title) {
    final isSelected = _tripType == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tripType = key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.iosBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkSecondary : AppColors.lightSecondary),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildDateTile({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required Color fieldBg,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.iosBlue),
                const SizedBox(width: 8),
                Text(DateFormat('MMM d, yyyy').format(date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildClassDropdown(Color bg, bool isDark) {
    const items = [
      {'value': 'economy', 'label': 'Economy'},
      {'value': 'premiumeconomy', 'label': 'Premium'},
      {'value': 'business', 'label': 'Business'},
      {'value': 'first', 'label': 'First'},
    ];
    final display = items.firstWhere(
      (i) => i['value'] == _cabinClass,
      orElse: () => items.first,
    )['label']!;
    return PopupSelectorField(
      label: 'Class',
      value: _cabinClass,
      displayLabel: display,
      items: items,
      onSelected: (val) => setState(() => _cabinClass = val),
      bg: bg,
      isDark: isDark,
    );
  }

  Widget _buildCurrencyDropdown(Color bg, bool isDark) {
    final items = CurrencyHelper.supportedCurrencies
        .map((c) => {'value': c['code']!, 'label': c['label']!})
        .toList();
    return PopupSelectorField(
      label: 'Currency',
      value: _currency,
      displayLabel: CurrencyHelper.getLabel(_currency),
      items: items,
      onSelected: (val) {
        setState(() => _currency = val);
        widget.onCurrencyChanged?.call(val);
      },
      bg: bg,
      isDark: isDark,
    );
  }

  Widget _buildMultiCityBanner(bool isDark) {
    final fallbackUrl = FlightService.buildGoogleFlightsFallbackUrl(
      FlightSearchParams(
        origin: _originController.text,
        destination: _destinationController.text,
        departureDate: DateFormat('yyyy-MM-dd').format(_departureDate),
        tripType: 'multicity',
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.iosBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iosBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.iosBlue, size: 18),
              const SizedBox(width: 8),
              const Text('Multi-City Route Planning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Multi-city routes require interactive leg-by-leg selection. Open Google Flights directly to configure complex itineraries with real-time seat availability.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => FlightService.launchFlightUrl(fallbackUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.iosBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Configure on Google Flights', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
