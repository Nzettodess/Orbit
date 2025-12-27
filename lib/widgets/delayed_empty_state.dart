import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';

/// Widget that shows skeleton during loading and waits a minimum delay
/// before showing empty state to confirm data is truly empty
class DelayedEmptyStateWidget extends StatefulWidget {
  final Stream<List<Group>> stream;
  final int delayMs;
  final Widget Function() skeletonBuilder;
  final Widget Function() emptyBuilder;

  const DelayedEmptyStateWidget({
    super.key,
    required this.stream,
    required this.delayMs,
    required this.skeletonBuilder,
    required this.emptyBuilder,
  });

  @override
  State<DelayedEmptyStateWidget> createState() => _DelayedEmptyStateWidgetState();
}

class _DelayedEmptyStateWidgetState extends State<DelayedEmptyStateWidget> {
  bool _minDelayPassed = false;
  bool _hasData = false;
  List<Group>? _data;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    
    // Start the minimum delay timer
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        setState(() => _minDelayPassed = true);
      }
    });

    // Subscribe to the stream
    _subscription = widget.stream.listen(
      (data) {
        if (mounted) {
          setState(() {
            _hasData = true;
            _data = data;
          });
        }
      },
      onError: (error) {
        debugPrint('DelayedEmptyStateWidget stream error: $error');
        if (mounted) {
          setState(() {
            _hasData = true;
            _data = []; // Assume empty on error to avoid hanging
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If we have groups, hide this widget
    if (_hasData && _data != null && _data!.isNotEmpty) {
      return const SizedBox.shrink();
    }

    // If minimum delay hasn't passed, show skeleton (or nothing if we already have data with groups)
    if (!_minDelayPassed) {
      return widget.skeletonBuilder();
    }

    // Delay passed - now show empty state only if confirmed empty
    if (_hasData && _data != null && _data!.isEmpty) {
      return widget.emptyBuilder();
    }

    // Still waiting for data after delay - keep showing skeleton
    return widget.skeletonBuilder();
  }
}
