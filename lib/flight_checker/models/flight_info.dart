import 'package:flutter/foundation.dart';

/// Flight departure/arrival endpoint details
@immutable
class FlightEndpoint {
  final String airport;
  final String time;
  final String date;

  const FlightEndpoint({
    required this.airport,
    required this.time,
    required this.date,
  });

  factory FlightEndpoint.fromJson(Map<String, dynamic> json) {
    return FlightEndpoint(
      airport: json['airport'] as String? ?? '',
      time: json['time'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'airport': airport,
    'time': time,
    'date': date,
  };
}

/// Individual leg/segment of a flight itinerary
@immutable
class FlightSegment {
  final String departureAirport;
  final String departureCode;
  final String departureTime;
  final String arrivalAirport;
  final String arrivalCode;
  final String arrivalTime;
  final String duration;
  final String legroom;
  final String aircraft;
  final String flightNumber;
  final String airline;
  final String delayInfo;
  final String emissions;
  final List<String> amenities;
  final String contrail;

  const FlightSegment({
    this.departureAirport = '',
    this.departureCode = '',
    this.departureTime = '',
    this.arrivalAirport = '',
    this.arrivalCode = '',
    this.arrivalTime = '',
    this.duration = '',
    this.legroom = '',
    this.aircraft = '',
    this.flightNumber = '',
    this.airline = '',
    this.delayInfo = '',
    this.emissions = '',
    this.amenities = const [],
    this.contrail = '',
  });

  factory FlightSegment.fromJson(Map<String, dynamic> json) {
    return FlightSegment(
      departureAirport: json['departureAirport'] as String? ?? '',
      departureCode: json['departureCode'] as String? ?? '',
      departureTime: json['departureTime'] as String? ?? '',
      arrivalAirport: json['arrivalAirport'] as String? ?? '',
      arrivalCode: json['arrivalCode'] as String? ?? '',
      arrivalTime: json['arrivalTime'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      legroom: json['legroom'] as String? ?? '',
      aircraft: json['aircraft'] as String? ?? '',
      flightNumber: json['flightNumber'] as String? ?? '',
      airline: json['airline'] as String? ?? '',
      delayInfo: json['delayInfo'] as String? ?? '',
      emissions: json['emissions'] as String? ?? '',
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      contrail: json['contrail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'departureAirport': departureAirport,
    'departureCode': departureCode,
    'departureTime': departureTime,
    'arrivalAirport': arrivalAirport,
    'arrivalCode': arrivalCode,
    'arrivalTime': arrivalTime,
    'duration': duration,
    'legroom': legroom,
    'aircraft': aircraft,
    'flightNumber': flightNumber,
    'airline': airline,
    'delayInfo': delayInfo,
    'emissions': emissions,
    'amenities': amenities,
    'contrail': contrail,
  };
}

/// Layover details between flight segments
@immutable
class FlightLayover {
  final String duration;
  final int durationMinutes;
  final String airportCode;
  final String airportName;
  final String city;
  final String text;

  const FlightLayover({
    this.duration = '',
    this.durationMinutes = 0,
    this.airportCode = '',
    this.airportName = '',
    this.city = '',
    this.text = '',
  });

  factory FlightLayover.fromJson(Map<String, dynamic> json) {
    return FlightLayover(
      duration: json['duration'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      airportCode: json['airportCode'] as String? ?? '',
      airportName: json['airportName'] as String? ?? '',
      city: json['city'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'duration': duration,
    'durationMinutes': durationMinutes,
    'airportCode': airportCode,
    'airportName': airportName,
    'city': city,
    'text': text,
  };
}

/// Parsed single flight item model
@immutable
class FlightInfo {
  final String airline;
  final String? logoUrl;
  final String stops;
  final String duration;
  final String price;
  final int priceNumeric;
  final FlightEndpoint departure;
  final FlightEndpoint arrival;
  final String deepLink;
  final List<FlightSegment> segments;
  final List<FlightLayover> layovers;

  const FlightInfo({
    required this.airline,
    this.logoUrl,
    required this.stops,
    required this.duration,
    required this.price,
    required this.priceNumeric,
    required this.departure,
    required this.arrival,
    required this.deepLink,
    this.segments = const [],
    this.layovers = const [],
  });

  factory FlightInfo.fromJson(Map<String, dynamic> json) {
    return FlightInfo(
      airline: json['airline'] as String? ?? 'Unknown Airline',
      logoUrl: json['logoUrl'] as String?,
      stops: json['stops'] as String? ?? 'Nonstop',
      duration: json['duration'] as String? ?? '',
      price: json['price'] as String? ?? '',
      priceNumeric: (json['priceNumeric'] as num?)?.toInt() ?? 0,
      departure: FlightEndpoint.fromJson(
        (json['departure'] as Map<String, dynamic>?) ?? {},
      ),
      arrival: FlightEndpoint.fromJson(
        (json['arrival'] as Map<String, dynamic>?) ?? {},
      ),
      deepLink: json['deepLink'] as String? ?? '',
      segments: (json['segments'] as List<dynamic>?)
              ?.map((e) => FlightSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      layovers: (json['layovers'] as List<dynamic>?)
              ?.map((e) => FlightLayover.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'airline': airline,
    'logoUrl': logoUrl,
    'stops': stops,
    'duration': duration,
    'price': price,
    'priceNumeric': priceNumeric,
    'departure': departure.toJson(),
    'arrival': arrival.toJson(),
    'deepLink': deepLink,
    'segments': segments.map((e) => e.toJson()).toList(),
    'layovers': layovers.map((e) => e.toJson()).toList(),
  };
}

/// Search parameter query model
@immutable
class FlightSearchParams {
  final String origin;
  final String destination;
  final String departureDate;
  final String? returnDate;
  final String tripType; // 'oneway' | 'roundtrip' | 'multicity'
  final int adults;
  final int children;
  final String cabinClass; // 'economy' | 'premiumeconomy' | 'business' | 'first'
  final String currency;

  const FlightSearchParams({
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.returnDate,
    this.tripType = 'oneway',
    this.adults = 1,
    this.children = 0,
    this.cabinClass = 'economy',
    this.currency = 'MYR',
  });

  FlightSearchParams copyWith({
    String? origin,
    String? destination,
    String? departureDate,
    String? returnDate,
    String? tripType,
    int? adults,
    int? children,
    String? cabinClass,
    String? currency,
  }) {
    return FlightSearchParams(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      tripType: tripType ?? this.tripType,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      cabinClass: cabinClass ?? this.cabinClass,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() => {
    'origin': origin,
    'destination': destination,
    'departureDate': departureDate,
    if (returnDate != null && returnDate!.isNotEmpty) 'returnDate': returnDate,
    'tripType': tripType,
    'adults': adults,
    'children': children,
    'cabinClass': cabinClass,
    'currency': currency,
  };
}

/// Search API response model
@immutable
class FlightSearchResponse {
  final bool success;
  final int count;
  final List<FlightInfo> flights;
  final String fallbackUrl;
  final String? error;
  final bool isMultiCity;

  const FlightSearchResponse({
    required this.success,
    this.count = 0,
    this.flights = const [],
    required this.fallbackUrl,
    this.error,
    this.isMultiCity = false,
  });

  factory FlightSearchResponse.fromJson(Map<String, dynamic> json) {
    final rawFlights = json['flights'] as List<dynamic>? ?? [];
    return FlightSearchResponse(
      success: json['success'] as bool? ?? false,
      count: (json['count'] as num?)?.toInt() ?? 0,
      flights: rawFlights
          .map((f) => FlightInfo.fromJson(f as Map<String, dynamic>))
          .toList(),
      fallbackUrl: json['fallbackUrl'] as String? ?? '',
      error: json['error'] as String?,
      isMultiCity: json['isMultiCity'] as bool? ?? false,
    );
  }
}
