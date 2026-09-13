import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/flight_info.dart';
import '../utils/airport_data.dart';

/// Service for flight searches and deep-linking fallback
class FlightService {
  static const String _apiPath = '/api/check-flights';

  /// Execute in-app flight search query via Vercel serverless function
  static Future<FlightSearchResponse> searchFlights(
    FlightSearchParams params,
  ) async {
    final fallbackUrl = buildGoogleFlightsFallbackUrl(params);

    try {
      String apiUrl = _apiPath;
      if (kIsWeb) {
        final origin = Uri.base.origin;
        final isLocalDev = origin.contains('localhost') ||
            origin.contains('127.0.0.1') ||
            origin.contains('0.0.0.0') ||
            origin.startsWith('http://');
        if (isLocalDev) {
          // In local web development, connect to local API server daemon on port 3001
          apiUrl = 'http://localhost:3001$_apiPath';
        } else {
          apiUrl = '${origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin}$_apiPath';
        }
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(params.toJson()),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return FlightSearchResponse.fromJson(data);
      } else {
        return FlightSearchResponse(
          success: false,
          error: 'Server responded with status ${response.statusCode}',
          fallbackUrl: fallbackUrl,
        );
      }
    } catch (e) {
      debugPrint('[FlightService] Search exception: $e');
      return FlightSearchResponse(
        success: false,
        error: 'Unable to reach search service: $e',
        fallbackUrl: fallbackUrl,
      );
    }
  }

  /// Construct pre-filled Google Flights search URL as direct fallback
  static String buildGoogleFlightsFallbackUrl(FlightSearchParams params) {
    final origin = AirportHelper.cleanLocationName(params.origin);
    final dest = AirportHelper.cleanLocationName(params.destination);
    final depDate = params.departureDate.trim();
    final retDate = params.returnDate?.trim();

    String query;
    if (params.tripType == 'multicity' &&
        params.multiCityLegs != null &&
        params.multiCityLegs!.isNotEmpty) {
      final legParts = <String>[];
      for (int i = 0; i < params.multiCityLegs!.length; i++) {
        final leg = params.multiCityLegs![i];
        final legFrom = AirportHelper.cleanLocationName(leg.origin);
        final legTo = AirportHelper.cleanLocationName(leg.destination);
        if (i == 0) {
          legParts.add('Flights from $legFrom to $legTo on ${leg.date}');
        } else {
          legParts.add('then from $legFrom to $legTo on ${leg.date}');
        }
      }
      query = legParts.join(' ');
    } else {
      query = 'Flights to ${dest.isNotEmpty ? dest : 'anywhere'} from ${origin.isNotEmpty ? origin : 'here'}';
      if (depDate.isNotEmpty) query += ' on $depDate';
      if (params.tripType == 'roundtrip' && retDate != null && retDate.isNotEmpty) {
        query += ' through $retDate';
      } else {
        query += ' one way';
      }
    }

    if (params.cabinClass == 'business') {
      query += ' business class';
    } else if (params.cabinClass == 'first') {
      query += ' first class';
    } else if (params.cabinClass == 'premiumeconomy') {
      query += ' premium economy';
    }

    if (params.adults > 1) {
      query += ' ${params.adults} adults';
    }
    if (params.children > 0) {
      query += ' ${params.children} children';
    }

    return 'https://www.google.com/travel/flights?q=${Uri.encodeComponent(query)}&curr=${params.currency}&hl=en';
  }

  /// Launch external flight booking/viewing URL in browser
  static Future<void> launchFlightUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static const String _prefLastTripType = 'flight_last_trip_type';

  /// Get the user's last selected trip type ('roundtrip', 'oneway', 'multicity')
  static Future<String> getLastTripType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefLastTripType) ?? 'oneway';
    } catch (_) {
      return 'oneway';
    }
  }

  /// Save the user's last selected trip type
  static Future<void> saveLastTripType(String tripType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastTripType, tripType);
    } catch (_) {}
  }
}
