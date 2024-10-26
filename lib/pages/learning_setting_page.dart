import 'package:flutter/material.dart';
import 'package:libmuyenglish/domain/global.dart';
import '../widgets/setting_group.dart';
import '../providers/service_locator.dart';
import '../providers/setting_provider.dart';

class LearningSettingPage extends StatefulWidget {

  const LearningSettingPage({super.key});

  @override
  createState() => _LearningSettingPageState();
}

class _LearningSettingPageState extends State<LearningSettingPage> {
  final _settingProvider = getIt<SettingProvider>();
  double _fontSize = 0;

  @override
  initState() {
    super.initState();
    _fontSize = _settingProvider.settings.fontSize;
  }

  Widget settingItemTitle(BuildContext context, String text) {
    return Text(text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSecondary));
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settingProvider.settings;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          SettingGroup(children: [
            SwitchListTile(
              title: settingItemTitle(context, 'Show English'),
              value: settings.isVisibleTextEn,
              onChanged: (value) async {
                setState(() {
                  settings.isVisibleTextEn = value;
                });
              },
            ),
            SwitchListTile(
              title: settingItemTitle(context, 'Show Chinese'),
              value: settings.isVisibleTextCn,
              onChanged: (value) async {
                setState(() {
                  settings.isVisibleTextCn = value;
                });
              },
            ),
            SwitchListTile(
              title: settingItemTitle(context, 'Show Word Select'),
              value: settings.isVisibleSelect,
              onChanged: (value) async {
                setState(() {
                  settings.isVisibleSelect = value;
                });
              },
            ),
            SwitchListTile(
              title: settingItemTitle(context, 'Show Text Input'),
              value: settings.isVisibleInput,
              onChanged: (value) async {
                setState(() {
                  settings.isVisibleInput = value;
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
                min: kFontSizeMin,
                max: kFontSizeMax,
                value: _fontSize,
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                },
                onChangeEnd: (value) {
                  settings.fontSize = value;
                },
              ),
            ),
          ]),
          SettingGroup(title: 'Playback Settings', children: [
            settingItemListTile(
              context: context,
              title: 'Playback Times',
              value: settings.playbackTimes,
              items: List.generate(6, (index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text(index == 0 ? 'Unlimited' : '$index'),
                );
              }),
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    settings.playbackTimes = value;
                  });
                }
              },
            ),
            settingItemListTile(
              context: context,
              title: 'Playback Interval (seconds)',
              value: settings.playbackInterval,
              items: List.generate(16, (index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text('$index seconds'),
                );
              }),
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    settings.playbackInterval = value;
                  });
                }
              },
            ),
            settingItemListTile(
              context: context,
              title: 'Playback Speed',
              value: settings.playbackSpeed,
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
                    settings.playbackSpeed = value;
                  });
                }
              },
            ),
            SwitchListTile(
              title:
                  settingItemTitle(context, 'Auto Play After Switch Sentence'),
              value: settings.isAutoPlayAfterSwitch,
              onChanged: (value) {
                setState(() {
                  settings.isAutoPlayAfterSwitch = value;
                });
              },
            ),
            SwitchListTile(
              title: settingItemTitle(context, 'Auto Play Next Sentence'),
              value: settings.isAutoPlayNext,
              onChanged: (value) {
                setState(() {
                  settings.isAutoPlayNext = value;
                });
              },
            ),
          ])
        ],
      ),
    );
  }
}
