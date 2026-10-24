import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../blocs/player/player_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../../utils/song_text.dart';
import '../../widgets/appbar/appbar_widget.dart';
import '../../widgets/audio_player/now_playing_bar.dart';
import '../../widgets/common/page_title/page_title.dart';
import '../../widgets/song_list/song_list_view.dart';

/// The songs of a folder, an artist or a playlist.
class SongListScreen extends StatelessWidget {
  final String title;
  final List<Song> Function(LibraryState state) select;

  /// Set for the user's own playlists, which can be deleted from here.
  final String? playlistName;

  const SongListScreen({
    super.key,
    required this.title,
    required this.select,
    this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final songs = select(state);
        final playlist =
            state.playlists.where((p) => p.name == playlistName).firstOrNull;
        return Scaffold(
          appBar: AppBarWidget(
            isMainScreen: false,
            hasSecondAction: playlist != null,
            onSecondActionTap: () => _confirmDelete(context, playlist!),
          ),
          body: WithNowPlaying(
            child: songs.isEmpty
                ? _Empty(title: title, isPlaylist: playlist != null)
                : SongListView(
                    songs: songs,
                    playlist: playlist,
                    bottomPadding: WithNowPlaying.bottomSpace(context),
                    header: _Header(title: title, songs: songs),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Playlist playlist) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete ${playlist.name}?',
          style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
        ),
        content: Text(
          'The songs stay on your phone.',
          style: TextStyles.getRegularStyle(fontSize: FontSize.s14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (delete != true || !context.mounted) return;
    context.read<LibraryCubit>().deletePlaylist(playlist);
    Navigator.of(context).pop();
  }
}

class _Header extends StatelessWidget {
  final String title;
  final List<Song> songs;
  const _Header({required this.title, required this.songs});

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle(title: title, subtitle: describeSongs(songs)),
        AppGap.h20,
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => player.play(songs, 0),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play'),
              ),
            ),
            AppGap.w12,
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => player.playShuffled(songs),
                icon: const Icon(Icons.shuffle_rounded),
                label: const Text('Shuffle'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final String title;
  final bool isPlaylist;
  const _Empty({required this.title, required this.isPlaylist});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.p28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle(title: title, subtitle: 'No songs'),
          AppGap.h20,
          Text(
            isPlaylist
                ? 'Add songs from their menu: tap the dots next to a song, '
                    'then Add to playlist.'
                : 'There are no songs here any more.',
            style: TextStyles.getRegularStyle(
              fontSize: FontSize.s16,
              color: ColorManager.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
