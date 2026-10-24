import 'package:flutter/material.dart';

import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../blocs/library/library_cubit.dart';
import '../../motion.dart';
import '../common/artwork/artwork_image.dart';

class ArtistThumbnailWidget extends StatelessWidget {
  final SongGroup artist;
  final VoidCallback? onTap;
  const ArtistThumbnailWidget({
    super.key,
    required this.artist,
    this.onTap,
  });

  /// Height of the thumbnail, used to size horizontal lists of artists.
  static double height(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return (AppPadding.p12 * 2 +
            AppSize.s84 +
            AppSize.s8 +
            textScaler.scale(FontSize.s14) * FontHeight.h1_3)
        .ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: AppSize.s84,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppPadding.p12),
            child: Column(
              children: [
                // * The cover of one of their songs
                ArtworkImage(
                  song: artist.songs.first,
                  size: AppSize.s84,
                  borderRadius: const BorderRadius.all(AppRadius.rad999),
                ),

                AppGap.h8,
                // * Artist name
                Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyles.getMediumStyle(fontSize: FontSize.s14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
