import 'package:flutter/material.dart';
import '../utils/utils.dart';
import '../providers/learning_provider.dart';
import 'package:simple_logging/simple_logging.dart';
import '../widgets/resource_widget.dart';
import '../providers/service_locator.dart';

final _log = Logger('CategoryList', level: LogLevel.debug);

class CoursePage extends StatelessWidget {
  final int courseId;
  const CoursePage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final courseFuture = getIt<LearningProvider>().fetchCourse(courseId);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
            future: courseFuture,
            builder: (context, snapshot) {
              return futureBuilderHelper(
                  snapshot: snapshot,
                  onDone: () {
                    final course = snapshot.data!;
                    return Text(course.name);
                  });
            }),
      ),
      body: FutureBuilder(
          future: courseFuture,
          builder: (context, snapshot) {
            return futureBuilderHelper(
                snapshot: snapshot,
                onDone: () {
                  final course = snapshot.data!;
                  final episods = course.episodes;

                  if (episods == null) {
                    return resourceListSectionNoContentLabel(context);
                  }

                  return ListView(
                    children: episods.map((episod) {
                      return ResourceWidget(
                        res: episod,
                      );
                    }).toList(),
                  );
                },
                logger: _log);
          }),
    );
  }
}
