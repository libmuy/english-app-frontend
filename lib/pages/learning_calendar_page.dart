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

    Map<DateTime, int> fetchedMonthData = {};
    try {
      // Call the new provider method to get all counts for the month
      fetchedMonthData = await _learningProvider.fetchMonthlyLearnedCounts(
        monthDate.year,
        monthDate.month,
      );
    } catch (e) {
      // Handle or log error for the monthly fetch
      print("Error fetching counts for month ${monthDate.year}-${monthDate.month}: $e");
      // Optionally, show a snackbar or error message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data for ${monthDate.year}-${monthDate.month}.')),
        );
      }
    }

    setState(() {
      // Option 1: Replace all counts with the newly fetched month's data.
      // This is simpler if we don't need to cache previously viewed months.
      // _learnedCounts = fetchedMonthData;

      // Option 2: Merge fetched data with existing data (caches other months).
      // This is generally better for UX if users flip between months.
      // Ensure that data for the current month is updated, not just added to.
      // The fetchedMonthData contains ALL days for the month from the backend.
      // So, we can update _learnedCounts by removing old entries for the current month
      // and then adding the new ones. Or, more simply, just use addAll which
      // will overwrite existing keys for the current month.

      // Create a new map to avoid modifying the existing one during iteration (if any)
      // and to ensure proper state update.
      Map<DateTime, int> newLearnedCounts = Map.from(_learnedCounts);
      newLearnedCounts.addAll(fetchedMonthData);
      _learnedCounts = newLearnedCounts;

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
