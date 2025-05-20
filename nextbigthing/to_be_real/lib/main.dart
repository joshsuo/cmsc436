// Copyright 2019 Aleksander Woźniak (table_calendar package example)
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:to_be_real/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
//notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:to_be_real/notifications.dart';






// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   Notifications().initNoti();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'To Be Real',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const StartPage(),
//     );
//   }
// }


// class StartPage extends StatefulWidget {
//   const StartPage({super.key});

//   @override
//   State<StartPage> createState() => _StartPageState();
// }

// class _StartPageState extends State<StartPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 Notifications().showNoti(
//                   title: 'calendar page'
//                 );
//               } ,
//               child: Text('hello')
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 DateTime schedule = DateTime.now().add(Duration(seconds: 5));
//                 Notifications().scheduleNoti(
//                   'schedule',
//                   'priority',
//                   schedule
//                 );
//               } ,
//               child: Text('scheduled')
//               )
//           ],
//         )
//       )
//     );
//   }
// }



/////////////////////////////////////
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Notifications().initNoti();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Be Real',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const StartPage(),
    );
  }
}

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        initialIndex: 1, // Set ToDoListPage as default
        child: Scaffold(
          body: const TabBarView(
            children: [CalendarPage(), ToDoListPage(), AlbumsPage()],
          ),
          bottomNavigationBar: const BottomAppBar(
            child: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
                Tab(icon: Icon(Icons.list), text: 'To-Do'),
                Tab(icon: Icon(Icons.photo_album), text: 'Albums'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final TextEditingController _eventController = TextEditingController();
  DateTime? _selectedForEvent;
  final Map<String, int> priorityOrder = {
    'High': 3,
    'Medium': 2,
    'Low': 1,
    'Done': 0,
  };
  final Map<String, Color?> priorityColors = {
    'High': Colors.red[300],
    'Medium': Colors.yellow[200],
    'Low': Colors.green[200],
  };
  final ImagePicker picker = ImagePicker();
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_focusedDay));
    _loadEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    _eventController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventsString = prefs.getString('events');
    if (eventsString != null) {
      final eventsMap = jsonDecode(eventsString) as Map<String, dynamic>;
      kEvents.clear();
      eventsMap.forEach((key, value) {
        final date = DateTime.parse(key);
        final events = (value as List).map((e) {
          final data = jsonDecode(e);
          return Event(
            data['title'],
            data['priority'],
            recurrence: Recurrence.values
                .firstWhere((r) => r.toString() == data['recurrence']),
            customDays: data['customDays'] != null
                ? List<int>.from(data['customDays'])
                : null,
            isCompleted: data['isCompleted'],
            photoPath: data['photoPath'],
            time: data['time'] != null
                ? TimeOfDay(
                    hour: int.parse(data['time'].split(':')[0]),
                    minute: int.parse(data['time'].split(':')[1]),
                  )
                : null,
          );
        }).toList();
        kEvents[date] = events;
      });
      _selectedEvents.value = _getEventsForDay(_selectedDay ?? _focusedDay);
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsMap = kEvents.map((key, value) => MapEntry(
          key.toIso8601String(),
          value
              .map((e) => jsonEncode({
                    'title': e.title,
                    'priority': e.priority,
                    'recurrence': e.recurrence.toString(),
                    'customDays': e.customDays,
                    'isCompleted': e.isCompleted,
                    'photoPath': e.photoPath,
                    'time': e.time != null
                        ? '${e.time!.hour}:${e.time!.minute}'
                        : null,
                  }))
              .toList(),
        ));
    await prefs.setString('events', jsonEncode(eventsMap));
  }

  List<Event> _getEventsForDay(DateTime day) {
    final events = List<Event>.from(kEvents[day] ?? []);

    events.sort((a, b) {
      final aVal = priorityOrder[a.priority] ?? 0;
      final bVal = priorityOrder[b.priority] ?? 0;
      return _sortDescending ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
    });

    return events;
  }

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);
    final allEvents = [for (final d in days) ..._getEventsForDay(d)];

    allEvents.sort((a, b) {
      final one = priorityOrder[a.priority] ?? 0;
      final two = priorityOrder[b.priority] ?? 0;
      return _sortDescending ? one.compareTo(two) : two.compareTo(one);
    });

    return allEvents;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ToDoListPage(selectedDay: selectedDay),
        ),
      );
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  Future<void> addEventPrompt({Event? eventToEdit, int? eventIndex}) async {
    String selectedPriority = eventToEdit?.priority ?? 'Low';
    Recurrence selectedRecurrence = eventToEdit?.recurrence ?? Recurrence.None;
    List<bool> selectedDays = eventToEdit?.customDays != null
        ? List.generate(7, (i) => eventToEdit!.customDays!.contains(i + 1))
        : List.filled(7, false);
    TimeOfDay? reminderTime = eventToEdit?.time;
    _eventController.text = eventToEdit?.title ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(eventToEdit == null ? 'New To-Do' : 'Edit To-Do'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    controller: _eventController,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: ['Low', 'Medium', 'High']
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedPriority = value);
                      }
                    },
                  ),
                  DropdownButtonFormField<Recurrence>(
                    value: selectedRecurrence,
                    decoration: const InputDecoration(labelText: 'Repeat'),
                    items: Recurrence.values.map((rec) {
                      return DropdownMenuItem(
                        value: rec,
                        child: Text(rec.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRecurrence = val);
                      }
                    },
                  ),
                  if (selectedRecurrence == Recurrence.Custom)
                    Wrap(
                      spacing: 2,
                      children: List.generate(7, (index) {
                        const dayLabels = [
                          'M',
                          'T',
                          'W',
                          'Th',
                          'F',
                          'Sa',
                          'Su'
                        ];
                        return FilterChip(
                          label: Text(dayLabels[index]),
                          selected: selectedDays[index],
                          selectedColor: Colors.blue.shade100,
                          checkmarkColor: Colors.blue,
                          onSelected: (bool selected) {
                            setDialogState(
                                () => selectedDays[index] = selected);
                          },
                        );
                      }),
                    ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: reminderTime ?? TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setDialogState(() => reminderTime = pickedTime);
                      }
                    },
                    child: Text(
                      reminderTime == null
                          ? 'Set Reminder Time'
                          : 'Reminder: ${reminderTime!.format(context)}',
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(Icons.cancel, size: 50),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            if (_eventController.text.isEmpty) return;

                            setState(() {
                              final event = Event(
                                _eventController.text,
                                selectedPriority,
                                recurrence: selectedRecurrence,
                                customDays: selectedDays
                                    .asMap()
                                    .entries
                                    .where((e) => e.value)
                                    .map((e) => e.key + 1)
                                    .toList(),
                                time: reminderTime,
                                isCompleted: eventToEdit?.isCompleted ?? false,
                                photoPath: eventToEdit?.photoPath,
                              );

                              if (eventToEdit != null && eventIndex != null) {
                                // Edit existing event
                                kEvents[_selectedDay ?? _focusedDay]
                                    ?[eventIndex] = event;
                              } else {
                                // Add new event
                                addEvent(
                                  _selectedForEvent ?? _focusedDay,
                                  event,
                                  selectedRecurrence,
                                  selectedRecurrence == Recurrence.Custom
                                      ? selectedDays
                                          .asMap()
                                          .entries
                                          .where((e) => e.value)
                                          .map((e) => e.key + 1)
                                          .toList()
                                      : null,
                                );
                              }

                              _selectedEvents.value =
                                  _getEventsForDay(_selectedDay ?? _focusedDay);
                              _saveEvents();
                            });

                            // notifications 
                            if (reminderTime == null && _selectedDay!.day == DateTime.now().day) {
                              // no time reminder
                              // shows right away
                              print("day: ${_selectedDay!.day}");
                              
                              Notifications().showNoti(
                                title: _eventController.text,
                                body: selectedPriority
                              );
                              
                            } else if (reminderTime != null){
                              // scheduled reminder
                              // day and time given
                              print('schedule noti before');
                              print('reminder hour: ${reminderTime!.hour}');
                              print('reminder min: ${reminderTime!.minute}');

                              // change date time
                              DateTime date = DateTime(
                                _focusedDay.year, 
                                _focusedDay.month,
                                _focusedDay.day,
                                reminderTime!.hour,
                                reminderTime!.minute
                              ).toLocal();

                              Notifications().scheduleNoti(
                                _eventController.text, 
                                selectedPriority, 
                                date
                              );
                            }

                            _eventController.clear();
                            Navigator.pop(context);
                          },
                          child: const Icon(Icons.check_circle_outline_rounded,
                              size: 50),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _saveImage(XFile photo) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${directory.path}/$fileName';
    await File(photo.path).copy(path);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To Be Real'),
        actions: [
          PopupMenuButton<bool>(
            onSelected: (value) {
              setState(() {
                _sortDescending = value;
                _selectedEvents.value =
                    _getEventsForDay(_selectedDay ?? _focusedDay);
              });
            },
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: true,
                child: Text('Sort: High -> Low'),
              ),
              const PopupMenuItem(
                value: false,
                child: Text('Sort: Low -> High'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addEventPrompt,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: _calendarFormat,
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: {
              CalendarFormat.month: 'Week',
              CalendarFormat.week: 'Month',
            },
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final photos = events
                    .where((e) => e.isCompleted && e.photoPath != null)
                    .map((e) => e.photoPath!)
                    .toList();
                if (photos.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: FileImage(File(photos.first)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              _onDaySelected(selectedDay, focusedDay);
              _selectedForEvent = selectedDay;
            },
            onRangeSelected: _onRangeSelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: priorityColors[value[index].priority],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          leading: value[index].isCompleted &&
                                  value[index].photoPath != null
                              ? Image.file(
                                  File(value[index].photoPath!),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                )
                              : IconButton(
                                  icon: const Icon(Icons.camera_alt),
                                  onPressed: () async {
                                    final XFile? photo = await picker.pickImage(
                                        source: ImageSource.camera);
                                    if (photo != null) {
                                      final path = await _saveImage(photo);
                                      setState(() {
                                        value[index].isCompleted = true;
                                        value[index].photoPath = path;
                                        _selectedEvents.value =
                                            _getEventsForDay(
                                                _selectedDay ?? _focusedDay);
                                        _saveEvents();
                                      });
                                    }
                                  },
                                ),
                          title: Text('${value[index]}'),
                          subtitle: value[index].time != null
                              ? Text(
                                  'Reminder: ${value[index].time!.format(context)}')
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  addEventPrompt(
                                    eventToEdit: value[index],
                                    eventIndex: index,
                                  );
                                  
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    kEvents[_selectedDay ?? _focusedDay]
                                        ?.remove(value[index]);
                                    _selectedEvents.value = _getEventsForDay(
                                        _selectedDay ?? _focusedDay);
                                    _saveEvents();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

class ToDoListPage extends StatefulWidget {
  final DateTime? selectedDay;

  const ToDoListPage({super.key, this.selectedDay});

  @override
  State<ToDoListPage> createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  late DateTime _selectedDay;
  late ValueNotifier<List<Event>> _selectedEvents;
  final TextEditingController _eventController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  bool _sortDescending = true;
  bool _sortByPriority = true;

  final Map<String, Color?> priorityColors = {
    'High': Colors.red[300],
    'Medium': Colors.yellow[200],
    'Low': Colors.green[200],
  };

  final Map<String, int> priorityOrder = {
    'High': 3,
    'Medium': 2,
    'Low': 1,
    'Done': 0,
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDay ?? DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventsString = prefs.getString('events');
    if (eventsString != null) {
      final eventsMap = jsonDecode(eventsString) as Map<String, dynamic>;
      kEvents.clear();
      eventsMap.forEach((key, value) {
        final date = DateTime.parse(key);
        final events = (value as List).map((e) {
          final data = jsonDecode(e);
          return Event(
            data['title'],
            data['priority'],
            recurrence: Recurrence.values
                .firstWhere((r) => r.toString() == data['recurrence']),
            customDays: data['customDays'] != null
                ? List<int>.from(data['customDays'])
                : null,
            isCompleted: data['isCompleted'],
            photoPath: data['photoPath'],
            time: data['time'] != null
                ? TimeOfDay(
                    hour: int.parse(data['time'].split(':')[0]),
                    minute: int.parse(data['time'].split(':')[1]),
                  )
                : null,
          );
        }).toList();
        kEvents[date] = events;
      });
      _selectedEvents.value = _getEventsForDay(_selectedDay);
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsMap = kEvents.map((key, value) => MapEntry(
          key.toIso8601String(),
          value
              .map((e) => jsonEncode({
                    'title': e.title,
                    'priority': e.priority,
                    'recurrence': e.recurrence.toString(),
                    'customDays': e.customDays,
                    'isCompleted': e.isCompleted,
                    'photoPath': e.photoPath,
                    'time': e.time != null
                        ? '${e.time!.hour}:${e.time!.minute}'
                        : null,
                  }))
              .toList(),
        ));
    await prefs.setString('events', jsonEncode(eventsMap));
  }

  List<Event> _getEventsForDay(DateTime day) {
    final events = List<Event>.from(kEvents[day] ?? []);
    events.sort((a, b) {
      if (_sortByPriority) {
        final aVal = priorityOrder[a.priority] ?? 0;
        final bVal = priorityOrder[b.priority] ?? 0;
        return _sortDescending ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
      } else {
        if (a.time == null && b.time == null) return 0;
        if (a.time == null) return 1;
        if (b.time == null) return -1;
        final aMinutes = a.time!.hour * 60 + a.time!.minute;
        final bMinutes = b.time!.hour * 60 + b.time!.minute;
        return _sortDescending
            ? bMinutes.compareTo(aMinutes)
            : aMinutes.compareTo(bMinutes);
      }
    });
    return events;
  }

  Future<void> _addEventPrompt({Event? eventToEdit, int? eventIndex}) async {
    String selectedPriority = eventToEdit?.priority ?? 'Low';
    Recurrence selectedRecurrence = eventToEdit?.recurrence ?? Recurrence.None;
    List<bool> selectedDays = eventToEdit?.customDays != null
        ? List.generate(7, (i) => eventToEdit!.customDays!.contains(i + 1))
        : List.filled(7, false);
    TimeOfDay? reminderTime = eventToEdit?.time;
    _eventController.text = eventToEdit?.title ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(eventToEdit == null ? 'New To-Do' : 'Edit To-Do'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    controller: _eventController,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: ['Low', 'Medium', 'High']
                        .map((level) =>
                            DropdownMenuItem(value: level, child: Text(level)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedPriority = value);
                      }
                    },
                  ),
                  DropdownButtonFormField<Recurrence>(
                    value: selectedRecurrence,
                    decoration: const InputDecoration(labelText: 'Repeat'),
                    items: Recurrence.values
                        .map((rec) =>
                            DropdownMenuItem(value: rec, child: Text(rec.name)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRecurrence = val);
                      }
                    },
                  ),
                  if (selectedRecurrence == Recurrence.Custom)
                    Wrap(
                      spacing: 2,
                      children: List.generate(7, (index) {
                        const dayLabels = [
                          'M',
                          'T',
                          'W',
                          'Th',
                          'F',
                          'Sa',
                          'Su'
                        ];
                        return FilterChip(
                          label: Text(dayLabels[index]),
                          selected: selectedDays[index],
                          selectedColor: Colors.blue.shade100,
                          checkmarkColor: Colors.blue,
                          onSelected: (bool selected) {
                            setDialogState(
                                () => selectedDays[index] = selected);
                          },
                        );
                      }),
                    ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: reminderTime ?? TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setDialogState(() => reminderTime = pickedTime);
                      }
                    },
                    child: Text(
                      reminderTime == null
                          ? 'Set Reminder Time'
                          : 'Reminder: ${reminderTime!.format(context)}',
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(Icons.cancel, size: 50),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            if (_eventController.text.isEmpty) return;

                            setState(() {
                              final event = Event(
                                _eventController.text,
                                selectedPriority,
                                recurrence: selectedRecurrence,
                                customDays: selectedDays
                                    .asMap()
                                    .entries
                                    .where((e) => e.value)
                                    .map((e) => e.key + 1)
                                    .toList(),
                                time: reminderTime,
                                isCompleted: eventToEdit?.isCompleted ?? false,
                                photoPath: eventToEdit?.photoPath,
                              );

                              if (eventToEdit != null && eventIndex != null) {
                                // Edit existing event
                                kEvents[_selectedDay]?[eventIndex] = event;
                              } else {
                                // Add new event
                                addEvent(
                                  _selectedDay,
                                  event,
                                  selectedRecurrence,
                                  selectedRecurrence == Recurrence.Custom
                                      ? selectedDays
                                          .asMap()
                                          .entries
                                          .where((e) => e.value)
                                          .map((e) => e.key + 1)
                                          .toList()
                                      : null,
                                );
                              }

                              _selectedEvents.value =
                                  _getEventsForDay(_selectedDay);
                              _saveEvents();
                              
                            });

                            // notifications
                            if (reminderTime == null && _selectedDay.day == DateTime.now().day) {
                              // no time reminder
                              // shows right away
                              
                              Notifications().showNoti(
                                title: _eventController.text,
                                body: selectedPriority
                              );
                              
                            } 
                            else if (reminderTime == null && _selectedDay.day != DateTime.now().day) {
                              // scheduled reminder
                              // only day given

                              // change date time
                              DateTime date = DateTime(
                                _selectedDay.year, 
                                _selectedDay.month,
                                _selectedDay.day,
                                0, // hour
                                0 // min
                              ).toLocal();

                              Notifications().scheduleNoti(
                                _eventController.text,
                                selectedPriority,
                                date
                              );
                            } 
                            else if (reminderTime != null){
                              // scheduled reminder
                              // day and time given

                              // change date time
                              DateTime date = DateTime(
                                _selectedDay.year, 
                                _selectedDay.month,
                                _selectedDay.day,
                                reminderTime!.hour,
                                reminderTime!.minute
                              ).toLocal();

                              Notifications().scheduleNoti(
                                _eventController.text, 
                                selectedPriority, 
                                date
                              );
                            }

                            _eventController.clear();
                            Navigator.pop(context);
                          },
                          child: const Icon(Icons.check_circle_outline_rounded,
                              size: 50),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _saveImage(XFile photo) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${directory.path}/$fileName';
    await File(photo.path).copy(path);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List - ${_selectedDay.toString().split(' ')[0]}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'priority') {
                  _sortByPriority = true;
                } else {
                  _sortByPriority = false;
                }
                _sortDescending = !_sortDescending;
                _selectedEvents.value = _getEventsForDay(_selectedDay);
              });
            },
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'priority', child: Text('Sort by Priority')),
              const PopupMenuItem(value: 'time', child: Text('Sort by Time')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEventPrompt,
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<List<Event>>(
        valueListenable: _selectedEvents,
        builder: (context, value, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: value.length,
            itemBuilder: (context, index) {
              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: priorityOrder.containsKey(value[index].priority)
                        ? priorityColors[value[index].priority]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    leading: value[index].isCompleted &&
                            value[index].photoPath != null
                        ? Image.file(
                            File(value[index].photoPath!),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                        : IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: () async {
                              final XFile? photo = await picker.pickImage(
                                  source: ImageSource.camera);
                              if (photo != null) {
                                final path = await _saveImage(photo);
                                setState(() {
                                  value[index].isCompleted = true;
                                  value[index].photoPath = path;
                                  _selectedEvents.value =
                                      _getEventsForDay(_selectedDay);
                                  _saveEvents();
                                });
                              }
                            },
                          ),
                    title: Text('${value[index]}'),
                    subtitle: value[index].time != null
                        ? Text(
                            'Reminder: ${value[index].time!.format(context)}')
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _addEventPrompt(
                              eventToEdit: value[index],
                              eventIndex: index,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              kEvents[_selectedDay]?.remove(value[index]);
                              _selectedEvents.value =
                                  _getEventsForDay(_selectedDay);
                              _saveEvents();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  final Map<DateTime, List<String>> _photosByDay = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() {
    _photosByDay.clear();
    kEvents.forEach((date, events) {
      final photos = events
          .where((e) => e.isCompleted && e.photoPath != null)
          .map((e) => e.photoPath!)
          .toList();
      if (photos.isNotEmpty) {
        _photosByDay[date] = photos;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Albums')),
      body: _photosByDay.isEmpty
          ? const Center(child: Text('No photos yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _photosByDay.keys.length,
              itemBuilder: (context, index) {
                final date = _photosByDay.keys.elementAt(index);
                final photos = _photosByDay[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        date.toString().split(' ')[0],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, photoIndex) {
                        return Image.file(
                          File(photos[photoIndex]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
