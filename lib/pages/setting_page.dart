import 'package:flutter/material.dart';
import 'package:libmuyenglish/domain/global.dart';
import 'package:libmuyenglish/providers/auth_provider.dart';
import '../widgets/setting_group.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/service_locator.dart';
import '../providers/setting_provider.dart';
import 'profile_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
    double _fontSize = 0;
    final _settingProvider = getIt<SettingProvider>();
    late final AppSettings _settings;
    final _authProvider = getIt<AuthProvider>();
    late Color _themeColor;

    @override
    initState() {
        super.initState();
        _fontSize = _settingProvider.settings.fontSize;
        _settings = _settingProvider.settings;
        _themeColor = Color(_settings.themeColor);
    }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SettingGroup(title: 'User Settings', children: [
            ListTile(
              title: settingItemTitle(context, 'Profile'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              title: settingItemTitle(context, 'Select Theme Mode'),
              trailing: DropdownButton<AppThemeMode>(
                underline: const SizedBox.shrink(),
                dropdownColor: Theme.of(context).colorScheme.secondary,
                value: _settings.theme,
                onChanged: (AppThemeMode? newMode) {
                  if (newMode != null) {
                    setState(() {
                      _settingProvider.changeThemeMode(newMode);
                    });
                  }
                },
                items: AppThemeMode.values.map((AppThemeMode mode) {
                  return DropdownMenuItem<AppThemeMode>(
                    value: mode,
                    child: settingItemTitle(context, mode.toString()),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: settingItemTitle(context, 'Select Theme Color'),
              subtitle: Container(
                width: 24,
                height: 24,
                color: _themeColor,
              ),
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Pick your theme color'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: _themeColor,
                          onColorChanged: (Color color) {
                            setState(() {
                              _themeColor = color;
                              _settingProvider.changeThemeColor(color.value);
                            });
                          },
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Select'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ]),
          SettingGroup(title: 'Learning Settings', children: [
            SwitchListTile(
              title: settingItemTitle(context, 'Show English'),
              value: _settings.isVisibleTextEn,
              onChanged: (value) async {
                setState(() {
                  _settings.isVisibleTextEn = value;
                });
              },
            ),
            SwitchListTile(
              title: settingItemTitle(context, 'Show Chinese'),
              value: _settings.isVisibleTextCn,
              onChanged: (value) async {
                setState(() {
                  _settings.isVisibleTextCn = value;
                });
              },
            ),
            SwitchListTile(
              title: settingItemTitle(context, 'Show Word Select'),
              value: _settings.isVisibleSelect,
              onChanged: (value) async {
                setState(() {
                  _settings.isVisibleSelect = value;
                });
              },
            ),
            SwitchListTile(
              title: settingItemTitle(context, 'Show Text Input'),
              value: _settings.isVisibleInput,
              onChanged: (value) async {
                setState(() {
                  _settings.isVisibleInput = value;
                });
              },
            ),
          ]),
          SettingGroup(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Smaller',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: kFontSizeMin,
                        ),
                  ),
                  Text(
                    'Font Size',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: _fontSize,
                        ),
                  ),
                  Text(
                    'Bigger',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: kFontSizeMax,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Slider(
                min: 15,
                max: 25,
                value: _fontSize,
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                },
                onChangeEnd: (value) {
                  _settings.fontSize = value;
                },
              ),
            ),
          ]),
          SettingGroup(title: 'Playback Settings', children: [
            settingItemListTile(
              context: context,
              title: 'Playback Times',
              value: _settings.playbackTimes,
              items: List.generate(6, (index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text(index == 0 ? 'Unlimited' : '$index'),
                );
              }),
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    _settings.playbackTimes = value;
                  });
                }
              },
            ),
            settingItemListTile(
              context: context,
              title: 'Playback Interval (seconds)',
              value: _settings.playbackInterval,
              items: List.generate(16, (index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text('$index seconds'),
                );
              }),
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    _settings.playbackInterval = value;
                  });
                }
              },
            ),
            settingItemListTile(
              context: context,
              title: 'Playback Speed',
              value: _settings.playbackSpeed,
              items: List.generate(17, (index) {
                final double speed = (index + 4) / 10;
                return DropdownMenuItem<double>(
                  value: speed,
                  child: Text('${speed}x'),
                );
              }),
              onChanged: (double? value) {
                if (value != null) {
                  setState(() {
                    _settings.playbackSpeed = value;
                  });
                }
              },
            ),
            SwitchListTile(
              title:
                  settingItemTitle(context, 'Auto Play After Switch Sentence'),
              value: _settings.isAutoPlayAfterSwitch,
              onChanged: (value) {
                setState(() {
                  _settings.isAutoPlayAfterSwitch = value;
                });
              },
            ),
            SwitchListTile(
              title: settingItemTitle(context, 'Auto Play Next Sentence'),
              value: _settings.isAutoPlayNext,
              onChanged: (value) {
                setState(() {
                  _settings.isAutoPlayNext = value;
                });
              },
            ),          ]),
          ListTile(
            title: settingItemTitle(context, 'Logout'),
            onTap: () {
              _authProvider.logout();
              _settingProvider.resetSettings();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
