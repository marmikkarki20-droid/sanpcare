import 'package:flutter/widgets.dart';

import '../controllers/care_controller.dart';

class CareScope extends InheritedNotifier<CareController> {
  const CareScope({
    super.key,
    required CareController controller,
    required super.child,
  }) : super(notifier: controller);

  static CareController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CareScope>();
    assert(scope != null, 'No CareScope found in context.');
    return scope!.notifier!;
  }
}
