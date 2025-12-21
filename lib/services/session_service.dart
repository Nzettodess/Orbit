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

  CollectionReference get _sessionsCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('active_sessions');

  DocumentReference get _sessionRef => _sessionsCollection.doc(sessionId);

  /// Start tracking this session
  Future<void> startSession({
    required Function(List<Map<String, dynamic>> sessions) onMultipleSessions,
  }) async {
    if (_isActive) return;
    _isActive = true;

    print('[SessionService] Starting session: $sessionId');

    // First, clean up stale sessions (older than 2 minutes)
    await _cleanupStaleSessions();

    // Register this session
    final now = DateTime.now();
    try {
      await _sessionRef.set({
        'device': _getDeviceInfo(),
        'lastActive': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      print('[SessionService] Error creating session: $e');
      _isActive = false;
      return;
    }

    // Heartbeat every 30 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_isActive) {
        try {
          await _sessionRef.update({'lastActive': Timestamp.fromDate(DateTime.now())});
        } catch (e) {
          print('[SessionService] Heartbeat error: $e');
        }
      }
    });

    // Listen for other sessions
    _sessionListener = _sessionsCollection.snapshots().listen(
      (snapshot) {
        final now = DateTime.now();
        final activeSessions = <Map<String, dynamic>>[];
        
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final lastActive = data['lastActive'] as Timestamp?;
          final createdAt = data['createdAt'] as Timestamp?;
          final device = data['device'] ?? 'Unknown';
          
          final activeTime = lastActive ?? createdAt;
          if (activeTime == null) {
            activeSessions.add({
              'id': doc.id,
              'device': device,
              'isCurrentSession': doc.id == sessionId,
            });
          } else {
            final isActive = now.difference(activeTime.toDate()).inMinutes < 2;
            if (isActive) {
              activeSessions.add({
                'id': doc.id,
                'device': device,
                'isCurrentSession': doc.id == sessionId,
              });
            }
          }
        }

        if (activeSessions.length > 1) {
          print('[SessionService] Multiple sessions detected: ${activeSessions.length}');
          onMultipleSessions(activeSessions);
        }
      },
      onError: (e) => print('[SessionService] Listener error: $e'),
    );
  }

  /// Clean up stale sessions (older than 2 minutes)
  Future<void> _cleanupStaleSessions() async {
    try {
      final snapshot = await _sessionsCollection.get();
      final now = DateTime.now();
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lastActive = data['lastActive'] as Timestamp?;
        
        if (lastActive != null) {
          final age = now.difference(lastActive.toDate());
          if (age.inMinutes >= 2) {
            await doc.reference.delete();
            print('[SessionService] Cleaned up stale session: ${doc.id}');
          }
        }
      }
    } catch (e) {
      print('[SessionService] Cleanup error: $e');
    }
  }

  /// Terminate all other sessions except current one
  Future<void> terminateOtherSessions() async {
    try {
      final snapshot = await _sessionsCollection.get();
      for (final doc in snapshot.docs) {
        if (doc.id != sessionId) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('[SessionService] Terminate error: $e');
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
      // Ignore
    }
  }

  String _getDeviceInfo() {
    return kIsWeb ? 'Web Browser' : 'Mobile App';
  }
}
