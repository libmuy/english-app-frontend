import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:simple_logging/simple_logging.dart';

import '../domain/entities.dart';
import '../domain/global.dart';
import '../providers/auth_provider.dart';
import '../providers/service_locator.dart';
import '../providers/setting_provider.dart';
import 'errors.dart';

final _authProvider = getIt<AuthProvider>();
final _settingProvider = getIt<SettingProvider>();

void showSnackBar(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}

Widget futureBuilderHelper(
    {required AsyncSnapshot snapshot,
    required Widget Function() onDone,
    Logger? logger,
    String? logId}) {
  final logStr = logId == null ? "" : "$logId: ";
  const circle = Center(child: CircularProgressIndicator());
  if (snapshot.connectionState == ConnectionState.waiting) {
    logger?.debug("${logStr}waiting");
    return circle;
  } else if (snapshot.hasError) {
    logger?.debug('${logStr}Error: ${snapshot.error}');
    return Center(child: Text('Error: ${snapshot.error}'));
  } else if (snapshot.connectionState == ConnectionState.done) {
    if (snapshot.data == null) {
      logger?.debug('${logStr}Snapshot completed, but data is null');
      return circle;
    }
    logger?.debug('${logStr}Snapshot completed');
    return onDone();
  }

  logger?.debug('${logStr}Snapshot : ${snapshot.connectionState}');
  return circle;
}

List<Widget> resourceListSection(
    BuildContext context, String title, Iterable<Widget> list) {
  return [
    Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
    const SizedBox(height: 8.0),
    ...list,
    const SizedBox(height: 16.0),
  ];
}

Widget resourceListSectionNoContentLabel(BuildContext context) {
  return Text('No content here',
      style: Theme.of(context).textTheme.headlineSmall);
}

String formatDateTimeForMySQL(DateTime dateTime) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');

  String year = dateTime.year.toString();
  String month = twoDigits(dateTime.month);
  String day = twoDigits(dateTime.day);
  String hour = twoDigits(dateTime.hour);
  String minute = twoDigits(dateTime.minute);
  String second = twoDigits(dateTime.second);

  return '$year-$month-${day}T$hour:$minute:$second';
}

String formatDateForMySQL(DateTime dateTime) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');

  String year = dateTime.year.toString();
  String month = twoDigits(dateTime.month);
  String day = twoDigits(dateTime.day);

  return '$year-$month-$day';
}

(double easeFactor, int intervalDays) reviewAlgrithm(
    LearningData data, ReviewResult result) {
  const minEaseFactor = 1.3;
  const maxEaseFactor = 2.5;
  const maxIntervalDays = 365;
  const initialIntervals = [1, 3, 7];
  const graduatedInterval = 14;

  double retEaseFactor = data.easeFactor;
  int retIntervalDays = data.intervalDays;

  if (!data.isGraduated) {
    if (result == ReviewResult.again) {
      retIntervalDays = initialIntervals[0];
    } else {
      int currentIndex = initialIntervals.indexOf(data.intervalDays);
      if (currentIndex < initialIntervals.length - 1) {
        retIntervalDays = initialIntervals[currentIndex + 1];
      } else {
        data.isGraduated = true;
        retIntervalDays = graduatedInterval;
      }
    }
  } else {
    switch (result) {
      case ReviewResult.again:
        retIntervalDays = 1;
        retEaseFactor =
            (data.easeFactor - 0.2).clamp(minEaseFactor, maxEaseFactor);
        break;
      case ReviewResult.hard:
        retIntervalDays = (data.intervalDays * 0.8).round();
        retEaseFactor =
            (data.easeFactor - 0.15).clamp(minEaseFactor, maxEaseFactor);
        break;
      case ReviewResult.good:
        retIntervalDays = (data.intervalDays * data.easeFactor).round();
        break;
      case ReviewResult.easy:
        retIntervalDays = (data.intervalDays * 1.3).round();
        retEaseFactor =
            (data.easeFactor + 0.15).clamp(minEaseFactor, maxEaseFactor);
        break;
      case ReviewResult.skip:
        data.isSkipped = true;
        break;
    }
  }

  // Handle late reviews
  final daysLate =
      DateTime.now().difference(data.learnedDate).inDays - data.intervalDays;
  if (daysLate > 4) {
    final newIntervalDays = (data.intervalDays - daysLate / 4).round();
    final limit = (data.intervalDays / 3).round();
    if (newIntervalDays < limit) {
      retIntervalDays = limit;
    } else {
      retIntervalDays = newIntervalDays;
    }
  }

  // Apply interval randomization
  final randomFactor = 1 + (Random().nextDouble() * 0.1 - 0.05);
  retIntervalDays = (data.intervalDays * randomFactor).round();

  // Ensure interval does not exceed maximum
  retIntervalDays = data.intervalDays.clamp(1, maxIntervalDays);

  // Leech management
  if (data.failureCount >= 5) {
    // Mark for extra attention or removal
    // This can be implemented as needed
  }

  return (retEaseFactor, retIntervalDays);
}

int mapDouble2TinyInt(double min, double max, double value) {
  return ((value - min) / (max - min) * 255).round();
}

double mapTinyInt2Double(double min, double max, int value) {
  return min + (max - min) * value / 255;
}

Future<Response> httpRequest(String php,
    {Object? body,
    bool permitStatus404 = false,
    String baseUrl = kUrlPrefix,
    bool useGet = false}) async {
  final token = _authProvider.token;
  final url = Uri.parse('$baseUrl/$php');
  Response response;

  if (useGet) {
    response = await get(url, headers: <String, String>{
    'Authorization': 'Bearer $token',
  });
  } else {
    response = await post(url, headers: <String, String>{
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  }, body: body);
  }
  if (response.statusCode == 401) {
    _authProvider.logout();
    _settingProvider.resetSettings();
  }

  if (permitStatus404 && response.statusCode == 404) {}
  if (response.statusCode != 200) {
    final data = jsonDecode(response.body);
    throw HttpStatusError(php, response.statusCode, error: data['error']);
  }

  return response;
}
