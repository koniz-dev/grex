import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/features/auth/data/handlers/auth_deep_link_handler.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/entities/profile_setup_data.dart';
import 'package:grex/features/auth/domain/repositories/repositories.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/domain/services/social_login_analytics.dart';
import 'package:grex/features/auth/domain/validators/validators.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';
import 'package:grex/features/auth/presentation/bloc/auth_state.dart';
import 'package:grex/shared/utils/locale_defaults.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// BLoC for managing authentication state and operations.
///
/// This BLoC handles all authentication-related events including
/// login, registration, logout, session management, password reset,
/// and social login with OAuth providers.
/// It coordinates between the UI and the authentication repositories.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Creates an AuthBloc with the required repositories and session manager.
  ///
  /// The [authRepository] handles authentication operations.
  /// The [userRepository] handles user profile operations.
  /// The [sessionManager] handles session persistence and automatic refresh.
  /// The [socialAuthRepository] handles social login operations.
  /// The [deepLinkHandler] handles OAuth callback deep links.
  /// The [analytics] handles social login analytics tracking.
  AuthBloc({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    required SessionManager sessionManager,
    required SocialAuthRepository socialAuthRepository,
    required AuthDeepLinkHandler deepLinkHandler,
    required SocialLoginAnalytics analytics,
  }) : _authRepository = authRepository,
       _userRepository = userRepository,
       _sessionManager = sessionManager,
       _socialAuthRepository = socialAuthRepository,
       _deepLinkHandler = deepLinkHandler,
       _analytics = analytics,
       super(const AuthInitial()) {
    // Register event handlers
    on<AuthSessionInitialized>(_onSessionInitialized);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionChecked>(_onSessionChecked);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthPasswordUpdateRequested>(_onPasswordUpdateRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthVerificationEmailRequested>(_onVerificationEmailRequested);
    on<AuthEmailVerificationRequested>(_onEmailVerificationRequested);
    on<AuthOtpVerificationRequested>(_onOtpVerificationRequested);

    // Register social login event handlers
    on<AuthSocialLoginRequested>(_onSocialLoginRequested);
    on<AuthProfileSetupCompleted>(_onProfileSetupCompleted);
    on<AuthProfileSetupCancelled>(_onProfileSetupCancelled);
    on<AuthAccountLinkingConfirmed>(_onAccountLinkingConfirmed);
    on<AuthAccountLinkingDeclined>(_onAccountLinkingDeclined);

    // Listen to authentication state changes
    _listenToAuthStateChanges();

    // Initialize deep link handler
    unawaited(_deepLinkHandler.initialize());
  }
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final SessionManager _sessionManager;
  final SocialAuthRepository _socialAuthRepository;
  final AuthDeepLinkHandler _deepLinkHandler;
  final SocialLoginAnalytics _analytics;

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

    await result.fold(
      (AuthFailure failure) async => emit(
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

    // Attempt registration with metadata for database trigger
    final result = await _authRepository.signUpWithEmail(
      email: event.email.trim(),
      password: event.password,
      displayName: event.displayName.trim(),
      preferredCurrency: event.preferredCurrency ?? LocaleDefaults.currencyCode,
      languageCode: event.languageCode ?? LocaleDefaults.languageCode,
    );

    await result.fold(
      (AuthFailure failure) async => emit(
        AuthError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (user) async {
        // Align with login flow: get session, load profile,
        // start session, then emit
        final session = _authRepository.currentSession;
        if (session == null) {
          emit(
            const AuthError(
              message:
                  'Registration succeeded but no session. '
                  'Please try signing in.',
            ),
          );
          return;
        }

        // Load profile (trigger creates it; retry once if not ready yet)
        var profileResult = await _userRepository.getUserProfile(user.id);
        if (profileResult.isLeft()) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          profileResult = await _userRepository.getUserProfile(user.id);
        }

        await profileResult.fold(
          (failure) async {
            // Emit state without profile so flow does not hang
            if (user.emailConfirmed) {
              emit(AuthAuthenticated(user: user));
            } else {
              emit(
                AuthEmailVerificationRequired(
                  user: user,
                  email: user.email,
                ),
              );
            }
          },
          (profile) async {
            final supabaseSession = session as supabase.Session;
            await _sessionManager.startSession(
              accessToken: supabaseSession.accessToken,
              refreshToken: supabaseSession.refreshToken ?? '',
              user: user,
              userProfile: profile,
            );

            if (user.emailConfirmed) {
              emit(AuthAuthenticated(user: user, profile: profile));
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

  /// Handles password update requests.
  ///
  /// Updates the user's password using a reset token or current session.
  Future<void> _onPasswordUpdateRequested(
    AuthPasswordUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.updatePassword(
      newPassword: event.newPassword,
      token: event.token,
    );

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (_) => emit(const AuthPasswordUpdated()),
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

  /// Handles OTP verification requests.
  ///
  /// Verifies the user's email using the OTP code from email.
  Future<void> _onOtpVerificationRequested(
    AuthOtpVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Validate email
    final emailError = InputValidators.validateEmail(event.email);
    if (emailError != null) {
      emit(AuthError(message: emailError));
      return;
    }

    // Validate OTP format (6 digits)
    if (event.token.length != 6 || int.tryParse(event.token) == null) {
      emit(const AuthError(message: 'OTP code must be 6 digits'));
      return;
    }

    final result = await _authRepository.verifyEmail(
      token: event.token,
      email: event.email.trim(),
    );

    await result.fold(
      (AuthFailure failure) async => emit(
        AuthError(
          message: _getOtpErrorMessage(failure),
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

          await profileResult.fold(
            (failure) async {
              emit(AuthEmailVerified(user: currentUser));
            },
            (profile) async {
              // Start session management after successful verification
              final session = _authRepository.currentSession;
              if (session != null) {
                final supabaseSession = session as supabase.Session;
                await _sessionManager.startSession(
                  accessToken: supabaseSession.accessToken,
                  refreshToken: supabaseSession.refreshToken ?? '',
                  user: currentUser,
                  userProfile: profile,
                );
              }

              emit(AuthAuthenticated(user: currentUser, profile: profile));
            },
          );
        } else {
          emit(
            const AuthError(
              message: 'Verification succeeded but user not found',
            ),
          );
        }
      },
    );
  }

  /// Maps OTP verification failures to user-friendly error messages.
  String _getOtpErrorMessage(AuthFailure failure) {
    final message = failure.message.toLowerCase();
    if (message.contains('expired') || message.contains('otp_expired')) {
      return 'OTP code has expired. Please request a new one.';
    }
    if (message.contains('invalid') || message.contains('token')) {
      return 'Invalid OTP code. Please check and try again.';
    }
    return failure.message;
  }

  /// Listens to authentication state changes from the repository.
  ///
  /// This ensures the BLoC stays in sync with the underlying
  /// authentication state (e.g., session expiration, external changes).
  ///
  /// Wrapped in try/catch so a misbehaving repository (e.g., a mock without
  /// a stub for `authStateChanges` in tests) doesn't fail bloc construction.
  /// In production this never throws — Supabase always exposes the stream.
  void _listenToAuthStateChanges() {
    try {
      _authStateSubscription = _authRepository.authStateChanges.listen(
        (user) => add(AuthStateChanged(user: user)),
      );
    } on Object catch (_) {
      // Repository didn't provide a stream — skip subscription. Either the
      // repository was constructed without one (test fixture) or it isn't
      // initialized yet; callers depending on stream-driven updates should
      // stub `authStateChanges` explicitly.
    }
  }

  /// Maps authentication failures to user-friendly error messages.
  String _getErrorMessage(AuthFailure failure) {
    if (failure is InvalidCredentialsFailure) {
      return 'Invalid email or password. Please try again.';
    } else if (failure is EmailAlreadyInUseFailure) {
      return 'This email is already registered. Please use a different '
          'email or try logging in.';
    } else if (failure is WeakPasswordFailure) {
      return 'Password is too weak. Please choose a stronger password.';
    } else if (failure is UnverifiedEmailFailure) {
      return 'Please verify your email address before signing in.';
    } else if (failure is NetworkFailure ||
        failure is SocialAuthNetworkFailure) {
      return 'Network error. Please check your connection and try again.';
    } else if (failure is SocialAuthTimeoutFailure) {
      return 'Connection timed out. Please check your network and try again.';
    } else if (failure is TooManyAttemptsFailure) {
      return 'Too many attempts. Please try again later.';
    } else if (failure is SessionExpiredFailure) {
      return 'Your session has expired. Please sign in again.';
    } else {
      return failure.message;
    }
  }

  /// Handles social login requests.
  ///
  /// Validates provider, initiates OAuth flow, and handles the result
  /// including profile existence checking and account linking detection.
  Future<void> _onSocialLoginRequested(
    AuthSocialLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Parse provider from string
    final provider = SocialAuthProvider.fromString(event.provider);
    if (provider == null) {
      emit(const AuthError(message: 'Invalid social login provider'));
      return;
    }

    // Log analytics event for social login initiation
    _analytics.logSocialLoginInitiated(provider);

    emit(AuthSocialLoginInProgress(provider));

    // Attempt social login based on provider
    final result = provider == SocialAuthProvider.google
        ? await _socialAuthRepository.signInWithGoogle()
        : await _socialAuthRepository.signInWithApple();

    await result.fold(
      (AuthFailure failure) async {
        // Log analytics event for social login failure
        _analytics.logSocialLoginFailure(
          provider: provider,
          errorType: _getAnalyticsErrorType(failure),
        );

        // Check if it's a cancellation (don't show error for cancellation)
        if (failure is SocialAuthCancelledFailure) {
          _analytics.logSocialLoginCancelled(provider);
          emit(const AuthUnauthenticated());
        } else {
          emit(
            AuthError(
              message: _getErrorMessage(failure),
              failure: failure,
            ),
          );
        }
      },
      (user) async => _handleSocialLoginSuccess(user, provider, emit),
    );
  }

  /// Handles successful social login by checking profile existence
  /// and determining the appropriate next step.
  Future<void> _handleSocialLoginSuccess(
    User user,
    SocialAuthProvider provider,
    Emitter<AuthState> emit,
  ) async {
    // Check if user profile exists
    final profileResult = await _userRepository.getUserProfile(user.id);

    await profileResult.fold(
      (failure) async {
        // Profile doesn't exist - check if email already exists for linking
        final emailCheckResult = await _userRepository.getUserProfileByEmail(
          user.email,
        );

        await emailCheckResult.fold(
          (failure) async {
            // No existing profile with this email - new user needs setup
            _analytics.logSocialLoginSuccess(
              provider: provider,
              userType: 'new',
            );

            emit(
              AuthProfileSetupRequired(
                user: user,
                provider: provider,
                displayName: user.oauthDisplayName,
                email: user.email,
              ),
            );
          },
          (existingProfile) async {
            if (existingProfile != null) {
              // Email already exists - prompt for account linking
              _analytics.logSocialLoginSuccess(
                provider: provider,
                userType: 'linking_required',
              );

              emit(
                AuthAccountLinkingRequired(
                  newUser: user,
                  existingProfile: existingProfile,
                  provider: provider,
                ),
              );
            } else {
              // No existing profile - new user needs profile setup
              _analytics.logSocialLoginSuccess(
                provider: provider,
                userType: 'new',
              );

              emit(
                AuthProfileSetupRequired(
                  user: user,
                  provider: provider,
                  displayName: user.oauthDisplayName,
                  email: user.email,
                ),
              );
            }
          },
        );
      },
      (profile) async {
        // Profile exists - user has logged in before, start session
        _analytics.logSocialLoginSuccess(
          provider: provider,
          userType: 'existing',
        );

        final session = _authRepository.currentSession;
        if (session != null) {
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
  }

  /// Handles profile setup completion for new social users.
  ///
  /// Creates user profile with provided data and establishes session.
  Future<void> _onProfileSetupCompleted(
    AuthProfileSetupCompleted event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      emit(const AuthError(message: 'No authenticated user found'));
      return;
    }

    emit(const AuthLoading());

    // Create profile setup data
    final profileData = ProfileSetupData(
      displayName: event.displayName.trim(),
      preferredCurrency: event.preferredCurrency,
      languageCode: event.languageCode,
      socialProvider: currentUser.socialProvider,
    );

    // Create user profile
    final result = await _socialAuthRepository.createUserProfile(
      currentUser.id,
      profileData,
    );

    await result.fold(
      (AuthFailure failure) async => emit(
        AuthError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (_) async {
        // Log analytics event for profile setup completion
        if (currentUser.socialProvider != null) {
          _analytics.logProfileSetupCompleted(
            provider: currentUser.socialProvider!,
            displayName: event.displayName.trim(),
            currency: event.preferredCurrency,
            language: event.languageCode,
          );
        }

        // Load the created profile
        final profileResult = await _userRepository.getUserProfile(
          currentUser.id,
        );

        await profileResult.fold(
          (UserFailure failure) async =>
              emit(AuthAuthenticated(user: currentUser)),
          (profile) async {
            // Start session management
            final session = _authRepository.currentSession;
            if (session != null) {
              final supabaseSession = session as supabase.Session;
              await _sessionManager.startSession(
                accessToken: supabaseSession.accessToken,
                refreshToken: supabaseSession.refreshToken ?? '',
                user: currentUser,
                userProfile: profile,
              );
            }

            emit(AuthAuthenticated(user: currentUser, profile: profile));
          },
        );
      },
    );
  }

  /// Handles profile setup cancellation.
  ///
  /// Signs out the user and returns to login screen since profile
  /// completion is required for new social users.
  Future<void> _onProfileSetupCancelled(
    AuthProfileSetupCancelled event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // End session management and sign out
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

  /// Handles account linking confirmation.
  ///
  /// Links the social provider to the existing user account.
  Future<void> _onAccountLinkingConfirmed(
    AuthAccountLinkingConfirmed event,
    Emitter<AuthState> emit,
  ) async {
    final linkingState = state as AuthAccountLinkingRequired;

    emit(const AuthLoading());

    // Log analytics event for account linking confirmation
    _analytics.logAccountLinking(
      provider: linkingState.provider,
      action: 'confirmed',
      existingEmail: linkingState.existingProfile.email,
    );

    // Link the social provider to existing account
    final result = await _socialAuthRepository.linkSocialProvider(
      userId: event.existingUserId,
      provider: linkingState.provider,
    );

    await result.fold(
      (AuthFailure failure) async => emit(
        AuthError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (_) async {
        // Load existing profile and establish session
        final profileResult = await _userRepository.getUserProfile(
          event.existingUserId,
        );

        await profileResult.fold(
          (UserFailure failure) async {
            final currentUser = _authRepository.currentUser;
            if (currentUser != null) {
              emit(AuthAuthenticated(user: currentUser));
            } else {
              emit(const AuthError(message: 'User not found after linking'));
            }
          },
          (profile) async {
            final currentUser = _authRepository.currentUser;
            if (currentUser != null) {
              // Start session management
              final session = _authRepository.currentSession;
              if (session != null) {
                final supabaseSession = session as supabase.Session;
                await _sessionManager.startSession(
                  accessToken: supabaseSession.accessToken,
                  refreshToken: supabaseSession.refreshToken ?? '',
                  user: currentUser,
                  userProfile: profile,
                );
              }

              emit(AuthAuthenticated(user: currentUser, profile: profile));
            } else {
              emit(const AuthError(message: 'User not found after linking'));
            }
          },
        );
      },
    );
  }

  /// Handles account linking decline.
  ///
  /// Treats the social login as a new account and initiates profile setup.
  Future<void> _onAccountLinkingDeclined(
    AuthAccountLinkingDeclined event,
    Emitter<AuthState> emit,
  ) async {
    final linkingState = state as AuthAccountLinkingRequired;

    // Log analytics event for account linking decline
    _analytics.logAccountLinking(
      provider: linkingState.provider,
      action: 'declined',
      existingEmail: linkingState.existingProfile.email,
    );

    // Treat as new account - go to profile setup
    emit(
      AuthProfileSetupRequired(
        user: linkingState.newUser,
        provider: linkingState.provider,
        displayName: linkingState.newUser.oauthDisplayName,
        email: linkingState.newUser.email,
      ),
    );
  }

  /// Maps authentication failures to analytics error types.
  String _getAnalyticsErrorType(AuthFailure failure) {
    if (failure is SocialAuthCancelledFailure) {
      return 'cancelled';
    } else if (failure is SocialAuthNetworkFailure) {
      return 'network';
    } else if (failure is SocialAuthTimeoutFailure) {
      return 'timeout';
    } else if (failure is AccountLinkingFailure) {
      return 'linking';
    } else if (failure is NetworkFailure) {
      return 'network';
    } else {
      return 'unknown';
    }
  }

  @override
  Future<void> close() async {
    await _authStateSubscription?.cancel();
    _deepLinkHandler.dispose();
    return super.close();
  }
}
