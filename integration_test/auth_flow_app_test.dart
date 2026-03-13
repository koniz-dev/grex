import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/main.dart' as app;
import 'package:integration_test/integration_test.dart';

/// Integration tests that run the real app and verify auth-related flows
/// do not crash and reach a stable UI (login or main app).
///
/// Run with: flutter test integration_test/auth_flow_app_test.dart
/// Or: flutter drive --driver=test_driver/integration_test.dart
///     --target=integration_test/auth_flow_app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth flow (real app)', () {
    testWidgets('app starts and reaches stable auth UI (login or home)', (
      tester,
    ) async {
      app.main();
      // Allow main() to complete (async init) before pumping
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // App should show either login flow or main app (groups); no crash
      expect(find.byType(MaterialApp), findsOneWidget);
      // At least one Scaffold (login page or main app has scaffold)
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
