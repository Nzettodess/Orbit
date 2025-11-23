import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'models.dart';

class MyCalendarDataSource extends CalendarDataSource {
  MyCalendarDataSource(List<UserLocation> locations, List<Holiday> holidays, List<GroupEvent> groupEvents) {
    appointments = <dynamic>[];
    appointments!.addAll(locations);
    appointments!.addAll(holidays);
    appointments!.addAll(groupEvents);
  }

  @override
  DateTime getStartTime(int index) {
    final dynamic appointment = appointments![index];
    if (appointment is UserLocation) {
      return appointment.date;
    } else if (appointment is Holiday) {
      return appointment.date;
    } else if (appointment is GroupEvent) {
      return appointment.date;
    }
    return DateTime.now();
  }

  @override
  DateTime getEndTime(int index) {
    final dynamic appointment = appointments![index];
    if (appointment is UserLocation) {
      return appointment.date; // All day
    } else if (appointment is Holiday) {
      return appointment.date; // All day
    } else if (appointment is GroupEvent) {
      return appointment.date.add(const Duration(hours: 1)); // Default 1 hour for now
    }
    return DateTime.now();
  }

  @override
  bool isAllDay(int index) {
    final dynamic appointment = appointments![index];
    return appointment is UserLocation || appointment is Holiday;
  }

  @override
  String getSubject(int index) {
    final dynamic appointment = appointments![index];
    if (appointment is UserLocation) {
      return "${appointment.nation} ${appointment.state ?? ''}";
    } else if (appointment is Holiday) {
      return appointment.localName;
    } else if (appointment is GroupEvent) {
      return appointment.title;
    }
    return '';
  }
  
  @override
  Color getColor(int index) {
    final dynamic appointment = appointments![index];
     if (appointment is UserLocation) {
      return Colors.blue;
    } else if (appointment is Holiday) {
      return Colors.red;
    } else if (appointment is GroupEvent) {
      return Colors.green;
    }
    return Colors.grey;
  }
}
