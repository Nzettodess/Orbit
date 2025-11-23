import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'firestore_service.dart';
import 'religious_calendar_helper.dart';
import 'location_picker.dart';

class DetailModal extends StatefulWidget {
  final DateTime date;
  final List<UserLocation> locations;
  final List<GroupEvent> events;
  final List<Holiday> holidays;
  final String currentUserId;

  const DetailModal({
    super.key,
    required this.date,
    required this.locations,
    required this.events,
    required this.holidays,
    required this.currentUserId,
  });

  @override
  State<DetailModal> createState() => _DetailModalState();
}

class _DetailModalState extends State<DetailModal> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, Map<String, dynamic>> _userDetails = {};
  Map<String, String> _groupNames = {}; // Map groupId -> groupName
  List<String> _pinnedMembers = [];

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadPinnedMembers();
    _loadGroupNames();
  }

  Future<void> _loadGroupNames() async {
    // Load group names for all groups in locations
    final groupIds = widget.locations.map((l) => l.groupId).toSet();
    for (final groupId in groupIds) {
      final doc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
      if (doc.exists) {
        setState(() {
          _groupNames[groupId] = doc.data()?['name'] ?? 'Unknown Group';
        });
      }
    }
  }

  Future<List<String>> _getReligiousDates() async {
    // Get user's enabled religious calendars from Firestore
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).get();
    if (doc.exists) {
      final data = doc.data();
      final religious = data?['religiousCalendars'];
      if (religious != null && religious is List) {
        final enabledCalendars = List<String>.from(religious);
        return ReligiousCalendarHelper.getReligiousDates(widget.date, enabledCalendars);
      }
    }
    return [];
  }

  Future<void> _loadPinnedMembers() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).get();
    if (doc.exists) {
      setState(() {
        _pinnedMembers = List<String>.from(doc.data()?['pinnedMembers'] ?? []);
      });
    }
  }

  Future<void> _loadUserDetails() async {
    final userIds = widget.locations.map((l) => l.userId).toSet();
    for (final uid in userIds) {
      if (!_userDetails.containsKey(uid)) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          setState(() {
            _userDetails[uid] = doc.data() as Map<String, dynamic>;
          });
        }
      }
    }
  }

  Future<void> _togglePin(String userId) async {
    List<String> newPinned = List.from(_pinnedMembers);
    if (newPinned.contains(userId)) {
      newPinned.remove(userId);
    } else {
      newPinned.add(userId);
    }

    await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).update({
      'pinnedMembers': newPinned,
    });

    setState(() {
      _pinnedMembers = newPinned;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: const Center(child: Text("Detail Modal Simplified")),
    );
  }
}
