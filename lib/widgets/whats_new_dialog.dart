import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';

/// Modal dialog highlighting the major features introduced in Orbit v1.1.0
class WhatsNewDialog extends StatelessWidget {
  final bool isPreview;
  final Future<bool> Function()? onSendTestAnnouncement;

  const WhatsNewDialog({
    super.key,
    this.isPreview = false,
    this.onSendTestAnnouncement,
  });

  static const String version = '1.1.0';
  static const String lastSeenVersionKey = 'last_seen_version';
  static const String announcementSeenDateKey = 'announcement_seen_date';

  /// Check if the user needs to see the What's New dialog for [version]
  static Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(lastSeenVersionKey);
      debugPrint('[WhatsNew] shouldShow check -> lastSeen: "$lastSeen", target: "$version"');
      return lastSeen != version;
    } catch (e) {
      debugPrint('[WhatsNew] Error checking SharedPreferences: $e');
      return false;
    }
  }

  /// Mark the current version as seen in SharedPreferences
  static Future<void> markAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastSeenVersionKey, version);
      await prefs.setString(announcementSeenDateKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  /// Reset seen status (useful for developer testing)
  static Future<void> resetSeenStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(lastSeenVersionKey);
      await prefs.remove(announcementSeenDateKey);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkSurface : Colors.white;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Mascot and Version Badge
              _buildHeader(context, isDark, primaryTextColor, secondaryTextColor),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Scrollable Feature Highlights
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildFeatureCard(
                        context: context,
                        isDark: isDark,
                        icon: Icons.pets_rounded,
                        accentColor: AppColors.iosPurple,
                        title: 'Meet Cosmic Otter',
                        description:
                            'Say hello to our new mascot and a refreshed look across the app.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        context: context,
                        isDark: isDark,
                        icon: Icons.flight_takeoff_rounded,
                        accentColor: AppColors.iosBlue,
                        title: 'Smarter Flight Search',
                        description:
                            'Search multi-city & round-trip flights with live prices, lowest-fare highlights, and layover alerts.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        context: context,
                        isDark: isDark,
                        icon: Icons.badge_rounded,
                        accentColor: AppColors.iosTeal,
                        title: 'Custom Nicknames',
                        description:
                            'Set private nicknames for group members that only you can see.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        context: context,
                        isDark: isDark,
                        icon: Icons.bolt_rounded,
                        accentColor: AppColors.iosOrange,
                        title: 'Instant Loading',
                        description:
                            'Your groups and calendars now open instantly with zero waiting.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        context: context,
                        isDark: isDark,
                        icon: Icons.cake_rounded,
                        accentColor: AppColors.iosPink,
                        title: 'Birthday Reminders',
                        description:
                            'Automatic alerts for solar and lunar birthdays so you never miss a celebration.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Primary Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!isPreview) {
                      await markAsSeen();
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.iosPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Explore Orbit v1.1.0',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Debug / Test Controls
              if (isPreview) ...[
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await resetSeenStatus();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dialog seen status reset. Will auto-show on next boot.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Reset Seen Status',
                        style: TextStyle(fontSize: 12, color: AppColors.iosOrange),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (onSendTestAnnouncement != null) {
                          final result = await onSendTestAnnouncement!();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result ? 'Broadcast notification sent (1-time limit enforced).' : 'Notification already sent for v1.1.0 (duplicate prevented).'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Announcement trigger only available in active session.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Send Test Announcement',
                        style: TextStyle(fontSize: 12, color: AppColors.iosBlue),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primaryTextColor, Color? secondaryTextColor) {
    return Row(
      children: [
        // Mascot Logo Container
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkBackground : Colors.grey.shade100,
            boxShadow: [
              BoxShadow(
                color: AppColors.iosPurple.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: ClipOval(
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.iosPurple,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      "What's New in Orbit",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.iosPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.iosPurple.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'v1.1.0',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.iosPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what's new in this update",
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String description,
  }) {
    final cardBg = isDark
        ? AppColors.darkBackground.withValues(alpha: 0.6)
        : Colors.grey.shade50;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
