import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lunar/lunar.dart';

class Group {
  final String id;
  final String name;
  final String ownerId;
  final List<String> admins;
  final List<String> members;

  Group({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.admins,
    required this.members,
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      admins: List<String>.from(data['admins'] ?? []),
      members: List<String>.from(data['members'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'admins': admins,
      'members': members,
    };
  }
}

class UserLocation {
  final String userId;
  final String groupId;
  final DateTime date;
  final String nation;
  final String? state;

  UserLocation({
    required this.userId,
    required this.groupId,
    required this.date,
    required this.nation,
    this.state,
  });

  factory UserLocation.fromFirestore(Map<String, dynamic> data) {
    return UserLocation(
      userId: data['userId'] ?? '',
      groupId: data['groupId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      nation: data['nation'] ?? '',
      state: data['state'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'groupId': groupId,
      'date': Timestamp.fromDate(date),
      'nation': nation,
      'state': state,
    };
  }
}

class Holiday {
  final String localName;
  final DateTime date;
  final String countryCode;

  Holiday({
    required this.localName,
    required this.date,
    required this.countryCode,
  });

  factory Holiday.fromJsonCalendarific(Map<String, dynamic> json) {
    return Holiday(
      localName: json['name'] ?? '',
      date: DateTime.parse(json['date']['iso']),
      countryCode: json['country']['id'] ?? '',
    );
  }

  factory Holiday.fromJsonFestivo(Map<String, dynamic> json) {
    return Holiday(
      localName: json['name'] ?? '',
      date: DateTime.parse(json['date']),
      countryCode: json['country'] ?? '',
    );
  }

  factory Holiday.fromGoogleCalendar(Map<String, dynamic> json, String calendarId) {
    // Parse date from Google Calendar format
    final startDate = json['start'];
    DateTime date;
    
    if (startDate['date'] != null) {
      // All-day event
      date = DateTime.parse(startDate['date']);
    } else if (startDate['dateTime'] != null) {
      // Timed event
      date = DateTime.parse(startDate['dateTime']);
    } else {
      date = DateTime.now();
    }

    // Extract country code from calendar ID
    String countryCode = 'GLOBAL';
    if (calendarId.contains('#holiday@group.v.calendar.google.com')) {
      final parts = calendarId.split('#');
      if (parts.isNotEmpty) {
        countryCode = parts[0].toUpperCase();
      }
    }

    return Holiday(
      localName: json['summary'] ?? 'Holiday',
      date: date,
      countryCode: countryCode,
    );
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String message;
  final DateTime timestamp;
  final bool read;

  AppNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
    required this.read,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }
}

class GroupEvent {
  final String id;
  final String groupId;
  final String creatorId;
  final String title;
  final String description;
  final String? venue; // Optional venue field
  final DateTime date;
  final bool hasTime;
  final Map<String, String> rsvps; // userId -> status ('Yes', 'No', 'Maybe')

  GroupEvent({
    required this.id,
    required this.groupId,
    required this.creatorId,
    required this.title,
    required this.description,
    this.venue,
    required this.date,
    this.hasTime = false,
    required this.rsvps,
  });

  factory GroupEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupEvent(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      creatorId: data['creatorId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      venue: data['venue'],
      date: (data['date'] as Timestamp).toDate(),
      hasTime: data['hasTime'] ?? false,
      rsvps: Map<String, String>.from(data['rsvps'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'venue': venue,
      'date': Timestamp.fromDate(date),
      'hasTime': hasTime,
      'rsvps': rsvps,
    };
  }

  // RSVP Helper Methods
  
  /// Get count of users with specific RSVP status
  int getRSVPCount(String status) {
    return rsvps.values.where((s) => s == status).length;
  }

  /// Get list of user IDs with specific RSVP status
  List<String> getUsersWithStatus(String status) {
    return rsvps.entries
        .where((entry) => entry.value == status)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get list of users who haven't responded yet
  List<String> getUsersWithNoResponse(List<String> allMembers) {
    return allMembers.where((userId) => !rsvps.containsKey(userId)).toList();
  }

  /// Get total number of responses (excluding no response)
  int getTotalResponses() {
    return rsvps.length;
  }

  /// Calculate response rate as percentage
  double getResponseRate(int totalMembers) {
    if (totalMembers == 0) return 0.0;
    return (rsvps.length / totalMembers) * 100;
  }

  /// Get accepted count
  int get acceptedCount => getRSVPCount('Yes');

  /// Get declined count
  int get declinedCount => getRSVPCount('No');

  /// Get maybe count
  int get maybeCount => getRSVPCount('Maybe');
}

class Birthday {
  final String userId;
  final String displayName;
  final DateTime birthDate; // Original birth date with year
  final DateTime occurrenceDate; // This year's occurrence
  final int age;
  final bool isLunar; // Whether this is a lunar calendar birthday

  Birthday({
    required this.userId,
    required this.displayName,
    required this.birthDate,
    required this.occurrenceDate,
    required this.age,
    this.isLunar = false,
  });

  // Helper to calculate birthday occurrence for a given year
  static Birthday? fromUserData(Map<String, dynamic> userData, int year) {
    final birthday = userData['birthday'];
    final isLunarBirthday = userData['isLunarBirthday'] ?? false;
    
    if (birthday == null) return null;

    final birthDate = (birthday as Timestamp).toDate();
    final userId = userData['uid'] ?? '';
    final displayName = userData['displayName'] ?? userData['email'] ?? 'User';

    DateTime occurrenceDate;
    int age = year - birthDate.year;

    if (isLunarBirthday) {
      // Convert lunar birth date to solar date for this year
      try {
        // Import lunar package at top of file
        final lunar = Lunar.fromDate(birthDate);
        // Find solar date for this lunar date in target year
        final solarDate = Solar.fromYmd(year, lunar.getMonth(), lunar.getDay());
        occurrenceDate = DateTime(year, solarDate.getMonth(), solarDate.getDay());
      } catch (e) {
        print('Error converting lunar birthday: $e');
        // Fallback to solar calendar
        occurrenceDate = DateTime(year, birthDate.month, birthDate.day);
      }
    } else {
      // Regular solar calendar birthday
      occurrenceDate = DateTime(year, birthDate.month, birthDate.day);
    }

    return Birthday(
      userId: userId,
      displayName: displayName,
      birthDate: birthDate,
      occurrenceDate: occurrenceDate,
      age: age,
      isLunar: isLunarBirthday,
    );
  }
}
