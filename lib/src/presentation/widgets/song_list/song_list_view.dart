import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../blocs/player/player_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../song_list_item/song_list_item_widget.dart';
import '../song_options/song_options_sheet.dart';

/// Songs one under the other. A tap plays the list from that song.
class SongListView extends StatelessWidget {
  final List<Song> songs;

  /// Scrolls with the songs, above them.
  final Widget? header;
  final double bottomPadding;

  /// Set when the songs are a playlist, so a song's menu can take it out.
  final Playlist? playlist;

  const SongListView({
    super.key,
    required this.songs,
    required this.bottomPadding,
    this.header,
    this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    final offset = header == null ? 0 : 1;
    return BlocBuilder<PlayerCubit, PlayerState>(
      buildWhen: (a, b) => a.song?.id != b.song?.id,
      builder: (context, player) => ListView.separated(
        padding: EdgeInsets.fromLTRB(
          AppPadding.p28,
          AppPadding.p20,
          AppPadding.p28,
          bottomPadding,
        ),
        itemCount: songs.length + offset,
        itemBuilder: (context, index) {
          if (index < offset) return header!;
          final song = songs[index - offset];
          return SongListItemWidget(
            song: song,
            isCurrent: player.song?.id == song.id,
            onTap: () =>
                context.read<PlayerCubit>().play(songs, index - offset),
            onMenuTap: () => showSongOptions(context, song, playlist: playlist),
          );
        },
        separatorBuilder: (context, index) => index < offset
            ? AppGap.h24
            : const Divider(
                height: AppSize.s24,
                thickness: AppSize.s0_3,
                color: ColorManager.listSeparator,
              ),
      ),
    );
  }
}
