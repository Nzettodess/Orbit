import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../models.dart';
import 'notification_debug_dialog.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class CreditsAndFeedbackDialog extends StatefulWidget {
  const CreditsAndFeedbackDialog({super.key});

  @override
  State<CreditsAndFeedbackDialog> createState() => _CreditsAndFeedbackDialogState();
}

class _CreditsAndFeedbackDialogState extends State<CreditsAndFeedbackDialog> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSending = false;
  int _logoTapCount = 0;
  DateTime _lastTapTime = DateTime.now();

  // Links
  static const String _githubUrl = 'https://github.com/Nzettodess';
  static const String _linkedinUrl = 'https://www.linkedin.com/in/angkangheng22/';
  static const String _emailAddress = 'angkangheng@hotmail.com';
  static const String _repoUrl = 'https://github.com/Nzettodess/Orbit';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _openUrl(String url) {
    // Use JavaScript window.open for reliable web popup
    js.context.callMethod('open', [url, '_blank']);
  }

  void _openEmail() {
    js.context.callMethod('open', ['mailto:$_emailAddress', '_self']);
  }

  Future<void> _copyDeviceInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final sb = StringBuffer();

    sb.writeln('--- Orbit Device Info ---');
    sb.writeln('App Version: v1.0.1');
    sb.writeln('Timestamp: ${DateTime.now()}');
    sb.writeln('User ID: ${user?.uid ?? "Not Logged In"}');
    sb.writeln('Email: ${user?.email ?? "N/A"}');
    
    // Platform Check
    try {
      sb.writeln('Platform: ${Theme.of(context).platform}');
    } catch (_) {
      sb.writeln('Platform: Unknown');
    }

    // Web-specific Info via dart:js
    try {
      final nav = js.context['navigator'];
      final win = js.context;
      
      sb.writeln('User Agent: ${nav['userAgent']}');
      sb.writeln('Language: ${nav['language']}');
      sb.writeln('Touch Points: ${nav['maxTouchPoints']}');
      
      // Screen/Window
      sb.writeln('Window Size: ${win['innerWidth']} x ${win['innerHeight']}');
      sb.writeln('Pixel Ratio: ${win['devicePixelRatio']}');
      
      // Timezone
      final tz = js.context['Intl']
          .callMethod('DateTimeFormat')
          .callMethod('resolvedOptions')['timeZone'];
      sb.writeln('Timezone: $tz');

      // PWA Check
      final isPwa = win.callMethod('matchMedia', ['(display-mode: standalone)'])['matches'];
      sb.writeln('PWA Mode: $isPwa');
      
    } catch (e) {
      sb.writeln('Web Info Error: $e');
    }
    
    sb.writeln('Flutter Screen Size: ${MediaQuery.of(context).size}');
    sb.writeln('-------------------------');

    await Clipboard.setData(ClipboardData(text: sb.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Device info copied to clipboard!'),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send feedback')),
      );
      return;
    }

    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance.collection('feedback').add({
        'message': _feedbackController.text.trim(),
        'senderUid': user?.uid ?? 'anonymous',
        'senderEmail': user?.email ?? 'Anonymous',
        'senderName': user?.displayName ?? 'Unknown',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Thank you! Feedback submitted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with SVG logo
            GestureDetector(
              onTap: () {
                final now = DateTime.now();
                if (now.difference(_lastTapTime).inSeconds > 3) {
                  _logoTapCount = 1;
                } else {
                  _logoTapCount++;
                }
                _lastTapTime = now;

                if (_logoTapCount >= 5) {
                  _logoTapCount = 0;
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => NotificationDebugDialog(
                      currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                  );
                }
              },
              child: SizedBox(
                width: 70,
                height: 70,
                child: SvgPicture.asset(
                  'assets/orbit_logo.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orbit',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Keep your world in sync',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 12),
            
            // Star on GitHub CTA - prominent button
            ElevatedButton.icon(
              onPressed: () => _openUrl(_repoUrl),
              icon: const Icon(Icons.star, color: Colors.amber, size: 18),
              label: const Text('Star on GitHub', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade200,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'If you find Orbit useful, please consider starring!',
              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
            ),

            const Divider(height: 16),

            // Credits - Developer name changed to Nzettodess
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Developed by ',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
                ),
                const Text('Nzettodess', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'v1.0.1',
              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 12),
            
            // Connect - SVG icons with LIGHT backgrounds
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // GitHub - light background, black icon
                _buildSvgButton(
                  svgPath: 'assets/github.svg',
                  onTap: () => _openUrl(_githubUrl),
                  tooltip: 'GitHub',
                  bgColor: Colors.grey.shade100,
                ),
                const SizedBox(width: 12),
                // LinkedIn - blue background, white icon
                _buildSvgButton(
                  svgPath: 'assets/linkedin.svg',
                  onTap: () => _openUrl(_linkedinUrl),
                  tooltip: 'LinkedIn',
                  bgColor: const Color(0xFF0A66C2),
                  useWhiteIcon: true,
                ),
                const SizedBox(width: 12),
                // Email - light background, black icon
                _buildSvgButton(
                  svgPath: 'assets/mail.svg',
                  onTap: _openEmail,
                  tooltip: 'Email',
                  bgColor: Colors.grey.shade100,
                ),
              ],
            ),
            
            const Divider(height: 20),
            
            // Feedback Section
            Text(
              'Quick Feedback',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Share thoughts, suggestions, or bugs...',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(10),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade100,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyDeviceInfo,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Info', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: _isSending 
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 16),
                    label: Text(_isSending ? 'Sending...' : 'Submit', style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }



  Widget _buildSvgButton({
    required String svgPath,
    required VoidCallback onTap,
    required String tooltip,
    required Color bgColor,
    bool useWhiteIcon = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              svgPath,
              colorFilter: useWhiteIcon 
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
