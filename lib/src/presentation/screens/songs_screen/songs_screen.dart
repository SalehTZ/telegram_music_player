import 'package:flutter/material.dart';

import '../../../constants/colors_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/fake_music_data.dart';
import '../../../data/models/song_model.dart';
import '../../widgets/song_list_item/song_list_item_widget.dart';

class SongsScreen extends StatelessWidget {
  /// Space kept free under the content, e.g. for the mini player.
  final double bottomPadding;
  final ValueChanged<Song>? onSongTap;
  const SongsScreen({
    super.key,
    this.bottomPadding = AppPadding.p20,
    this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppPadding.p28,
        AppPadding.p20,
        AppPadding.p28,
        bottomPadding,
      ),
      itemCount: fakeSongsList.length,
      itemBuilder: (context, index) {
        final song = fakeSongsList[index];
        return SongListItemWidget(
          song: song,
          onTap: () => onSongTap?.call(song),
          // TODO open song options, e.g. edit tags or album art
          onMenuTap: () {},
        );
      },
      separatorBuilder: (context, index) => const Divider(
        height: AppSize.s24,
        thickness: AppSize.s0_3,
        color: ColorManager.listSeparator,
      ),
    );
  }
}
