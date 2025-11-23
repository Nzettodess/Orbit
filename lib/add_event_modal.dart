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
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  late DateTime _selectedDate;
  bool _isAllDay = false;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveEvent() async {
    if (_formKey.currentState!.validate() && _selectedGroupId != null) {
      DateTime eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _isAllDay ? 0 : _selectedTime.hour,
        _isAllDay ? 0 : _selectedTime.minute,
      );

      final event = GroupEvent(
        id: const Uuid().v4(),
        groupId: _selectedGroupId!,
        creatorId: widget.currentUserId,
        title: _titleController.text,
        description: _descController.text,
        date: eventDateTime,
        isAllDay: _isAllDay,
        rsvps: {widget.currentUserId: 'Yes'},
      );

      await _firestoreService.createEvent(event);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Schedule Event", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Date: "),
                TextButton(
                  onPressed: _pickDate,
                  child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text("All Day"),
              value: _isAllDay,
              onChanged: (bool value) {
                setState(() {
                  _isAllDay = value;
                });
              },
            ),
            if (!_isAllDay)
              Row(
                children: [
                  const Text("Time: "),
                  TextButton(
                    onPressed: () => _selectTime(context),
                    child: Text(_selectedTime.format(context)),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveEvent,
                child: const Text("Create Event"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
