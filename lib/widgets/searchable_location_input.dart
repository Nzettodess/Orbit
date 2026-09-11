import 'package:flutter/material.dart';
import 'location_data.dart';

/// A modern, responsive location input widget that supports:
/// 1. Instant search and autocomplete from standard world countries and states.
/// 2. 100% free-text input: type any country, province, or custom location.
/// 3. Click-stable suggestion overlays using TapRegion (prevents premature dismiss on web).
/// 4. One-tap popular country chips.
class SearchableLocationInput extends StatefulWidget {
  final String? initialCountry;
  final String? initialState;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String?> onStateChanged;

  const SearchableLocationInput({
    super.key,
    this.initialCountry,
    this.initialState,
    required this.onCountryChanged,
    required this.onStateChanged,
  });

  @override
  State<SearchableLocationInput> createState() => _SearchableLocationInputState();
}

class _SearchableLocationInputState extends State<SearchableLocationInput> {
  late final TextEditingController _countryController;
  late final TextEditingController _stateController;
  final FocusNode _countryFocus = FocusNode();
  final FocusNode _stateFocus = FocusNode();

  bool _showCountrySuggestions = false;
  bool _showStateSuggestions = false;
  List<CountryInfo> _countryMatches = [];
  List<String> _stateMatches = [];

  @override
  void initState() {
    super.initState();
    final cleanCountry = LocationData.cleanText(widget.initialCountry ?? '');
    final cleanState = LocationData.cleanText(widget.initialState ?? '');

    _countryController = TextEditingController(text: cleanCountry);
    _stateController = TextEditingController(text: cleanState);

    _countryMatches = LocationData.searchCountries(_countryController.text);
    _stateMatches = LocationData.searchStates(_countryController.text, _stateController.text);
  }

