import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../constants/assets_manager.dart';
import '../../../../constants/values_manager.dart';

class LargeAlbumArtImage extends StatelessWidget {
  final Uint8List? imageData;

  /// Width and height of the image. When null the image fills its parent,
  /// e.g. inside an [AspectRatio] on the player screen.
  final double? size;
  const LargeAlbumArtImage({
    super.key,
    required this.imageData,
    this.size = AppSize.s162,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(AppRadius.rad12),
        child: imageData == null
            ? Image.asset(
                AssetsManager.defaultSongThumbnail,
                fit: BoxFit.cover,
              )
            : Image.memory(
                imageData!,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
