import 'package:flutter_test/flutter_test.dart';

import 'package:medisync/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MediSyncApp());
    await tester.pumpAndSettle();
  });
}
