import 'package:flutter/foundation.dart';

/// Airport and city metadata for autocomplete and intelligent location mapping
@immutable
class AirportOption {
  final String code;
  final String city;
  final String country;
  final String name;

  const AirportOption({
    required this.code,
    required this.city,
    required this.country,
    required this.name,
  });

  /// Display string e.g. "Kuala Lumpur (KUL) - Malaysia"
  String get displayLabel => '$city ($code) - $country';

  /// Compact string e.g. "Kuala Lumpur (KUL)"
  String get shortLabel => '$city ($code)';
}

/// Curated registry of international airports with fast fuzzy matching
class AirportHelper {
  static const List<AirportOption> airports = [
    // Malaysia
    AirportOption(code: 'KUL', city: 'Kuala Lumpur', country: 'Malaysia', name: 'Kuala Lumpur International Airport'),
    AirportOption(code: 'PEN', city: 'Penang', country: 'Malaysia', name: 'Penang International Airport'),
    AirportOption(code: 'BKI', city: 'Kota Kinabalu', country: 'Malaysia', name: 'Kota Kinabalu International Airport'),
    AirportOption(code: 'JHB', city: 'Johor Bahru', country: 'Malaysia', name: 'Senai International Airport'),
    AirportOption(code: 'KCH', city: 'Kuching', country: 'Malaysia', name: 'Kuching International Airport'),
    AirportOption(code: 'LGK', city: 'Langkawi', country: 'Malaysia', name: 'Langkawi International Airport'),
    AirportOption(code: 'SZB', city: 'Subang', country: 'Malaysia', name: 'Sultan Abdul Aziz Shah Airport'),
    AirportOption(code: 'MYY', city: 'Miri', country: 'Malaysia', name: 'Miri Airport'),

    // Singapore
    AirportOption(code: 'SIN', city: 'Singapore', country: 'Singapore', name: 'Singapore Changi Airport'),

    // Thailand
    AirportOption(code: 'BKK', city: 'Bangkok', country: 'Thailand', name: 'Suvarnabhumi Airport'),
    AirportOption(code: 'DMK', city: 'Bangkok', country: 'Thailand', name: 'Don Mueang International Airport'),
    AirportOption(code: 'HKT', city: 'Phuket', country: 'Thailand', name: 'Phuket International Airport'),
    AirportOption(code: 'CNX', city: 'Chiang Mai', country: 'Thailand', name: 'Chiang Mai International Airport'),
    AirportOption(code: 'KBV', city: 'Krabi', country: 'Thailand', name: 'Krabi International Airport'),

    // Indonesia
    AirportOption(code: 'DPS', city: 'Bali', country: 'Indonesia', name: 'Ngurah Rai International Airport'),
    AirportOption(code: 'CGK', city: 'Jakarta', country: 'Indonesia', name: 'Soekarno-Hatta International Airport'),
    AirportOption(code: 'SUB', city: 'Surabaya', country: 'Indonesia', name: 'Juanda International Airport'),

    // Vietnam & Philippines
    AirportOption(code: 'SGN', city: 'Ho Chi Minh City', country: 'Vietnam', name: 'Tan Son Nhat International Airport'),
    AirportOption(code: 'HAN', city: 'Hanoi', country: 'Vietnam', name: 'Noi Bai International Airport'),
    AirportOption(code: 'DAD', city: 'Da Nang', country: 'Vietnam', name: 'Da Nang International Airport'),
    AirportOption(code: 'MNL', city: 'Manila', country: 'Philippines', name: 'Ninoy Aquino International Airport'),
    AirportOption(code: 'CEB', city: 'Cebu', country: 'Philippines', name: 'Mactan-Cebu International Airport'),

    // East Asia
    AirportOption(code: 'HND', city: 'Tokyo', country: 'Japan', name: 'Tokyo Haneda Airport'),
    AirportOption(code: 'NRT', city: 'Tokyo', country: 'Japan', name: 'Narita International Airport'),
    AirportOption(code: 'KIX', city: 'Osaka', country: 'Japan', name: 'Kansai International Airport'),
    AirportOption(code: 'FUK', city: 'Fukuoka', country: 'Japan', name: 'Fukuoka Airport'),
    AirportOption(code: 'CTS', city: 'Sapporo', country: 'Japan', name: 'New Chitose Airport'),
    AirportOption(code: 'ICN', city: 'Seoul', country: 'South Korea', name: 'Incheon International Airport'),
    AirportOption(code: 'GMP', city: 'Seoul', country: 'South Korea', name: 'Gimpo International Airport'),
    AirportOption(code: 'PUS', city: 'Busan', country: 'South Korea', name: 'Gimhae International Airport'),
    AirportOption(code: 'TPE', city: 'Taipei', country: 'Taiwan', name: 'Taoyuan International Airport'),
    AirportOption(code: 'KHH', city: 'Kaohsiung', country: 'Taiwan', name: 'Kaohsiung International Airport'),
    AirportOption(code: 'HKG', city: 'Hong Kong', country: 'Hong Kong', name: 'Hong Kong International Airport'),
    AirportOption(code: 'MFM', city: 'Macau', country: 'Macau', name: 'Macau International Airport'),
    AirportOption(code: 'PVG', city: 'Shanghai', country: 'China', name: 'Shanghai Pudong International Airport'),
    AirportOption(code: 'PEK', city: 'Beijing', country: 'China', name: 'Beijing Capital International Airport'),
    AirportOption(code: 'CAN', city: 'Guangzhou', country: 'China', name: 'Guangzhou Baiyun International Airport'),

    // Australia & New Zealand
    AirportOption(code: 'SYD', city: 'Sydney', country: 'Australia', name: 'Sydney Kingsford Smith Airport'),
    AirportOption(code: 'MEL', city: 'Melbourne', country: 'Australia', name: 'Melbourne Airport'),
    AirportOption(code: 'BNE', city: 'Brisbane', country: 'Australia', name: 'Brisbane Airport'),
    AirportOption(code: 'PER', city: 'Perth', country: 'Australia', name: 'Perth Airport'),
    AirportOption(code: 'AKL', city: 'Auckland', country: 'New Zealand', name: 'Auckland Airport'),

    // Europe
    AirportOption(code: 'LHR', city: 'London', country: 'United Kingdom', name: 'Heathrow Airport'),
    AirportOption(code: 'LGW', city: 'London', country: 'United Kingdom', name: 'Gatwick Airport'),
    AirportOption(code: 'CDG', city: 'Paris', country: 'France', name: 'Charles de Gaulle Airport'),
    AirportOption(code: 'AMS', city: 'Amsterdam', country: 'Netherlands', name: 'Amsterdam Airport Schiphol'),
    AirportOption(code: 'FRA', city: 'Frankfurt', country: 'Germany', name: 'Frankfurt Airport'),
    AirportOption(code: 'MUC', city: 'Munich', country: 'Germany', name: 'Munich Airport'),
    AirportOption(code: 'ZRH', city: 'Zurich', country: 'Switzerland', name: 'Zurich Airport'),
    AirportOption(code: 'FCO', city: 'Rome', country: 'Italy', name: 'Leonardo da Vinci-Fiumicino Airport'),
    AirportOption(code: 'BCN', city: 'Barcelona', country: 'Spain', name: 'Josep Tarradellas Barcelona-El Prat'),
    AirportOption(code: 'MAD', city: 'Madrid', country: 'Spain', name: 'Adolfo Suárez Madrid-Barajas'),
    AirportOption(code: 'IST', city: 'Istanbul', country: 'Turkey', name: 'Istanbul Airport'),

    // Middle East
    AirportOption(code: 'DXB', city: 'Dubai', country: 'United Arab Emirates', name: 'Dubai International Airport'),
    AirportOption(code: 'DOH', city: 'Doha', country: 'Qatar', name: 'Hamad International Airport'),

    // North America
    AirportOption(code: 'JFK', city: 'New York', country: 'United States', name: 'John F. Kennedy International Airport'),
    AirportOption(code: 'EWR', city: 'New York', country: 'United States', name: 'Newark Liberty International Airport'),
    AirportOption(code: 'LAX', city: 'Los Angeles', country: 'United States', name: 'Los Angeles International Airport'),
    AirportOption(code: 'SFO', city: 'San Francisco', country: 'United States', name: 'San Francisco International Airport'),
    AirportOption(code: 'ORD', city: 'Chicago', country: 'United States', name: "O'Hare International Airport"),
    AirportOption(code: 'YVR', city: 'Vancouver', country: 'Canada', name: 'Vancouver International Airport'),
    AirportOption(code: 'YYZ', city: 'Toronto', country: 'Canada', name: 'Toronto Pearson International Airport'),
  ];

