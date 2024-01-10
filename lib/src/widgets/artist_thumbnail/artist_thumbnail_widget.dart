import 'package:flutter/material.dart';

import '../../constants/fonts_manager.dart';
import '../../constants/styles_manager.dart';
import '../../constants/values_manager.dart';
import '../../models/artist_model.dart';
import '../common/artist_image/artist_image_placeholder.dart';

class ArtistThumbnailWidget extends StatelessWidget {
  final Artist artist;
  const ArtistThumbnailWidget({
    super.key,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSize.s84,
      child: Column(
        children: [
          // * Artist image
          ArtistImagePlaceholder(imageData: artist.image),

          AppGap.h8,
          // * Artist name
          Text(
            artist.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s14),
          ),
        ],
      ),
    );
  }
}
