import 'package:flutter/material.dart';

/// App logo widget with branding
///
/// Displays the Grex logo, app name, and tagline according to design specs.
class AppLogo extends StatelessWidget {
  /// Creates an [AppLogo].
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        // Wallet icon (48px)
        Icon(
          Icons.account_balance_wallet,
          size: 48,
          color: Colors.black,
        ),
        SizedBox(height: 8),
        // App name (Outfit, 32px, 800 weight)
        Text(
          'Grex',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        // Tagline (Inter, 14px, normal)
        Text(
          'Split expenses with ease',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF71717A),
          ),
        ),
      ],
    );
  }
}
