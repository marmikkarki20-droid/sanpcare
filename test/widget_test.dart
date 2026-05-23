import 'package:caresnap/app/care_snap_app.dart';
import 'package:caresnap/data/demo_care_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CareSnap opens on the sign in screen', (tester) async {
    await tester.pumpWidget(CareSnapApp(repository: DemoCareRepository()));

    expect(find.text('CareSnap'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
