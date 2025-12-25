import 'package:flutter_test/flutter_test.dart';
import 'package:grex/main.dart' as app;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('app starts successfully', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app starts without crashing
      expect(find.byType(app.MyApp), findsOneWidget);
    });
  });
}
