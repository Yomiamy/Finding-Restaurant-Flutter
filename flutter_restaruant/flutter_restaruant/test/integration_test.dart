import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_app.dart' as test_app;

main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('tap on the floating action button, verify counter',
            (tester) async {
          test_app.main();
          await tester.pumpAndSettle();

          // Verify the counter starts at 0.
          expect(find.text('0'), findsOneWidget);

          // Finds the floating action button to tap on.
          final Finder fab = find.byTooltip('Increment');

          // Emulate a tap on the floating action button.
          await tester.tap(fab);

          // Trigger a frame.
          await tester.pumpAndSettle();

          // Verify the counter increments by 1.
          expect(find.text('1'), findsOneWidget);
        });
  });
}