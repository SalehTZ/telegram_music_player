import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../constants/assets_manager.dart';
import '../../../../constants/values_manager.dart';

class SmallAlbumArtImage extends StatelessWidget {
  final Uint8List? imageData;
  const SmallAlbumArtImage({
    super.key,
    required this.imageData,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(AppRadius.rad8),
      child: imageData == null
          ? Image.asset(
              AssetsManager.defaultSongThumbnail,
              width: AppSize.s84,
              height: AppSize.s84,
              fit: BoxFit.cover,
            )
          : Image.memory(
              imageData!,
              width: AppSize.s84,
              height: AppSize.s84,
              fit: BoxFit.cover,
            ),
    );
  }
}
