import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'firestore_service.dart';
import 'religious_calendar_helper.dart';
import 'location_picker.dart';
import 'add_event_modal.dart';
import 'widgets/user_avatar.dart';
import 'rsvp_management.dart';

class DetailModal extends StatefulWidget {
  final DateTime date;
  final List<UserLocation> locations;
  final List<GroupEvent> events;
  final List<Holiday> holidays;
  final List<Birthday> birthdays;
  final String currentUserId;

  const DetailModal({
    super.key,
    required this.date,
    required this.locations,
    required this.events,
    required this.holidays,
    required this.birthdays,
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

  /// Deduplicates locations by userId - each user appears only once.
  /// Priority: explicit location > default location > "No location selected"
  /// Uses a "global" groupId for consolidated view.
  List<UserLocation> _getDeduplicatedLocations() {
    final Map<String, UserLocation> userLocationMap = {};
    
    for (final loc in widget.locations) {
      final userId = loc.userId;
      final existing = userLocationMap[userId];
      
      if (existing == null) {
        // First occurrence - add it with 'global' groupId
        userLocationMap[userId] = UserLocation(
          userId: loc.userId,
          groupId: 'global', // Use 'global' for consolidated view
          date: loc.date,
          nation: loc.nation,
          state: loc.state,
        );
      } else {
        // Already exists - prefer explicit location over "No location selected"
        final isNewExplicit = loc.nation != "No location selected";
        final isExistingNoLocation = existing.nation == "No location selected";
        
        if (isNewExplicit && isExistingNoLocation) {
          // Replace with the explicit location
          userLocationMap[userId] = UserLocation(
            userId: loc.userId,
            groupId: 'global',
            date: loc.date,
            nation: loc.nation,
            state: loc.state,
          );
        }
        // Otherwise keep existing (first explicit wins)
      }
    }
    
    return userLocationMap.values.toList();
  }

  Future<void> _loadGroupNames() async {
    // Load group names for all groups in locations
    final groupIds = widget.locations.map((l) => l.groupId).toSet();
    for (final groupId in groupIds) {
      // Handle special "global" groupId
      if (groupId == 'global') {
        setState(() {
          _groupNames['global'] = 'All Members';
        });
        continue;
      }
      
      final doc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
      if (doc.exists) {
        setState(() {
          _groupNames[groupId] = doc.data()?['name'] ?? 'Unknown Group';
        });
      } else {
        // Group doesn't exist, use a readable fallback
        setState(() {
          _groupNames[groupId] = 'Group';
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
        // Check if this is a placeholder member
        if (uid.startsWith('placeholder_')) {
          final doc = await FirebaseFirestore.instance.collection('placeholder_members').doc(uid).get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            setState(() {
              _userDetails[uid] = {
                'displayName': '👻 ${data['displayName'] ?? 'Placeholder'}',
                'photoURL': null,
                'isPlaceholder': true,
                'groupId': data['groupId'],
              };
            });
          }
        } else {
          // Regular user
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists) {
            setState(() {
              _userDetails[uid] = doc.data() as Map<String, dynamic>;
            });
          }
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

  // Check if current user is owner or admin of the group
  Future<bool> _isOwnerOrAdminOfGroup(String groupId) async {
    if (groupId == 'global') return false;
    final doc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    final ownerId = data['ownerId'] as String?;
    final admins = List<String>.from(data['admins'] ?? []);
    return ownerId == widget.currentUserId || admins.contains(widget.currentUserId);
  }

  // Edit placeholder member location
  Future<void> _editPlaceholderLocation(UserLocation element) async {
    final result = await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: LocationPicker(
            currentUserId: widget.currentUserId,
            defaultCountry: element.nation,
            defaultState: element.state,
            initialStartDate: widget.date,
            initialEndDate: widget.date,
            onLocationSelected: (country, state, startDate, endDate, selectedMemberIds) async {
              // Save the placeholder location
              await _firestoreService.setPlaceholderMemberLocationRange(
                element.userId,
                element.groupId,
                startDate,
                endDate,
                country,
                state,
              );
              Navigator.pop(context, true);
            },
          ),
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context); // Refresh detail modal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Details for ${widget.date.toLocal().toString().split(' ')[0]}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          
          // Religious Calendar Dates
          FutureBuilder<List<String>>(
            future: _getReligiousDates(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    ...snapshot.data!.map((date) => Text(
                      date,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    )),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const SizedBox(height: 10),
          
          // Holidays
          if (widget.holidays.isNotEmpty) ...[
            const Text("Holidays", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ...widget.holidays.map((h) => ListTile(
              leading: const Icon(Icons.star, color: Colors.red),
              title: Text(h.localName),
              subtitle: Text(h.countryCode),
            )),
            const Divider(),
          ],

          // Birthdays
          if (widget.birthdays.isNotEmpty) ...[
            const Text("Birthdays 🎂", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ...widget.birthdays.map((b) => ListTile(
              leading: Icon(
                b.isLunar ? Icons.nights_stay : Icons.cake, 
                color: b.isLunar ? Colors.orange : Colors.green,
              ),
              title: Text(b.isLunar ? "${b.displayName} [lunar birthday]" : b.displayName),
              subtitle: b.isLunar ? null : Text("Turning ${b.age} years old"),
            )),
            const Divider(),
          ],

          // Events
          if (widget.events.isNotEmpty) ...[
             const Text("Events", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
             ...widget.events.map((e) {
               final isOwner = e.creatorId == widget.currentUserId;
               return ListTile(
                 leading: const Icon(Icons.event, color: Colors.blue),
                 title: Text("${e.title} (${e.hasTime ? DateFormat('yyyy-MM-dd HH:mm').format(e.date) : DateFormat('yyyy-MM-dd').format(e.date)})"),
                 subtitle: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     if (e.description.isNotEmpty)
                       Text(
                         e.description,
                         softWrap: true,
                         maxLines: 3,
                         overflow: TextOverflow.ellipsis,
                       ),
                     if (e.venue != null && e.venue!.isNotEmpty)
                       Row(
                         children: [
                           const Icon(Icons.location_on, size: 14, color: Colors.grey),
                           const SizedBox(width: 4),
                           Expanded(
                             child: Text(
                               e.venue!,
                               style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                         ],
                       ),
                     FutureBuilder<DocumentSnapshot>(
                       future: FirebaseFirestore.instance.collection('users').doc(e.creatorId).get(),
                       builder: (context, snapshot) {
                         if (snapshot.hasData) {
                           final data = snapshot.data!.data() as Map<String, dynamic>?;
                           return Text("Owner: ${data?['displayName'] ?? 'Unknown'}", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12));
                         }
                         return const SizedBox.shrink();
                       },
                     ),
                   ],
                 ),
                 trailing: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     if (isOwner) ...[
                       IconButton(
                         icon: const Icon(Icons.edit, color: Colors.blue),
                         onPressed: () {
                           Navigator.pop(context);
                           showModalBottomSheet(
                             context: context,
                             isScrollControlled: true,
                             builder: (context) => AddEventModal(
                               currentUserId: widget.currentUserId,
                               initialDate: e.date,
                               eventToEdit: e,
                             ),
                           );
                         },
                       ),
                       IconButton(
                         icon: const Icon(Icons.delete, color: Colors.red),
                         onPressed: () async {
                           await _firestoreService.deleteEvent(e.id);
                           if (mounted) Navigator.pop(context);
                         },
                       ),
                     ],
                     IconButton(
                        icon: const Icon(Icons.bar_chart, color: Colors.deepPurple),
                        tooltip: 'RSVP Stats',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => RSVPManagementDialog(
                              currentUserId: widget.currentUserId,
                            ),
                          );
                        },
                      ),
                     const SizedBox(width: 8),
                     ElevatedButton(
                       onPressed: () => _showRSVPDialog(e),
                       child: const Text("RSVP"),
                     ),
                   ],
                 ),
               );
             }),
             const Divider(),
          ],

          // Locations (Grouped) - Deduplicated
          Expanded(
            child: Builder(
              builder: (context) {
                final deduplicatedLocations = _getDeduplicatedLocations();
                
                if (deduplicatedLocations.isEmpty) {
                  return const Center(child: Text("No member locations set."));
                }
                
                return GroupedListView<UserLocation, String>(
                  elements: deduplicatedLocations,
                  groupBy: (element) {
                    // Current user always at top
                    if (element.userId == widget.currentUserId) {
                      return "___CURRENT_USER"; // Special key to sort first
                    }
                    // Pinned members second
                    if (_pinnedMembers.contains(element.userId)) {
                      return "___FAVORITES";
                    }
                    // All other members
                    return "___OTHER_MEMBERS";
                  },
                  groupComparator: (value1, value2) {
                    if (value1 == "___CURRENT_USER") return -1;
                    if (value2 == "___CURRENT_USER") return 1;
                    if (value1 == "___FAVORITES") return -1;
                    if (value2 == "___FAVORITES") return 1;
                    return value1.compareTo(value2);
                  },
                  groupSeparatorBuilder: (String value) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      value == "___CURRENT_USER" 
                        ? "You" 
                        : value == "___FAVORITES" 
                          ? "Favorites" 
                          : "Members",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                  itemBuilder: (context, element) {
                    final user = _userDetails[element.userId];
                    final name = user?['displayName'] ?? user?['email'] ?? "Unknown User";
                    final photoUrl = user?['photoURL'];
                    final isPinned = _pinnedMembers.contains(element.userId);
                    final isCurrentUser = element.userId == widget.currentUserId;
                    final isPlaceholder = element.userId.startsWith('placeholder_');

                    return FutureBuilder<bool>(
                      future: isPlaceholder ? _isOwnerOrAdminOfGroup(element.groupId) : Future.value(false),
                      builder: (context, canEditSnapshot) {
                        final canEditPlaceholder = canEditSnapshot.data ?? false;

                        return ListTile(
                          leading: isPlaceholder
                            ? CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person_outline, color: Colors.grey),
                              )
                            : UserAvatar(
                                photoUrl: photoUrl,
                                name: name,
                                radius: 20,
                              ),
                          title: Text(name),
                          subtitle: element.nation == "No location selected"
                            ? Text(
                                "No location selected",
                                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              )
                            : Text("${element.nation}${element.state != null && element.state!.isNotEmpty ? ', ${element.state}' : ''}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edit for placeholder members (owner/admin only)
                              if (isPlaceholder && canEditPlaceholder)
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                  onPressed: () => _editPlaceholderLocation(element),
                                  tooltip: 'Edit Placeholder Location',
                                ),
                              // Edit/Delete for own location
                              if (isCurrentUser) ...[
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                // Fetch user's default location for pre-population
                                final userDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.currentUserId)
                                    .get();
                                final defaultLocation = userDoc.data()?['defaultLocation'] as String?;
                                
                                // Helper function to remove emoji flags
                                String stripEmojis(String text) {
                                  return text.replaceAll(RegExp(r'[\u{1F1E6}-\u{1F1FF}]|\p{Emoji_Presentation}|\p{Emoji}\uFE0F', unicode: true), '').trim();
                                }
                                
                                String? defaultCountry;
                                String? defaultState;
                                
                                if (defaultLocation != null && defaultLocation.isNotEmpty) {
                                  final parts = defaultLocation.split(',');
                                  if (parts.length == 2) {
                                    // Format: "🇲🇾 Country, State"
                                    defaultCountry = stripEmojis(parts[0].trim());  // First part is COUNTRY
                                    defaultState = stripEmojis(parts[1].trim());     // Second part is STATE
                                  } else {
                                    defaultCountry = stripEmojis(parts[0].trim());
                                  }
                                }
                                
                                if (!mounted) return;
                                
                                // Show location picker to edit
                                final result = await showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 500),
                                      child: LocationPicker(
                                        currentUserId: widget.currentUserId,
                                        defaultCountry: defaultCountry ?? element.nation,
                                        defaultState: defaultState ?? element.state,
                                        initialStartDate: widget.date,
                                        initialEndDate: widget.date, // Default to single day
                                        onLocationSelected: (country, state, startDate, endDate, selectedMemberIds) async {
                                          // Save the updated location for date range
                                          await _firestoreService.setLocationRange(
                                            widget.currentUserId,
                                            element.groupId,
                                            startDate,
                                            endDate,
                                            country,
                                            state,
                                          );
                                          Navigator.pop(context, true); // Return true to indicate success
                                        },
                                      ),
                                    ),
                                  ),
                                );
                                if (result == true && mounted) {
                                  Navigator.pop(context); // Refresh detail modal
                                }
                              },
                              tooltip: 'Edit Location',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () async {
                                // Delete location - reverts to default
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete Location?'),
                                    content: const Text('This will revert to your default location for this date.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true) {
                                  // Delete from Firestore
                                  final dateStr = "${widget.date.year}${widget.date.month.toString().padLeft(2, '0')}${widget.date.day.toString().padLeft(2, '0')}";
                                  final docId = "${element.userId}_${element.groupId}_$dateStr";
                                  await FirebaseFirestore.instance.collection('user_locations').doc(docId).delete();
                                  if (mounted) Navigator.pop(context); // Refresh
                                }
                              },
                              tooltip: 'Delete (Revert to Default)',
                            ),
                          ],
                          // Pin button for all users
                          IconButton(
                            icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                            color: isPinned ? Colors.blue : Colors.grey,
                            onPressed: () => _togglePin(element.userId),
                          ),
                        ],
                      ),
                    );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRSVPDialog(GroupEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("RSVP for ${event.title}"),
        content: const Text("Are you going?"),
        actions: [
          TextButton(
            onPressed: () {
              _firestoreService.rsvpEvent(event.id, widget.currentUserId, 'No');
              Navigator.pop(context);
            },
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              _firestoreService.rsvpEvent(event.id, widget.currentUserId, 'Maybe');
              Navigator.pop(context);
            },
            child: const Text("Maybe"),
          ),
          ElevatedButton(
            onPressed: () {
              _firestoreService.rsvpEvent(event.id, widget.currentUserId, 'Yes');
              Navigator.pop(context);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }
}
