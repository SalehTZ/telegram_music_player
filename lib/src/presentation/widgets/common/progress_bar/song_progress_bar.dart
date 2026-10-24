import 'package:flutter/material.dart';

import '../../../../constants/colors_manager.dart';
import '../../../../constants/values_manager.dart';
import '../../../motion.dart';

class SongProgressBar extends StatefulWidget {
  /// Played fraction of the song, between 0 and 1.
  final double progress;

  /// Called with the tapped or dragged fraction. When null the bar is
  /// read only, like in the mini player.
  final ValueChanged<double>? onSeek;
  const SongProgressBar({
    super.key,
    required this.progress,
    this.onSeek,
  });

  @override
  State<SongProgressBar> createState() => _SongProgressBarState();
}

class _SongProgressBarState extends State<SongProgressBar> {
  /// A finger is on the bar: it thickens, so the seek is felt.
  bool _held = false;

  void _hold(bool held) {
    if (held != _held) setState(() => _held = held);
  }

  @override
  Widget build(BuildContext context) {
    final onSeek = widget.onSeek;
    final progress = widget.progress;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void seek(Offset localPosition) =>
            onSeek?.call((localPosition.dx / width).clamp(0.0, 1.0));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onSeek == null
              ? null
              : (d) {
                  _hold(true);
                  seek(d.localPosition);
                },
          onTapUp: onSeek == null ? null : (_) => _hold(false),
          onTapCancel: onSeek == null ? null : () => _hold(false),
          onHorizontalDragStart: onSeek == null ? null : (_) => _hold(true),
          onHorizontalDragUpdate:
              onSeek == null ? null : (d) => seek(d.localPosition),
          onHorizontalDragEnd: onSeek == null ? null : (_) => _hold(false),
          onHorizontalDragCancel: onSeek == null ? null : () => _hold(false),
          child: TweenAnimationBuilder<double>(
            tween: Tween(
              end: _held && !Motion.reduced(context) ? 1.6 : 1,
            ),
            duration: _held ? Motion.press : Motion.ui,
            curve: Motion.easeOut,
            builder: (context, thickness, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(1, thickness, 1),
              child: child,
            ),
            child: Container(
              height: AppSize.s8,
              width: width,
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                color: ColorManager.progressTrack,
                borderRadius: BorderRadius.all(AppRadius.rad999),
              ),
              child: Container(
                width: width * progress.clamp(0.0, 1.0),
                decoration: const BoxDecoration(
                  color: ColorManager.progressFill,
                  borderRadius: BorderRadius.all(AppRadius.rad999),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
