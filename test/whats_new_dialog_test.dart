import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whereabouts/widgets/whats_new_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WhatsNewDialog Logic Tests', () {
    test('shouldShow returns true when version has not been seen', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await WhatsNewDialog.shouldShow(), isTrue);
    });

    test('shouldShow returns true when older version was seen', () async {
      SharedPreferences.setMockInitialValues({
        WhatsNewDialog.lastSeenVersionKey: '1.0.3',
      });
      expect(await WhatsNewDialog.shouldShow(), isTrue);
    });

    test('shouldShow returns false when 1.1.0 was already seen', () async {
      SharedPreferences.setMockInitialValues({
        WhatsNewDialog.lastSeenVersionKey: '1.1.0',
      });
      expect(await WhatsNewDialog.shouldShow(), isFalse);
    });

    test('markAsSeen saves version 1.1.0 and timestamp to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      await WhatsNewDialog.markAsSeen();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(WhatsNewDialog.lastSeenVersionKey), '1.1.0');
      expect(prefs.getString(WhatsNewDialog.announcementSeenDateKey), isNotNull);
      expect(await WhatsNewDialog.shouldShow(), isFalse);
    });

    test('resetSeenStatus clears seen version and timestamp', () async {
      SharedPreferences.setMockInitialValues({
        WhatsNewDialog.lastSeenVersionKey: '1.1.0',
        WhatsNewDialog.announcementSeenDateKey: DateTime.now().toIso8601String(),
      });
      expect(await WhatsNewDialog.shouldShow(), isFalse);

      await WhatsNewDialog.resetSeenStatus();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(WhatsNewDialog.lastSeenVersionKey), isNull);
      expect(await WhatsNewDialog.shouldShow(), isTrue);
    });
  });

  group('WhatsNewDialog Widget Tests', () {
    testWidgets('renders all feature highlight cards and v1.1.0 badge', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsNewDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and badge
      expect(find.text("What's New in Orbit"), findsOneWidget);
      expect(find.text('v1.1.0'), findsOneWidget);

      // Check feature card titles
      expect(find.text('Meet Cosmic Otter'), findsOneWidget);
      expect(find.text('Smarter Flight Search'), findsOneWidget);
      expect(find.text('Custom Nicknames'), findsOneWidget);
      expect(find.text('Instant Loading'), findsOneWidget);
      expect(find.text('Birthday Reminders'), findsOneWidget);

      // Check explore button
      expect(find.text('Explore Orbit v1.1.0'), findsOneWidget);
    });

    testWidgets('tapping explore button marks as seen and dismisses dialog', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const WhatsNewDialog(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text("What's New in Orbit"), findsOneWidget);

      // Tap Explore Orbit v1.1.0
      await tester.tap(find.text('Explore Orbit v1.1.0'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text("What's New in Orbit"), findsNothing);

      // Verify marked as seen in preferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(WhatsNewDialog.lastSeenVersionKey), '1.1.0');
    });

    testWidgets('renders debug tools when isPreview is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsNewDialog(isPreview: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Seen Status'), findsOneWidget);
      expect(find.text('Send Test Announcement'), findsOneWidget);
    });
  });
}
