import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whereabouts/models.dart';
import 'package:whereabouts/religious_calendar_helper.dart';

void main() {
  group('UserLocation Model Tests', () {
    test('serializes and deserializes correctly', () {
      final date = DateTime(2026, 9, 15);
      final loc = UserLocation(
        userId: 'user_123',
        groupId: 'group_abc',
        date: date,
        nation: 'Malaysia',
        state: 'Penang',
      );

      final map = loc.toMap();
      expect(map['userId'], 'user_123');
      expect(map['groupId'], 'group_abc');
      expect(map['date'], '2026-09-15');
      expect(map['nation'], 'Malaysia');
      expect(map['state'], 'Penang');

      final fromMap = UserLocation.fromFirestore({
        'userId': 'user_123',
        'groupId': 'group_abc',
        'date': '2026-09-15',
        'nation': 'Malaysia',
        'state': 'Penang',
      });

      expect(fromMap.userId, 'user_123');
      expect(fromMap.nation, 'Malaysia');
      expect(fromMap.state, 'Penang');
      expect(fromMap.date.year, 2026);
      expect(fromMap.date.month, 9);
      expect(fromMap.date.day, 15);
    });

    test('handles Timestamp date format in fromFirestore', () {
      final now = DateTime(2026, 1, 1);
      final fromMap = UserLocation.fromFirestore({
        'userId': 'user_456',
        'groupId': 'group_xyz',
        'date': Timestamp.fromDate(now),
        'nation': 'Singapore',
      });

      expect(fromMap.userId, 'user_456');
      expect(fromMap.nation, 'Singapore');
      expect(fromMap.state, isNull);
      expect(fromMap.date.year, 2026);
    });
  });

  group('Holiday Model Tests', () {
    test('Holiday fromGoogleCalendar parses date and country code', () {
      final holiday = Holiday.fromGoogleCalendar({
        'summary': 'Independence Day',
        'start': {'date': '2026-08-31'},
      }, 'en-gb.malaysia#holiday@group.v.calendar.google.com');

      expect(holiday.localName, 'Independence Day');
      expect(holiday.date.year, 2026);
      expect(holiday.date.month, 8);
      expect(holiday.date.day, 31);
      expect(holiday.countryCode, 'EN-GB.MALAYSIA');
    });

    test('Holiday toMap and fromMap round-trip', () {
      final original = Holiday(
        localName: 'New Year',
        date: DateTime(2026, 1, 1),
        countryCode: 'GLOBAL',
      );

      final map = original.toMap();
      final restored = Holiday.fromMap(map);

      expect(restored.localName, 'New Year');
      expect(restored.date.year, 2026);
      expect(restored.countryCode, 'GLOBAL');
    });
  });

  group('Group and GroupEvent Model Tests', () {
    test('Group toMap outputs correct fields', () {
      final group = Group(
        id: 'g_1',
        name: 'Family',
        ownerId: 'u_owner',
        admins: ['u_owner', 'u_admin'],
        members: ['u_owner', 'u_admin', 'u_member'],
        lastBirthdayCheck: '2026-09-12',
      );

      final map = group.toMap();
      expect(map['name'], 'Family');
      expect(map['ownerId'], 'u_owner');
      expect(map['admins'], contains('u_admin'));
      expect(map['members'], hasLength(3));
      expect(map['lastBirthdayCheck'], '2026-09-12');
    });

    test('GroupEvent toMap outputs correct fields and RSVP map', () {
      final event = GroupEvent(
        id: 'e_1',
        groupId: 'g_1',
        creatorId: 'u_owner',
        title: 'Dinner Gathering',
        description: 'Casual dinner at restaurant',
        venue: 'Italian Bistro',
        date: DateTime(2026, 9, 20, 19, 0),
        hasTime: true,
        rsvps: {'u_owner': 'Yes', 'u_admin': 'Maybe'},
        timezone: 'Asia/Kuala_Lumpur',
      );

      final map = event.toMap();
      expect(map['title'], 'Dinner Gathering');
      expect(map['venue'], 'Italian Bistro');
      expect(map['hasTime'], isTrue);
      expect(map['rsvps']['u_owner'], 'Yes');
      expect(map['rsvps']['u_admin'], 'Maybe');
      expect(map['timezone'], 'Asia/Kuala_Lumpur');
      expect(map['date'], isA<Timestamp>());
    });
  });

  group('ReligiousCalendarHelper Tests', () {
    test('getChineseLunarDate returns formatted string', () {
      final date = DateTime(2026, 2, 17); // Chinese New Year in 2026
      final result = ReligiousCalendarHelper.getChineseLunarDate(date);
      expect(result, startsWith('🏮 '));
      expect(result, contains('月'));
    });

    test('getHijriDate returns formatted day and month', () {
      final date = DateTime(2026, 3, 20); // Ramadan in 2026
      final result = ReligiousCalendarHelper.getHijriDate(date);
      expect(result, matches(r'^\d+\/\d+$'));
    });

    test('getReligiousDates filters based on enabled calendars', () {
      final date = DateTime(2026, 5, 1);

      // Empty enabled list
      final empty = ReligiousCalendarHelper.getReligiousDates(date, []);
      expect(empty, isEmpty);

      // Only Chinese
      final chineseOnly = ReligiousCalendarHelper.getReligiousDates(date, ['chinese']);
      expect(chineseOnly.length, 1);
      expect(chineseOnly.first, startsWith('🏮 '));

      // Both Chinese and Islamic
      final both = ReligiousCalendarHelper.getReligiousDates(date, ['chinese', 'islamic']);
      expect(both.length, 2);
      expect(both.any((s) => s.startsWith('🏮 ')), isTrue);
      expect(both.any((s) => s.startsWith('☪️ ')), isTrue);
    });
  });

  group('Role Hierarchy Sorting Tests', () {
    test('sorts Owner first, then Admins, then Members, alphabetically by name', () {
      const ownerId = 'user_owner';
      const admin1 = 'user_admin_bob';
      const admin2 = 'user_admin_alice';
      const member1 = 'user_member_charlie';
      const member2 = 'user_member_aaron';

      final members = [member1, admin1, ownerId, member2, admin2];
      final admins = [admin1, admin2];
      final memberNames = {
        ownerId: 'Zack Owner',
        admin1: 'Bob Admin',
        admin2: 'Alice Admin',
        member1: 'Charlie Member',
        member2: 'Aaron Member',
      };

      // Sorting logic matching member_management.dart
      members.sort((a, b) {
        final aIsOwner = a == ownerId;
        final bIsOwner = b == ownerId;
        final aIsAdmin = admins.contains(a);
        final bIsAdmin = admins.contains(b);

        int aPriority = aIsOwner ? 0 : (aIsAdmin ? 1 : 2);
        int bPriority = bIsOwner ? 0 : (bIsAdmin ? 1 : 2);

        if (aPriority != bPriority) {
          return aPriority - bPriority;
        }

        final aName = (memberNames[a] ?? '').toLowerCase();
        final bName = (memberNames[b] ?? '').toLowerCase();
        return aName.compareTo(bName);
      });

      expect(members, [
        ownerId,            // Priority 0: Owner
        admin2,             // Priority 1: Alice (alphabetical)
        admin1,             // Priority 1: Bob
        member2,            // Priority 2: Aaron (alphabetical)
        member1,            // Priority 2: Charlie
      ]);
    });
  });
}