  @override
  void didUpdateWidget(covariant SearchableLocationInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCountry != oldWidget.initialCountry) {
      final clean = LocationData.cleanText(widget.initialCountry ?? '');
      if (clean != _countryController.text) {
        _countryController.text = clean;
        _countryMatches = LocationData.searchCountries(clean);
        _stateMatches = LocationData.searchStates(clean, _stateController.text);
      }
    }
    if (widget.initialState != oldWidget.initialState) {
      final clean = LocationData.cleanText(widget.initialState ?? '');
      if (clean != _stateController.text) {
        _stateController.text = clean;
        _stateMatches = LocationData.searchStates(_countryController.text, clean);
      }
    }
  }

  @override
  void dispose() {
    _countryController.dispose();
    _stateController.dispose();
    _countryFocus.dispose();
    _stateFocus.dispose();
    super.dispose();
  }

  void _onCountryTextChanged(String val) {
    final cleaned = LocationData.cleanText(val);
    widget.onCountryChanged(cleaned);
    setState(() {
      _showCountrySuggestions = true;
      _countryMatches = LocationData.searchCountries(cleaned);
      _stateMatches = LocationData.searchStates(cleaned, _stateController.text);
    });
  }

  void _selectCountry(CountryInfo country) {
    _countryController.text = country.name;
    widget.onCountryChanged(country.name);
    _countryFocus.unfocus();
    setState(() {
      _showCountrySuggestions = false;
      _countryMatches = LocationData.searchCountries(country.name);
      _stateMatches = LocationData.searchStates(country.name, _stateController.text);
    });
  }

  void _selectCustomCountry(String customText) {
    final cleaned = LocationData.cleanText(customText);
    _countryController.text = cleaned;
    widget.onCountryChanged(cleaned);
    _countryFocus.unfocus();
    setState(() {
      _showCountrySuggestions = false;
    });
  }

  void _onStateTextChanged(String val) {
    final cleaned = LocationData.cleanText(val);
    widget.onStateChanged(cleaned.isEmpty ? null : cleaned);
    setState(() {
      _showStateSuggestions = true;
      _stateMatches = LocationData.searchStates(_countryController.text, cleaned);
    });
  }

  void _selectState(String stateName) {
    _stateController.text = stateName;
    widget.onStateChanged(stateName);
    _stateFocus.unfocus();
    setState(() {
      _showStateSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentCountry = LocationData.findCountry(_countryController.text);
    final currentFlag = currentCountry?.flag ?? (LocationData.cleanText(_countryController.text).isNotEmpty ? '📍' : '🌍');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // COUNTRY SECTION (Using TapRegion to prevent focus-drop on click)
        TapRegion(
          groupId: 'country_search_region',
          onTapOutside: (_) {
            if (_showCountrySuggestions && mounted) {
              setState(() => _showCountrySuggestions = false);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Country / Location",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('location_country_field'),
                controller: _countryController,
                focusNode: _countryFocus,
                onTap: () {
                  setState(() {
                    _showCountrySuggestions = true;
                    _countryMatches = LocationData.searchCountries(_countryController.text);
                  });
                },
                onChanged: _onCountryTextChanged,
                decoration: InputDecoration(
                  hintText: "Search country or type custom location...",
                  prefixIcon: Center(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10, top: 3.0),
                      child: Text(
                        currentFlag,
                        style: const TextStyle(fontSize: 19, height: 1.0),
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 0),
                  suffixIcon: _countryController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _countryController.clear();
                            _onCountryTextChanged('');
                          },
                          tooltip: 'Clear',
                        )
                      : const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),

              // COUNTRY SUGGESTIONS OVERLAY
              if (_showCountrySuggestions) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: [
                        // Custom location tile if user typed text
                        if (_countryController.text.trim().isNotEmpty &&
                            !LocationData.countries.any((c) =>
                                c.name.toLowerCase() == _countryController.text.trim().toLowerCase()))
                          Material(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.15),
                            child: InkWell(
                              onTap: () => _selectCustomCountry(_countryController.text.trim()),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.add_location_alt_outlined, color: Colors.blue, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Use custom location: "${_countryController.text.trim()}"',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ..._countryMatches.take(20).map((country) => Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectCountry(country),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    children: [
                                      Text(country.flag, style: const TextStyle(fontSize: 20)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          country.name,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        country.code,
                                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ] else if (_countryController.text.isEmpty) ...[
                // Popular country quick chips
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: LocationData.popularCountryNames.map((name) {
                      final c = LocationData.findCountry(name);
                      if (c == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          avatar: Text(c.flag, style: const TextStyle(fontSize: 14)),
                          label: Text(c.name, style: const TextStyle(fontSize: 12)),
                          onPressed: () => _selectCountry(c),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // STATE / REGION SECTION (Using TapRegion to prevent focus-drop on click)
        TapRegion(
          groupId: 'state_search_region',
          onTapOutside: (_) {
            if (_showStateSuggestions && mounted) {
              setState(() => _showStateSuggestions = false);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "State / Province / City (Optional)",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                    ),
                  ),
                  if (currentCountry != null && currentCountry.states.isNotEmpty)
                    Text(
                      "${currentCountry.states.length} known regions",
                      style: TextStyle(fontSize: 11, color: theme.hintColor),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('location_state_field'),
                controller: _stateController,
                focusNode: _stateFocus,
                onTap: () {
                  setState(() {
                    _showStateSuggestions = true;
                    _stateMatches = LocationData.searchStates(_countryController.text, _stateController.text);
                  });
                },
                onChanged: _onStateTextChanged,
                decoration: InputDecoration(
                  hintText: "Select or type state, province, or city...",
                  prefixIcon: const Icon(Icons.location_city, size: 20),
                  suffixIcon: _stateController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _stateController.clear();
                            _onStateTextChanged('');
                          },
                          tooltip: 'Clear',
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),

              // STATE SUGGESTIONS OVERLAY
              if (_showStateSuggestions && _stateMatches.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: [
                        if (_stateController.text.trim().isNotEmpty &&
                            !_stateMatches.any((s) =>
                                s.toLowerCase() == _stateController.text.trim().toLowerCase()))
                          Material(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.15),
                            child: InkWell(
                              onTap: () {
                                _selectState(_stateController.text.trim());
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_location_alt_outlined, color: Colors.blue, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Use custom region: "${_stateController.text.trim()}"',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ..._stateMatches.take(15).map((stateName) => Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectState(stateName),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.place, size: 18, color: Colors.grey),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          stateName,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ] else if (!_showStateSuggestions &&
                  _stateController.text.isEmpty &&
                  currentCountry != null &&
                  currentCountry.states.isNotEmpty) ...[
                // Quick state chips when state is empty
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: currentCountry.states.take(8).map((stateName) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(stateName, style: const TextStyle(fontSize: 12)),
                          onPressed: () => _selectState(stateName),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
