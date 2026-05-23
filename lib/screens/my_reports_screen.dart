import 'package:flutter/material.dart';

import '../app/care_scope.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/info_widgets.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    return AppScaffold(
      title: 'My reports',
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ReportList(
          reports: controller.reports,
          emptyMessage: 'No reports have been submitted.',
        ),
      ),
    );
  }
}
