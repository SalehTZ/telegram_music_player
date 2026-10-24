import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/assets_manager.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../../utils/duration_extension.dart';
import '../common/artwork/artwork_image.dart';

class SongListItemWidget extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  /// The song that is playing, shown with its title in the accent colour.
  final bool isCurrent;
  const SongListItemWidget({
    super.key,
    required this.song,
    this.onTap,
    this.onMenuTap,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // * Album art
          ArtworkImage(song: song, size: AppSize.s84),

          AppGap.w12,
          // * Song name and artist
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppPadding.p10_5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.getSemiBoldStyle(
                      fontSize: FontSize.s18,
                      color: isCurrent
                          ? ColorManager.primaryPressedColor
                          : ColorManager.white,
                    ),
                  ),
                  AppGap.h16,
                  Text(
                    song.artistOrUnknown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.getRegularStyle(fontSize: FontSize.s14),
                  ),
                ],
              ),
            ),
          ),

          // * Format, duration and menu
          SizedBox(
            height: AppSize.s84,
            child: Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(song.format, style: TextStyles.getRegularStyle()),
                      AppGap.h16,
                      Text(
                        song.duration.toClock(),
                        style: TextStyles.getRegularStyle(),
                      ),
                    ],
                  ),
                  AppGap.w16,
                  Padding(
                    padding: const EdgeInsets.only(top: AppPadding.p14),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onMenuTap,
                      child: SvgPicture.asset(
                        AssetsManager.verticalDotsMenuIcon,
                        width: AppSize.s24,
                        height: AppSize.s24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
