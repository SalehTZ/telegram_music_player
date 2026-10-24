import 'package:flutter/material.dart';

import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/fake_artist_data.dart';
import '../../../data/fake_music_data.dart';
import '../../../data/models/song_model.dart';
import '../../widgets/artist_thumbnail/artist_thumbnail_widget.dart';
import '../../widgets/common/custom_list_builder/custom_list_builder.dart';
import '../../widgets/common/section_widget/section.dart';
import '../../widgets/common/section_widget/section_header.dart';
import '../../widgets/search_bar/search_bar_widget.dart';
import '../../widgets/song_thumbnail/song_thumbnail_widget.dart';

class HomeScreen extends StatelessWidget {
  /// Space kept free under the content, e.g. for the mini player.
  final double bottomPadding;
  final ValueChanged<Song>? onSongTap;
  const HomeScreen({
    super.key,
    this.bottomPadding = AppPadding.p20,
    this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    var fakeSongsWidget = List.generate(
      fakeSongsList.length,
      (index) {
        final song = fakeSongsList[index];
        return SongThumbnailWidget(
          song: song,
          onTap: () => onSongTap?.call(song),
        );
      },
    );
    var fakeArtistWidget = List.generate(
      fakeArtistsList.length,
      (index) {
        return ArtistThumbnailWidget(
          artist: fakeArtistsList[index],
        );
      },
    );
    const listPadding = EdgeInsets.symmetric(horizontal: AppPadding.p20);
    final songsListHeight = SongThumbnailWidget.height(context);
    return ListView(
      padding: EdgeInsets.only(top: AppPadding.p20, bottom: bottomPadding),
      children: [
        // * SearchBar
        const Padding(
          padding: listPadding,
          child: SearchBarWidget(),
        ),

        AppGap.h28,
        // * Recently Played section
        SectionWidget(
          header: SectionHeader(
            child: Text(
              "Recently Played",
              style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
            ),
          ),
          slot: CustomListBuilder(
            widgetList: fakeSongsWidget,
            listPadding: listPadding,
            gutter: AppSize.s12,
            crossAxisSize: songsListHeight,
          ),
        ),

        AppGap.h28,
        // * Artists section
        SectionWidget(
          header: SectionHeader(
            child: Text(
              "Artists",
              style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
            ),
          ),
          slot: CustomListBuilder(
            widgetList: fakeArtistWidget,
            listPadding: listPadding,
            crossAxisSize: ArtistThumbnailWidget.height(context),
          ),
        ),

        AppGap.h28,
        // * Favorites section
        SectionWidget(
          header: SectionHeader(
            child: Text(
              "Favorites",
              style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
            ),
          ),
          slot: CustomListBuilder(
            widgetList: fakeSongsWidget,
            listPadding: listPadding,
            gutter: AppSize.s12,
            crossAxisSize: songsListHeight,
          ),
        ),
      ],
    );
  }
}
