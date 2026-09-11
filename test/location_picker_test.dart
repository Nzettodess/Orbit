import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whereabouts/widgets/default_location_picker.dart';
import 'package:whereabouts/widgets/searchable_location_input.dart';
import 'package:whereabouts/location_picker.dart';

Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: child,
      ),
    ),
  );
}

void main() {
  group('SearchableLocationInput Widget Tests', () {
    testWidgets('renders input fields with initial values', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          SearchableLocationInput(
            initialCountry: 'Malaysia',
            initialState: 'Penang',
            onCountryChanged: (_) {},
            onStateChanged: (_) {},
          ),
        ),
      );

      expect(find.byKey(const Key('location_country_field')), findsOneWidget);
      expect(find.byKey(const Key('location_state_field')), findsOneWidget);
      expect(find.text('Malaysia'), findsOneWidget);
      expect(find.text('Penang'), findsOneWidget);
    });

    testWidgets('allows typing custom free-text location not in preset list', (WidgetTester tester) async {
      String selectedCountry = '';
      String? selectedState;

      await tester.pumpWidget(
        createTestableWidget(
          SearchableLocationInput(
            onCountryChanged: (c) => selectedCountry = c,
            onStateChanged: (s) => selectedState = s,
          ),
        ),
      );

      final countryField = find.byKey(const Key('location_country_field'));
      await tester.enterText(countryField, 'Neo Tokyo Base');
      await tester.pump();

      expect(selectedCountry, 'Neo Tokyo Base');

      final stateField = find.byKey(const Key('location_state_field'));
      await tester.enterText(stateField, 'Sector 7');
      await tester.pump();

      expect(selectedState, 'Sector 7');
    });

    testWidgets('shows suggestions when typing preset country like South Korea and selects on tap', (WidgetTester tester) async {
      String selectedCountry = '';

      await tester.pumpWidget(
        createTestableWidget(
          SearchableLocationInput(
            onCountryChanged: (c) => selectedCountry = c,
            onStateChanged: (_) {},
          ),
        ),
      );

      final countryField = find.byKey(const Key('location_country_field'));
      await tester.tap(countryField);
      await tester.pump();
      await tester.enterText(countryField, 'Korea');
      await tester.pump();

      expect(find.text('South Korea'), findsWidgets);

      // Tap on the South Korea suggestion
      await tester.tap(find.text('South Korea').first);
      await tester.pump();

      expect(selectedCountry, 'South Korea');
    });

    testWidgets('allows selecting custom location via suggestion tile', (WidgetTester tester) async {
      String selectedCountry = '';

      await tester.pumpWidget(
        createTestableWidget(
          SearchableLocationInput(
            onCountryChanged: (c) => selectedCountry = c,
            onStateChanged: (_) {},
          ),
        ),
      );

      final countryField = find.byKey(const Key('location_country_field'));
      await tester.tap(countryField);
      await tester.pump();
      await tester.enterText(countryField, 'Atlantis Office');
      await tester.pump();

      expect(find.text('Use custom location: "Atlantis Office"'), findsOneWidget);

      await tester.tap(find.text('Use custom location: "Atlantis Office"'));
      await tester.pump();

      expect(selectedCountry, 'Atlantis Office');
    });

    testWidgets('updates when parent updates initialCountry and initialState', (WidgetTester tester) async {
      String country = 'Japan';
      String? state = 'Tokyo';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return createTestableWidget(
              Column(
                children: [
                  SearchableLocationInput(
                    initialCountry: country,
                    initialState: state,
                    onCountryChanged: (c) => country = c,
                    onStateChanged: (s) => state = s,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        country = 'South Korea';
                        state = 'Seoul';
                      });
                    },
                    child: const Text('Update Props'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      expect(find.text('Japan'), findsOneWidget);
      expect(find.text('Tokyo'), findsOneWidget);

      await tester.tap(find.text('Update Props'));
      await tester.pump();

      expect(find.text('South Korea'), findsOneWidget);
      expect(find.text('Seoul'), findsOneWidget);
    });
  });

  group('DefaultLocationPicker Tests', () {
    testWidgets('saves selected custom free-text location', (WidgetTester tester) async {
      String? savedCountry;
      String? savedState;

      await tester.pumpWidget(
        createTestableWidget(
          DefaultLocationPicker(
            onLocationSelected: (country, state) {
              savedCountry = country;
              savedState = state;
            },
          ),
        ),
      );

      final countryField = find.byKey(const Key('location_country_field'));
      await tester.enterText(countryField, 'South Korea');
      await tester.pump();

      final stateField = find.byKey(const Key('location_state_field'));
      await tester.enterText(stateField, 'Seoul');
      await tester.pump();

      // Tap save button
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Default Location');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();

      expect(savedCountry, 'South Korea');
      expect(savedState, 'Seoul');
    });

    testWidgets('shows snackbar when country is empty on save', (WidgetTester tester) async {
      bool called = false;

      await tester.pumpWidget(
        createTestableWidget(
          DefaultLocationPicker(
            onLocationSelected: (_, __) => called = true,
          ),
        ),
      );

      final saveButton = find.widgetWithText(ElevatedButton, 'Save Default Location');
      await tester.tap(saveButton);
      await tester.pump();

      expect(called, isFalse);
      expect(find.text('Please enter or select a country/location'), findsOneWidget);
    });
  });

  group('LocationPicker Tests', () {
    testWidgets('renders properly and saves custom free-text range location', (WidgetTester tester) async {
      String? savedCountry;
      String? savedState;
      DateTime? savedStart;
      DateTime? savedEnd;
      List<String>? savedMembers;

      await tester.pumpWidget(
        createTestableWidget(
          LocationPicker(
            currentUserId: 'user_123',
            initialStartDate: DateTime(2026, 9, 15),
            initialEndDate: DateTime(2026, 9, 20),
            onLocationSelected: (c, s, start, end, members) {
              savedCountry = c;
              savedState = s;
              savedStart = start;
              savedEnd = end;
              savedMembers = members;
            },
          ),
        ),
      );

      // Verify date range display
      expect(find.text('6 days selected'), findsOneWidget);

      // Enter custom location
      final countryField = find.byKey(const Key('location_country_field'));
      await tester.enterText(countryField, 'Bali Remote Villa');
      await tester.pump();

      final stateField = find.byKey(const Key('location_state_field'));
      await tester.enterText(stateField, 'Ubud');
      await tester.pump();

      // Tap save button
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Location for 1 member (6 days)');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();

      expect(savedCountry, 'Bali Remote Villa');
      expect(savedState, 'Ubud');
      expect(savedStart, DateTime(2026, 9, 15));
      expect(savedEnd, DateTime(2026, 9, 20));
      expect(savedMembers, ['user_123']);
    });

    testWidgets('revisiting with existing location maintains the saved location instead of resetting', (WidgetTester tester) async {
      // Simulate editing an existing event where user location was set to Japan
      // while default home country is Malaysia
      const existingNation = 'Japan';
      const existingState = 'Osaka';
      const defaultHomeCountry = 'Malaysia';
      const defaultHomeState = 'Penang';

      final resolvedCountry = (existingNation.isNotEmpty && existingNation != "No location selected")
          ? existingNation 
          : defaultHomeCountry;
      final resolvedState = (existingNation.isNotEmpty && existingNation != "No location selected")
          ? existingState 
          : defaultHomeState;

      await tester.pumpWidget(
        createTestableWidget(
          LocationPicker(
            currentUserId: 'user_123',
            defaultCountry: resolvedCountry,
            defaultState: resolvedState,
            initialStartDate: DateTime(2026, 9, 15),
            initialEndDate: DateTime(2026, 9, 15),
            onLocationSelected: (_, __, ___, ____, _____) {},
          ),
        ),
      );

      // Verify that Japan and Osaka are preserved, not Malaysia
      expect(find.text('Japan'), findsOneWidget);
      expect(find.text('Osaka'), findsOneWidget);
      expect(find.text('Malaysia'), findsNothing);
    });
  });
}
