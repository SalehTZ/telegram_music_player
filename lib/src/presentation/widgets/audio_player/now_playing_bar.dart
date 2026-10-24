import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/player/player_cubit.dart';
import '../../../constants/values_manager.dart';
import '../../navigation.dart';
import 'mini_music_player.dart';

/// [child] with the mini player for the playing song floating over its
/// bottom edge.
class WithNowPlaying extends StatelessWidget {
  final Widget child;
  const WithNowPlaying({super.key, required this.child});

  /// Space a page keeps free under its content so the mini player doesn't
  /// cover the last item.
  static double bottomSpace(BuildContext context) =>
      MiniPlayer.height +
      AppPadding.p8 * 2 +
      AppPadding.p20 +
      MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        const Positioned(
          left: AppPadding.p20,
          right: AppPadding.p20,
          bottom: AppPadding.p8,
          child: SafeArea(top: false, child: _NowPlayingBar()),
        ),
      ],
    );
  }
}

class _NowPlayingBar extends StatelessWidget {
  const _NowPlayingBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      // * identical, not ==: an edited song keeps its id but has new tags
      buildWhen: (a, b) => !identical(a.song, b.song) || a.playing != b.playing,
      builder: (context, state) {
        final song = state.song;
        if (song == null) return const SizedBox.shrink();
        final player = context.read<PlayerCubit>();
        return StreamBuilder<Duration>(
          stream: player.position,
          builder: (context, position) {
            final total = song.duration.inMilliseconds;
            final played = position.data?.inMilliseconds ?? 0;
            return MiniPlayer(
              song: song,
              isPlaying: state.playing,
              progress: total == 0 ? 0 : played / total,
              onTap: () => openPlayer(context),
              onPlayPause: player.toggle,
              onSkipNext: player.next,
            );
          },
        );
      },
    );
  }
}
