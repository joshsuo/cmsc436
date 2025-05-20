// Copyright 2019 Aleksander Woźniak (table_calendar package example)
// SPDX-License-Identifier: Apache-2.0

import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

enum Recurrence { None, Daily, Weekly, Monthly, Custom }

class Event {
  final String title;
  final String priority;
  Recurrence recurrence;
  final List<int>? customDays;
  bool isCompleted;
  String? photoPath;
  TimeOfDay? time; // Add time field for sorting and reminders

  Event(
    this.title,
    this.priority, {
    this.recurrence = Recurrence.None,
    this.customDays,
    this.isCompleted = false,
    this.photoPath,
    this.time,
  });

  @override
  String toString() {
    return '$title (Priority: $priority${time != null ? ', Time: ${time!.hour}:${time!.minute}' : ''})';
  }
}

/// Example events.
///
/// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
final kEvents = LinkedHashMap<DateTime, List<Event>>(
  equals: isSameDay,
  hashCode: getHashCode,
);

//milestone2: adding todo item to the day
void addEvent(
  DateTime day,
  Event event,
  Recurrence recurrence,
  List<int>? customDays,
) {
  kEvents[day] ??= [];
  kEvents[day]!.add(event);
  if (recurrence == Recurrence.Daily) {
    for (int i = 1; i < 7; i++) {
      final newDay = day.add(Duration(days: i));
      kEvents[newDay] ??= [];
      kEvents[newDay]!.add(Event(
        event.title,
        event.priority,
        recurrence: recurrence,
        time: event.time,
      ));
    }
  } else if (recurrence == Recurrence.Weekly) {
    for (int i = 1; i < 4; i++) {
      final newDay = day.add(Duration(days: i * 7));
      kEvents[newDay] ??= [];
      kEvents[newDay]!.add(Event(
        event.title,
        event.priority,
        recurrence: recurrence,
        time: event.time,
      ));
    }
  } else if (recurrence == Recurrence.Monthly) {
    for (int i = 1; i < 3; i++) {
      final newDay = DateTime(day.year, day.month + i, day.day);
      kEvents[newDay] ??= [];
      kEvents[newDay]!.add(Event(
        event.title,
        event.priority,
        recurrence: recurrence,
        time: event.time,
      ));
    }
  } else if (recurrence == Recurrence.Custom && customDays != null) {
    final startDate = DateTime(day.year, day.month, day.day);
    for (int i = 0; i < 28; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final dayOfWeek = currentDate.weekday;
      if (customDays.contains(dayOfWeek)) {
        kEvents[currentDate] ??= [];
        kEvents[currentDate]!.add(Event(
          event.title,
          event.priority,
          recurrence: recurrence,
          time: event.time,
        ));
      }
    }
  }
}

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);
