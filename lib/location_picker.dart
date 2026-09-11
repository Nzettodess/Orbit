import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/syncfusion_date_picker.dart';
import 'widgets/searchable_location_input.dart';
import 'widgets/location_data.dart';
import 'models/placeholder_member.dart';
import 'theme.dart';

class LocationPicker extends StatefulWidget {
  final Function(String country, String? state, DateTime startDate, DateTime endDate, List<String> selectedMemberIds) onLocationSelected;
  final String? defaultCountry;
  final String? defaultState;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String currentUserId;
  final List<PlaceholderMember> placeholderMembers;
  // Group members who allow location editing (filtered by privacy settings)
  final List<Map<String, dynamic>> groupMembers;
  // Is current user owner or admin (can set location for others)
  final bool isOwnerOrAdmin;

  const LocationPicker({
    super.key, 
    required this.onLocationSelected,
    this.defaultCountry,
    this.defaultState,
    this.initialStartDate,
    this.initialEndDate,
    required this.currentUserId,
    this.placeholderMembers = const [],
    this.groupMembers = const [],
    this.isOwnerOrAdmin = false,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  String? countryValue;
  String? stateValue;
  late DateTime startDate;
  late DateTime endDate;
  
  // Track selected members (current user always selected by default)
  late Set<String> selectedMemberIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize with default values (cleaned of flag emojis)
    countryValue = widget.defaultCountry != null ? LocationData.cleanText(widget.defaultCountry!) : null;
    stateValue = widget.defaultState != null ? LocationData.cleanText(widget.defaultState!) : null;
    
    // Initialize date range
    startDate = widget.initialStartDate ?? DateTime.now();
    endDate = widget.initialEndDate ?? DateTime.now();
    
    // Current user selected by default
    selectedMemberIds = {widget.currentUserId};
  }

  @override
  void didUpdateWidget(covariant LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.defaultCountry != oldWidget.defaultCountry) {
      setState(() {
        countryValue = widget.defaultCountry != null ? LocationData.cleanText(widget.defaultCountry!) : null;
      });
    }
    if (widget.defaultState != oldWidget.defaultState) {
      setState(() {
        stateValue = widget.defaultState != null ? LocationData.cleanText(widget.defaultState!) : null;
      });
    }
    if (widget.initialStartDate != oldWidget.initialStartDate && widget.initialStartDate != null) {
      setState(() {
        startDate = widget.initialStartDate!;
      });
    }
    if (widget.initialEndDate != oldWidget.initialEndDate && widget.initialEndDate != null) {
      setState(() {
        endDate = widget.initialEndDate!;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showSyncfusionDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Start Date',
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        // Ensure end date is not before start date
        if (endDate.isBefore(startDate)) {
          endDate = startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showSyncfusionDatePicker(
      context: context,
      initialDate: endDate.isBefore(startDate) ? startDate : endDate,
      firstDate: startDate, // Can't select before start date
      lastDate: DateTime(2030),
      helpText: 'Select End Date',
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  int get _dayCount => endDate.difference(startDate).inDays + 1;

  String _getSelectedMembersSummary() {
    final names = <String>[];
    if (selectedMemberIds.contains(widget.currentUserId)) {
      names.add("Myself");
    }
    for (final p in widget.placeholderMembers) {
      if (selectedMemberIds.contains(p.id)) {
        names.add(p.displayName);
      }
    }
    return names.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // SCROLLABLE CONTENT
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Set Location",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
            
            // Member Selection (if owner/admin with members to manage, or placeholder members exist)
            if (widget.placeholderMembers.isNotEmpty || 
                (widget.isOwnerOrAdmin && widget.groupMembers.isNotEmpty)) ...[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Row(
                    children: [
                      const Icon(Icons.people, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        "Apply to ${selectedMemberIds.length} member${selectedMemberIds.length > 1 ? 's' : ''}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _getSelectedMembersSummary(),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  children: [
                    const Divider(height: 1),
                    // Current user
                    CheckboxListTile(
                      dense: true,
                      title: const Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Myself"),
                        ],
                      ),
                      value: selectedMemberIds.contains(widget.currentUserId),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedMemberIds.add(widget.currentUserId);
                          } else {
                            if (selectedMemberIds.length > 1) {
                              selectedMemberIds.remove(widget.currentUserId);
                            }
                          }
                        });
                      },
                    ),
                    // Group members (who allow location editing)
                    if (widget.isOwnerOrAdmin && widget.groupMembers.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text("Group Members", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontWeight: FontWeight.bold)),
                      ),
                      ...widget.groupMembers.map((member) {
                        final memberId = member['uid'] as String;
                        final memberName = member['displayName'] ?? member['email'] ?? 'Unknown Member';
                        final photoUrl = member['photoURL'] as String?;
                        
                        return CheckboxListTile(
                          dense: true,
                          title: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                child: photoUrl == null ? const Icon(Icons.person, size: 14) : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  memberName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          value: selectedMemberIds.contains(memberId),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedMemberIds.add(memberId);
                              } else {
                                if (selectedMemberIds.length > 1) {
                                  selectedMemberIds.remove(memberId);
                                }
                              }
                            });
                          },
                        );
                      }),
                    ],
                    // Placeholder members
                    if (widget.placeholderMembers.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text("Placeholder Members", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      ...widget.placeholderMembers.map((placeholder) => CheckboxListTile(
                        dense: true,
                        title: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "👻 ${placeholder.displayName}",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        value: selectedMemberIds.contains(placeholder.id),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedMemberIds.add(placeholder.id);
                            } else {
                              if (selectedMemberIds.length > 1) {
                                selectedMemberIds.remove(placeholder.id);
                              }
                            }
                          });
                        },
                      )),
                    ],
                    // Quick actions
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedMemberIds = {widget.currentUserId};
                                for (var p in widget.placeholderMembers) {
                                  selectedMemberIds.add(p.id);
                                }
                                for (var m in widget.groupMembers) {
                                  selectedMemberIds.add(m['uid'] as String);
                                }
                              });
                            },
                            child: const Text("Select All", style: TextStyle(fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedMemberIds = {widget.currentUserId};
                              });
                            },
                            child: const Text("Only Me", style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Date Range Selection
            Text(
              "Date Range",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Start Date",
                            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(startDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "End Date",
                            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(endDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "$_dayCount day${_dayCount > 1 ? 's' : ''} selected",
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Searchable & Free-Text Location Input
            SearchableLocationInput(
              initialCountry: countryValue,
              initialState: stateValue,
              onCountryChanged: (value) {
                setState(() {
                  countryValue = value.trim().isNotEmpty ? value.trim() : null;
                });
              },
              onStateChanged: (value) {
                setState(() {
                  stateValue = (value != null && value.trim().isNotEmpty) ? value.trim() : null;
                });
              },
            ),
              ],
            ),
          ),
        ),
        
        // FIXED FOOTER - Save button stays at bottom
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () async {
                if (countryValue != null && countryValue!.isNotEmpty && selectedMemberIds.isNotEmpty) {
                  setState(() => _isSaving = true);
                  try {
                    await widget.onLocationSelected(
                      countryValue!, 
                      stateValue, 
                      startDate, 
                      endDate,
                      selectedMemberIds.toList(),
                    );
                    if (mounted) {
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isSaving = false);
                    }
                  }
                } else if (countryValue == null || countryValue!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter or select a country/location")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select at least one member")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getButtonBackground(context),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving 
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white, semanticsLabel: "Saving location…"),
                  )
                : Text(
                    "Save Location for ${selectedMemberIds.length} member${selectedMemberIds.length > 1 ? 's' : ''} " 
                    "($_dayCount day${_dayCount > 1 ? 's' : ''})"
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
