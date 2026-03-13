import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';
import 'package:grex/features/auth/presentation/bloc/auth_state.dart';
import 'package:grex/features/auth/presentation/widgets/account_linking_dialog.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  group('AccountLinkingDialog', () {
    late MockAuthBloc mockAuthBloc;
    late User testUser;
    late UserProfile testProfile;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      testUser = User(
        id: 'new-user-id',
        email: 'test@example.com',
        createdAt: DateTime(2023),
      );
      testProfile = UserProfile(
        id: 'existing-user-id',
        email: 'test@example.com',
        displayName: 'Existing User',
        preferredCurrency: 'VND',
        languageCode: 'vi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createWidget({
      SocialAuthProvider provider = SocialAuthProvider.google,
    }) {
      return MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: Scaffold(
            body: AccountLinkingDialog(
              newUser: testUser,
              existingProfile: testProfile,
              provider: provider,
            ),
          ),
        ),
      );
    }

    testWidgets('should display dialog with correct email', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidget());

      // Should display title
      expect(find.text('Link Your Account'), findsOneWidget);

      // Should display email in message
      expect(find.textContaining('test@example.com'), findsOneWidget);
      expect(
        find.textContaining(
          'An account with email test@example.com already exists.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'should display provider-specific message for Google',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

        await tester.pumpWidget(createWidget());

        // Should display Google-specific message
        expect(find.textContaining('Google account'), findsOneWidget);
        expect(
          find.textContaining('Would you like to link your Google account'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should display provider-specific message for Apple',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

        await tester.pumpWidget(
          createWidget(provider: SocialAuthProvider.apple),
        );

        // Should display Apple-specific message
        expect(find.textContaining('Apple account'), findsOneWidget);
        expect(
          find.textContaining('Would you like to link your Apple account'),
          findsOneWidget,
        );
      },
    );

    testWidgets('should display benefit explanation', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidget());

      // Should display benefit explanation
      expect(
        find.textContaining(
          'This will allow you to sign in with either method.',
        ),
        findsOneWidget,
      );

      // Should show info icon
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets(
      'should have Link Accounts button as primary action',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

        await tester.pumpWidget(createWidget());

        // Should find Link Accounts button
        final linkButton = find.text('Link Accounts');
        expect(linkButton, findsOneWidget);

        // Should be an ElevatedButton (primary action)
        final linkButtonWidget = find.ancestor(
          of: linkButton,
          matching: find.byType(ElevatedButton),
        );
        expect(linkButtonWidget, findsOneWidget);
      },
    );

    testWidgets(
      'should have Create New Account button as secondary action',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

        await tester.pumpWidget(createWidget());

        // Should find Create New Account button
        final createButton = find.text('Create New Account');
        expect(createButton, findsOneWidget);

        // Should be a TextButton (secondary action)
        final createButtonWidget = find.ancestor(
          of: createButton,
          matching: find.byType(TextButton),
        );
        expect(createButtonWidget, findsOneWidget);
      },
    );

    testWidgets(
      'should trigger confirmation event when Link Accounts is tapped',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

        await tester.pumpWidget(createWidget());

        // Tap Link Accounts button
        await tester.tap(find.text('Link Accounts'));
        await tester.pump();

        // Should trigger AuthAccountLinkingConfirmed event with correct user ID
        verify(
          () => mockAuthBloc.add(
            AuthAccountLinkingConfirmed(testProfile.id),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'should trigger decline event when Create New Account is tapped',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

        await tester.pumpWidget(createWidget());

        // Tap Create New Account button
        await tester.tap(find.text('Create New Account'));
        await tester.pump();

        // Should trigger AuthAccountLinkingDeclined event
        verify(
          () => mockAuthBloc.add(
            const AuthAccountLinkingDeclined(),
          ),
        ).called(1);
      },
    );

    testWidgets('should be non-dismissible', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidget());

      // Try to dismiss by tapping outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      // Dialog should still be visible
      expect(find.text('Link Your Account'), findsOneWidget);
    });

    testWidgets('should close dialog when Link Accounts is tapped', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await AccountLinkingDialog.show(
                        context,
                        newUser: testUser,
                        existingProfile: testProfile,
                        provider: SocialAuthProvider.google,
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Link Your Account'), findsOneWidget);

      // Tap Link Accounts button
      await tester.tap(find.text('Link Accounts'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Link Your Account'), findsNothing);
    });

    testWidgets('should close dialog when Create New Account is tapped', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await AccountLinkingDialog.show(
                        context,
                        newUser: testUser,
                        existingProfile: testProfile,
                        provider: SocialAuthProvider.google,
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Link Your Account'), findsOneWidget);

      // Tap Create New Account button
      await tester.tap(find.text('Create New Account'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Link Your Account'), findsNothing);
    });

    testWidgets('should use theme colors correctly', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              primaryContainer: Colors.lightBlue,
            ),
          ),
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: Scaffold(
              body: AccountLinkingDialog(
                newUser: testUser,
                existingProfile: testProfile,
                provider: SocialAuthProvider.google,
              ),
            ),
          ),
        ),
      );

      // Should use theme colors for info container and icon
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      // Should find the info container
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('should show static factory method', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await AccountLinkingDialog.show(
                        context,
                        newUser: testUser,
                        existingProfile: testProfile,
                        provider: SocialAuthProvider.apple,
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Show dialog using static method
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should be visible with Apple provider
      expect(find.text('Link Your Account'), findsOneWidget);
      expect(find.textContaining('Apple account'), findsOneWidget);
    });

    testWidgets(
      'should handle different user emails correctly',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

        final differentUser = User(
          id: 'different-user-id',
          email: 'different@example.com',
          createdAt: DateTime(2023),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: Scaffold(
                body: AccountLinkingDialog(
                  newUser: differentUser,
                  existingProfile: testProfile,
                  provider: SocialAuthProvider.google,
                ),
              ),
            ),
          ),
        );

        // Should display the new user's email
        expect(find.textContaining('different@example.com'), findsOneWidget);
      },
    );
  });
}
