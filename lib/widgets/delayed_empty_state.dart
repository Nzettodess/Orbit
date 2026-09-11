import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';

/// Widget that shows skeleton during loading and waits a minimum delay
/// before showing empty state to confirm data is truly empty
class DelayedEmptyStateWidget extends StatefulWidget {
  final List<Group>? groups;
  final int delayMs;
  final Widget Function() skeletonBuilder;
  final Widget Function() emptyBuilder;

  const DelayedEmptyStateWidget({
    super.key,
    required this.groups,
    required this.delayMs,
    required this.skeletonBuilder,
    required this.emptyBuilder,
  });

  @override
  State<DelayedEmptyStateWidget> createState() => _DelayedEmptyStateWidgetState();
}

class _DelayedEmptyStateWidgetState extends State<DelayedEmptyStateWidget> {
  bool _minDelayPassed = false;

  @override
  void initState() {
    super.initState();
    
    // Start the minimum delay timer
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        setState(() => _minDelayPassed = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If groups exist and non-empty, hide immediately!
    if (widget.groups != null && widget.groups!.isNotEmpty) {
      return const SizedBox.shrink();
    }

    // If minimum delay hasn't passed, show skeleton
    if (!_minDelayPassed) {
      return widget.skeletonBuilder();
    }

    // Delay passed - now show empty state only if confirmed empty
    if (widget.groups != null && widget.groups!.isEmpty) {
      return widget.emptyBuilder();
    }

    // Still waiting for data after delay - keep showing skeleton
    return widget.skeletonBuilder();
  }
}
