// import 'package:hijri/hijri.dart'; // Temporarily disabled due to package issues
import 'package:lunar/lunar.dart';

class ReligiousCalendarHelper {
  // Convert Gregorian date to Hijri (Islamic) date
  // Temporarily disabled - hijri package has file issues
  static String getHijriDate(DateTime gregorianDate) {
    // TODO: Re-enable when hijri package is fixed
    // try {
    //   final hijri = HijriCalendar.fromDate(gregorianDate);
    //   return '${hijri.hDay} ${_getHijriMonthName(hijri.hMonth)} ${hijri.hYear} AH';
    // } catch (e) {
    //   return '';
    // }
    return ''; // Placeholder
  }

  static String _getHijriMonthName(int month) {
    const months = [
      'Muharram', 'Safar', 'Rabi\' al-Awwal', 'Rabi\' al-Thani',
      'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
    ];
    return month > 0 && month <= 12 ? months[month - 1] : '';
  }

  // Chinese Lunar Calendar using lunar package
  static String getChineseLunarDate(DateTime gregorianDate) {
    try {
      final lunar = Lunar.fromDate(gregorianDate);
      return '农历 ${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
    } catch (e) {
      return '';
    }
  }

  // Get all enabled religious calendar dates for a given Gregorian date
  static List<String> getReligiousDates(DateTime date, List<String> enabledCalendars) {
    final dates = <String>[];
    
    if (enabledCalendars.contains('islamic')) {
      final hijri = getHijriDate(date);
      if (hijri.isNotEmpty) dates.add('☪️ $hijri');
    }
    
    if (enabledCalendars.contains('chinese')) {
      final lunar = getChineseLunarDate(date);
      if (lunar.isNotEmpty) dates.add('🏮 $lunar');
    }
    
    // Add more calendars as needed
    // Jewish, Hindu, etc. would require additional libraries
    
    return dates;
  }
}
