import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/flight_info.dart';

/// Structured price range summary computed directly from live flight search results.
@immutable
class PriceRange {
  final int min;
  final int max;
  final int average;
  final String currency;
  final String minFormatted;
  final String maxFormatted;
  final String avgFormatted;
  final String bestAirline;

  const PriceRange({
    required this.min,
    required this.max,
    required this.average,
    required this.currency,
    required this.minFormatted,
    required this.maxFormatted,
    required this.avgFormatted,
    required this.bestAirline,
  });
}

/// Currency formatting and live fare range utilities.
/// Pure live data from Google Flights — zero hardcoded exchange rates.
/// Strictly under 500 lines (Hard limit: 500 lines)
class CurrencyHelper {
  /// Currency dropdown options for selector UI
  static const List<Map<String, String>> supportedCurrencies = [
    {'code': 'MYR', 'label': 'MYR (RM)'},
    {'code': 'USD', 'label': 'USD (\$)'},
    {'code': 'SGD', 'label': 'SGD (S\$)'},
    {'code': 'EUR', 'label': 'EUR (€)'},
    {'code': 'GBP', 'label': 'GBP (£)'},
    {'code': 'JPY', 'label': 'JPY (¥)'},
    {'code': 'AUD', 'label': 'AUD (A\$)'},
    {'code': 'CAD', 'label': 'CAD (C\$)'},
    {'code': 'CNY', 'label': 'CNY (¥)'},
    {'code': 'THB', 'label': 'THB (฿)'},
    {'code': 'IDR', 'label': 'IDR (Rp)'},
  ];

  /// Format numeric price with standard currency symbols and commas
  static String formatAmount(num amount, String currencyCode) {
    final code = currencyCode.toUpperCase();
    final formatter = NumberFormat('#,###');
    final rounded = amount.round();
    final formatted = formatter.format(rounded);

    switch (code) {
      case 'MYR':
        return 'RM $formatted';
      case 'USD':
        return '\$$formatted';
      case 'SGD':
        return 'S\$$formatted';
      case 'EUR':
        return '€$formatted';
      case 'GBP':
        return '£$formatted';
      case 'JPY':
        return '¥$formatted';
      case 'AUD':
        return 'A\$$formatted';
      case 'CAD':
        return 'C\$$formatted';
      case 'CNY':
        return '¥$formatted';
      case 'THB':
        return '฿$formatted';
      case 'IDR':
        return 'Rp $formatted';
      case 'TWD':
        return 'NT\$$formatted';
      case 'KRW':
        return '₩$formatted';
      case 'HKD':
        return 'HK\$$formatted';
      default:
        return '$code $formatted';
    }
  }

  /// Calculates the live price range (min, max, average, lowest airline) directly
  /// from Google Flights results.
  static PriceRange? calculatePriceRange(List<FlightInfo> flights, String currency) {
    final priced = flights.where((f) => f.priceNumeric > 0).toList();
    if (priced.isEmpty) return null;

    priced.sort((a, b) => a.priceNumeric.compareTo(b.priceNumeric));
    final min = priced.first.priceNumeric;
    final max = priced.last.priceNumeric;
    final sum = priced.fold<int>(0, (prev, f) => prev + f.priceNumeric);
    final avg = (sum / priced.length).round();

    return PriceRange(
      min: min,
      max: max,
      average: avg,
      currency: currency,
      minFormatted: formatAmount(min, currency),
      maxFormatted: formatAmount(max, currency),
      avgFormatted: formatAmount(avg, currency),
      bestAirline: priced.first.airline,
    );
  }
}
