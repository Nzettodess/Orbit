import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'user_avatar.dart';
import 'lunar_date_picker.dart';

class UserProfileDialog extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final String? defaultLocation;
  final DateTime? birthday;
  final bool hasLunarBirthday;
  final int? lunarBirthdayMonth;
  final int? lunarBirthdayDay;
  final bool isPlaceholder;
  final bool canEdit;
  final VoidCallback? onEdit;
  
  const UserProfileDialog({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.defaultLocation,
    this.birthday,
    this.hasLunarBirthday = false,
    this.lunarBirthdayMonth,
    this.lunarBirthdayDay,
    this.isPlaceholder = false,
    this.canEdit = false,
    this.onEdit,
  });

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(displayName, overflow: TextOverflow.ellipsis)),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Edit User Info',
              onPressed: () {
                Navigator.pop(context);
                if (onEdit != null) onEdit!();
              },
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           // Avatar
           Center(
             child: isPlaceholder
               ? CircleAvatar(
                   radius: 40,
                   backgroundColor: Colors.grey[300],
                   child: const Icon(Icons.person_outline, size: 40, color: Colors.grey),
                 )
               : UserAvatar(
                   photoUrl: photoUrl,
                   name: displayName,
                   radius: 40,
                 ),
           ),
           const SizedBox(height: 16),
           
           // Info Tiles
           ListTile(
             leading: const Icon(Icons.location_on, color: Colors.blue),
             title: const Text("Default Location"),
             subtitle: Text(defaultLocation ?? "Not set", 
               style: defaultLocation == null ? const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey) : null),
           ),
           
           // Birthdays - Always shown
           ListTile(
             leading: const Icon(Icons.cake, color: Colors.pink),
             title: const Text("Birthday"),
             subtitle: Text(
               birthday != null ? _formatDate(birthday!) : "Not set",
               style: birthday == null ? const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey) : null
             ),
           ),
             
            ListTile(
              leading: const Icon(Icons.nightlight_round, color: Colors.purple),
              title: const Text("Lunar Birthday"),
              subtitle: Text(
                (hasLunarBirthday && lunarBirthdayMonth != null && lunarBirthdayDay != null)
                  ? LunarDatePickerDialog.formatLunarDate(lunarBirthdayMonth!, lunarBirthdayDay!)
                  : "Not set",
                style: (!hasLunarBirthday || lunarBirthdayMonth == null) ? const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey) : null
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
