import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../navigation.dart';
import '../../widgets/song_options/song_options_sheet.dart';
import '../folders_screen/folders_screen.dart';

/// Lists the library keeps by itself, then the user's own.
class PlaylistsScreen extends StatelessWidget {
  final double bottomPadding;
  const PlaylistsScreen({super.key, this.bottomPadding = AppPadding.p20});

  static final _smart = <(String, List<Song> Function(LibraryState))>[
    ('Favorites', (s) => s.favoriteSongs),
    ('Recently added', (s) => s.songs.take(50).toList()),
    ('Recently played', (s) => s.recentlyPlayed),
    ('From Telegram', (s) => [...s.songs.where((x) => x.fromTelegram)]),
  ];

  @override
  Widget build(BuildContext context) {
    final heading = TextStyles.getSemiBoldStyle(fontSize: FontSize.s20);
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) => ListView(
        padding: EdgeInsets.fromLTRB(
            AppPadding.p20, AppPadding.p20, AppPadding.p20, bottomPadding),
        children: [
          for (final (name, select) in _smart) ...[
            CollectionRow(
              cover: select(state).firstOrNull,
              title: name,
              count: select(state).length,
              onTap: () => openSongList(context, title: name, select: select),
            ),
            AppGap.h8,
          ],
          AppGap.h20,
          Row(
            children: [
              Expanded(child: Text('Your playlists', style: heading)),
              TextButton.icon(
                onPressed: () async {
                  final name = await askPlaylistName(context);
                  if (name != null && context.mounted) {
                    context.read<LibraryCubit>().createPlaylist(name);
                  }
                },
                icon: const Icon(Icons.add_rounded, size: AppSize.s20),
                label: const Text('New playlist'),
              ),
            ],
          ),
          AppGap.h8,
          if (state.playlists.isEmpty)
            Text(
              "You haven't made any yet. Make one here, or add a song "
              'from its menu.',
              style: TextStyles.getRegularStyle(
                fontSize: FontSize.s14,
                color: ColorManager.secondaryText,
              ),
            ),
          for (final playlist in state.playlists) ...[
            CollectionRow(
              cover: state.songsFor(playlist.songKeys).firstOrNull,
              title: playlist.name,
              count: state.songsFor(playlist.songKeys).length,
              onTap: () => openSongList(
                context,
                title: playlist.name,
                playlistName: playlist.name,
                select: (s) => s.songsFor(
                  s.playlists
                          .where((p) => p.name == playlist.name)
                          .firstOrNull
                          ?.songKeys ??
                      const [],
                ),
              ),
            ),
            AppGap.h8,
          ],
        ],
      ),
    );
  }
}
