import 'package:flutter/material.dart';
import 'package:grex/shared/theme/app_durations.dart';
import 'package:grex/shared/theme/app_radius.dart';

/// A lightweight shimmer placeholder primitive.
///
/// Renders a single skeletal block with a moving gradient highlight. Compose
/// multiple [ShimmerBox]es inside a skeleton widget to mirror the layout of
/// the content being loaded — this is what gives the perceived performance
/// boost over a [CircularProgressIndicator].
///
/// The implementation runs a single [AnimationController] per box; for very
/// dense skeletons consider wrapping in a single [Stack] that drives all
/// children from one ticker.
class ShimmerBox extends StatefulWidget {
  /// Creates a [ShimmerBox].
  const ShimmerBox({
    this.width,
    this.height = 16,
    this.borderRadius = AppRadius.brSm,
    this.shape = BoxShape.rectangle,
    super.key,
  }) : assert(
         shape == BoxShape.rectangle || borderRadius == null,
         'borderRadius is ignored when shape is circle',
       );

  /// Explicit width. When null the box expands to its parent constraint.
  final double? width;

  /// Box height (defaults to a body-line height of 16).
  final double height;

  /// Corner radius; ignored when [shape] is [BoxShape.circle].
  final BorderRadius? borderRadius;

  /// Box shape — use [BoxShape.circle] for avatar placeholders.
  final BoxShape shape;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.shimmer,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surfaceContainerHigh;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Map the controller's 0→1 value to a -1.5→1.5 gradient sweep so
          // the highlight enters from off-screen left and exits off-screen
          // right, leaving a brief "rest" between cycles.
          final t = _controller.value * 3 - 1.5;
          return DecoratedBox(
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.rectangle
                  ? widget.borderRadius
                  : null,
              gradient: LinearGradient(
                begin: Alignment(t - 1, 0),
                end: Alignment(t + 1, 0),
                colors: [base, highlight, base],
                stops: const [0.35, 0.5, 0.65],
              ),
            ),
          );
        },
      ),
    );
  }
}
