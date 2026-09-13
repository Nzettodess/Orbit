import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';
import 'user_avatar.dart';
import 'lunar_date_picker.dart';

/// Modal dialog displaying member profile details with nickname customization
class UserProfileDialog extends StatefulWidget {
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
  final String? memberId;
  final String? currentUserId;
  final String? alias;
  final ValueChanged<String?>? onAliasChanged;

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
    this.memberId,
    this.currentUserId,
    this.alias,
    this.onAliasChanged,
  });

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  late String? _currentAlias;
  bool _isSavingAlias = false;

  @override
  void initState() {
    super.initState();
    _currentAlias = widget.alias;
  }

  @override
  void didUpdateWidget(covariant UserProfileDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alias != oldWidget.alias) {
      _currentAlias = widget.alias;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d').format(date);
  }

  bool get _canSetAlias =>
      widget.memberId != null &&
      widget.currentUserId != null &&
      widget.memberId != widget.currentUserId;

  Future<void> _showEditAliasDialog() async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    final String? result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _EditAliasDialog(
        displayName: widget.displayName,
        initialAlias: _currentAlias,
      ),
    );

    if (result == null || !mounted) return;

    final effective = result == '__REMOVE__'
        ? null
        : (result.trim().isNotEmpty ? result.trim() : null);

    setState(() {
      _currentAlias = effective;
      _isSavingAlias = true;
    });

    String? errorMessage;
    if (widget.currentUserId != null && widget.memberId != null) {
      try {
        await FirestoreService().setMemberAlias(
          widget.currentUserId!,
          widget.memberId!,
          effective,
        );
      } catch (e) {
        errorMessage = e.toString();
        debugPrint('[UserProfileDialog] Error saving member alias: $e');
      }
    }

    // Notify parent to refresh list tiles
    widget.onAliasChanged?.call(effective);

    if (mounted) {
      setState(() => _isSavingAlias = false);
    }

    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          errorMessage != null
              ? "Failed to save to Firestore: $errorMessage"
              : (effective != null ? "Nickname set to '$effective'" : "Nickname removed"),
        ),
        backgroundColor: errorMessage != null ? Colors.red.shade800 : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double horizontalInset = 16.0;
    const double horizontalContentPadding = 16.0;
    final double maxDialogCardWidth = screenWidth < 600 ? (screenWidth - (horizontalInset * 2)) : 500.0;
    final double contentWidth = maxDialogCardWidth - (horizontalContentPadding * 2);

    final hasAlias = _currentAlias != null && _currentAlias!.trim().isNotEmpty;
    final effectiveName = hasAlias
        ? "${_currentAlias!.trim()} (${widget.displayName})"
        : widget.displayName;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 24.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 16.0, 0.0),
      contentPadding: const EdgeInsets.fromLTRB(horizontalContentPadding, 16.0, horizontalContentPadding, 8.0),
      title: Row(
        children: [
          Expanded(
            child: Text(
              effectiveName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.canEdit)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Edit User Info',
              onPressed: () {
                Navigator.pop(context);
                if (widget.onEdit != null) widget.onEdit!();
              },
            ),
        ],
      ),
      content: SizedBox(
        width: contentWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Center(
                child: widget.isPlaceholder
                    ? CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person_outline, size: 40, color: Colors.grey),
                      )
                    : UserAvatar(
                        photoUrl: widget.photoUrl,
                        name: hasAlias ? _currentAlias!.trim() : widget.displayName,
                        radius: 40,
                      ),
              ),
              const SizedBox(height: 16),

              // Nickname Tile
              if (_canSetAlias)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  leading: Icon(Icons.badge_outlined, color: Colors.amber.shade700),
                  title: const Text(
                    "Nickname",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    hasAlias ? _currentAlias! : "None (tap to set)",
                    style: !hasAlias
                        ? const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)
                        : const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: _isSavingAlias
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: Icon(hasAlias ? Icons.edit_outlined : Icons.add_circle_outline_rounded, size: 20, color: Colors.amber.shade800),
                          tooltip: hasAlias ? 'Change Nickname' : 'Add Nickname',
                          onPressed: _showEditAliasDialog,
                        ),
                  onTap: _showEditAliasDialog,
                ),

              // Info Tiles
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                leading: const Icon(Icons.location_on, color: Colors.blue),
                title: const Text("Default Location"),
                subtitle: Text(
                  widget.defaultLocation ?? "Not set",
                  style: widget.defaultLocation == null ? const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey) : null,
                ),
              ),

              // Birthdays
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                leading: const Icon(Icons.cake, color: Colors.pink),
                title: const Text("Birthday"),
                subtitle: Text(
                  widget.birthday != null ? _formatDate(widget.birthday!) : "Not set",
                  style: widget.birthday == null ? const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey) : null,
                ),
              ),

              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                leading: const Icon(Icons.nightlight_round, color: Colors.purple),
                title: const Text("Lunar Birthday"),
                subtitle: Text(
                  (widget.hasLunarBirthday && widget.lunarBirthdayMonth != null && widget.lunarBirthdayDay != null)
                      ? LunarDatePickerDialog.formatLunarDate(widget.lunarBirthdayMonth!, widget.lunarBirthdayDay!)
                      : "Not set",
                  style: (!widget.hasLunarBirthday || widget.lunarBirthdayMonth == null) ? const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey) : null,
                ),
              ),
            ],
          ),
        ),
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

class _EditAliasDialog extends StatefulWidget {
  final String displayName;
  final String? initialAlias;

  const _EditAliasDialog({
    required this.displayName,
    required this.initialAlias,
  });

  @override
  State<_EditAliasDialog> createState() => _EditAliasDialogState();
}

class _EditAliasDialogState extends State<_EditAliasDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAlias ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double horizontalInset = 16.0;
    const double horizontalContentPadding = 20.0;
    final double maxDialogCardWidth = screenWidth < 600 ? (screenWidth - (horizontalInset * 2)) : 500.0;
    final double contentWidth = maxDialogCardWidth - (horizontalContentPadding * 2);
    final bool hasExisting = widget.initialAlias != null && widget.initialAlias!.trim().isNotEmpty;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 24.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(horizontalContentPadding, 16.0, horizontalContentPadding, 8.0),
      title: Row(
        children: [
          Icon(Icons.badge_outlined, color: Colors.amber.shade700, size: 22),
          const SizedBox(width: 8),
          const Expanded(child: Text("Set Nickname", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
      content: SizedBox(
        width: contentWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Set a personal nickname for ${widget.displayName}. Only you see this across your calendar and member lists.",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Nickname",
                hintText: "e.g. Nick, Dave, Mom",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
              onSubmitted: (val) => Navigator.of(context).pop(val),
            ),
          ],
        ),
      ),
      actions: [
        if (hasExisting)
          TextButton(
            onPressed: () => Navigator.of(context).pop('__REMOVE__'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Save"),
        ),
      ],
    );
  }
}

