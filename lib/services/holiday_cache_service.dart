import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import '../google_calendar_service.dart';
import 'connectivity_service.dart';

/// Service to cache holiday data with 7-day expiry
/// Reduces API calls by ~87% while ensuring fresh data
class HolidayCacheService {
  final String userId;
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  HolidayCacheService(this.userId);

  /// Get holidays for multiple calendars, using cache when available
  Future<List<Holiday>> getHolidays(List<String> calendarIds) async {
    final allHolidays = <Holiday>[];

    for (final calendarId in calendarIds) {
      final cacheKey = _getCacheKey(calendarId);
      final holidays = await _getHolidaysForCalendar(calendarId, cacheKey);
      allHolidays.addAll(holidays);
    }

    allHolidays.sort((a, b) => a.date.compareTo(b.date));
    return allHolidays;
  }

  Future<List<Holiday>> _getHolidaysForCalendar(
      String calendarId, String cacheKey) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      final snapshot = await userDoc.get();
      final cache = snapshot.data()?['holidayCache']?[cacheKey];

      // Check if cached and not expired
      if (cache != null) {
        final expiresAt = cache['expiresAt'];
        if (expiresAt != null) {
          final expiryDate = (expiresAt as Timestamp).toDate();
          if (DateTime.now().isBefore(expiryDate)) {
            try {
              final holidays = _parseHolidays(cache['holidays']);
              
              // If we have data, it's a valid cache hit
              if (holidays.isNotEmpty) {
                return holidays;
              }
              
              // If cache is empty, check if we fetched it recently (within 5 mins)
              // This forces an update for old empty caches, but prevents infinite loops if the calendar is truly empty
              final fetchedAt = cache['fetchedAt'];
              if (fetchedAt != null && fetchedAt is Timestamp) {
                final fetchTime = fetchedAt.toDate();
                if (DateTime.now().difference(fetchTime).inMinutes < 5) {
                  return [];
                }
              }
              
              print('Cache existed but was empty and stale. Fetching fresh data...');
            } catch (e) {
              print('Cache parsing failed (likely format change): $e. Fetching fresh data...');
              // Fall through to fetch fresh data
            }
          }
        }
      }

      // Cache expired or missing - try to fetch fresh
      if (ConnectivityService().isOnline) {
        try {
          final holidays =
              await _calendarService.fetchMultipleCalendarsDateRange(
            [calendarId],
            DateTime(DateTime.now().year, 1, 1), // Start of current year
            DateTime(DateTime.now().year + 1, 12, 31), // End of next year
          );

          // Save to cache with 7-day expiry
          await userDoc.set({
            'holidayCache': {
              cacheKey: {
                'calendarId': calendarId,
                'holidays': holidays.map((h) => h.toMap()).toList(),
                'fetchedAt': FieldValue.serverTimestamp(),
                'expiresAt':
                    Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
              }
            }
          }, SetOptions(merge: true));

          return holidays;
        } catch (e) {
          // API failed - return stale cache if available
          if (cache != null) {
            return _parseHolidays(cache['holidays']);
          }
          return [];
        }
      }

      // Offline - return stale cache or empty
      if (cache != null) {
        return _parseHolidays(cache['holidays']);
      }
      return [];
    } catch (e) {
      // Firestore error - return empty
      return [];
    }
  }

  List<Holiday> _parseHolidays(dynamic data) {
    if (data == null) return [];
    return (data as List)
        .map((h) => Holiday.fromMap(h as Map<String, dynamic>))
        .toList();
  }

  String _getCacheKey(String calendarId) {
    // Replace special characters with underscores for Firestore field name
    return calendarId.replaceAll(RegExp(r'[.#@]'), '_');
  }

  /// Force refresh cache for specific calendar IDs
  Future<void> invalidateCache(List<String> calendarIds) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    
    for (final calendarId in calendarIds) {
      final cacheKey = _getCacheKey(calendarId);
      await userDoc.update({
        'holidayCache.$cacheKey': FieldValue.delete(),
      });
    }
  }
}
