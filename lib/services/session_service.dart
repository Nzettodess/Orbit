import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service to detect and manage multiple active sessions
class SessionService {
  final String userId;
  final String sessionId = const Uuid().v4();
  Timer? _heartbeatTimer;
  StreamSubscription? _sessionListener;
  bool _isActive = false;

  SessionService(this.userId);

  DocumentReference get _sessionRef => FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('active_sessions')
      .doc(sessionId);

  /// Start tracking this session
  Future<void> startSession({
    required Function(List<Map<String, dynamic>> sessions) onMultipleSessions,
  }) async {
    if (_isActive) return;
    _isActive = true;

    // Register this session
    await _sessionRef.set({
      'device': _getDeviceInfo(),
      'lastActive': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Heartbeat every 30 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isActive) {
        _sessionRef.update({'lastActive': FieldValue.serverTimestamp()});
      }
    });

    // Listen for other sessions
    _sessionListener = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('active_sessions')
        .snapshots()
        .listen((snapshot) {
      // Filter to sessions active in last 2 minutes
      final activeSessions = snapshot.docs.where((doc) {
        final lastActive = doc.data()['lastActive'] as Timestamp?;
        if (lastActive == null) return false;
        return DateTime.now().difference(lastActive.toDate()).inMinutes < 2;
      }).map((doc) {
        return {
          'id': doc.id,
          'device': doc.data()['device'] ?? 'Unknown device',
          'isCurrentSession': doc.id == sessionId,
        };
      }).toList();

      if (activeSessions.length > 1) {
        onMultipleSessions(activeSessions);
      }
    });
  }

  /// Terminate all other sessions except current one
  Future<void> terminateOtherSessions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('active_sessions')
        .get();

    for (final doc in snapshot.docs) {
      if (doc.id != sessionId) {
        await doc.reference.delete();
      }
    }
  }

  /// End current session
  Future<void> endSession() async {
    _isActive = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _sessionListener?.cancel();
    _sessionListener = null;
    
    try {
      await _sessionRef.delete();
    } catch (e) {
      // Ignore errors when deleting (might already be gone)
    }
  }

  /// Get device info for display
  String _getDeviceInfo() {
    if (kIsWeb) {
      // For web, we don't have direct access to user agent in a clean way
      // This is a simplified detection
      return 'Web Browser';
    }
    return 'Mobile App';
  }
}
