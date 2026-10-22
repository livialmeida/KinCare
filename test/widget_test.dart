// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kincare/main.dart';

void main() {
  testWidgets('KinCareApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KinCareApp());

    // Verify that the app mounts successfully
    expect(find.byType(KinCareApp), findsOneWidget);
  });
}