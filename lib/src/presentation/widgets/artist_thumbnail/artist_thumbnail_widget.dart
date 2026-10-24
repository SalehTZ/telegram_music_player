import 'package:flutter/material.dart';

import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/artist_model.dart';
import '../common/artist_image/artist_image_placeholder.dart';

class ArtistThumbnailWidget extends StatelessWidget {
  final Artist artist;
  const ArtistThumbnailWidget({
    super.key,
    required this.artist,
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
    return SizedBox(
      width: AppSize.s84,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.p12),
        child: Column(
          children: [
            // * Artist image
            ArtistImagePlaceholder(imageData: artist.image),

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
    );
  }
}
