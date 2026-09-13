import 'package:flutter_test/flutter_test.dart';

String formatMemberDisplayName(String name, String? alias) {
  final hasAlias = alias != null && alias.trim().isNotEmpty;
  return hasAlias ? '${alias.trim()} ($name)' : name;
}

String formatLocationSubtitle(String nation, String? state) {
  if (nation == 'No location selected') {
    return 'No location selected';
  }
  return '$nation${state != null && state.isNotEmpty ? ', $state' : ''}';
}

void main() {
  group('Member display name formatting', () {
    test('Formats as "nickname (orig name)" when alias is set', () {
      expect(
        formatMemberDisplayName('nz nz', 'Bestie'),
        'Bestie (nz nz)',
      );
      expect(
        formatMemberDisplayName('John Doe', 'Bro'),
        'Bro (John Doe)',
      );
    });

    test('Trims whitespace from alias before formatting', () {
      expect(
        formatMemberDisplayName('nz nz', '  Bestie  '),
        'Bestie (nz nz)',
      );
    });

    test('Falls back to orig name when alias is null', () {
      expect(
        formatMemberDisplayName('nz nz', null),
        'nz nz',
      );
    });

    test('Falls back to orig name when alias is empty or whitespace', () {
      expect(
        formatMemberDisplayName('nz nz', ''),
        'nz nz',
      );
      expect(
        formatMemberDisplayName('nz nz', '   '),
        'nz nz',
      );
    });
  });

  group('Location subtitle formatting (unaffected by nickname)', () {
    test('Formats nation and state correctly', () {
      expect(
        formatLocationSubtitle('United States', 'California'),
        'United States, California',
      );
      expect(
        formatLocationSubtitle('Malaysia', 'Penang'),
        'Malaysia, Penang',
      );
    });

    test('Formats nation only when state is null or empty', () {
      expect(
        formatLocationSubtitle('Singapore', null),
        'Singapore',
      );
      expect(
        formatLocationSubtitle('Singapore', ''),
        'Singapore',
      );
    });

    test('Preserves "No location selected"', () {
      expect(
        formatLocationSubtitle('No location selected', null),
        'No location selected',
      );
    });
  });
}
