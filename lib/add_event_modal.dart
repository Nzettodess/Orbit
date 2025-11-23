import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'firestore_service.dart';

class AddEventModal extends StatefulWidget {
  final String currentUserId;
  final DateTime initialDate;

  const AddEventModal({
    super.key,
    required this.currentUserId,
    required this.initialDate,
  });

  @override
  State<AddEventModal> createState() => _AddEventModalState();
}

class _AddEventModalState extends State<AddEventModal> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String? _selectedGroupId;
  List<Group> _userGroups = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _loadUserGroups();
  }

  void _loadUserGroups() {
    _firestoreService.getUserGroups(widget.currentUserId).listen((groups) {
      if (mounted) {
        setState(() {
          _userGroups = groups;
          if (groups.isNotEmpty) {
            _selectedGroupId = groups.first.id;
          }
        });
      }
    });
  }

  void _saveEvent() async {
    if (_formKey.currentState!.validate() && _selectedGroupId != null) {
      final event = GroupEvent(
        id: const Uuid().v4(),
        groupId: _selectedGroupId!,
        creatorId: widget.currentUserId,
        title: _titleController.text,
        description: _descController.text,
        date: _selectedDate,
        rsvps: {widget.currentUserId: 'Yes'}, // Creator automatically RSVPs Yes
      );

      await _firestoreService.createEvent(event);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Schedule Event", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Event Title"),
              validator: (value) => value!.isEmpty ? "Required" : null,
            ),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Date: "),
                TextButton(
                  onPressed: _pickDate,
                  child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGroupId,
              decoration: const InputDecoration(labelText: "Group"),
              items: _userGroups.map((g) => DropdownMenuItem(
                value: g.id,
                child: Text(g.name),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGroupId = value;
                });
              },
              validator: (value) => value == null ? "Select a group" : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveEvent,
              child: const Text("Create Event"),
            ),
          ],
        ),
      ),
    );
  }
}
