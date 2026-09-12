import 'package:flutter/material.dart';
import 'location_data.dart';

/// Reusable autocomplete suggestion tile for LocationMatch items
/// Strictly under 500 lines (Hard limit: 500 lines)
class LocationSuggestionTile extends StatelessWidget {
  final LocationMatch match;
  final VoidCallback onTap;

  const LocationSuggestionTile({
    super.key,
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(match.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      match.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      match.displaySubtitle,
                      style: TextStyle(fontSize: 11, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              if (match.isState)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'City / Region',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                )
              else
                Text(
                  match.code,
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom location selection tile for free-text location entries
class LocationCustomTile extends StatelessWidget {
  final String text;
  final String labelPrefix;
  final VoidCallback onTap;

  const LocationCustomTile({
    super.key,
    required this.text,
    required this.labelPrefix,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              const Icon(Icons.add_location_alt_outlined, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$labelPrefix: "$text"',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
