import 'package:flutter/material.dart';

/// Lunar date picker dialog showing months and days in traditional Chinese format
/// Returns a tuple of (month, day) as integers
class LunarDatePickerDialog extends StatefulWidget {
  final int? initialMonth;
  final int? initialDay;

  const LunarDatePickerDialog({
    super.key,
    this.initialMonth,
    this.initialDay,
  });

  // Chinese lunar month names
  static const List<String> lunarMonths = [
    '正月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '冬月', '腊月',
  ];

  // Convert day number to Chinese lunar day name
  static String getLunarDayName(int day) {
    const units = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
    
    if (day <= 10) {
      return '初${units[day]}';
    } else if (day == 20) {
      return '二十';
    } else if (day == 30) {
      return '三十';
    } else if (day < 20) {
      return '十${units[day - 10]}';
    } else if (day < 30) {
      return '廿${units[day - 20]}';
    }
    return '';
  }

  // Chinese lunar day names (初一 to 三十)
  static List<String> get lunarDays {
    final days = <String>[];
    for (int i = 1; i <= 30; i++) {
      days.add(getLunarDayName(i));
    }
    return days;
  }

  // Public helper to format lunar date for display
  static String formatLunarDate(int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 30) {
      return 'Invalid date';
    }
    return '${lunarMonths[month - 1]}${getLunarDayName(day)}';
  }

  @override
  State<LunarDatePickerDialog> createState() => _LunarDatePickerDialogState();
}

class _LunarDatePickerDialogState extends State<LunarDatePickerDialog> {
  late int selectedMonth;
  late int selectedDay;

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.initialMonth ?? 1;
    selectedDay = widget.initialDay ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.nights_stay, size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      '选择农历生日',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Select Lunar Birthday',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Month and Day pickers side by side
            Row(
              children: [
                // Month picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '月份 (Month)',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            final isSelected = selectedMonth == index + 1;
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              selectedTileColor: Colors.deepPurple.withOpacity(0.1),
                              title: Text(
                                LunarDatePickerDialog.lunarMonths[index],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.deepPurple : null,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedMonth = index + 1;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Day picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '日期 (Day)',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: 30,
                          itemBuilder: (context, index) {
                            final isSelected = selectedDay == index + 1;
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              selectedTileColor: Colors.deepPurple.withOpacity(0.1),
                              title: Text(
                                LunarDatePickerDialog.lunarDays[index],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.deepPurple : null,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedDay = index + 1;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected date display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎂 ', style: TextStyle(fontSize: 18)),
                  Text(
                    LunarDatePickerDialog.formatLunarDate(selectedMonth, selectedDay),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, (selectedMonth, selectedDay)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show the lunar date picker
Future<(int, int)?> showLunarDatePicker({
  required BuildContext context,
  int? initialMonth,
  int? initialDay,
}) async {
  return await showDialog<(int, int)>(
    context: context,
    builder: (context) => LunarDatePickerDialog(
      initialMonth: initialMonth,
      initialDay: initialDay,
    ),
  );
}
