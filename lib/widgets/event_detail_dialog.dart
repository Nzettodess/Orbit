import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import 'rich_description_viewer.dart';

/// A custom dialog for displaying event details with full markdown support.
/// Uses fixed width to avoid intrinsic size calculation issues with MarkdownBody.
class EventDetailDialog extends StatelessWidget {
  final GroupEvent event;
  final String? groupName;
  final VoidCallback? onEdit; // Optional edit callback
  final bool showDate; // Whether to show date (for upcoming summary)
  
  const EventDetailDialog({
    super.key,
    required this.event,
    this.groupName,
    this.onEdit,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 500 ? screenWidth * 0.92 : 420.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date (for upcoming summary)
                    if (showDate) ...[
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(event.date) +
                                (event.hasTime ? ' at ${DateFormat('h:mm a').format(event.date)}' : ''),
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Time only (for detail modal when showDate is false)
                    if (!showDate && event.hasTime) ...[
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: Colors.deepPurple.shade400),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('h:mm a').format(event.date),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade400,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Venue
                    if (event.venue != null && event.venue!.isNotEmpty) ...[
                      VenueLinkText(
                        venue: event.venue!,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Description with full markdown support
                    if (event.description.isNotEmpty) ...[
                      SizedBox(
                        width: dialogWidth - 40, // Fixed width for MarkdownBody
                        child: MarkdownBody(
                          data: event.description,
                          styleSheet: _buildMarkdownStyleSheet(context, isDark),
                          onTapLink: (text, href, title) => _launchUrl(href),
                          shrinkWrap: true,
                          softLineBreak: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Divider
                    Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    const SizedBox(height: 12),
                    
                    // Group and owner info
                    if (groupName != null)
                      Text(
                        "Group: $groupName",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(event.creatorId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          return Text(
                            "Owner: ${data?['displayName'] ?? 'Unknown'}",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context, bool isDark) {
    final textTheme = Theme.of(context).textTheme;
    return MarkdownStyleSheet(
      p: textTheme.bodyMedium,
      h1: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      h2: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      h3: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      a: TextStyle(
        color: isDark ? Colors.lightBlue.shade300 : Colors.blue.shade700,
        decoration: TextDecoration.underline,
      ),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(fontStyle: FontStyle.italic),
      code: TextStyle(
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            width: 4,
          ),
        ),
      ),
      listBullet: textTheme.bodyMedium,
      listIndent: 16,
      blockSpacing: 12,
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

/// Helper function to show the event detail dialog
void showEventDetailDialog(
  BuildContext context, 
  GroupEvent event, {
  String? groupName,
  VoidCallback? onEdit,
  bool showDate = false,
}) {
  showDialog(
    context: context,
    builder: (context) => EventDetailDialog(
      event: event,
      groupName: groupName,
      onEdit: onEdit,
      showDate: showDate,
    ),
  );
}
