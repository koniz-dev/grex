import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';

import 'package:grex/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';
import 'package:grex/features/auth/presentation/bloc/auth_state.dart';
import 'package:grex/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:grex/features/auth/presentation/widgets/widgets.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:grex/shared/utils/locale_defaults.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAuthEvent());
  });

  group('ProfileSetupPage', () {
    late MockAuthBloc mockAuthBloc;
    late User testUser;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        createdAt: DateTime(2023),
      );
      // Force Vietnamese app locale so LocaleDefaults picks VND/vi for the
      // dropdown defaults. The MaterialApp itself stays on `en` for the
      // hard-coded English UI strings ("Continue", "Cancel Profile Setup",
      // etc.) — these defaults flow through LocaleDefaults, not the widget
      // tree locale.
      LocaleDefaults.appLocale = const Locale('vi');
    });

    tearDown(LocaleDefaults.resetAppLocale);

    Widget createWidget({
      String? prefilledDisplayName,
    }) {
      return MaterialApp(
        // Force English — these tests assert English strings.
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // Stub `/login` + `/home` so the page's pushReplacementNamed
        // navigations (cancellation, post-auth) don't throw
        // "Could not find a generator for route".
        routes: {
          '/login': (context) => const Scaffold(body: Text('Login Screen')),
          '/home': (context) => const Scaffold(body: Text('Home Screen')),
        },
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: ProfileSetupPage(
            user: testUser,
            provider: SocialAuthProvider.google,
            prefilledDisplayName: prefilledDisplayName,
            email: 'test@example.com',
          ),
        ),
      );
    }

    testWidgets('should display form with pre-filled OAuth data', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(
        createWidget(
          prefilledDisplayName: 'John Doe',
        ),
      );

      // Should display title
      expect(find.text('Complete Your Profile'), findsAtLeastNWidgets(1));

      // Should display description (l10n profileSetupDescription)
      expect(
        find.text('Please complete your profile to get started with Grex'),
        findsOneWidget,
      );

      // Should have pre-filled display name
      final displayNameField = find.byType(AuthTextField).first;
      final displayNameWidget = tester.widget<AuthTextField>(displayNameField);
      expect(displayNameWidget.controller?.text, equals('John Doe'));

      // Should have pre-filled email
      expect(find.text('test@example.com'), findsOneWidget);

      // Should have continue button
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('should display email in hero header', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidget());

      // Email should be displayed
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should validate display name', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidget());

      // Clear display name field
      final displayNameField = find.byType(AuthTextField).first;
      await tester.enterText(displayNameField, '');

      // Try to submit form
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Button should be disabled
      final continueButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(continueButton.onPressed, isNull);
    });

    testWidgets('should validate display name minimum length', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidget());

      // Enter short display name
      final displayNameField = find.byType(AuthTextField).first;
      await tester.enterText(displayNameField, 'A');

      // Try to submit form
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Button should be disabled
      final continueButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(continueButton.onPressed, isNull);
    });

    testWidgets('should validate display name maximum length', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidget());

      // Enter long display name
      final displayNameField = find.byType(AuthTextField).first;
      await tester.enterText(displayNameField, 'A' * 51);

      // Try to submit form
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Button should be disabled
      final continueButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(continueButton.onPressed, isNull);
    });

    testWidgets(
      'should trigger profile setup event when continue button is pressed',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

        await tester.pumpWidget(
          createWidget(
            prefilledDisplayName: 'John Doe',
          ),
        );

        // Fill form and submit
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pump();

        // Should trigger AuthProfileSetupCompleted event
        verify(
          () => mockAuthBloc.add(any(that: isA<AuthProfileSetupCompleted>())),
        ).called(1);
      },
    );

    testWidgets(
      'should trigger cancel event and navigate when use different account is pressed',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        await tester.pumpWidget(createWidget());

        // Tap use different account button
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Use a different account'));
        await tester.pump();

        // Should trigger AuthProfileSetupCancelled event
        verify(
          () => mockAuthBloc.add(any(that: isA<AuthProfileSetupCancelled>())),
        ).called(1);
      },
    );

    testWidgets('should show loading state when AuthLoading is emitted', (
      tester,
    ) async {
      // Stream AuthInitial → AuthLoading so BlocListener sees the
      // transition and flips _isLoading.
      whenListen(
        mockAuthBloc,
        Stream<AuthState>.value(const AuthLoading()),
        initialState: const AuthInitial(),
      );

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // Continue button should show loading indicator
      final continueButton = find.byType(ElevatedButton);
      expect(continueButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull); // Should be disabled

      // Should show loading indicator in button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when AuthError is emitted', (
      tester,
    ) async {
      const errorMessage = 'Profile setup failed';
      whenListen(
        mockAuthBloc,
        Stream<AuthState>.value(const AuthError(message: errorMessage)),
        initialState: const AuthInitial(),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Should show error in snackbar
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should navigate to home when AuthAuthenticated is emitted', (
      tester,
    ) async {
      final mockUser = testUser;
      final mockProfile = UserProfile(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        preferredCurrency: 'VND',
        languageCode: 'vi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      whenListen(
        mockAuthBloc,
        Stream<AuthState>.value(
          AuthAuthenticated(user: mockUser, profile: mockProfile),
        ),
        initialState: const AuthInitial(),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: ProfileSetupPage(
              user: testUser,
              provider: SocialAuthProvider.google,
              email: 'test@example.com',
            ),
          ),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home Screen')),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Should navigate to home screen
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('should disable form fields when loading', (tester) async {
      // BlocListener fires on state CHANGES, not the initial state, so we
      // need to transition AuthInitial → AuthLoading for `_isLoading` to
      // become true.
      whenListen(
        mockAuthBloc,
        Stream<AuthState>.value(const AuthLoading()),
        initialState: const AuthInitial(),
      );

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // All form fields should be disabled
      final textFields = find.byType(AuthTextField);
      for (var i = 0; i < tester.widgetList(textFields).length; i++) {
        final textField = tester
            .widgetList<AuthTextField>(textFields)
            .elementAt(i);
        expect(textField.enabled, isFalse);
      }

      // Checkbox should be disabled
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.onChanged, isNull);
    });
  });
}
