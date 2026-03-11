import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/auth/domain/services/email_verification_service.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';

/// Listens to app links (e.g. cold start or while app is open) and dispatches
/// email verification events to [AuthBloc] when the link is a valid
/// verification link.
class AppLinkListener extends StatefulWidget {
  /// Creates an [AppLinkListener].
  const AppLinkListener({
    required this.child,
    super.key,
  });

  /// The widget tree below this listener.
  final Widget child;

  @override
  State<AppLinkListener> createState() => _AppLinkListenerState();
}

class _AppLinkListenerState extends State<AppLinkListener> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();

    // Handle initial link (e.g. app opened from email verification link)
    unawaited(_handleInitialLink());

    // Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(_processUri);
  }

  Future<void> _handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _processUri(uri);
      }
    } on Object {
      // Ignore errors (e.g. platform not supported)
    }
  }

  void _processUri(Uri uri) {
    final link = uri.toString();
    final emailVerificationService = getIt<EmailVerificationService>();
    emailVerificationService.processVerificationLink(link).fold(
      (_) {
        // Not a valid verification link or invalid data; ignore
      },
      (data) {
        getIt<AuthBloc>().add(
          AuthEmailVerificationRequested(
            token: data.token,
            email: data.email,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    unawaited(_linkSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
