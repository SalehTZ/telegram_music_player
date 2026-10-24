import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../constants/colors_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../motion.dart';
import '../common/artwork/artwork_image.dart';
import 'mini_player_controls.dart';

class MiniPlayer extends StatelessWidget {
  final Song song;
  final double progress;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onSkipNext;
  const MiniPlayer({
    super.key,
    required this.song,
    required this.progress,
    this.isPlaying = false,
    this.onTap,
    this.onPlayPause,
    this.onSkipNext,
  });

  /// Height of the player card, without the space around it.
  static const double height = AppSize.s100;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(AppRadius.rad12);
    return Pressable(
      scale: 0.98,
      child: CustomPaint(
        painter: const _OuterShadowPainter(borderRadius: borderRadius),
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppBlur.sigma20,
                sigmaY: AppBlur.sigma20,
              ),
              child: Container(
                color: ColorManager.miniPlayerBackground,
                padding: const EdgeInsets.all(AppPadding.p8),
                child: Row(
                  children: [
                    Hero(
                      tag: Motion.coverHeroTag,
                      child: SizedBox.square(
                        dimension: AppSize.s84,
                        child: MotionSwitcher(
                          rise: 0,
                          child: ArtworkImage(
                            key: ValueKey(song.id),
                            song: song,
                            size: AppSize.s84,
                          ),
                        ),
                      ),
                    ),
                    AppGap.w8,
                    Expanded(
                      child: MiniPlayerControls(
                        song: song,
                        progress: progress,
                        isPlaying: isPlaying,
                        onPlayPause: onPlayPause,
                        onSkipNext: onSkipNext,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drop shadow that is only painted outside the card, so it doesn't darken
/// the translucent, blurred background (Figma's "show behind" turned off).
class _OuterShadowPainter extends CustomPainter {
  final BorderRadius borderRadius;
  const _OuterShadowPainter({required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final card = borderRadius.toRRect(Offset.zero & size);
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(card.outerRect.inflate(AppSize.s20)),
      Path()..addRRect(card),
    );
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRRect(
        card.shift(const Offset(0, AppSize.s4)),
        Paint()
          ..color = ColorManager.miniPlayerShadowColor
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, AppBlur.sigma2),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius;
}
