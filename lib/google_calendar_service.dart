import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'environment.dart';

class GoogleCalendarService {
  static String get _apiKey => Environment.googleCalendarApiKey;
  static const String _baseUrl = 'https://www.googleapis.com/calendar/v3/calendars';

  // Country calendar IDs
  static const Map<String, String> countryCalendars = {
    'MY': 'en-gb.malaysia#holiday@group.v.calendar.google.com',
    'US': 'en.usa#holiday@group.v.calendar.google.com',
    'GB': 'en.uk#holiday@group.v.calendar.google.com',
    'CA': 'en.canadian#holiday@group.v.calendar.google.com',
    'AU': 'en.australian#holiday@group.v.calendar.google.com',
    'NZ': 'en.new_zealand#holiday@group.v.calendar.google.com',
    'SG': 'en.singapore#holiday@group.v.calendar.google.com',
    'ID': 'en.indonesian#holiday@group.v.calendar.google.com',
    'TH': 'en.th#holiday@group.v.calendar.google.com',
    'PH': 'en.philippines#holiday@group.v.calendar.google.com',
    'VN': 'en.vietnamese#holiday@group.v.calendar.google.com',
    'JP': 'en.japanese#holiday@group.v.calendar.google.com',
    'KR': 'en.south_korea#holiday@group.v.calendar.google.com',
    'CN': 'zh.china#holiday@group.v.calendar.google.com',
    'HK': 'zh_hk.hong_kong#holiday@group.v.calendar.google.com',
    'TW': 'zh_tw.taiwan#holiday@group.v.calendar.google.com',
    'IN': 'en.indian#holiday@group.v.calendar.google.com',
    'DE': 'en.german#holiday@group.v.calendar.google.com',
    'FR': 'en.french#holiday@group.v.calendar.google.com',
    'IT': 'en.italian#holiday@group.v.calendar.google.com',
    'ES': 'en.spanish#holiday@group.v.calendar.google.com',
    'NL': 'en.dutch#holiday@group.v.calendar.google.com',
    'BE': 'en.be#holiday@group.v.calendar.google.com',
    'CH': 'en.ch#holiday@group.v.calendar.google.com',
    'AT': 'en.austrian#holiday@group.v.calendar.google.com',
    'SE': 'en.swedish#holiday@group.v.calendar.google.com',
    'NO': 'en.norwegian#holiday@group.v.calendar.google.com',
    'DK': 'en.danish#holiday@group.v.calendar.google.com',
    'FI': 'en.finnish#holiday@group.v.calendar.google.com',
    'PL': 'en.polish#holiday@group.v.calendar.google.com',
    'IE': 'en.irish#holiday@group.v.calendar.google.com',
    'PT': 'en.portuguese#holiday@group.v.calendar.google.com',
    'GR': 'en.greek#holiday@group.v.calendar.google.com',
    'BR': 'en.brazilian#holiday@group.v.calendar.google.com',
    'MX': 'en.mexican#holiday@group.v.calendar.google.com',
    'AR': 'en.ar#holiday@group.v.calendar.google.com',
    'CL': 'en.cl#holiday@group.v.calendar.google.com',
    'CO': 'en.co#holiday@group.v.calendar.google.com',
    'ZA': 'en.sa#holiday@group.v.calendar.google.com',
    'EG': 'en.eg#holiday@group.v.calendar.google.com',
    'NG': 'en.ng#holiday@group.v.calendar.google.com',
    'RU': 'en.russian#holiday@group.v.calendar.google.com',
    'TR': 'en.turkish#holiday@group.v.calendar.google.com',
    'SA': 'en.sa#holiday@group.v.calendar.google.com',
    'AE': 'en.ae#holiday@group.v.calendar.google.com',
    'IL': 'en.jewish#holiday@group.v.calendar.google.com',
  };

  // Religious calendar IDs
  static const Map<String, String> religiousCalendars = {
    'islamic': 'en.islamic#holiday@group.v.calendar.google.com',
    'chinese': 'zh.china#holiday@group.v.calendar.google.com',
    'jewish': 'en.jewish#holiday@group.v.calendar.google.com',
    'hindu': 'en.indian#holiday@group.v.calendar.google.com',
    'christian': 'en.christian#holiday@group.v.calendar.google.com',
  };

  /// Fetch holidays for a specific year (legacy method)
  Future<List<Holiday>> fetchHolidays(String calendarId, int year) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);
    return fetchHolidaysDateRange(calendarId, startDate, endDate);
  }

  /// Fetch holidays for a date range - more efficient for multi-year fetching
  Future<List<Holiday>> fetchHolidaysDateRange(String calendarId, DateTime startDate, DateTime endDate) async {
    try {
      final timeMin = Uri.encodeComponent(startDate.toUtc().toIso8601String());
      final timeMax = Uri.encodeComponent(endDate.toUtc().toIso8601String());
      final encodedCalendarId = Uri.encodeComponent(calendarId);
      
      final url = '$_baseUrl/$encodedCalendarId/events?key=$_apiKey&timeMin=$timeMin&timeMax=$timeMax&singleEvents=true&maxResults=250';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>?;
        
        if (items == null || items.isEmpty) {
          return [];
        }

        return items
            .where((item) => item['start'] != null && item['summary'] != null)
            .map((item) => Holiday.fromGoogleCalendar(item, calendarId))
            .toList();
      } else {
        print('Google Calendar API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching Google Calendar: $e');
      return [];
    }
  }

  /// Fetch multiple calendars for a specific year (legacy)
  Future<List<Holiday>> fetchMultipleCalendars(List<String> calendarIds, int year) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);
    return fetchMultipleCalendarsDateRange(calendarIds, startDate, endDate);
  }

  /// Fetch multiple calendars for a date range - single API call per calendar
  Future<List<Holiday>> fetchMultipleCalendarsDateRange(List<String> calendarIds, DateTime startDate, DateTime endDate) async {
    final futures = calendarIds.map((id) => fetchHolidaysDateRange(id, startDate, endDate)).toList();
    final results = await Future.wait(futures);
    
    final allHolidays = <Holiday>[];
    for (final holidays in results) {
      allHolidays.addAll(holidays);
    }
    
    // Sort by date
    allHolidays.sort((a, b) => a.date.compareTo(b.date));
    
    return allHolidays;
  }
}
