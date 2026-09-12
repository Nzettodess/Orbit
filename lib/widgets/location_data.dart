/// Comprehensive location dataset and helper utilities for Orbit
/// Supports standard world countries, major states/provinces, and custom free-text locations.
library;

import 'location_database.dart';

class CountryInfo {
  final String name;
  final String code;
  final String flag;
  final List<String> states;

  const CountryInfo({
    required this.name,
    required this.code,
    required this.flag,
    this.states = const [],
  });

  /// Display label with flag emoji (e.g. "🇲🇾 Malaysia")
  String get displayLabel => flag.isNotEmpty ? "$flag $name" : name;

  @override
  String toString() => name;
}

/// A structured suggestion match that can represent a country or an individual state/city
class LocationMatch {
  final String countryName;
  final String? stateName;
  final String flag;
  final String code;
  final bool isState;

  const LocationMatch({
    required this.countryName,
    this.stateName,
    required this.flag,
    required this.code,
    this.isState = false,
  });

  /// Convenience aliases
  String get country => countryName;
  String? get state => stateName;

  /// Main title for autocomplete tile, e.g. "Bali, Indonesia" or "Indonesia"
  String get displayTitle =>
      isState && stateName != null ? '$stateName, $countryName' : countryName;

  /// Subtitle explaining the geographic level
  String get displaySubtitle =>
      isState ? 'State / Region in $countryName' : 'Country';

  @override
  String toString() => displayTitle;
}

class LocationData {
  /// Reference to standard world countries database
  static List<CountryInfo> get countries => kWorldCountries;

  /// Converts a 2-letter ISO country code into a flag emoji (e.g. "MY" -> "🇲🇾")
  static String countryCodeToEmoji(String code) {
    if (code.length != 2) return '';
    final upper = code.toUpperCase();
    final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    if (first < 0x1F1E6 || first > 0x1F1FF || second < 0x1F1E6 || second > 0x1F1FF) {
      return '';
    }
    return String.fromCharCode(first) + String.fromCharCode(second);
  }

  /// Removes emoji characters and flag symbols from text
  static String cleanText(String text) {
    return text
        .replaceAll(
          RegExp(
            r'[\u{1F1E6}-\u{1F1FF}]|\p{Emoji_Presentation}|\p{Emoji}\uFE0F',
            unicode: true,
          ),
          '',
        )
        .trim();
  }

  /// Popular quick-pick countries shown at top of selection
  static const List<String> popularCountryNames = [
    'Malaysia',
    'Singapore',
    'Indonesia',
    'Thailand',
    'Japan',
    'South Korea',
    'United States',
    'United Kingdom',
    'Australia',
    'China',
    'Hong Kong',
    'Taiwan',
    'Canada',
    'Germany',
    'France',
    'Vietnam',
  ];

  /// Find a country by name, case-insensitively
  static CountryInfo? findCountry(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final clean = cleanText(name).toLowerCase();
    for (final c in countries) {
      if (c.name.toLowerCase() == clean || c.code.toLowerCase() == clean) {
        return c;
      }
    }
    return null;
  }

  /// Search countries matching a query
  static List<CountryInfo> searchCountries(String query) {
    final cleanQuery = cleanText(query).toLowerCase().trim();
    if (cleanQuery.isEmpty) return countries;

    final prefixMatches = <CountryInfo>[];
    final otherMatches = <CountryInfo>[];

    for (final country in countries) {
      final countryName = country.name.toLowerCase();
      if (countryName.startsWith(cleanQuery) || country.code.toLowerCase().startsWith(cleanQuery)) {
        prefixMatches.add(country);
      } else if (countryName.contains(cleanQuery)) {
        otherMatches.add(country);
      }
    }

    return [...prefixMatches, ...otherMatches];
  }

  /// Search states for a specific country
  static List<String> searchStates(String? countryName, String query) {
    final country = findCountry(countryName);
    if (country == null || country.states.isEmpty) return [];

    final cleanQuery = cleanText(query).toLowerCase().trim();
    if (cleanQuery.isEmpty) return country.states;

    return country.states
        .where((s) => s.toLowerCase().contains(cleanQuery))
        .toList();
  }

