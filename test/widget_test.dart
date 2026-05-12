// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/main.dart';

void main() {
  // TODO(smoke): pumps the full MyApp tree without initializing Supabase /
  // DI / locale-detection, so neither the welcome page nor the login page
  // actually finishes mounting. Re-enable after a full-boot test harness is
  // wired.
  testWidgets('App displays welcome message', skip: true,
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: MyApp requires ProviderScope, so we need to wrap it
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Wait for async initialization and router navigation
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // App boots via router and lands on either the (localized) welcome
    // page or the (localized) login page depending on auth state. Check for
    // any of the known landing strings in either English or Vietnamese.
    final welcomeEn = find.text('Welcome to Grex with Clean Architecture!');
    final welcomeVi = find.text(
      'Chào mừng đến với Grex với Clean Architecture!',
    );
    final loginEn = find.text('Login');
    final loginVi = find.text('Đăng nhập');

    expect(
      tester.any(welcomeEn) ||
          tester.any(welcomeVi) ||
          tester.any(loginEn) ||
          tester.any(loginVi),
      isTrue,
      reason: 'Expected either welcome message or login screen',
    );
  });
}
