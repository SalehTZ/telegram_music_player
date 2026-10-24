import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/library/library_cubit.dart';
import '../../../../constants/colors_manager.dart';
import '../../../../constants/values_manager.dart';
import '../../../../data/library/artwork_cache.dart';
import '../../../../data/models/song_model.dart';
import '../../../motion.dart';

/// A song's embedded cover, or a dark tile with a note when it has none.
class ArtworkImage extends StatelessWidget {
  final Song? song;

  /// Width and height. When null the cover fills its parent.
  final double? size;
  final ArtworkSize quality;
  final BorderRadius borderRadius;

  const ArtworkImage({
    super.key,
    required this.song,
    this.size,
    this.quality = ArtworkSize.small,
    this.borderRadius = const BorderRadius.all(AppRadius.rad8),
  });

  @override
  Widget build(BuildContext context) {
    final song = this.song;
    final cache = context.read<LibraryCubit>().artwork;
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: song == null
            ? const ArtworkPlaceholder()
            : FutureBuilder<Uint8List?>(
                future: cache.get(song, quality),
                initialData: cache.peek(song, quality),
                // * A cover that has to be read fades in over the tile;
                // * one already in memory is there at once
                builder: (context, snapshot) {
                  final cover = snapshot.data;
                  return AnimatedSwitcher(
                    duration: Motion.ui,
                    switchInCurve: Motion.easeOut,
                    layoutBuilder: (current, previous) => Stack(
                      fit: StackFit.passthrough,
                      children: [...previous, if (current != null) current],
                    ),
                    child: cover == null
                        ? const ArtworkPlaceholder()
                        : Image.memory(
                            key: const ValueKey(true),
                            cover,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) =>
                                const ArtworkPlaceholder(),
                          ),
                  );
                },
              ),
      ),
    );
  }
}

class ArtworkPlaceholder extends StatelessWidget {
  const ArtworkPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColorManager.artworkPlaceholder,
      child: LayoutBuilder(
        builder: (context, box) => Center(
          child: Icon(
            Icons.music_note_rounded,
            size: box.biggest.shortestSide * 0.36,
            color: ColorManager.faintText,
          ),
        ),
      ),
    );
  }
}
