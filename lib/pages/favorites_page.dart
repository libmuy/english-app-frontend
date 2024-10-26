import 'package:flutter/material.dart';
import 'package:libmuyenglish/domain/entities.dart';
import '../domain/global.dart';
import '../utils/utils.dart';
import '../providers/learning_provider.dart';
import 'package:simple_logging/simple_logging.dart';
import '../widgets/resource_widget.dart';
import '../providers/service_locator.dart';

final _log = Logger('FavoritePage', level: LogLevel.debug);

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  Future<({Map<ResourceType, List<ResourceEntity>> favRes, List<FavoriteList> favLists})> getFavs() async {
    final learningProvider = getIt<LearningProvider>();
    final favRes = await learningProvider.fetchFavoriteResource();
    final favLists = await learningProvider.fetchFavoriteLists();

    return (favRes: favRes, favLists: favLists);
  }

  @override
  Widget build(BuildContext context) {
    final favoriteFuture = getFavs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏'),
      ),
      body: FutureBuilder(
          future: favoriteFuture,
          builder: (context, snapshot) {
            return futureBuilderHelper(
                snapshot: snapshot,
                onDone: () {
                  final favRes = snapshot.data!.favRes;
                  final favLists = snapshot.data!.favLists;
                  final categoryFav = favRes[ResourceType.category];
                  final courseFav = favRes[ResourceType.course];
                  final episodFav = favRes[ResourceType.episode];
                  final isEmpty = (categoryFav == null || categoryFav.isEmpty) &&
                  (courseFav == null || courseFav.isEmpty) &&
                  (episodFav == null || episodFav.isEmpty);

                  if (isEmpty) {
                    return resourceListSectionNoContentLabel(context);
                  }

                  return ListView(
                    children: [
                    const SizedBox(height: kPageTopPadding),
                      if (categoryFav != null && categoryFav.isNotEmpty)
                        ...resourceListSection(context, '分类',
                            categoryFav.map((c) {
                          return ResourceWidget(
                            res: c,
                          );
                        })),
                      if (courseFav != null && courseFav.isNotEmpty)
                        ...resourceListSection(context, '课程',
                            courseFav.map((c) {
                          return ResourceWidget(
                            res: c,
                          );
                        })),
                      if (episodFav != null && episodFav.isNotEmpty)
                        ...resourceListSection(context, '音频',
                            episodFav.map((c) {
                          return ResourceWidget(
                            res: c,
                          );
                        })),
                      if (favLists.isNotEmpty)
                        ...resourceListSection(context, '收藏列表',
                            favLists.map((c) {
                          return ResourceWidget(
                            res: c,
                          );
                        })),
                    ],
                  );
                },
                logger: _log);
          }),
    );
  }
}
