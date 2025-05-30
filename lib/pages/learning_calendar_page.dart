import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // For date formatting, if needed by table_calendar or for keys

import '../providers/learning_provider.dart';
import '../providers/service_locator.dart';
import '../domain/global.dart'; // For kBaseDate or other constants if they become relevant

class LearningCalendarPage extends StatefulWidget {
  const LearningCalendarPage({super.key});

  @override
  State<LearningCalendarPage> createState() => _LearningCalendarPageState();
}

class _LearningCalendarPageState extends State<LearningCalendarPage> {
  late final LearningProvider _learningProvider;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Store fetched data: Date (normalized to midnight) -> learned count
  Map<DateTime, int> _learnedCounts = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _learningProvider = getIt<LearningProvider>();
    _selectedDay = _focusedDay;
    _fetchLearnedCountsForMonth(_focusedDay);
  }

  // Normalize DateTime to midnight (to use as a consistent map key)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _fetchLearnedCountsForMonth(DateTime monthDate) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    // Determine the range of days to fetch for the given month
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    
    Map<DateTime, int> newCounts = {};

    for (DateTime day = firstDayOfMonth; 
         day.isBefore(lastDayOfMonth) || day.isAtSameMomentAs(lastDayOfMonth); 
         day = day.add(const Duration(days: 1))) {
      try {
        final reviewInfo = await _learningProvider.fetchReviewInfo(date: day);
        if (reviewInfo.learnedCount > 0) {
          newCounts[_normalizeDate(day)] = reviewInfo.learnedCount;
        }
      } catch (e) {
        // Handle or log error for individual day fetch, if necessary
        print("Error fetching count for $day: $e");
      }
    }

    setState(() {
      _learnedCounts.addAll(newCounts); // Merge with existing data
      _isLoading = false;
    });
  }

  List<Widget> _buildEventMarkers(DateTime day, int count) {
    if (count > 0) {
      return [
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar<dynamic>( // Using dynamic for events if not strongly typed
            firstDay: kBaseDate, // Assuming kBaseDate is a sensible earliest date
            lastDay: DateTime.now().add(const Duration(days: 365)), // Allow viewing up to a year in future
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: (day) {
              // This eventLoader is for dots. We will use calendarBuilders for custom markers.
              // For now, let's return an empty list or a single event if count > 0 to show a dot.
              final normalizedDay = _normalizeDate(day);
              final count = _learnedCounts[normalizedDay];
              if (count != null && count > 0) {
                return [count]; // Return a list with one item to show default marker
              }
              return [];
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              // Customize look if needed
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final normalizedDay = _normalizeDate(day);
                final count = _learnedCounts[normalizedDay];
                if (count != null && count > 0) {
                  return Stack(
                    children: <Widget>[
                      // This ensures day numbers are still visible
                      // Default day cell is built by the calendar, we just add markers.
                      // If you need to completely override the cell, use `defaultBuilder`.
                      ..._buildEventMarkers(day, count),
                    ],
                  );
                }
                return null; // Return null or empty container if no custom marker
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              // Fetch data for the new visible month
              _fetchLearnedCountsForMonth(focusedDay);
            },
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          // Optionally, display details for the selected day
          // Expanded(
          //   child: _selectedDay != null && _learnedCounts.containsKey(_normalizeDate(_selectedDay!))
          //       ? Padding(
          //           padding: const EdgeInsets.all(8.0),
          //           child: Text(
          //               'Sentences learned on ${DateFormat.yMMMd().format(_selectedDay!)}: ${_learnedCounts[_normalizeDate(_selectedDay!)]}'),
          //         )
          //       : Container(),
          // ),
        ],
      ),
    );
  }
}
