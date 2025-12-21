import 'dart:async';
import 'dart:html' as html;

/// Service to detect online/offline status using browser APIs
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;
  bool _initialized = false;

  /// Initialize the connectivity listener
  void init() {
    if (_initialized) return;
    _initialized = true;

    _isOnline = html.window.navigator.onLine ?? true;

    html.window.addEventListener('online', (_) {
      _isOnline = true;
      _controller.add(true);
    });

    html.window.addEventListener('offline', (_) {
      _isOnline = false;
      _controller.add(false);
    });
  }

  /// Stream of online status changes
  Stream<bool> get onlineStatus => _controller.stream;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Dispose resources
  void dispose() {
    _controller.close();
  }
}
