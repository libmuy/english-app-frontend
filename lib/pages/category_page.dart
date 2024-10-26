import 'package:flutter/material.dart';
import 'package:libmuyenglish/domain/global.dart';
import '../utils/utils.dart';
import '../providers/learning_provider.dart';
import 'package:simple_logging/simple_logging.dart';

import '../widgets/resource_widget.dart';
import '../providers/service_locator.dart';

final _log = Logger('CategoryPage', level: LogLevel.debug);

class CategoryPage extends StatelessWidget {
  final int? categoryId;
  const CategoryPage({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    final categoryFuture = getIt<LearningProvider>().fetchCategory(categoryId);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
            future: categoryFuture,
            builder: (context, snapshot) {
              return futureBuilderHelper(
                  snapshot: snapshot,
                  onDone: () {
                    final category = snapshot.data!;
                    return Text(category.name);
                  });
            }),
      ),
      body: FutureBuilder(
          future: categoryFuture,
          builder: (context, snapshot) {
            return futureBuilderHelper(
                snapshot: snapshot,
                onDone: () {
                  final category = snapshot.data!;
                  final subcategories = category.subcategories;
                  final courses = category.courses;
                  final noContent = subcategories == null && courses == null;

                  if (noContent) {
                    return resourceListSectionNoContentLabel(context);
                  }

                  return ListView(
                    children: [
                      const SizedBox(height: kPageTopPadding),
                      if (subcategories != null && subcategories.isNotEmpty)
                        ...resourceListSection(context, '分类',
                            subcategories.map((subcategory) {
                          return ResourceWidget(
                            res: subcategory,
                          );
                        })),
                      if (courses != null && courses.isNotEmpty)
                        ...resourceListSection(context, '课程',
                            courses.map((course) {
                          return ResourceWidget(
                            res: course,
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
