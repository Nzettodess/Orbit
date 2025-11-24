import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../religious_calendar_helper.dart';
import '../detail_modal.dart';

class HomeCalendar extends StatefulWidget {
  final CalendarController controller;
  final List<UserLocation> locations;
  final List<GroupEvent> events;
  final List<Holiday> holidays;
  final List<Map<String, dynamic>> allUsers;
  final String tileCalendarDisplay;
  final List<String> religiousCalendars;
  final Function(String, DateTime) onMonthChanged;
  final String currentUserId;
  final DateTime currentViewMonth;

  const HomeCalendar({
    super.key,
    required this.controller,
    required this.locations,
    required this.events,
    required this.holidays,
    required this.allUsers,
    required this.tileCalendarDisplay,
    required this.religiousCalendars,
    required this.onMonthChanged,
    required this.currentUserId,
    required this.currentViewMonth,
  });

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  // Helper to get effective locations for a date
  List<UserLocation> _getLocationsForDate(DateTime date) {
    // 1. Get explicit locations
    final explicit = widget.locations.where((l) => 
      l.date.year == date.year && l.date.month == date.month && l.date.day == date.day).toList();
    
    final explicitUserIds = explicit.map((l) => l.userId).toSet();

    // 2. Add default locations for users who don't have explicit location
    final defaults = <UserLocation>[];
    for (final user in widget.allUsers) {
      if (!explicitUserIds.contains(user['uid']) && user['defaultLocation'] != null && (user['defaultLocation'] as String).isNotEmpty) {
        // Parse default location "Country, State" or "Country"
        final parts = (user['defaultLocation'] as String).split(', ');
        final country = parts[0];
        final state = parts.length > 1 ? parts[1] : null;
        
        defaults.add(UserLocation(
          userId: user['uid'],
          groupId: "global", // or "default"
          date: date,
          nation: country,
          state: state,
        ));
      }
    }

    return [...explicit, ...defaults];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SfCalendar(
        controller: widget.controller,
        view: CalendarView.month,
        headerHeight: 0,
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
          showAgenda: false,
        ),
        onViewChanged: (ViewChangedDetails details) {
          if (details.visibleDates.isNotEmpty) {
            final midDate = details.visibleDates[details.visibleDates.length ~/ 2];
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                widget.onMonthChanged(DateFormat('MMMM yyyy').format(midDate), midDate);
              }
            });
          }
        },
        monthCellBuilder: (context, details) {
          final date = details.date;
          final isToday = date.year == DateTime.now().year && 
                         date.month == DateTime.now().month && 
                         date.day == DateTime.now().day;
          final isCurrentMonth = date.month == widget.currentViewMonth.month;
          
          final dayLocations = _getLocationsForDate(date);
          final dayHolidays = widget.holidays.where((h) => 
            h.date.year == date.year && h.date.month == date.month && h.date.day == date.day).toList();
          final dayEvents = widget.events.where((e) => 
            e.date.year == date.year && e.date.month == date.month && e.date.day == date.day).toList();
          
          // Get religious calendar dates for this day
          final religiousDates = ReligiousCalendarHelper.getReligiousDates(
            date, 
            widget.tileCalendarDisplay == 'none' ? [] : [widget.tileCalendarDisplay]
          );
          
          // Items to display as bars (Holidays & Events)
          final allItems = [...dayHolidays, ...dayEvents];
          final maxBars = 2;
          final displayItems = allItems.take(maxBars).toList();
          final remainingCount = allItems.length - maxBars;

          return Container(
            decoration: BoxDecoration(
              border: isToday 
                ? Border.all(color: Colors.deepPurple, width: 2.5)
                : Border.all(color: Colors.grey.withOpacity(0.1)),
              color: isToday 
                ? Colors.deepPurple.withOpacity(0.05) 
                : (isCurrentMonth ? null : Colors.grey[50]),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.0), // Reduced padding for overflow fix
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(date.day.toString(), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 14,
                          color: isToday 
                            ? Colors.deepPurple 
                            : (isCurrentMonth ? Colors.black87 : Colors.grey)
                        )),
                      if (religiousDates.isNotEmpty)
                        Expanded(
                          child: Text(
                            religiousDates.join(' '),
                            style: TextStyle(
                              fontSize: 9, 
                              color: isCurrentMonth ? Colors.black54 : Colors.grey, 
                              fontWeight: FontWeight.w500
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 1), // Reduced spacing
                  // Display Bars
                  ...displayItems.map((item) {
                    String title = "";
                    Color color = Colors.blue;
                    if (item is Holiday) {
                      title = item.localName;
                      color = Colors.red.withOpacity(0.7);
                    } else if (item is GroupEvent) {
                      title = item.title;
                      color = Colors.blue.withOpacity(0.7);
                    }
                    
                    // Dim bars for non-current month
                    if (!isCurrentMonth) {
                      color = color.withOpacity(0.3);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 0.5), // Reduced margin
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      width: double.infinity,
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 7.5), // Reduced font size
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                  if (remainingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        "+$remainingCount more",
                        style: TextStyle(
                          fontSize: 7, // Reduced font size
                          color: isCurrentMonth ? Colors.grey : Colors.grey[300], 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  
                  const Spacer(),
                  // Avatars
                  if (dayLocations.isNotEmpty)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 1,
                      runSpacing: 1,
                      children: dayLocations.take(4).map((l) {
                        final user = widget.allUsers.firstWhere((u) => u['uid'] == l.userId, orElse: () => {});
                        final name = user['displayName'] ?? user['email'] ?? "User";
                        final photoUrl = user['photoURL'];
                        
                        final imageUrl = (photoUrl != null && photoUrl is String && photoUrl.isNotEmpty) 
                          ? photoUrl 
                          : "https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&size=24";
                        
                        return Opacity(
                          opacity: isCurrentMonth ? 1.0 : 0.5,
                          child: CircleAvatar(
                            radius: 5,
                            backgroundImage: NetworkImage(imageUrl),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
        onTap: (CalendarTapDetails details) {
          if (details.targetElement == CalendarElement.calendarCell && details.date != null) {
            final date = details.date!;
            final dayLocations = _getLocationsForDate(date);
            final dayHolidays = widget.holidays.where((h) => 
              h.date.year == date.year && h.date.month == date.month && h.date.day == date.day).toList();
            final dayEvents = widget.events.where((e) => 
              e.date.year == date.year && e.date.month == date.month && e.date.day == date.day).toList();

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => DetailModal(
                date: date,
                locations: dayLocations,
                events: dayEvents,
                holidays: dayHolidays,
                currentUserId: widget.currentUserId,
              ),
            );
          }
        },
      ),
    );
  }
}
