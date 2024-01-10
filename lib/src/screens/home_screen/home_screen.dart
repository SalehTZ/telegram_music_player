import 'package:flutter/material.dart';

import '../../constants/fonts_manager.dart';
import '../../constants/styles_manager.dart';
import '../../constants/values_manager.dart';
import '../../data/fake_artist_data.dart';
import '../../data/fake_music_data.dart';
import '../../widgets/appbar/appbar_widget.dart';
import '../../widgets/artist_thumbnail/artist_thumbnail_widget.dart';
import '../../widgets/common/custom_list_builder/custom_list_builder.dart';
import '../../widgets/common/section_widget/section.dart';
import '../../widgets/common/section_widget/section_header.dart';
import '../../widgets/search_bar/search_bar_widget.dart';
import '../../widgets/song_thumbnail/song_thumbnail_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var fakeSongsWidget = List.generate(
      fakeSongsList.length,
      (index) {
        return SongThumbnailWidget(
          song: fakeSongsList[index],
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
    return SafeArea(
      child: Scaffold(
        appBar: const AppBarWidget(),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.p20),
          child: ListView(
            children: [
              AppGap.h20,
              // * SearchBar
              const SearchBarWidget(),

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
                  listPadding: EdgeInsets.zero,
                  crossAxisSize: AppSize.s210,
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
                  listPadding: EdgeInsets.zero,
                  crossAxisSize: AppSize.s136,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
