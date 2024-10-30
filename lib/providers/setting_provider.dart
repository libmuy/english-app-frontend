import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:libmuyenglish/utils/utils.dart';
import '../utils/errors.dart';
import 'service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_logging/simple_logging.dart';
import 'auth_provider.dart';
import '../domain/global.dart';

final _log = Logger('SettingProvider', level: LogLevel.debug);
final _kDefaultTheme =
    AppThemeSetting(themeColor: 0xff6d4c41, mode: AppThemeMode.light);

class SettingProvider {
  late AuthProvider _authProvider;
  final _themeNotifier = ValueNotifier(_kDefaultTheme);
  late AppSettings settings;
  late AppSettings _syncedSettings;

  ValueNotifier<AppThemeSetting> get themeNotifier => _themeNotifier;

  SettingProvider() {
    _authProvider = getIt<AuthProvider>();
    _initializeSettings();
  }

  void _initializeSettings() {
    settings = AppSettings(themeNotifier: _themeNotifier);
    _syncedSettings = AppSettings(themeNotifier: _themeNotifier);
  }

  // called when logout
  void resetSettings() {
    _initializeSettings();

    final color = getIt<SharedPreferences>().getInt('theme_color');
    final themeStr = getIt<SharedPreferences>().getString('theme');
    final theme = _kDefaultTheme.copyWith();

    if (color != null) {
      theme.themeColor = color;
    }
    if (themeStr != null) {
      theme.mode = AppThemeMode.fromString(themeStr);
    }

    themeNotifier.value = theme;
  }

  Future<void> changeThemeColor(int color) async {
    final theme = themeNotifier.value.copyWith();
    theme.themeColor = color;
    themeNotifier.value = theme;
    await getIt<SharedPreferences>().setInt('theme_color', color);
  }

  Future<void> changeThemeMode(AppThemeMode mode) async {
    final theme = themeNotifier.value.copyWith();
    theme.mode = mode;
    themeNotifier.value = theme;
    await getIt<SharedPreferences>().setString('theme', mode.toString());
  }

  Future<void> saveSettings({bool forceAll = false}) async {
    final token = _authProvider.token;

    final newSettings = settings.toJson();
    final syncedSettings = _syncedSettings.toJson();
    if (forceAll) {
      newSettings['add'] = true;
    } else {
      for (var k in syncedSettings.keys) {
        if (newSettings[k] == syncedSettings[k]) newSettings.remove(k);
      }
    }
    if (newSettings.keys.isEmpty) return;

    final json = jsonEncode(newSettings);
    final response = await http.post(
      Uri.parse('$kUrlPrefix/update_setting.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json,
    );

    if (response.statusCode != 200) {
      final msg = jsonDecode(response.body)['error'];
      throw HttpStatusError('Save Settings', response.statusCode, error: msg);
    }
    _syncedSettings = settings.copyWith();
  }

  Future<void> loadSettings() async {
    final token = _authProvider.token;
    _log.debug('loadSettings');

    _log.debug('  send request with auth header');
    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_setting.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final Map<String, dynamic> json = jsonDecode(response.body);
    final status = response.statusCode;
    if (status != 200) {
      throw HttpStatusError('Load Settings', status, error: json['error']);
    }
    try {
      settings = AppSettings.fromJson(_themeNotifier, json);
    } catch (e) {
      _log.error("got error: $e");
    }

    await getIt<SharedPreferences>().setInt('theme_color', settings.themeColor);
  }

  bool isDarkMode(BuildContext context) {
    return settings.theme.isDarkMode(context);
  }
}

class AppSettings {
  final ValueNotifier<AppThemeSetting> themeNotifier;
  AppThemeMode theme;
  double fontSize;
  int themeColor; // Store the color as an integer
  bool isVisibleTextEn;
  bool isVisibleTextCn;
  bool isVisibleSelect;
  bool isVisibleInput;
  bool isAutoPlayAfterSwitch;
  bool isAutoPlayNext;
  int playbackTimes;
  int playbackInterval;
  double playbackSpeed;
  int defaultFavoriteList;
  static const _kFlagBitIsVisibleTextEn = 0;
  static const _kFlagBitIsVisibleTextCn = 1;
  static const _kFlagBitIsVisibleSelect = 2;
  static const _kFlagBitIsVisibleInput = 3;
  static const _kFlagBitIsAutoPlayAfterSwitch = 4;
  static const _kFlagBitIsAutoPlayNext = 5;

  AppSettings({
    required this.themeNotifier,
    this.theme = AppThemeMode.light,
    this.fontSize = kFontSizeDefault,
    this.themeColor = 0xff6d4c41,
    // this.themeColor = 0xfff0f0f0,
    this.isVisibleTextEn = false,
    this.isVisibleTextCn = true,
    this.isVisibleSelect = false,
    this.isVisibleInput = false,
    this.isAutoPlayAfterSwitch = true,
    this.playbackTimes = 1,
    this.playbackInterval = 5,
    this.playbackSpeed = 1.0,
    this.isAutoPlayNext = true,
    this.defaultFavoriteList = 0,
  });

  Map<String, dynamic> toJson() => {
        'theme': themeNotifier.value.mode.toString(),
        'theme_color': themeNotifier.value.themeColor,
        'font_size': mapDouble2TinyInt(kFontSizeMin, kFontSizeMax, fontSize),
        'flags': _bits2Flag(),
        'playback_times': playbackTimes,
        'playback_interval': playbackInterval,
        'playback_speed': playbackSpeed,
        'default_favorite_list': defaultFavoriteList,
      };

