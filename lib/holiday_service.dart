import 'dart:convert';
import 'package:http/http.dart' as http;

class Holiday {
  final DateTime date;
  final String localName;
  final String name;
  final String countryCode;

  Holiday({
    required this.date,
    required this.localName,
    required this.name,
    required this.countryCode,
  });

  factory Holiday.fromJsonCalendarific(Map<String, dynamic> json) {
    return Holiday(
      date: DateTime.parse(json['date']['iso']),
      localName: json['name'] ?? '',
      name: json['name'] ?? '',
      countryCode: json['country']['id'] ?? '',
    );
  }

  factory Holiday.fromJsonFestivo(Map<String, dynamic> json) {
    return Holiday(
      date: DateTime.parse(json['date']),
      localName: json['name'] ?? '',
      name: json['name'] ?? '',
      countryCode: json['country'] ?? '',
    );
  }
}

class HolidayService {
  // Calendarific API: https://calendarific.com/api/v2/holidays
  static const String _calendarificBaseUrl = 'https://calendarific.com/api/v2/holidays';
  static const String _calendarificApiKey = 'XMBhtunafLI3sUlOXnlEDC6hpAnxPlj4';

  // Festivo API: https://api.getfestivo.com/v3/holidays
  static const String _festivoBaseUrl = 'https://api.getfestivo.com/v3/holidays';
  static const String _festivoApiKey = 'tok_v3_PYnebUWSMSTXIYwUySQgyE34ev7pliKaLBXMemQ603fqqG9M';

  Future<List<Holiday>> fetchHolidays(String countryCode, int year, {String provider = 'Calendarific'}) async {
    if (provider == 'Festivo') {
      return _fetchFestivo(countryCode, year);
    } else {
      return _fetchCalendarific(countryCode, year);
    }
  }

  Future<List<Holiday>> _fetchCalendarific(String countryCode, int year) async {
    try {
      final response = await http.get(Uri.parse('$_calendarificBaseUrl?api_key=$_calendarificApiKey&country=$countryCode&year=$year'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final holidays = data['response']['holidays'] as List<dynamic>;
        return holidays.map((json) => Holiday.fromJsonCalendarific(json)).toList();
      } else {
        print('Calendarific Failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching Calendarific: $e');
      return [];
    }
  }

  Future<List<Holiday>> _fetchFestivo(String countryCode, int year) async {
    // Festivo API requires a paid plan (returns 402 Payment Required)
    // Keeping code for reference but returning empty list
    print('Festivo API requires a paid subscription plan. Please use Calendarific instead.');
    return [];
    
    /* Original Festivo code - requires paid plan
    try {
      final response = await http.get(
        Uri.parse('$_festivoBaseUrl?country=$countryCode&year=$year'),
        headers: {
          'Authorization': 'Bearer $_festivoApiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final holidays = data['holidays'] as List<dynamic>;
        return holidays.map((json) => Holiday.fromJsonFestivo(json)).toList();
      } else {
        print('Festivo Failed: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching Festivo: $e');
      return [];
    }
    */
  }
}
