import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../widgets/song_list/song_list_view.dart';

class SongsScreen extends StatefulWidget {
  /// Space kept free under the content, e.g. for the mini player.
  final double bottomPadding;
  const SongsScreen({super.key, this.bottomPadding = AppPadding.p20});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  bool _byTitle = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final songs = _byTitle
            ? ([...state.songs]..sort((a, b) =>
                a.title.toLowerCase().compareTo(b.title.toLowerCase())))
            : state.songs;
        return SongListView(
          songs: songs,
          bottomPadding: widget.bottomPadding,
          header: Row(
            children: [
              Expanded(
                child: Text(
                  songs.length == 1 ? '1 song' : '${songs.length} songs',
                  style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _byTitle = !_byTitle),
                icon: const Icon(Icons.swap_vert_rounded, size: AppSize.s20),
                label: Text(_byTitle ? 'A to Z' : 'Newest'),
              ),
            ],
          ),
        );
      },
    );
  }
}
