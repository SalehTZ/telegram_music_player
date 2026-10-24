import 'package:flutter/material.dart';

import '../../../../constants/colors_manager.dart';
import '../../../../constants/values_manager.dart';

class SongProgressBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void seek(Offset localPosition) =>
            onSeek?.call((localPosition.dx / width).clamp(0.0, 1.0));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onSeek == null ? null : (d) => seek(d.localPosition),
          onHorizontalDragUpdate:
              onSeek == null ? null : (d) => seek(d.localPosition),
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
        );
      },
    );
  }
}
