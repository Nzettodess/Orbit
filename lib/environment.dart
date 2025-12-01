import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  // Load environment variables from .env file
  // These values can also be overridden with --dart-define at build time
  static String get calendarificApiKey {
    // Try dart-define first, then .env file, then empty string
    const dartDefine = String.fromEnvironment('CALENDARIFIC_API_KEY', defaultValue: '');
    if (dartDefine.isNotEmpty) return dartDefine;
    return dotenv.get('CALENDARIFIC_API_KEY', fallback: '');
  }
  
  static String get festivoApiKey {
    const dartDefine = String.fromEnvironment('FESTIVO_API_KEY', defaultValue: '');
    if (dartDefine.isNotEmpty) return dartDefine;
    return dotenv.get('FESTIVO_API_KEY', fallback: '');
  }
  
  static String get googleCalendarApiKey {
    const dartDefine = String.fromEnvironment('GOOGLE_CALENDAR_API_KEY', defaultValue: '');
    if (dartDefine.isNotEmpty) return dartDefine;
    return dotenv.get('GOOGLE_CALENDAR_API_KEY', fallback: '');
  }
  
  // Helper to check if all keys are configured
  static bool get isConfigured {
    return calendarificApiKey.isNotEmpty &&
           festivoApiKey.isNotEmpty &&
           googleCalendarApiKey.isNotEmpty;
  }
  
  // Helper to get missing keys
  static List<String> get missingKeys {
    final missing = <String>[];
    if (calendarificApiKey.isEmpty) missing.add('CALENDARIFIC_API_KEY');
    if (festivoApiKey.isEmpty) missing.add('FESTIVO_API_KEY');
    if (googleCalendarApiKey.isEmpty) missing.add('GOOGLE_CALENDAR_API_KEY');
    return missing;
  }
}
