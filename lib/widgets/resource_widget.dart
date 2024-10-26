import 'package:flutter/material.dart';
import 'package:libmuyenglish/utils/utils.dart';
import '../pages/category_page.dart';
import '../pages/course_page.dart';
import '../providers/service_locator.dart';
import '../domain/entities.dart';
import '../providers/learning_provider.dart';
import '../pages/learning_page.dart';

const _kSeprator = SizedBox(height: 10);
const _kIcons = {
  ResourceType.category: Icons.category,
  ResourceType.course: Icons.book,
  ResourceType.episode: Icons.audiotrack,
  ResourceType.favoriteList: Icons.favorite,
};

class ResourceWidget extends StatefulWidget {
  final ResourceEntity res;

  const ResourceWidget({
    super.key,
    required this.res,
  });

  @override
  ResourceWidgetState createState() => ResourceWidgetState();
}

class ResourceWidgetState extends State<ResourceWidget> {
  void _onTap(BuildContext context) {
    Widget Function(BuildContext)? builder;
    switch (widget.res.type) {
      case ResourceType.category:
        builder = (context) => CategoryPage(
              categoryId: widget.res.id,
            );
        break;
      case ResourceType.course:
        builder = (context) => CoursePage(
              courseId: widget.res.id,
            );
        break;
      case ResourceType.episode:
        final episode = widget.res as Episode;
        builder = (context) => LearningPage(
              sentenceSrc: SentenceSource(type: SentenceSourceType.episode, episodeId: episode.id),
              title: episode.name,
              audioLength: episode.audioLength,
            );
        break;
      case ResourceType.favoriteList:
        builder = (context) => LearningPage(
              sentenceSrc: SentenceSource(type: SentenceSourceType.favorite, favoriteListId: widget.res.id),
              title: widget.res.name,
            );
        break;
      case ResourceType.reviewSentences:
        builder = (context) => LearningPage(
              sentenceSrc: SentenceSource(type: SentenceSourceType.review),
              title: widget.res.name,
            );
        break;
      case ResourceType.bad:
        showSnackBar(context, 'This resource is broken');
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: builder,
      ),
    );
  }

  Widget _getIcon() {
    if (widget.res.icon != null) return widget.res.icon!;
    return Icon(
      _kIcons[widget.res.type],
      size: 40,
    );
  }

  List<Widget> _titles(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    final subTitleStyle = Theme.of(context).textTheme.titleSmall;

    List<Widget> result = [
      Text(
        widget.res.name,
        style: titleStyle,
      ),
      _kSeprator,
    ];

    switch (widget.res.type) {
      case ResourceType.category:
        final cate = widget.res as Category;
        result.addAll([
          Text(cate.desc ?? '', style: subTitleStyle),
        ]);

      case ResourceType.course:
        final course = widget.res as Course;
        result.addAll([
          Text(course.desc ?? ''),
          _kSeprator,
          Text('音频数: ${course.episodeCount}', style: subTitleStyle),
        ]);

      case ResourceType.episode:
        final episode = widget.res as Episode;
        result.addAll(
            [Text('音频时长: ${formatSeconds(episode.audioLength)}', style: subTitleStyle)]);

      case ResourceType.favoriteList:
        final fav = widget.res as FavoriteList;
        result.addAll([
          Text('句子数: ${fav.sentenceCount}', style: subTitleStyle),
        ]);

      case ResourceType.reviewSentences:
        final review = widget.res as ReviewSentences;
        result.addAll([
          Text('句子数: ${review.sentenceCount}', style: subTitleStyle),
        ]);

      case ResourceType.bad:
        result.addAll([
          Text('此资源已损坏！', style: subTitleStyle),
        ]);
    }

    return result;
  }

  Widget _favIcon(BuildContext context) {
    if (widget.res is FavoriteList) return Container();

    return IconButton(
      icon: widget.res.fav
          ? Icon(Icons.favorite, color: Theme.of(context).colorScheme.onPrimary)
          : Icon(Icons.favorite_border,
              color: Theme.of(context).colorScheme.onPrimary),
      onPressed: () async {
        final learningProvider = getIt<LearningProvider>();
        await learningProvider.updateFavoriteResource(
            widget.res, !widget.res.fav);
        setState(() {
          widget.res.fav = !widget.res.fav;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // final settingProvider = getIt<SettingProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        // shadowColor: settingProvider.isDarkMode(context)?Colors.white: Colors.black,
        child: InkWell(
          onTap: () => _onTap(context),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _getIcon(),
                _kSeprator,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _titles(context),
                  ),
                ),
                _favIcon(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatSeconds(int totalSeconds) {
  if (totalSeconds < 0) {
    throw ArgumentError("Total seconds cannot be negative");
  }

  Duration duration = Duration(seconds: totalSeconds);

  String twoDigits(int n) => n.toString().padLeft(2, '0');

  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));

  if (duration.inHours > 0) {
    return "$hours:$minutes:$seconds";
  } else {
    return "$minutes:$seconds";
  }
}

}