  /// Search for matching airports by code, city, or country
  static List<AirportOption> searchAirports(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return airports.take(8).toList();

    return airports.where((a) {
      return a.code.toLowerCase().contains(q) ||
          a.city.toLowerCase().contains(q) ||
          a.country.toLowerCase().contains(q) ||
          a.name.toLowerCase().contains(q);
    }).take(10).toList();
  }

  /// Common aliases and shorthand mapping to airport codes
  static const Map<String, String> cityAliases = {
    'nyc': 'JFK',
    'newyork': 'JFK',
    'newyorkcity': 'JFK',
    'kl': 'KUL',
    'jb': 'JHB',
    'sf': 'SFO',
    'la': 'LAX',
    'sg': 'SIN',
    'bkk': 'BKK',
    'hkg': 'HKG',
    'tyo': 'HND',
    'sel': 'ICN',
  };

  /// Automatically resolve a freeform location string (e.g. "Malaysia, Penang" or "Tokyo, Japan")
  /// to the best matching airport label (e.g. "Penang (PEN)" or "Tokyo (HND)").
  static String findBestAirport(String? locationString) {
    if (locationString == null || locationString.trim().isEmpty) return '';
    
    // Clean emojis and extra punctuation
    final cleaned = locationString.replaceAll(RegExp(r'[\u{1F1E6}-\u{1F1FF}]', unicode: true), '').trim();
    final parts = cleaned.split(RegExp(r'[,•/-]')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

    // 0. Check exact alias on full string
    final fullCleanedNorm = cleaned.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
    if (cityAliases.containsKey(fullCleanedNorm)) {
      final code = cityAliases[fullCleanedNorm]!;
      final match = airports.firstWhere((a) => a.code == code, orElse: () => const AirportOption(code: '', city: '', country: '', name: ''));
      if (match.code.isNotEmpty) return match.shortLabel;
    }

    // 1. Try matching each part from specific (state/city) to broad (country)
    for (int i = parts.length - 1; i >= 0; i--) {
      final part = parts[i].toLowerCase();
      final partNorm = part.replaceAll(RegExp(r'[\s\-_]'), '');

      if (cityAliases.containsKey(partNorm)) {
        final code = cityAliases[partNorm]!;
        final match = airports.firstWhere((a) => a.code == code, orElse: () => const AirportOption(code: '', city: '', country: '', name: ''));
        if (match.code.isNotEmpty) return match.shortLabel;
      }

      final match = airports.firstWhere(
        (a) {
          final cityLower = a.city.toLowerCase();
          final cityNorm = cityLower.replaceAll(RegExp(r'[\s\-_]'), '');
          return cityLower == part ||
              cityNorm == partNorm ||
              (partNorm.contains(cityNorm) && cityNorm.length >= 3) ||
              (cityNorm.contains(partNorm) && partNorm.length >= 3) ||
              a.name.toLowerCase().contains(part) ||
              a.code.toLowerCase() == partNorm;
        },
        orElse: () => const AirportOption(code: '', city: '', country: '', name: ''),
      );
      if (match.code.isNotEmpty) {
        return match.shortLabel;
      }
    }

    // 2. Try matching country level
    for (final part in parts) {
      final partLower = part.toLowerCase();
      final partNorm = partLower.replaceAll(RegExp(r'[\s\-_]'), '');
      final match = airports.firstWhere(
        (a) {
          final countryLower = a.country.toLowerCase();
          final countryNorm = countryLower.replaceAll(RegExp(r'[\s\-_]'), '');
          return countryLower == partLower || countryNorm == partNorm;
        },
        orElse: () => const AirportOption(code: '', city: '', country: '', name: ''),
      );
      if (match.code.isNotEmpty) {
        return match.shortLabel;
      }
    }

    // Fallback: return the first clean component
    return parts.isNotEmpty ? parts.first : cleaned;
  }

  /// Cleans an airport label like "Penang (PEN)" or "Tokyo (HND)" to the pure city name "Penang" or "Tokyo"
  static String cleanLocationName(String? input) {
    if (input == null || input.trim().isEmpty) return '';
    final trimmed = input.trim();
    final match = RegExp(r'^(.+?)\s*\([A-Z0-9]{3}\)$').firstMatch(trimmed);
    if (match != null) {
      return match.group(1)!.trim();
    }
    return trimmed;
  }

  /// Checks if a given location string maps to a recognized airport with an IATA code
  static bool hasKnownAirport(String? locationString) {
    if (locationString == null || locationString.trim().isEmpty) return false;
    final best = findBestAirport(locationString);
    return RegExp(r'\([A-Z0-9]{3}\)').hasMatch(best);
  }
}
