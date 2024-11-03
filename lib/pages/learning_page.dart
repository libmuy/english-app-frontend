import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:libmuyenglish/pages/desc_edit_page.dart';

import 'learning_page_ploc.dart';
import '../utils/utils.dart';
import '../domain/entities.dart';
import 'package:simple_logging/simple_logging.dart';
import 'learning_setting_page.dart';
import '../widgets/common_widgets.dart';

final _log = Logger('LearningPage', level: LogLevel.debug);
const _kSeparator = SizedBox(height: 20);

const _kAreaPadding = EdgeInsets.all(5);

class LearningPage extends StatefulWidget {
  final SentenceSource sentenceSrc;
  final String title;
  final int? audioLength;

  const LearningPage(
      {required this.sentenceSrc,
      required this.title,
      this.audioLength,
      super.key});

  @override
  createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  final ploc = LearningPagePloc();
  bool _showSpeed = false;
  bool _isVisibleDesc = false;
  final bool _isWordSelectVisible = false;
  final bool _isTextInputVisible = false;

  @override
  void initState() {
    super.initState();
    _log.debug('initState');
    ploc.init(widget.sentenceSrc, widget.title, widget.audioLength, setState);
  }

  @override
  void dispose() {
    ploc.dispose();
    _log.debug('dispose');
    super.dispose();
  }

