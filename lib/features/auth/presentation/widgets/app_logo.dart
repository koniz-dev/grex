import 'package:flutter/material.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_fonts.dart';

/// App logo widget with branding
///
/// Displays the Grex logo, app name, and tagline according to design specs.
class AppLogo extends StatelessWidget {
  /// Creates an [AppLogo].
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Wallet icon (48px)
        Icon(
          Icons.account_balance_wallet,
          size: 48,
          color: colorScheme.onSurface,
        ),
        const SizedBox(height: 8),
        // App name (Outfit, 32px, 800 weight)
        Text(
          'Grex',
          style: TextStyle(
            fontFamily: AppFonts.heading,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        // Tagline (Inter, 14px, normal)
        Text(
          context.l10n.appTagline,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
