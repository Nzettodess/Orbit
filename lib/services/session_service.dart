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

    print('[SessionService] Starting session: $sessionId for user: $userId');

    // Register this session with current timestamp (not server timestamp for immediate read)
    final now = DateTime.now();
    await _sessionRef.set({
      'device': _getDeviceInfo(),
      'lastActive': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
    });

    print('[SessionService] Session registered');

    // Heartbeat every 30 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isActive) {
        _sessionRef.update({'lastActive': Timestamp.fromDate(DateTime.now())});
      }
    });

    // Listen for other sessions
    _sessionListener = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('active_sessions')
        .snapshots()
        .listen((snapshot) {
      print('[SessionService] Received snapshot with ${snapshot.docs.length} documents');
      
      // Filter to sessions active in last 2 minutes
      final activeSessions = snapshot.docs.where((doc) {
        final data = doc.data();
        final lastActive = data['lastActive'] as Timestamp?;
        final createdAt = data['createdAt'] as Timestamp?;
        
        // Use createdAt if lastActive is null (new session)
        final activeTime = lastActive ?? createdAt;
        if (activeTime == null) {
          print('[SessionService] Session ${doc.id} has no timestamp, including');
          return true; // Include sessions without timestamp (just created)
        }
        
        final isActive = DateTime.now().difference(activeTime.toDate()).inMinutes < 2;
        print('[SessionService] Session ${doc.id}: lastActive=${activeTime.toDate()}, isActive=$isActive');
        return isActive;
      }).map((doc) {
        return {
          'id': doc.id,
          'device': doc.data()['device'] ?? 'Unknown device',
          'isCurrentSession': doc.id == sessionId,
        };
      }).toList();

      print('[SessionService] Active sessions: ${activeSessions.length}');

      if (activeSessions.length > 1) {
        print('[SessionService] Multiple sessions detected! Triggering callback');
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
      return 'Web Browser';
    }
    return 'Mobile App';
  }
}
