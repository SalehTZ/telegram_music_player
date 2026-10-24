import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../blocs/player/player_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../../data/tags/tag_cleaner.dart';
import '../../../utils/duration_extension.dart';
import '../../../utils/song_text.dart';
import '../../navigation.dart';
import '../common/artwork/artwork_image.dart';

/// What can be done with one song.
Future<void> showSongOptions(
  BuildContext context,
  Song song, {
  Playlist? playlist,
}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SongOptionsSheet(song: song, playlist: playlist),
    );

class _SongOptionsSheet extends StatelessWidget {
  final Song song;
  final Playlist? playlist;
  const _SongOptionsSheet({required this.song, this.playlist});

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryCubit>();
    final state = library.state;
    final favorite = state.isFavorite(song);
    final artist = TagCleaner.clean(song.artist);
    final playlist = this.playlist;

    // * The sheet closes before the action, so pushed pages and snack bars
    // * use the page's context, not the sheet's.
    void then(void Function() action) {
      Navigator.of(context).pop();
      action();
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppPadding.p20, 0, AppPadding.p20, AppPadding.p12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // * The song
            Row(
              children: [
                ArtworkImage(song: song, size: AppSize.s56),
                AppGap.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyles.getSemiBoldStyle(fontSize: FontSize.s16),
                      ),
                      AppGap.h4,
                      Text(
                        [
                          song.artistOrUnknown,
                          song.format,
                          song.duration.toClock(),
                        ].where((s) => s.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.getRegularStyle(
                          fontSize: FontSize.s14,
                          color: ColorManager.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppGap.h12,
            const Divider(),
            _Option(
              icon: Icons.queue_music_rounded,
              label: 'Play next',
              onTap: () =>
                  then(() => context.read<PlayerCubit>().playNext(song)),
            ),
            _Option(
              icon: favorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: favorite ? 'Remove from favorites' : 'Add to favorites',
              onTap: () => then(() => library.toggleFavorite(song)),
            ),
            _Option(
              icon: Icons.playlist_add_rounded,
              label: 'Add to playlist',
              onTap: () {
                final page = Navigator.of(context);
                page.pop();
                showModalBottomSheet(
                  context: page.context,
                  builder: (_) => _PlaylistPicker(song: song),
                );
              },
            ),
            if (playlist != null)
              _Option(
                icon: Icons.playlist_remove_rounded,
                label: 'Remove from ${playlist.name}',
                onTap: () =>
                    then(() => library.removeFromPlaylist(playlist, song)),
              ),
            _Option(
              icon: Icons.edit_outlined,
              label: song.canEditTags ? 'Edit tags and cover' : 'Tags',
              detail:
                  song.canEditTags ? null : 'Stash can change MP3 files only',
              onTap: () {
                final page = Navigator.of(context);
                page.pop();
                openEditTags(page.context, song);
              },
            ),
            if (artist.isNotEmpty)
              _Option(
                icon: Icons.person_outline_rounded,
                label: 'More by $artist',
                onTap: () {
                  final page = Navigator.of(context);
                  page.pop();
                  final key = artist.toLowerCase();
                  openSongList(
                    page.context,
                    title: artist,
                    select: (s) => [
                      for (final a in s.artists)
                        if (a.name.toLowerCase() == key) ...a.songs,
                    ],
                  );
                },
              ),
            _Option(
              icon: Icons.folder_outlined,
              label: 'Open folder',
              detail: displayPath(song.folder),
              onTap: () {
                final page = Navigator.of(context);
                page.pop();
                openSongList(
                  page.context,
                  title: song.folder.split('/').last,
                  select: (s) => [
                    for (final f in s.folders)
                      if (f.name == song.folder) ...f.songs,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback onTap;
  const _Option({
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(AppRadius.rad8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.p12),
        child: Row(
          children: [
            Icon(icon, size: AppSize.s24, color: ColorManager.lightGrey),
            AppGap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyles.getMediumStyle(fontSize: FontSize.s16),
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.getRegularStyle(
                        color: ColorManager.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistPicker extends StatelessWidget {
  final Song song;
  const _PlaylistPicker({required this.song});

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryCubit>();
    final messenger = ScaffoldMessenger.of(context);
    void added(String name) {
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('Added to $name')));
    }

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
            AppPadding.p20, 0, AppPadding.p20, AppPadding.p12),
        children: [
          Text(
            'Add to playlist',
            style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
          ),
          AppGap.h8,
          _Option(
            icon: Icons.add_rounded,
            label: 'New playlist',
            onTap: () async {
              final name = await askPlaylistName(context);
              if (name == null) return;
              added(library.createPlaylist(name, first: song).name);
            },
          ),
          for (final playlist in library.state.playlists)
            _Option(
              icon: Icons.queue_music_rounded,
              label: playlist.name,
              detail: playlist.songIds.length == 1
                  ? '1 song'
                  : '${playlist.songIds.length} songs',
              onTap: () {
                library.addToPlaylist(playlist, song);
                added(playlist.name);
              },
            ),
        ],
      ),
    );
  }
}

/// Asks for a new playlist's name. Null when cancelled.
Future<String?> askPlaylistName(BuildContext context) {
  final name = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      void done() {
        if (name.text.trim().isNotEmpty) Navigator.of(context).pop(name.text);
      }

      return AlertDialog(
        title: Text(
          'New playlist',
          style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
        ),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (_) => done(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(onPressed: done, child: const Text('Create')),
        ],
      );
    },
  );
}
