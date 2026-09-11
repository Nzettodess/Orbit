import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';

/// Widget that shows skeleton during loading and waits a minimum delay
/// before showing empty state to confirm data is truly empty
class DelayedEmptyStateWidget extends StatefulWidget {
  final Stream<List<Group>> stream;
  final List<Group>? groups;
  final int delayMs;
  final Widget Function() skeletonBuilder;
  final Widget Function() emptyBuilder;

  const DelayedEmptyStateWidget({
    super.key,
    required this.stream,
    this.groups,
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

    _subscribeToStream();
  }

  void _subscribeToStream() {
    _subscription?.cancel();
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
  void didUpdateWidget(DelayedEmptyStateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _subscribeToStream();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If parent already has non-empty groups, hide immediately!
    if (widget.groups != null && widget.groups!.isNotEmpty) {
      return const SizedBox.shrink();
    }

    // If we have groups from stream, hide this widget
    if (_hasData && _data != null && _data!.isNotEmpty) {
      return const SizedBox.shrink();
    }

    // If minimum delay hasn't passed, show skeleton (or nothing if we already have data with groups)
    if (!_minDelayPassed) {
      return widget.skeletonBuilder();
    }

    // Delay passed - now show empty state only if confirmed empty
    final isConfirmedEmpty = (widget.groups != null && widget.groups!.isEmpty) ||
        (_hasData && _data != null && _data!.isEmpty);
    if (isConfirmedEmpty) {
      return widget.emptyBuilder();
    }

    // Still waiting for data after delay - keep showing skeleton
    return widget.skeletonBuilder();
  }
}
