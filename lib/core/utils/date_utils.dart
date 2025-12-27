import 'package:intl/intl.dart';

/// Centralized date formatting utilities used throughout the app.
/// These were previously duplicated across multiple files.

/// Generate a consistent date key for caching and lookups
/// Format: YYYY-MM-DD
String formatDateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Format a timestamp for human-readable display
/// Shows relative time for recent dates, absolute for older
String formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);
  
  if (diff.inMinutes < 1) {
    return 'Just now';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  } else if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  } else if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  } else {
    return DateFormat('MMM d, yyyy').format(timestamp);
  }
}

/// Format a timestamp with time included
String formatTimestampWithTime(DateTime timestamp) {
  return DateFormat('MMM d, yyyy h:mm a').format(timestamp);
}

/// Get ordinal suffix for a day (1st, 2nd, 3rd, etc.)
String getDaySuffix(int day) {
  if (day >= 11 && day <= 13) {
    return '${day}th';
  }
  switch (day % 10) {
    case 1: return '${day}st';
    case 2: return '${day}nd';
    case 3: return '${day}rd';
    default: return '${day}th';
  }
}

/// Check if a date is in the future (upcoming)
bool isUpcoming(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final checkDate = DateTime(date.year, date.month, date.day);
  return checkDate.isAfter(today) || checkDate.isAtSameMomentAs(today);
}

/// Format a date range for display
String formatDateRange(DateTime start, DateTime end) {
  final startFmt = DateFormat('MMM d');
  final endFmt = DateFormat('MMM d, yyyy');
  
  if (start.year == end.year && start.month == end.month && start.day == end.day) {
    return endFmt.format(start);
  } else if (start.year == end.year) {
    return '${startFmt.format(start)} - ${endFmt.format(end)}';
  } else {
    return '${endFmt.format(start)} - ${endFmt.format(end)}';
  }
}

/// Get a short day name (Mon, Tue, etc.)
String getShortDayName(DateTime date) {
  return DateFormat('E').format(date);
}

/// Get full month name
String getMonthName(DateTime date) {
  return DateFormat('MMMM').format(date);
}
