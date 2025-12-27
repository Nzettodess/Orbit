import 'package:flutter/material.dart';

/// A customizable loading indicator widget.
/// Use this for consistent loading states throughout the app.
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final bool overlay;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 24.0,
    this.color,
    this.overlay = false,
  });

  /// Show as a full-screen overlay
  static Widget fullScreen({String? message}) {
    return LoadingIndicator(
      message: message,
      size: 48.0,
      overlay: true,
    );
  }

  /// Show as an inline indicator
  static Widget inline({double size = 16.0, Color? color}) {
    return LoadingIndicator(
      size: size,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final indicator = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: size > 30 ? 3.0 : 2.0,
            valueColor: color != null
                ? AlwaysStoppedAnimation<Color>(color!)
                : null,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (overlay) {
      return Container(
        color: Colors.black26,
        child: Center(child: indicator),
      );
    }

    return Center(child: indicator);
  }
}
