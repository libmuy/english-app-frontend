import 'package:flutter/material.dart';
import 'package:libmuyenglish/domain/entities.dart';
import 'package:libmuyenglish/providers/history.dart';
import '../domain/global.dart';
import '../utils/utils.dart';
import '../providers/learning_provider.dart';
import 'package:simple_logging/simple_logging.dart';
import '../widgets/resource_widget.dart';
import '../providers/service_locator.dart';

final _log = Logger('HomePage', level: LogLevel.debug);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<(Map<ResourceType, List<ResourceEntity>>, List<History>, int)>
      _getDisplayData() async {
    final learningProvider = getIt<LearningProvider>();
    final historyMgr = getIt<HistoryManager>();
    final historyFuture = historyMgr.loadHistory();
    final favoriteFuture = learningProvider.fetchFavoriteResource();
    final reviewSentenceCountFuture =
        learningProvider.fetchReviewSentenceCount();
    final  history = await historyFuture;
    final favorite = await favoriteFuture;
    final reviewSentenceCount = await reviewSentenceCountFuture;

    return (favorite, history, reviewSentenceCount);
  }

  _buildBody(BuildContext context, Map<ResourceType, List<ResourceEntity>> favs,
      List<History> historyList, int reviewSentenceCount) {
    final categoryFav = favs[ResourceType.category];
    final courseFav = favs[ResourceType.course];
    final episodFav = favs[ResourceType.episode];
    final favIsEmpty = (categoryFav == null || categoryFav.isEmpty) &&
        (courseFav == null || courseFav.isEmpty) &&
        (episodFav == null || episodFav.isEmpty);

    final List<Widget> widgetList = [
      if (reviewSentenceCount > 0)
        ...resourceListSection(context, '复习', [
          ResourceWidget(
              res: ReviewSentences(sentenceCount: reviewSentenceCount))
        ]),
      if (historyList.isNotEmpty) ...[
        const SizedBox(height: kPageTopPadding),
        ...resourceListSection(
            context,
            '最近',
            historyList.map((h) {
              return ResourceWidget(
                res: h.generateResource(),
              );
            }).toList()),
      ],
      if (!favIsEmpty) ...[
        if (categoryFav != null && categoryFav.isNotEmpty)
          ...resourceListSection(
              context,
              '分类',
              categoryFav.map((c) {
                return ResourceWidget(
                  res: c,
                );
              }).toList()),
        if (courseFav != null && courseFav.isNotEmpty)
          ...resourceListSection(
              context,
              '课程',
              courseFav.map((c) {
                return ResourceWidget(
                  res: c,
                );
              }).toList()),
        if (episodFav != null && episodFav.isNotEmpty)
          ...resourceListSection(
              context,
              '音频',
              episodFav.map((c) {
                return ResourceWidget(
                  res: c,
                );
              }).toList()),
      ]
    ];

    if (widgetList.isEmpty) {
      return resourceListSectionNoContentLabel(context);
    }

    return Column(
      children: widgetList,
    );
  }


  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;
    try {
      bodyWidget = ListView(children: [
      const SizedBox(height: kPageTopPadding),
      FutureBuilder(
          future: _getDisplayData(),
          builder: (context, snapshot) {
            return futureBuilderHelper(
                snapshot: snapshot,
                onDone: () {
                  final (favs, historyList, reviewSentenceCount) =
                      snapshot.data!;

                      return _buildBody(context, favs, historyList, reviewSentenceCount);
                },
                logger: _log,
                logId: 'HomePage');
          })
    ]);
    } catch (err) {
      bodyWidget = Center(child: Text(err.toString()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Libmuy English'),
      ),
      body: bodyWidget,
    );
  }
}
