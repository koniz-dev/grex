import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dev-only floating logout button.
///
/// Wraps the app body so a small red FAB sits in the bottom-right corner
/// on every route. Tapping it calls `signOut()` directly on the Supabase
/// client — the auth state stream then propagates through
/// `authNotifierProvider` and GoRouter's redirect kicks the user back to
/// `/login`. Disabled in release builds via [kDebugMode] so it never
/// ships to the stores.
///
/// Positioned slightly above the bottom edge so it stacks above (rather
/// than collides with) a page's own FAB when both are present.
class DevLogoutOverlay extends StatelessWidget {
  /// Creates a [DevLogoutOverlay] wrapping [child].
  const DevLogoutOverlay({required this.child, super.key});

  /// The app's normal widget tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    // Plain Material+InkWell instead of FloatingActionButton because the
    // overlay sits ABOVE the Navigator in the widget tree, so there's no
    // ancestor `Overlay` for FAB's Tooltip/Hero machinery to attach to.
    return Stack(
      children: [
        child,
        Positioned(
          right: 16,
          bottom: 96,
          child: SafeArea(
            child: Material(
              color: Colors.red.shade700,
              shape: const CircleBorder(),
              elevation: 6,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
