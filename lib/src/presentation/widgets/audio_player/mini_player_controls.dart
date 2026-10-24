import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/assets_manager.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../motion.dart';
import '../common/progress_bar/song_progress_bar.dart';

class MiniPlayerControls extends StatelessWidget {
  final Song song;
  final double progress;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onSkipNext;
  const MiniPlayerControls({
    super.key,
    required this.song,
    required this.progress,
    this.isPlaying = false,
    this.onPlayPause,
    this.onSkipNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // * Song name and artist
            Expanded(
              child: MotionSwitcher(
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  key: ValueKey(song.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.getMediumStyle(fontSize: FontSize.s15),
                    ),
                    AppGap.h4,
                    Text(
                      song.artistOrUnknown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.getRegularStyle(
                        color: ColorManager.miniPlayerSubtitle,
                        height: FontHeight.h1_4,
                        letterSpacing: FontLetterSpacing.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // * Controls
            Padding(
              padding: const EdgeInsets.only(right: AppPadding.p8),
              child: Row(
                children: [
                  _MiniPlayerButton(
                    onTap: onPlayPause,
                    child: MotionSwitcher(
                      rise: 0,
                      scale: 0.6,
                      duration: Motion.hover,
                      child: isPlaying
                          ? SvgPicture.asset(
                              key: const ValueKey(true),
                              AssetsManager.pauseIcon,
                              width: AppSize.s24,
                              height: AppSize.s24,
                              colorFilter: const ColorFilter.mode(
                                ColorManager.white,
                                BlendMode.srcIn,
                              ),
                            )
                          : SvgPicture.asset(
                              key: const ValueKey(false),
                              AssetsManager.playIcon,
                              width: AppSize.s24,
                              height: AppSize.s24,
                            ),
                    ),
                  ),
                  AppGap.w8,
                  _MiniPlayerButton(
                    onTap: onSkipNext,
                    child: SvgPicture.asset(
                      AssetsManager.skipForwardIcon,
                      width: AppSize.s24,
                      height: AppSize.s24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        AppGap.h10,
        // * Progress
        SongProgressBar(progress: progress),
      ],
    );
  }
}

class _MiniPlayerButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _MiniPlayerButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.85,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
