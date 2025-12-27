import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

/// A widget that renders text with clickable links.
/// Auto-detects URLs and makes them tappable.
class RichDescriptionViewer extends StatelessWidget {
  final String description;
  final TextStyle? style;
  final int? maxLines;
  final bool selectable;

  const RichDescriptionViewer({
    super.key,
    required this.description,
    this.style,
    this.maxLines,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final linkStyle = TextStyle(
      color: isDark ? Colors.lightBlue.shade300 : Colors.blue.shade700,
      decoration: TextDecoration.underline,
    );

    if (selectable) {
      return SelectableLinkify(
        text: description,
        style: style ?? Theme.of(context).textTheme.bodyMedium,
        linkStyle: linkStyle,
        options: const LinkifyOptions(humanize: false),
        onOpen: (link) => _launchUrl(link.url),
      );
    }

    return Linkify(
      text: description,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
      linkStyle: linkStyle,
      options: const LinkifyOptions(humanize: false),
      onOpen: (link) => _launchUrl(link.url),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// A compact preview for descriptions in list views.
class RichDescriptionPreview extends StatelessWidget {
  final String description;
  final int maxLength;
  final TextStyle? style;

  const RichDescriptionPreview({
    super.key,
    required this.description,
    this.maxLength = 100,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    // Truncate for preview
    String plainText = description.replaceAll(RegExp(r'\n+'), ' ').trim();
    if (plainText.length > maxLength) {
      plainText = '${plainText.substring(0, maxLength)}...';
    }

    // Check if has links
    final hasLinks = RegExp(r'https?://|www\.').hasMatch(description);

    return Row(
      children: [
        Expanded(
          child: Text(
            plainText,
            style: style ?? Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasLinks) ...[
          const SizedBox(width: 4),
          Icon(Icons.link, size: 14, color: Colors.grey.shade500),
        ],
      ],
    );
  }
}

/// A widget that displays venue with clickable link support for map URLs.
class VenueLinkText extends StatelessWidget {
  final String venue;
  final TextStyle? style;
  final bool showIcon;

  const VenueLinkText({
    super.key,
    required this.venue,
    this.style,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    if (venue.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Check if venue is a URL
    final isUrl = RegExp(r'^(https?://|www\.)', caseSensitive: false).hasMatch(venue.trim());

    if (isUrl) {
      return InkWell(
        onTap: () => _launchUrl(venue),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                Icons.location_on,
                size: 16,
                color: isDark ? Colors.lightBlue.shade300 : Colors.blue.shade700,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                _formatVenueDisplay(venue),
                style: (style ?? const TextStyle()).copyWith(
                  color: isDark ? Colors.lightBlue.shade300 : Colors.blue.shade700,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 12,
              color: isDark ? Colors.lightBlue.shade300 : Colors.blue.shade600,
            ),
          ],
        ),
      );
    }

    // Regular venue text
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(Icons.location_on, size: 16, color: Theme.of(context).hintColor),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            venue,
            style: style ?? TextStyle(color: Theme.of(context).hintColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatVenueDisplay(String url) {
    if (url.contains('maps.app.goo.gl') || 
        url.contains('google.com/maps') || 
        url.contains('goo.gl/maps')) {
      return 'Open in Google Maps';
    }
    if (url.contains('maps.apple.com')) {
      return 'Open in Apple Maps';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.isNotEmpty) {
      return uri.host.replaceFirst('www.', '');
    }
    return url.length > 30 ? '${url.substring(0, 30)}...' : url;
  }

  Future<void> _launchUrl(String url) async {
    String urlToLaunch = url.trim();
    if (!urlToLaunch.startsWith('http')) {
      urlToLaunch = 'https://$urlToLaunch';
    }
    final uri = Uri.tryParse(urlToLaunch);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
