import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// How things move in Stash. Motion is feedback: it shows where something
/// came from, confirms a tap, or keeps a change from being jarring. Nothing
/// bounces, and with the system's reduce motion setting on, things only
/// fade.
class Motion {
  /// Entrances and anything under 600ms (quint out).
  static const Curve easeOut = Cubic(0.22, 1, 0.36, 1);

  /// Longer reveals and the cover flying into the player (expo out).
  static const Curve easeExpo = Cubic(0.16, 1, 0.3, 1);

  /// Things that travel while they stay in view (quart in-out).
  static const Curve easeInOut = Cubic(0.76, 0, 0.24, 1);

  static const press = Duration(milliseconds: 140);
  static const hover = Duration(milliseconds: 180);
  static const ui = Duration(milliseconds: 240);
  static const page = Duration(milliseconds: 380);
  static const reveal = Duration(milliseconds: 520);

  /// Leaving takes about 70% of arriving.
  static Duration exit(Duration enter) => enter * 0.7;

  /// Between list items as they arrive; only the first few are staggered.
  static const stagger = Duration(milliseconds: 60);
  static const maxStaggerSteps = 4;

  /// The playing song's cover, which flies from the mini player into the
  /// player page.
  static const coverHeroTag = 'now-playing-cover';

  /// Whether the system asks for less motion: fades stay, travel and scale
  /// go.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Pages rise into place while they fade in. Under reduced motion they only
/// fade.
class StashPageTransitionsBuilder extends PageTransitionsBuilder {
  const StashPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Motion.page;

  @override
  Duration get reverseTransitionDuration => Motion.exit(Motion.page);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.easeOut,
      reverseCurve: Motion.easeOut.flipped,
    );
    final fade = FadeTransition(opacity: curved, child: child);
    if (Motion.reduced(context)) return fade;
    return SlideTransition(
      position:
          Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
      child: fade,
    );
  }
}

/// Swaps [child] for a new one, keyed by [Widget.key], with the new one
/// rising [rise] pixels into place and the old one moving on the same way
/// as it fades. Set [scale] below 1 for the new one to grow in as well.
class MotionSwitcher extends StatelessWidget {
  final Widget child;
  final double rise;
  final double scale;
  final Duration duration;
  final AlignmentGeometry alignment;
  const MotionSwitcher({
    super.key,
    required this.child,
    this.rise = 8,
    this.scale = 1,
    this.duration = Motion.ui,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: Motion.exit(duration),
      switchInCurve: Motion.easeOut,
      switchOutCurve: Motion.easeOut,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) {
        final faded = FadeTransition(opacity: animation, child: child);
        if (reduced || (rise == 0 && scale == 1)) return faded;
        return AnimatedBuilder(
          animation: animation,
          child: faded,
          builder: (context, child) {
            final t = 1 - animation.value;
            // * The old one keeps going the way the new one came from
            final leaving = animation.status == AnimationStatus.reverse;
            return Transform.translate(
              offset: Offset(0, leaving ? -rise * t : rise * t),
              child: Transform.scale(
                scale: leaving ? 1 : 1 - (1 - scale) * t,
                child: child,
              ),
            );
          },
        );
      },
      child: child,
    );
  }
}

/// Shrinks [child] a little while a finger or the mouse is down on it, so a
/// tap is felt before its result shows. Under reduced motion it dims
/// instead. It only listens, so the child's own gestures work as before.
class Pressable extends StatefulWidget {
  final Widget child;
  final double scale;
  final bool enabled;
  const Pressable({
    super.key,
    required this.child,
    this.scale = 0.96,
    this.enabled = true,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  Offset? _down;

  void _set(bool pressed) {
    if (pressed != _pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final reduced = Motion.reduced(context);
    // * Quick to go down, a little slower to come back up
    final duration = _pressed ? Motion.press : Motion.ui;
    return Listener(
      onPointerDown: (e) {
        _down = e.position;
        _set(true);
      },
      // * A scroll is not a press
      onPointerMove: (e) {
        final down = _down;
        if (down != null && (e.position - down).distance > kTouchSlop) {
          _set(false);
        }
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: reduced
          ? AnimatedOpacity(
              opacity: _pressed ? 0.6 : 1,
              duration: duration,
              curve: Motion.easeOut,
              child: widget.child,
            )
          : AnimatedScale(
              scale: _pressed ? widget.scale : 1,
              duration: duration,
              curve: Motion.easeOut,
              child: widget.child,
            ),
    );
  }
}

/// Marks where a list starts, so its first rows arrive one after the other
/// when it opens, and rows scrolled into view later just appear.
class ArrivalScope extends StatefulWidget {
  final Widget child;
  const ArrivalScope({super.key, required this.child});

  /// How long after the list opens rows still arrive.
  static const window = Duration(milliseconds: 500);

  @override
  State<ArrivalScope> createState() => _ArrivalScopeState();
}

class _ArrivalScopeState extends State<ArrivalScope> {
  final _opened = Stopwatch()..start();

  @override
  Widget build(BuildContext context) =>
      _Arrival(opened: _opened, child: widget.child);
}

class _Arrival extends InheritedWidget {
  final Stopwatch opened;
  const _Arrival({required this.opened, required super.child});

  @override
  bool updateShouldNotify(_Arrival oldWidget) => false;
}

/// [child] fading and rising into place, [index] steps after the first row
/// of its [ArrivalScope]. Without a scope, or once the list has been open a
/// moment, it is simply there.
class Arrive extends StatefulWidget {
  final int index;
  final Widget child;
  const Arrive({super.key, required this.index, required this.child});

  /// [children] arriving one after the other; the gaps between them don't
  /// count as a step.
  static List<Widget> all(List<Widget> children) {
    var step = 0;
    return [
      for (final child in children)
        child is SizedBox ? child : Arrive(index: step++, child: child),
    ];
  }

  @override
  State<Arrive> createState() => _ArriveState();
}

class _ArriveState extends State<Arrive> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _curve;
  late bool _reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = Motion.reduced(context);
    if (_controller != null) return;
    final scope = context.getInheritedWidgetOfExactType<_Arrival>();
    if (scope == null || scope.opened.elapsed > ArrivalScope.window) return;
    // * The delay is part of the animation, so no timer is left behind
    final step = widget.index.clamp(0, Motion.maxStaggerSteps - 1);
    final delay = _reduced ? Duration.zero : Motion.stagger * step;
    final total = delay + Motion.reveal;
    final controller = AnimationController(vsync: this, duration: total);
    _controller = controller;
    _curve = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Motion.easeOut,
      ),
    );
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = _curve;
    if (curve == null) return widget.child;
    final faded = FadeTransition(opacity: curve, child: widget.child);
    if (_reduced) return faded;
    return AnimatedBuilder(
      animation: curve,
      child: faded,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 16 * (1 - curve.value)),
        child: child,
      ),
    );
  }
}
