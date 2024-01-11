import 'package:flutter/material.dart';

import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../common/album_art_widget/album_art_image_small.dart';
import 'mini_player_controls.dart';

class MiniPlayer extends StatelessWidget {
  final Song song;
  const MiniPlayer({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(AppRadius.rad12),
      ),
      padding: const EdgeInsets.all(AppPadding.p8),
      child: Row(
        children: [
          SmallAlbumArtImage(imageData: song.albumArtUrl!),
          AppGap.w8,
          const MiniPlayerControls(),
        ],
      ),
    );
  }
}
