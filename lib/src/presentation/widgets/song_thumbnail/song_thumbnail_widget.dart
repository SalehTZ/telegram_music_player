import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/assets_manager.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../common/artwork/artwork_image.dart';

class SongThumbnailWidget extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  const SongThumbnailWidget({
    super.key,
    required this.song,
    this.onTap,
  });

  /// Height of the thumbnail, used to size horizontal lists of thumbnails.
  static double height(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return (AppSize.s162 +
            AppSize.s8 * 2 +
            textScaler.scale(FontSize.s16) * FontHeight.h1_3 +
            textScaler.scale(FontSize.s14) * FontHeight.h1_3)
        .ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: AppSize.s162,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // * album art image
            Stack(
              children: [
                ArtworkImage(
                  song: song,
                  size: AppSize.s162,
                  borderRadius: const BorderRadius.all(AppRadius.rad12),
                ),
                const Positioned(
                  left: AppPadding.p8,
                  bottom: AppPadding.p8,
                  child: _PlayBadge(),
                ),
              ],
            ),

            AppGap.h8,
            // * Song name
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s16),
            ),

            AppGap.h8,
            // * Artist name
            Text(
              song.artistOrUnknown,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.getLightStyle(fontSize: FontSize.s14),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.s34,
      height: AppSize.s34,
      padding: const EdgeInsets.only(left: AppPadding.p6, top: AppPadding.p5),
      alignment: Alignment.topLeft,
      decoration: const BoxDecoration(
        color: ColorManager.playButtonOverlay,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        AssetsManager.playFilledIcon,
        width: AppSize.s24,
        height: AppSize.s24,
      ),
    );
  }
}
