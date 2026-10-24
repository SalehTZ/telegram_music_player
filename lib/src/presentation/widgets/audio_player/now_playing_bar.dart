import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/player/player_cubit.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../motion.dart';
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
        return _SlideUp(
          child: song == null
              ? const SizedBox.shrink(key: ValueKey(false))
              : KeyedSubtree(
                  key: const ValueKey(true),
                  child: _bar(context, song, state),
                ),
        );
      },
    );
  }

  Widget _bar(BuildContext context, Song song, PlayerState state) {
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
  }
}

/// The mini player coming up from the bottom edge when the first song
/// starts, and going back down when the queue ends.
class _SlideUp extends StatelessWidget {
  final Widget child;
  const _SlideUp({required this.child});

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return AnimatedSwitcher(
      duration: Motion.reveal,
      reverseDuration: Motion.exit(Motion.reveal),
      switchInCurve: Motion.easeExpo,
      switchOutCurve: Motion.easeOut,
      transitionBuilder: (child, animation) {
        final faded = FadeTransition(opacity: animation, child: child);
        if (reduced) return faded;
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1.2), end: Offset.zero)
              .animate(animation),
          child: faded,
        );
      },
      child: child,
    );
  }
}
