import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/repositories.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/domain/validators/validators.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';
import 'package:grex/features/auth/presentation/bloc/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// BLoC for managing authentication state and operations.
///
/// This BLoC handles all authentication-related events including
/// login, registration, logout, session management, and password reset.
/// It coordinates between the UI and the authentication repositories.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Creates an AuthBloc with the required repositories and session manager.
  ///
  /// The [authRepository] handles authentication operations.
  /// The [userRepository] handles user profile operations.
  /// The [sessionManager] handles session persistence and automatic refresh.
  AuthBloc({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    required SessionManager sessionManager,
  }) : _authRepository = authRepository,
       _userRepository = userRepository,
       _sessionManager = sessionManager,
       super(const AuthInitial()) {
    // Register event handlers
    on<AuthSessionInitialized>(_onSessionInitialized);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionChecked>(_onSessionChecked);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthVerificationEmailRequested>(_onVerificationEmailRequested);
    on<AuthEmailVerificationRequested>(_onEmailVerificationRequested);

    // Listen to authentication state changes
    _listenToAuthStateChanges();
  }
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final SessionManager _sessionManager;

  StreamSubscription<User?>? _authStateSubscription;

  /// Handles session initialization.
  ///
  /// Attempts to restore session from storage and starts automatic
  /// session management if a valid session is found.
  Future<void> _onSessionInitialized(
    AuthSessionInitialized event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final sessionResult = await _sessionManager.initialize();

    sessionResult.fold(
      (failure) => emit(
        AuthError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (sessionData) {
        if (sessionData != null) {
          emit(
            AuthAuthenticated(
              user: sessionData.user,
              profile: sessionData.userProfile,
            ),
          );
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  /// Handles user login requests.
  ///
  /// Validates input, attempts authentication, and loads user profile
  /// if authentication is successful.
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // Validate input
    final emailError = InputValidators.validateEmail(event.email);
    final passwordError = InputValidators.validatePassword(event.password);

    if (emailError != null) {
      emit(AuthError(message: emailError));
      return;
    }

    if (passwordError != null) {
      emit(AuthError(message: passwordError));
      return;
    }

    // Attempt login
    final result = await _authRepository.signInWithEmail(
      email: event.email.trim(),
      password: event.password,
    );

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (user) async {
        // Load user profile
        final profileResult = await _userRepository.getUserProfile(user.id);

        await profileResult.fold(
          (failure) async {
            emit(AuthAuthenticated(user: user));
          },
          (profile) async {
            // Start session management with current Supabase session
            final session = _authRepository.currentSession;
            if (session != null) {
              // Cast dynamic session to Supabase Session type
              final supabaseSession = session as supabase.Session;
              await _sessionManager.startSession(
                accessToken: supabaseSession.accessToken,
                refreshToken: supabaseSession.refreshToken ?? '',
                user: user,
                userProfile: profile,
              );
            }

            emit(AuthAuthenticated(user: user, profile: profile));
          },
        );
      },
    );
  }

  /// Handles user registration requests.
  ///
  /// Validates input, creates user account, creates user profile,
  /// and handles email verification requirements.
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // Validate input
    final emailError = InputValidators.validateEmail(event.email);
    final passwordError = InputValidators.validatePassword(event.password);
    final displayNameError = InputValidators.validateDisplayName(
      event.displayName,
    );

    String? currencyError;
    if (event.preferredCurrency != null) {
      currencyError = InputValidators.validateCurrencyCode(
        event.preferredCurrency,
      );
    }

    String? languageError;
    if (event.languageCode != null) {
      languageError = InputValidators.validateLanguageCode(
        event.languageCode,
      );
    }

    if (emailError != null) {
      emit(AuthError(message: emailError));
      return;
    }

    if (passwordError != null) {
      emit(AuthError(message: passwordError));
      return;
    }

    if (displayNameError != null) {
      emit(AuthError(message: displayNameError));
      return;
    }

    if (currencyError != null) {
      emit(AuthError(message: currencyError));
      return;
    }

    if (languageError != null) {
      emit(AuthError(message: languageError));
      return;
    }

    // Attempt registration
    final result = await _authRepository.signUpWithEmail(
      email: event.email.trim(),
      password: event.password,
    );

    await result.fold(
      (failure) async => emit(
        AuthError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (user) async {
        // Create user profile
        final profile = UserProfile(
          id: user.id,
          email: user.email,
          displayName: event.displayName.trim(),
          preferredCurrency: event.preferredCurrency ?? 'VND',
          languageCode: event.languageCode ?? 'vi',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final profileResult = await _userRepository.createUserProfile(profile);

        profileResult.fold(
          (failure) => emit(
            AuthError(
              message:
                  'Account created but profile setup failed: '
                  '${_getErrorMessage(failure)}',
            ),
          ),
          (createdProfile) {
            if (user.emailConfirmed) {
              emit(AuthAuthenticated(user: user, profile: createdProfile));
            } else {
              emit(
                AuthEmailVerificationRequired(
                  user: user,
                  email: user.email,
                ),
              );
            }
          },
        );
      },
    );
  }

  /// Handles user logout requests.
  ///
  /// Signs out the user and clears all authentication state.
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // End session management first
    await _sessionManager.endSession();

    final result = await _authRepository.signOut();

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  /// Handles session check requests.
  ///
  /// Checks if there's an existing valid session and loads user data.
  Future<void> _onSessionChecked(
    AuthSessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final currentUser = _authRepository.currentUser;

    if (currentUser == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    // Load user profile
    final profileResult = await _userRepository.getUserProfile(currentUser.id);

    profileResult.fold(
      (failure) => emit(AuthAuthenticated(user: currentUser)),
      (profile) => emit(AuthAuthenticated(user: currentUser, profile: profile)),
    );
  }

  /// Handles password reset requests.
  ///
  /// Validates email and sends password reset email.
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // Validate email
    final emailError = InputValidators.validateEmail(event.email);
    if (emailError != null) {
      emit(AuthError(message: emailError));
      return;
    }

    final result = await _authRepository.resetPassword(
      email: event.email.trim(),
    );

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (_) => emit(AuthPasswordResetSent(email: event.email.trim())),
    );
  }

  /// Handles external authentication state changes.
  ///
  /// This is called when the authentication state changes outside
  /// of this BLoC (e.g., session expiration, external logout).
  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user == null) {
      emit(const AuthUnauthenticated());
    } else {
      final user = event.user as User;

      // Load user profile
      final profileResult = await _userRepository.getUserProfile(user.id);

      profileResult.fold(
        (failure) => emit(AuthAuthenticated(user: user)),
        (profile) => emit(AuthAuthenticated(user: user, profile: profile)),
      );
    }
  }

  /// Handles verification email requests.
  ///
  /// Sends a verification email to the current user's email address.
  Future<void> _onVerificationEmailRequested(
    AuthVerificationEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = _authRepository.currentUser;

    if (currentUser == null) {
      emit(const AuthError(message: 'No user is currently signed in'));
      return;
    }

    emit(const AuthLoading());

    final result = await _authRepository.sendVerificationEmail();

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (_) => emit(AuthVerificationEmailSent(email: currentUser.email)),
    );
  }

  /// Handles email verification requests.
  ///
  /// Verifies the user's email using the provided token and email.
  Future<void> _onEmailVerificationRequested(
    AuthEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // Validate email
    final emailError = InputValidators.validateEmail(event.email);
    if (emailError != null) {
      emit(AuthError(message: emailError));
      return;
    }

    final result = await _authRepository.verifyEmail(
      token: event.token,
      email: event.email.trim(),
    );

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (_) async {
        // Get the updated user after verification
        final currentUser = _authRepository.currentUser;

        if (currentUser != null) {
          // Load user profile
          final profileResult = await _userRepository.getUserProfile(
            currentUser.id,
          );

          profileResult.fold(
            (failure) => emit(AuthEmailVerified(user: currentUser)),
            (profile) {
              // Start session management after successful verification
              final session = _authRepository.currentSession;
              if (session != null) {
                // Cast dynamic session to Supabase Session type
                final supabaseSession = session as supabase.Session;
                unawaited(
                  _sessionManager.startSession(
                    accessToken: supabaseSession.accessToken,
                    refreshToken: supabaseSession.refreshToken ?? '',
                    user: currentUser,
                    userProfile: profile,
                  ),
                );
              }

              emit(AuthAuthenticated(user: currentUser, profile: profile));
            },
          );
        } else {
          emit(
            const AuthError(
              message: 'Verification successful but user not found',
            ),
          );
        }
      },
    );
  }

  /// Listens to authentication state changes from the repository.
  ///
  /// This ensures the BLoC stays in sync with the underlying
  /// authentication state (e.g., session expiration, external changes).
  void _listenToAuthStateChanges() {
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) => add(AuthStateChanged(user: user)),
    );
  }

  /// Maps authentication failures to user-friendly error messages.
  String _getErrorMessage(dynamic failure) {
    if (failure is AuthFailure) {
      if (failure is InvalidCredentialsFailure) {
        return 'Invalid email or password. Please try again.';
      } else if (failure is EmailAlreadyInUseFailure) {
        return 'This email is already registered. Please use a different '
            'email or try logging in.';
      } else if (failure is WeakPasswordFailure) {
        return 'Password is too weak. Please choose a stronger password.';
      } else if (failure is UnverifiedEmailFailure) {
        return 'Please verify your email address before signing in.';
      } else if (failure is NetworkFailure) {
        return 'Network error. Please check your connection and try again.';
      } else {
        return failure.message;
      }
    }

    if (failure is UserFailure) {
      if (failure is UserNotFoundFailure) {
        return 'User profile not found. Please contact support.';
      } else if (failure is ValidationFailure) {
        return 'Invalid user data. Please check your information.';
      } else if (failure is NetworkFailure) {
        return 'Network error. Please check your connection and try again.';
      } else {
        return failure.message;
      }
    }

    return failure.toString();
  }

  @override
  Future<void> close() async {
    await _authStateSubscription?.cancel();
    return super.close();
  }
}
