import 'package:flutter_test/flutter_test.dart';

import 'package:naqsh_office/app/app.dart';

void main() {
  testWidgets('App shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('NAQSH'), findsOneWidget);
  });
}