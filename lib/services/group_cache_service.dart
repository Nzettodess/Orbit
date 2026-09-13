import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../core/utils/logger.dart';

/// Service to manage persistent local caching for user groups using SharedPreferences.
/// Enables 0ms immediate UI rendering when refreshing the page on Flutter Web or native.
class GroupCacheService {
  static const String _keyPrefix = 'cached_user_groups_';
  final AppLogger _log = const AppLogger('GroupCacheService');

  // Singleton instance
  static final GroupCacheService _instance = GroupCacheService._internal();
  factory GroupCacheService() => _instance;
  GroupCacheService._internal();

  String _getKey(String userId) => '$_keyPrefix$userId';

  /// Save user groups to local storage
  Future<void> saveUserGroups(String userId, List<Group> groups) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = groups.map((g) => g.toCacheMap()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_getKey(userId), jsonString);
      _log.debug('Saved ${groups.length} groups to local cache for user $userId');
    } catch (e, stackTrace) {
      _log.error('Failed to save groups to cache', e, stackTrace);
    }
  }

  /// Load user groups from local storage (< 5ms)
  Future<List<Group>?> loadUserGroups(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_getKey(userId));
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        final groups = decoded
            .map((item) => Group.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
        _log.debug('Loaded ${groups.length} groups from local cache for user $userId');
        return groups;
      }
    } catch (e, stackTrace) {
      _log.error('Failed to load groups from cache', e, stackTrace);
    }
    return null;
  }

  /// Clear cached groups for user (e.g. on logout)
  Future<void> clearCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getKey(userId));
      _log.debug('Cleared cached groups for user $userId');
    } catch (e) {
      _log.warning('Failed to clear cached groups: $e');
    }
  }
}
