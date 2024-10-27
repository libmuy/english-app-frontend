import 'package:flutter/material.dart';
import 'package:libmuyenglish/domain/entities.dart';
import 'package:libmuyenglish/providers/history.dart';
import '../domain/global.dart';
import '../providers/auth_provider.dart';
import '../utils/utils.dart';
import '../providers/learning_provider.dart';
import 'package:simple_logging/simple_logging.dart';
import '../widgets/resource_widget.dart';
import '../providers/service_locator.dart';

final _log = Logger('HomePage', level: LogLevel.debug);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<(Map<ResourceType, List<ResourceEntity>>, List<History>, ReviewInfo)>
      _getDisplayData() async {
    final learningProvider = getIt<LearningProvider>();
    final historyMgr = getIt<HistoryManager>();
    final historyFuture = historyMgr.loadHistory();
    final favoriteFuture = learningProvider.fetchFavoriteResource();
    final reviewSentenceCountFuture =
        learningProvider.fetchReviewInfo();
    final  history = await historyFuture;
    final favorite = await favoriteFuture;
    final reviewInfo = await reviewSentenceCountFuture;

    return (favorite, history, reviewInfo);
  }

  _buildBody(BuildContext context, Map<ResourceType, List<ResourceEntity>> favs,
      List<History> historyList, ReviewInfo reviewInfo) {
    final categoryFav = favs[ResourceType.category];
    final courseFav = favs[ResourceType.course];
    final episodFav = favs[ResourceType.episode];
    final favIsEmpty = (categoryFav == null || categoryFav.isEmpty) &&
        (courseFav == null || courseFav.isEmpty) &&
        (episodFav == null || episodFav.isEmpty);

    final textStyle = Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).primaryColor);
    final List<Widget> widgetList = [
      Text("Hi! ${getIt<AuthProvider>().userName}",
      style: textStyle),
      Text("今天学习了${reviewInfo.todayLearnedCount}个句子，还有${reviewInfo.needToReviewCount}个句子需要复习。加油哦！",
      style: textStyle),
      const SizedBox(height: kPageTopPadding),
      if (reviewInfo.needToReviewCount > 0)
        ...resourceListSection(context, '复习', [
          ResourceWidget(
              res: ReviewSentences(sentenceCount: reviewInfo.needToReviewCount))
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
                  final (favs, historyList, reviewInfo) =
                      snapshot.data!;

                      return _buildBody(context, favs, historyList, reviewInfo);
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
