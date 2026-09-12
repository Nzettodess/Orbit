import 'package:intl/intl.dart';

/// Currency conversion and formatting utilities for instant client-side repainting.
/// Strictly under 500 lines (Hard limit: 500 lines)
class CurrencyHelper {
  /// Reference exchange rates anchored to 1.0 USD (approximate market benchmark)
  static const Map<String, double> ratesToUsd = {
    'USD': 1.0,
    'MYR': 4.45,
    'SGD': 1.34,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 155.0,
    'AUD': 1.52,
    'CAD': 1.38,
    'CNY': 7.24,
    'THB': 36.5,
    'IDR': 16250.0,
    'TWD': 32.5,
    'KRW': 1375.0,
    'HKD': 7.82,
  };

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

  /// Format numeric price with appropriate symbol and commas
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

  /// Convert amount from one currency to another without making a network request
  static String convertAndFormat(
    num baseAmount, {
    required String from,
    required String to,
  }) {
    if (baseAmount <= 0) return '';
    final fromCode = from.toUpperCase();
    final toCode = to.toUpperCase();

    if (fromCode == toCode) {
      return formatAmount(baseAmount, fromCode);
    }

    final fromRate = ratesToUsd[fromCode] ?? 1.0;
    final toRate = ratesToUsd[toCode] ?? 1.0;

    // Convert: Base -> USD -> Target
    final amountInUsd = baseAmount / fromRate;
    final amountInTarget = amountInUsd * toRate;

    return formatAmount(amountInTarget, toCode);
  }
}