  /// Smart unified search across both countries AND states/provinces/cities.
  /// If query is "Bali", it immediately surfaces:
  ///   LocationMatch(countryName: 'Indonesia', stateName: 'Bali', isState: true)
  static List<LocationMatch> searchLocations(String query) {
    final rawClean = cleanText(query).trim();
    if (rawClean.isEmpty) {
      return popularCountryNames.map((name) {
        final c = findCountry(name);
        if (c == null) return null;
        return LocationMatch(countryName: c.name, flag: c.flag, code: c.code, isState: false);
      }).whereType<LocationMatch>().toList();
    }

    // Handle comma or slash separated queries (e.g. "Bali, Indonesia" or "Indonesia, Bali")
    final separatorMatch = RegExp(r'[,•/-]').firstMatch(rawClean);
    if (separatorMatch != null) {
      final parts = rawClean.split(RegExp(r'[,•/-]')).map((p) => cleanText(p).trim()).toList();
      if (parts.length >= 2) {
        final p1 = parts[0].toLowerCase();
        final p2 = parts[1].toLowerCase();

        // Case 1: "State, Country" (e.g. "Bali, Indonesia")
        for (final c in countries) {
          if (c.name.toLowerCase() == p2 || c.name.toLowerCase().startsWith(p2)) {
            for (final s in c.states) {
              if (s.toLowerCase() == p1 || s.toLowerCase().startsWith(p1)) {
                return [
                  LocationMatch(countryName: c.name, stateName: s, flag: c.flag, code: c.code, isState: true),
                ];
              }
            }
          }
        }

        // Case 2: "Country, State" (e.g. "Indonesia, Bali")
        for (final c in countries) {
          if (c.name.toLowerCase() == p1 || c.name.toLowerCase().startsWith(p1)) {
            for (final s in c.states) {
              if (s.toLowerCase() == p2 || s.toLowerCase().startsWith(p2)) {
                return [
                  LocationMatch(countryName: c.name, stateName: s, flag: c.flag, code: c.code, isState: true),
                ];
              }
            }
          }
        }
      }
    }

    final cleanQuery = rawClean.toLowerCase();
    final exactStateMatches = <LocationMatch>[];
    final prefixStateMatches = <LocationMatch>[];
    final countryPrefixMatches = <LocationMatch>[];
    final otherStateMatches = <LocationMatch>[];
    final otherCountryMatches = <LocationMatch>[];

    for (final c in countries) {
      final cName = c.name.toLowerCase();
      final cCode = c.code.toLowerCase();

      // Check country name match
      if (cName == cleanQuery || cCode == cleanQuery) {
        countryPrefixMatches.insert(0, LocationMatch(countryName: c.name, flag: c.flag, code: c.code, isState: false));
      } else if (cName.startsWith(cleanQuery)) {
        countryPrefixMatches.add(LocationMatch(countryName: c.name, flag: c.flag, code: c.code, isState: false));
      } else if (cName.contains(cleanQuery)) {
        otherCountryMatches.add(LocationMatch(countryName: c.name, flag: c.flag, code: c.code, isState: false));
      }

      // Check states/provinces/cities in this country
      for (final s in c.states) {
        final sName = s.toLowerCase();
        if (sName == cleanQuery) {
          exactStateMatches.add(LocationMatch(countryName: c.name, stateName: s, flag: c.flag, code: c.code, isState: true));
        } else if (sName.startsWith(cleanQuery)) {
          prefixStateMatches.add(LocationMatch(countryName: c.name, stateName: s, flag: c.flag, code: c.code, isState: true));
        } else if (sName.contains(cleanQuery)) {
          otherStateMatches.add(LocationMatch(countryName: c.name, stateName: s, flag: c.flag, code: c.code, isState: true));
        }
      }
    }

    return [
      ...exactStateMatches,
      ...prefixStateMatches,
      ...countryPrefixMatches,
      ...otherStateMatches,
      ...otherCountryMatches,
    ];
  }

  /// Automatically resolve an ambiguous location string (e.g. "Bali") to its country and state
  static LocationMatch? resolveLocation(String locationString) {
    final matches = searchLocations(locationString);
    if (matches.isNotEmpty) return matches.first;
    return null;
  }
}