  List<Widget> _buildTextContainer(String text, String font) {
    return [
      _kSeparator,
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (mounted) {
                    showSnackBar(context, 'Text copied to clipboard!');
                  }
                },
                // style: OutlinedButton.styleFrom(
                //   visualDensity: VisualDensity.compact,
                //   padding: EdgeInsets.all(0),
                // side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),),
                child: const Text('Copy'))
          ],
        ),
        Container(
          padding: _kAreaPadding,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.primary),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontFamily: font,
                fontSize: ploc.settings.fontSize,
                color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ])
    ];
  }

  List<Widget> _buildWordSelect(int pageIndex) {
    final page = ploc.pages![pageIndex];
    final shuffledWords = page.shuffledWords;
    final selectedWords = page.selectedWords;
    return [
      _kSeparator,
      Text(
        'Word Select',
        style: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(color: Theme.of(context).colorScheme.primary),
      ),
      Container(
        padding: _kAreaPadding,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8.0,
              children: shuffledWords.asMap().entries.map((e) {
                final i = e.key;
                final word = e.value;
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ChoiceChip(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    label: Text(
                      word,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    selected: false,
                    onSelected: (selected) {
                      setState(() {
                        page.selectWord(i, word);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            Text(
              '↓',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Wrap(
              spacing: 8.0,
              children: selectedWords.asMap().entries.map((e) {
                final i = e.key;
                final word = e.value;
                final highlightPos = page.checkOrder();
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ChoiceChip(
                    backgroundColor: i < highlightPos
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                    label: Text(
                      word,
                      style: TextStyle(
                        color: i < highlightPos
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onError,
                      ),
                    ),
                    selected: false,
                    onSelected: (selected) {
                      setState(() {
                        page.deselectWord(i, word);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      )
    ];
  }

  List<Widget> _buildTextInput(int pageIndex) {
    final page = ploc.pages![pageIndex];
    return [
      _kSeparator,
      Text(
        'Text Input',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Container(
        padding: _kAreaPadding,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: QuillEditor.basic(
          configurations: QuillEditorConfigurations(
            controller: page.textController!,
            sharedConfigurations: const QuillSharedConfigurations(
              locale: Locale('en', 'US'),
            ),
          ),
        ),
      ),
      _kSeparator,
    ];
  }

  Widget _buildNavigationButtons() {
    final label = '${ploc.settings.playbackSpeed.toStringAsFixed(2)}x';
    return Column(
      children: [
        if (_showSpeed)
          Slider(
            label: label,
            divisions: 32,
            min: 0.4,
            max: 2.0,
            value: ploc.settings.playbackSpeed,
            onChanged: (value) {
              setState(() {
                ploc.settings.playbackSpeed = value;
              });
            },
            onChangeEnd: ploc.onPlaySpeedChanged,
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 70,
              child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showSpeed = !_showSpeed;
                    });
                  },
                  child: _showSpeed
                      ? Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Text(
                          label,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        )),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                (defaultTargetPlatform == TargetPlatform.android ||
                        defaultTargetPlatform == TargetPlatform.iOS)
                    ? Container()
                    : IconButton(
                        iconSize: 40,
                        onPressed: ploc.switchToPreviousSentence,
                        icon: const Icon(Icons.skip_previous),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                const SizedBox(
                  width: 10,
                ),
                ValueListenableBuilder<bool>(
                    valueListenable: ploc.playingNotifier,
                    builder: (context, playing, child) {
                      return ValueListenableBuilder(
                          valueListenable: ploc.countDownStr,
                          builder: (contex, cd, child) {
                            return PlayButton(
                              onPressed: () =>
                                  playing ? ploc.stopAudio() : ploc.playAudio(),
                              text: playing ? 'Stop' : 'Play',
                              subtitle: ploc.countDownStr.value,
                            );
                          });
                    }),
                const SizedBox(
                  width: 10,
                ),
                (defaultTargetPlatform == TargetPlatform.android ||
                        defaultTargetPlatform == TargetPlatform.iOS)
                    ? Container()
                    : IconButton(
                        iconSize: 40,
                        onPressed: ploc.switchToNextSentence,
                        icon: const Icon(Icons.skip_next),
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ],
            ),
            SizedBox(
              width: 70,
              child: Row(
                children: [
                  if (!ploc.settings.isVisibleTextCn)
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          ploc.pages![ploc.index].isVisibleTextCn =
                              !(ploc.pages![ploc.index].isVisibleTextCn);
                        });
                      },
                      child: const Text('汉'),
                    ),
                  if (!ploc.settings.isVisibleTextEn)
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _log.debug(
                              'toggle page: ${ploc.index} english text show');
                          ploc.pages![ploc.index].isVisibleTextEn =
                              !(ploc.pages![ploc.index].isVisibleTextEn);
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          //  width: 2
                        ), // Change border color and width
                      ),
                      child: const Text('英'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openSettingsPage() {
    ploc.stopAudio();
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LearningSettingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    )
        .then((_) {
      ploc.saveSettings();
      setState(() {});
    }); // Reload settings after returning from settings page
  }

  Widget _buildSentenceDropdown(int i) {
    final textStyle = TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 22,
        fontFamily: 'Mallanna');
    return Row(
      children: [
        FocusScope(
          canRequestFocus: false,
          child: DropdownButton<int>(
            alignment: Alignment.center,
            value: i + 1,
            icon: Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.primary,
            ), // The expandable icon
            iconSize: 24,
            elevation: 16,
            style: textStyle,
            underline: Container(
              height: 1,
              color: Theme.of(context).colorScheme.primary,
            ),
            onChanged: (int? newValue) {
              if (newValue != null) {
                ploc.switchToSentence(newValue - 1);
              }
            },
            items: List.generate(
              ploc.sentenceCount!,
              (index) => DropdownMenuItem<int>(
                value: index + 1,
                alignment: Alignment.center,
                child: Text('${index + 1}', style: textStyle),
              ),
            ),
          ),
        ),
        Text(
          '/${ploc.sentenceCount}',
          style: textStyle,
        ),
      ],
    );
  }

  Widget _buildPageHeader(int i, Sentence sentence) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSentenceDropdown(i),
        Row(
          children: [
            if (sentence.haveDesc)
              TextButton.icon(
                icon: Icon(
                  _isVisibleDesc ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  '句子详解',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: () async {
                  if (!_isVisibleDesc) await ploc.fetchDesc(sentence);
                  setState(() {
                    _isVisibleDesc = !_isVisibleDesc;
                  });
                },
              ),
            GestureDetector(
              onLongPress: () =>
                  ploc.onFavoriteIconLongPress(context, sentence),
              child: IconButton(
                icon: sentence.fav
                    ? Icon(
                        Icons.favorite,
                        color: Theme.of(context).colorScheme.tertiary,
                      )
                    : Icon(
                        Icons.favorite_border,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                onPressed: () => ploc.onFavoriteIconTap(sentence),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildPageSentenceDesc(String desc) {
    return [
      _kSeparator,
      Text(
        '句子详解',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Container(
        padding: _kAreaPadding,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: MarkdownBody(
          data: desc,
          styleSheet: _markdownStyleSheet(context),
        ),
      ),
    ];
  }

  Widget _buildPage(BuildContext context, int i) {
    _log.debug("building page: $i");
    final sentence = ploc.sentences![i];
    final page = ploc.pages![i];

    page.init();

    return Padding(
      padding: _kAreaPadding * 3,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPageHeader(i, sentence),
                if (page.isVisibleTextEn || ploc.settings.isVisibleTextEn)
                  ..._buildTextContainer(sentence.english, 'Mallanna'),
                if (page.isVisibleTextCn || ploc.settings.isVisibleTextCn)
                  ..._buildTextContainer(sentence.chinese, 'AlibabaHealth'),
                if (_isWordSelectVisible) ..._buildWordSelect(i),
                if (_isTextInputVisible) ..._buildTextInput(i),
                if (_isVisibleDesc && sentence.desc != null)
                  ..._buildPageSentenceDesc(sentence.desc!),
              ],
            ),
          ),
          _buildPageReviewButtons(page),
        ],
      ),
    );
  }

  Widget _buildPageReviewButtons(PageData page) {
    const kButtonPadding = SizedBox(width: 8);

    const buttonData = <ReviewResult, Map<String, dynamic>>{
      ReviewResult.skip: {
        'text': '跳过',
        'color': Colors.grey,
      },
      ReviewResult.easy: {
        'text': '简单',
        'color': Colors.blue,
      },
      ReviewResult.good: {
        'text': '正确',
        'color': Colors.green,
      },
      ReviewResult.hard: {
        'text': '较难',
        'color': Colors.orange,
      },
      ReviewResult.again: {
        'text': '忘记',
        'color': Colors.red,
      },
    };

    Widget buildButton(ReviewResult rate, int? nexIntervalDays, bool isActive) {
      final color = buttonData[rate]!['color'] as Color;
      String text = buttonData[rate]!['text'];
      if (nexIntervalDays != null) {
        text = '$nexIntervalDays\n$text';
      }
      final underline = isActive
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: color,
              ),
              height: 5,
            )
          : const SizedBox(
              height: 5,
            );
      return Expanded(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    page.reviewResult = rate;
                  });
                  ploc.reviewSentence(rate);
                  ploc.switchToNextSentence();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  backgroundColor: color,
                  elevation: 1,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Wrap(
                    direction: Axis.horizontal,
                    children: text
                        .split('')
                        .map((e) => Text(
                              e,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  // color: color
                                  fontSize: 20),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            underline,
          ],
        ),
      );
    }

    return ValueListenableBuilder<LearningData?>(
        valueListenable: ploc.learningDataNotifier,
        builder: (context, data, child) {
          int? nexIntervalDays;
          final ret = List<Widget>.empty(growable: true);
          for (var rate in ReviewResult.values) {
            if (data != null) (_, nexIntervalDays) = reviewAlgrithm(data, rate);
            ret.add(kButtonPadding);
            ret.add(
                buildButton(rate, nexIntervalDays, page.reviewResult == rate));
          }
          ret.add(kButtonPadding);
          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ret);
        });
  }

  MarkdownStyleSheet _markdownStyleSheet(BuildContext context) {
    // Define a custom MarkdownStyleSheet
    final fontColor = Theme.of(context).primaryColor;
    // final markdownStyleSheet = MarkdownStyleSheet(
    //   p: TextStyle(color: fontColor), // Set the text color to black
    //   h1: TextStyle(color: fontColor),
    //   h2: TextStyle(color: fontColor),
    //   h3: TextStyle(color: fontColor),
    //   h4: TextStyle(color: fontColor),
    //   h5: TextStyle(color: fontColor),
    //   h6: TextStyle(color: fontColor),
    //   listBullet: TextStyle(color: fontColor),
    // );
    return MarkdownStyleSheet(
      p: Theme.of(context).textTheme.bodyMedium!.copyWith(color: fontColor),
      h1: Theme.of(context).textTheme.headlineLarge!.copyWith(color: fontColor),
      h2: Theme.of(context)
          .textTheme
          .headlineMedium!
          .copyWith(color: fontColor),
      h3: Theme.of(context).textTheme.headlineSmall!.copyWith(color: fontColor),
      h4: Theme.of(context).textTheme.headlineSmall!.copyWith(color: fontColor),
      h5: Theme.of(context).textTheme.headlineSmall!.copyWith(color: fontColor),
      h6: Theme.of(context).textTheme.headlineSmall!.copyWith(color: fontColor),
      blockquote:
          Theme.of(context).textTheme.bodyMedium!.copyWith(color: fontColor),
      code: Theme.of(context).textTheme.bodyMedium!.copyWith(color: fontColor),
      strong:
          Theme.of(context).textTheme.bodyMedium!.copyWith(color: fontColor, fontWeight: FontWeight.bold),
      em: Theme.of(context).textTheme.bodyMedium!.copyWith(color: fontColor, fontWeight: FontWeight.bold),
      del: Theme.of(context).textTheme.bodyMedium!.copyWith(color: fontColor),
      listBullet: Theme.of(context).textTheme.bodyMedium!.copyWith(color: fontColor, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (ploc.isAdmin)
            IconButton(
              icon: const Icon(Icons.description),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => DescEditPage(
                          sentence: ploc.currentSentence!,
                          styleSheet: _markdownStyleSheet(context))),
                ).then((_) {
                  setState(() {
                    ploc.currentSentence!.haveDesc = true;
                  });
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettingsPage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: ploc.pageController,
              itemCount: ploc.sentenceCount,
              itemBuilder: _buildPage,
              onPageChanged: ploc.onPageChanged,
            ),
          ),
          Padding(
            padding: (_kAreaPadding * 4).copyWith(top: 0),
            child: _buildNavigationButtons(),
          ),
        ],
      ),
      // floatingActionButton: _buildFAB(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: ploc.sentencesFuture!,
        builder: (context, snapshot) {
          return futureBuilderHelper(
              snapshot: snapshot,
              onDone: () {
                ploc.initializeOnDataChanged(snapshot.data!);
                if (ploc.sentences!.isEmpty) {
                  return const Text('There is no sentence...');
                }
                return _buildBody(context);
              },
              logger: _log,
              logId: "FetchSentence");
        });
  }
}
