import 'package:flutter_test/flutter_test.dart';
import 'package:whereabouts/core/utils/date_utils.dart';
import 'package:whereabouts/models.dart';

void main() {
  group('Core Utilities & Models Tests', () {
    test('formatDateKey formats YYYY-MM-DD correctly', () {
      final date = DateTime(2026, 9, 15);
      expect(formatDateKey(date), '2026-09-15');
    });

    test('getDaySuffix returns correct suffix', () {
      expect(getDaySuffix(1), '1st');
      expect(getDaySuffix(2), '2nd');
      expect(getDaySuffix(3), '3rd');
      expect(getDaySuffix(4), '4th');
      expect(getDaySuffix(11), '11th');
      expect(getDaySuffix(21), '21st');
      expect(getDaySuffix(22), '22nd');
      expect(getDaySuffix(23), '23rd');
    });

    test('UserLocation serialization works with custom location', () {
      final loc = UserLocation(
        userId: 'user_123',
        groupId: 'group_456',
        date: DateTime(2026, 9, 15),
        nation: 'South Korea',
        state: 'Seoul',
      );

      final map = loc.toMap();
      expect(map['userId'], 'user_123');
      expect(map['groupId'], 'group_456');
      expect(map['nation'], 'South Korea');
      expect(map['state'], 'Seoul');
      expect(map['date'], '2026-09-15');

      final deserialized = UserLocation.fromFirestore(map);
      expect(deserialized.userId, 'user_123');
      expect(deserialized.nation, 'South Korea');
      expect(deserialized.state, 'Seoul');
    });
  });
}
