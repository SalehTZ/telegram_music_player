import 'package:flutter/material.dart';

import '../../constants/fonts_manager.dart';
import '../../constants/styles_manager.dart';
import '../../constants/values_manager.dart';
import '../../models/song_model.dart';
import '../common/album_art_widget/album_art_image_large.dart';

class SongThumbnailWidget extends StatelessWidget {
  final Song song;
  const SongThumbnailWidget({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSize.s172,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // * album art image
          LargeAlbumArtImage(imageData: song.albumArtUrl),

          AppGap.h8,
          // * Song name
          Text(
            song.title,
            style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s16),
          ),

          AppGap.h8,
          // * Artist name
          Text(
            song.artist,
            style: TextStyles.getRegularStyle(fontSize: FontSize.s14),
          ),
        ],
      ),
    );
  }
}