  int _bits2Flag() {
    int flag = 0;

    if (isVisibleInput) flag += 1 << _kFlagBitIsVisibleInput;
    if (isVisibleTextEn) flag += 1 << _kFlagBitIsVisibleTextEn;
    if (isVisibleTextCn) flag += 1 << _kFlagBitIsVisibleTextCn;
    if (isVisibleSelect) flag += 1 << _kFlagBitIsVisibleSelect;
    if (isAutoPlayAfterSwitch) flag += 1 << _kFlagBitIsAutoPlayAfterSwitch;
    if (isAutoPlayNext) flag += 1 << _kFlagBitIsAutoPlayNext;
    return flag;
  }

  static bool _flagBit2Bool(int? flag, int bit, {bool defaultValue = false}) {
    if (flag == null) return defaultValue;
    return (flag & (1 << bit)) != 0;
  }

  static double _doubleFromJson(dynamic json, {double defaultValue = 0}) {
    if (json == null) return defaultValue;
    return double.parse(json);
  }

  factory AppSettings.fromJson(
      ValueNotifier<AppThemeSetting> themeNotifier, Map<String, dynamic> json) {
    double fontSize = kFontSizeDefault;
    final theme = themeNotifier.value.copyWith();
    if (json['theme'] != null) {
      theme.mode = AppThemeMode.fromString(json['theme']);
    }
    if (json['theme_color'] != null) {
      theme.themeColor = json['theme_color'];
    }
    if (json['font_size'] != null) {
      fontSize =
          mapTinyInt2Double(kFontSizeMin, kFontSizeMax, json['font_size']);
    }

    themeNotifier.value = theme;

    return AppSettings(
      themeNotifier: themeNotifier,
      fontSize: fontSize,
      isVisibleTextEn: _flagBit2Bool(json['flags'], _kFlagBitIsVisibleTextEn),
      isVisibleTextCn: _flagBit2Bool(json['flags'], _kFlagBitIsVisibleTextCn,
          defaultValue: true),
      isVisibleSelect: _flagBit2Bool(json['flags'], _kFlagBitIsVisibleSelect),
      isVisibleInput: _flagBit2Bool(json['flags'], _kFlagBitIsVisibleInput),
      isAutoPlayAfterSwitch:
          _flagBit2Bool(json['flags'], _kFlagBitIsAutoPlayAfterSwitch),
      isAutoPlayNext: _flagBit2Bool(json['flags'], _kFlagBitIsAutoPlayNext),
      playbackTimes: json['playback_times'] ?? 1,
      playbackInterval: json['playback_interval'] ?? 5,
      playbackSpeed: _doubleFromJson(json['playback_speed'], defaultValue: 1.0),
      defaultFavoriteList: json['default_favorite_list'] ?? 0,
    );
  }

  // CopyWith method
  AppSettings copyWith({
    ValueNotifier<AppThemeSetting>? themeNotifier,
    AppThemeMode? theme,
    double? fontSize,
    int? themeColor,
    bool? isVisibleTextEn,
    bool? isVisibleTextCn,
    bool? isVisibleSelect,
    bool? isVisibleInput,
    bool? isAutoPlayAfterSwitch,
    int? playbackTimes,
    int? playbackInterval,
    double? playbackSpeed,
    bool? isAutoPlayNext,
    int? defaultFavoriteList,
  }) {
    return AppSettings(
      themeNotifier: themeNotifier ?? this.themeNotifier,
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      themeColor: themeColor ?? this.themeColor,
      isVisibleTextEn: isVisibleTextEn ?? this.isVisibleTextEn,
      isVisibleTextCn: isVisibleTextCn ?? this.isVisibleTextCn,
      isVisibleSelect: isVisibleSelect ?? this.isVisibleSelect,
      isVisibleInput: isVisibleInput ?? this.isVisibleInput,
      isAutoPlayAfterSwitch:
          isAutoPlayAfterSwitch ?? this.isAutoPlayAfterSwitch,
      playbackTimes: playbackTimes ?? this.playbackTimes,
      playbackInterval: playbackInterval ?? this.playbackInterval,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isAutoPlayNext: isAutoPlayNext ?? this.isAutoPlayNext,
      defaultFavoriteList: defaultFavoriteList ?? this.defaultFavoriteList,
    );
  }
}

enum AppThemeMode {
  light,
  dark,
  system;

  // Convert a string to the corresponding ThemeMode
  static AppThemeMode fromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
        return AppThemeMode.system;
      default:
        return AppThemeMode.light;
    }
  }

  // Override toString to return the string representation of each enum value
  @override
  String toString() {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  ThemeMode toSystemValue() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool isDarkMode(BuildContext context) {
    final systemIsDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    if (this == AppThemeMode.dark) return true;
    if (this == AppThemeMode.system && systemIsDark) return true;

    return false;
  }
}

class AppThemeSetting {
  int themeColor;
  AppThemeMode mode;

  AppThemeSetting({required this.themeColor, required this.mode});

  // Override the == operator for comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppThemeSetting &&
        other.themeColor == themeColor &&
        other.mode == mode;
  }

  // Override the hashCode
  @override
  int get hashCode => themeColor.hashCode ^ mode.hashCode;

  AppThemeSetting copyWith({int? themeColor, AppThemeMode? mode}) {
    return AppThemeSetting(
      themeColor: themeColor ?? this.themeColor,
      mode: mode ?? this.mode,
    );
  }
}
