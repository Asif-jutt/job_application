import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:job_application/app.dart';

void main() {
  testWidgets('Rozgar app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RozgarApp(),
      ),
    );
    expect(find.text('Rozgar'), findsWidgets);
  });
}
