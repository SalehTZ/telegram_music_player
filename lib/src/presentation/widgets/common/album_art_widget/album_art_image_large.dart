import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../constants/assets_manager.dart';
import '../../../../constants/values_manager.dart';

class LargeAlbumArtImage extends StatelessWidget {
  final Uint8List? imageData;
  const LargeAlbumArtImage({
    super.key,
    required this.imageData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(AppRadius.rad12),
      ),
      child: imageData == null
          ? ClipRRect(
              borderRadius: const BorderRadius.all(AppRadius.rad12),
              child: Image.asset(
                AssetsManager.defaultSongThumbnail,
                width: AppSize.s162,
                height: AppSize.s162,
              ),
            )
          : Image.memory(
              imageData!,
              width: AppSize.s162,
              height: AppSize.s162,
            ),
    );
  }
}
