import 'package:flutter/material.dart';
import 'location_data.dart';
import 'location_input_tiles.dart';

/// A modern, responsive location input widget that supports:
/// 1. Instant smart search across countries, states, provinces, and cities (e.g. "Bali" -> Indonesia, Bali).
/// 2. 100% free-text input: type any country, province, or custom location.
/// 3. Click-stable suggestion overlays using TapRegion (prevents premature dismiss on web).
/// 4. One-tap popular country and state chips.
/// Strictly under 500 lines (Hard limit: 500 lines)
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
  List<LocationMatch> _locationMatches = [];
  List<String> _stateMatches = [];

  @override
  void initState() {
    super.initState();
    final cleanCountry = LocationData.cleanText(widget.initialCountry ?? '');
    final cleanState = LocationData.cleanText(widget.initialState ?? '');

    _countryController = TextEditingController(text: cleanCountry);
    _stateController = TextEditingController(text: cleanState);

    _locationMatches = LocationData.searchLocations(_countryController.text);
    _stateMatches = LocationData.searchStates(_countryController.text, _stateController.text);
  }

  @override
  void didUpdateWidget(covariant SearchableLocationInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCountry != oldWidget.initialCountry) {
      final clean = LocationData.cleanText(widget.initialCountry ?? '');
      if (clean != _countryController.text) {
        _countryController.text = clean;
        _locationMatches = LocationData.searchLocations(clean);
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

    // Check if user typed "State, Country" or "Country, State" directly
    final resolved = LocationData.resolveLocation(cleaned);
    if (resolved != null && resolved.isState && resolved.stateName != null) {
      if (cleaned.contains(',')) {
        _countryController.text = resolved.countryName;
        _stateController.text = resolved.stateName!;
        widget.onCountryChanged(resolved.countryName);
        widget.onStateChanged(resolved.stateName);
        setState(() {
          _showCountrySuggestions = false;
          _locationMatches = LocationData.searchLocations(resolved.countryName);
          _stateMatches = LocationData.searchStates(resolved.countryName, resolved.stateName!);
        });
        return;
      }
    }

    widget.onCountryChanged(cleaned);
    setState(() {
      _showCountrySuggestions = true;
      _locationMatches = LocationData.searchLocations(cleaned);
      _stateMatches = LocationData.searchStates(cleaned, _stateController.text);
    });
  }

  void _selectLocationMatch(LocationMatch match) {
    _countryController.text = match.countryName;
    widget.onCountryChanged(match.countryName);

    if (match.isState && match.stateName != null) {
      _stateController.text = match.stateName!;
      widget.onStateChanged(match.stateName);
    } else {
      _stateController.clear();
      widget.onStateChanged(null);
    }

    _countryFocus.unfocus();
    setState(() {
      _showCountrySuggestions = false;
      _locationMatches = LocationData.searchLocations(match.countryName);
      _stateMatches = LocationData.searchStates(match.countryName, _stateController.text);
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
        // COUNTRY / LOCATION SECTION (Using TapRegion to prevent focus-drop on click)
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
                    _locationMatches = LocationData.searchLocations(_countryController.text);
                  });
                },
                onChanged: _onCountryTextChanged,
                decoration: InputDecoration(
                  hintText: "Search country or city (e.g. Bali, Tokyo, Paris)…",
                  prefixIcon: Center(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10, top: 1.0),
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
                          tooltip: 'Clear input',
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

              // COUNTRY / CITY SUGGESTIONS OVERLAY
              if (_showCountrySuggestions) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 240),
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
                        if (_countryController.text.trim().isNotEmpty &&
                            !LocationData.countries.any((c) =>
                                c.name.toLowerCase() == _countryController.text.trim().toLowerCase()))
                          LocationCustomTile(
                            text: _countryController.text.trim(),
                            labelPrefix: 'Use custom location',
                            onTap: () => _selectCustomCountry(_countryController.text.trim()),
                          ),
                        ..._locationMatches.take(20).map((match) => LocationSuggestionTile(
                              match: match,
                              onTap: () => _selectLocationMatch(match),
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
                          onPressed: () => _selectLocationMatch(
                            LocationMatch(countryName: c.name, flag: c.flag, code: c.code, isState: false),
                          ),
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
                  hintText: "Select or type state, province, or city…",
                  prefixIcon: const Icon(Icons.location_city, size: 20),
                  suffixIcon: _stateController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _stateController.clear();
                            _onStateTextChanged('');
                          },
                          tooltip: 'Clear input',
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
                          LocationCustomTile(
                            text: _stateController.text.trim(),
                            labelPrefix: 'Use custom region',
                            onTap: () => _selectState(_stateController.text.trim()),
                          ),
                        ..._stateMatches.take(15).map((stateName) => Material(
                              color: Colors.transparent,
                              child: InkWell(
                                mouseCursor: SystemMouseCursors.click,
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
