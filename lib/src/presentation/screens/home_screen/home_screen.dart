import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../blocs/player/player_cubit.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../navigation.dart';
import '../../widgets/artist_thumbnail/artist_thumbnail_widget.dart';
import '../../widgets/common/custom_list_builder/custom_list_builder.dart';
import '../../widgets/common/section_widget/section.dart';
import '../../widgets/common/section_widget/section_header.dart';
import '../../widgets/search_bar/search_bar_widget.dart';
import '../../widgets/song_list_item/song_list_item_widget.dart';
import '../../widgets/song_options/song_options_sheet.dart';
import '../../widgets/song_thumbnail/song_thumbnail_widget.dart';
import '../main_screen/library_gate.dart';
import 'tidy_card.dart';

class HomeScreen extends StatefulWidget {
  /// Space kept free under the content, e.g. for the mini player.
  final double bottomPadding;
  const HomeScreen({super.key, this.bottomPadding = AppPadding.p20});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    const listPadding = EdgeInsets.symmetric(horizontal: AppPadding.p20);
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        if (state.songs.isEmpty) return const EmptyLibrary();
        final query = _query.trim().toLowerCase();
        return ListView(
          padding: EdgeInsets.only(
            top: AppPadding.p20,
            bottom: widget.bottomPadding,
          ),
          children: [
            Padding(
              padding: listPadding,
              child: SearchBarWidget(
                hintText: 'Search ${state.songs.length} songs',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (query.isNotEmpty)
              ..._results(context, state.songs, query)
            else ...[
              if (state.fixes.isNotEmpty) ...[
                AppGap.h28,
                TidyCard(state: state),
              ],
              if (state.recentlyPlayed.isNotEmpty) ...[
                AppGap.h28,
                _SongRow(title: 'Recently played', songs: state.recentlyPlayed),
              ],
              AppGap.h28,
              _SongRow(
                title: 'Recently added',
                songs: state.songs.take(20).toList(),
              ),
              if (state.artists.isNotEmpty) ...[
                AppGap.h28,
                SectionWidget(
                  header: SectionHeader(
                    child: Text(
                      'Artists',
                      style:
                          TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
                    ),
                  ),
                  slot: CustomListBuilder(
                    widgetList: [
                      for (final artist in state.artists.take(20))
                        ArtistThumbnailWidget(
                          artist: artist,
                          onTap: () => _openArtist(context, artist.name),
                        ),
                    ],
                    listPadding: listPadding,
                    crossAxisSize: ArtistThumbnailWidget.height(context),
                  ),
                ),
              ],
              if (state.favoriteSongs.isNotEmpty) ...[
                AppGap.h28,
                _SongRow(title: 'Favorites', songs: state.favoriteSongs),
              ],
            ],
          ],
        );
      },
    );
  }

  List<Widget> _results(BuildContext context, List<Song> all, String query) {
    final found = [
      for (final s in all)
        if ('${s.title}\n${s.artist}\n${s.album}'.toLowerCase().contains(query))
          s,
    ];
    final player = context.read<PlayerCubit>();
    return [
      SectionHeader(
        child: Text(
          found.isEmpty
              ? 'Nothing matches “${_query.trim()}”'
              : found.length == 1
                  ? '1 song'
                  : '${found.length} songs',
          style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
        ),
      ),
      for (final (i, song) in found.take(100).indexed)
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppPadding.p20, AppPadding.p8, AppPadding.p20, AppPadding.p8),
          child: SongListItemWidget(
            song: song,
            onTap: () => player.play(found, i),
            onMenuTap: () => showSongOptions(context, song),
          ),
        ),
    ];
  }

  void _openArtist(BuildContext context, String name) {
    final key = name.toLowerCase();
    openSongList(
      context,
      title: name,
      select: (state) => [
        for (final a in state.artists)
          if (a.name.toLowerCase() == key) ...a.songs,
      ],
    );
  }
}

/// A titled, sideways scrolling row of song covers.
class _SongRow extends StatelessWidget {
  final String title;
  final List<Song> songs;
  const _SongRow({required this.title, required this.songs});

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerCubit>();
    return SectionWidget(
      header: SectionHeader(
        child: Text(
          title,
          style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
        ),
      ),
      slot: CustomListBuilder(
        widgetList: [
          for (final (i, song) in songs.indexed)
            SongThumbnailWidget(
              song: song,
              onTap: () => player.play(songs, i),
            ),
        ],
        listPadding: const EdgeInsets.symmetric(horizontal: AppPadding.p20),
        gutter: AppSize.s12,
        crossAxisSize: SongThumbnailWidget.height(context),
      ),
    );
  }
}
