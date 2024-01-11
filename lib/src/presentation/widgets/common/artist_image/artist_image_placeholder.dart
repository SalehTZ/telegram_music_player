import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../constants/assets_manager.dart';
import '../../../../constants/values_manager.dart';

class ArtistImagePlaceholder extends StatelessWidget {
  final Uint8List? imageData;
  const ArtistImagePlaceholder({
    super.key,
    required this.imageData,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(AppRadius.rad999),
      child: imageData == null
          ? Image.asset(
              AssetsManager.defaultSongThumbnail,
              width: AppSize.s84,
              height: AppSize.s84,
            )
          : Image.memory(
              imageData!,
              width: AppSize.s84,
              height: AppSize.s84,
            ),
    );
  }
}
