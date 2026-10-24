import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;

import '../../../blocs/library/library_cubit.dart';
import '../../../blocs/player/player_cubit.dart';
import '../../../constants/assets_manager.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/library/artwork_cache.dart';
import '../../../data/lyrics/lyrics.dart';
import '../../../data/models/song_model.dart';
import '../../../utils/duration_extension.dart';
import '../../navigation.dart';
import '../../widgets/appbar/appbar_widget.dart';
import '../../widgets/common/artwork/artwork_image.dart';
import '../../widgets/common/progress_bar/song_progress_bar.dart';
import '../../widgets/song_options/song_options_sheet.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int? _lyricsSongId;
  Lyrics? _lyrics;

  @override
  void initState() {
    super.initState();
    final song = context.read<PlayerCubit>().state.song;
    if (song != null) _loadLyrics(song);
  }

  Future<void> _loadLyrics(Song song) async {
    _lyricsSongId = song.id;
    _lyrics = null;
    final lyrics = await context.read<LibraryCubit>().lyricsFor(song);
    if (mounted && _lyricsSongId == song.id) setState(() => _lyrics = lyrics);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlayerCubit, PlayerState>(
      listenWhen: (a, b) => a.song?.id != b.song?.id,
      listener: (context, state) {
        final song = state.song;
        if (song != null) _loadLyrics(song);
      },
      builder: (context, state) {
        final song = state.song;
        if (song == null) {
          return const Scaffold(appBar: AppBarWidget(isMainScreen: false));
        }
        final player = context.read<PlayerCubit>();
        return Scaffold(
          appBar: AppBarWidget(
            isMainScreen: false,
            hasSecondAction: true,
            onSecondActionTap: () => showSongOptions(context, song),
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.p20),
              child: Column(
                children: [
                  AppGap.h20,
                  // * Album art, shrinks on short screens
                  Flexible(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ArtworkImage(
                        song: song,
                        quality: ArtworkSize.large,
                        borderRadius: const BorderRadius.all(AppRadius.rad12),
                      ),
                    ),
                  ),

                  AppGap.h20,
                  // * Song name and artist, the heart balanced by an equal
                  // * space on the left so the title stays centred
                  Row(
                    children: [
                      const SizedBox(width: AppSize.s48),
                      Expanded(
                        child: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              TextStyles.getBoldStyle(fontSize: FontSize.s24),
                        ),
                      ),
                      _FavoriteButton(song: song),
                    ],
                  ),
                  AppGap.h12,
                  Text(
                    song.artistOrUnknown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyles.getRegularStyle(
                      fontSize: FontSize.s18,
                      color: ColorManager.secondaryText,
                    ),
                  ),

                  AppGap.h40,
                  _PlayerControls(state: state, player: player),

                  AppGap.h40,
                  StreamBuilder<Duration>(
                    stream: player.position,
                    initialData: player.positionNow,
                    builder: (context, snapshot) => _Progress(
                      position: snapshot.data ?? Duration.zero,
                      duration: song.duration,
                      lyrics: _lyrics,
                      onSeek: player.seek,
                      onOpenLyrics: () => openLyrics(
                        context,
                        song,
                        _lyrics,
                        onFound: (found) {
                          if (mounted && _lyricsSongId == song.id) {
                            setState(() => _lyrics = found);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final Song song;
  const _FavoriteButton({required this.song});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      buildWhen: (a, b) => a.isFavorite(song) != b.isFavorite(song),
      builder: (context, state) {
        final favorite = state.isFavorite(song);
        return IconButton(
          onPressed: () => context.read<LibraryCubit>().toggleFavorite(song),
          tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
          icon: Icon(
            favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: favorite
                ? ColorManager.likeButtonColor
                : ColorManager.secondaryText,
          ),
        );
      },
    );
  }
}

/// The progress bar, the times and the lyrics at this point of the song.
class _Progress extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Lyrics? lyrics;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onOpenLyrics;
  const _Progress({
    required this.position,
    required this.duration,
    required this.lyrics,
    required this.onSeek,
    required this.onOpenLyrics,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = position > duration ? duration : position;
    final timeStyle = TextStyles.getRegularStyle(
      fontSize: FontSize.s20,
      color: ColorManager.playerTimeText,
    );
    return Column(
      children: [
        SongProgressBar(
          progress: duration.inMilliseconds == 0
              ? 0
              : clamped.inMilliseconds / duration.inMilliseconds,
          onSeek: (fraction) => onSeek(duration * fraction),
        ),
        AppGap.h10,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(clamped.toClock(), style: timeStyle),
            Text("-${(duration - clamped).toClock()}", style: timeStyle),
          ],
        ),
        AppGap.h20,
        _LyricsPreview(lines: _previewLines(), onTap: onOpenLyrics),
      ],
    );
  }

  /// The line being sung and the next, or the first two when not timed.
  List<String> _previewLines() {
    final lyrics = this.lyrics;
    if (lyrics == null) return const [];
    if (lyrics.timed.isEmpty) {
      return lyrics.lines.where((l) => l.isNotEmpty).take(2).toList();
    }
    final at = lyrics.lineAt(position);
    return [
      for (final line in lyrics.timed.skip(at < 0 ? 0 : at).take(2)) line.text,
    ];
  }
}

class _PlayerControls extends StatelessWidget {
  final PlayerState state;
  final PlayerCubit player;
  const _PlayerControls({required this.state, required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.p10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlButton(
            icon: AssetsManager.shuffleIcon,
            label: state.shuffle ? 'Shuffle on' : 'Shuffle off',
            active: state.shuffle,
            onTap: player.toggleShuffle,
          ),
          _ControlButton(
            icon: AssetsManager.skipBackIcon,
            label: 'Previous',
            onTap: player.previous,
          ),
          _ControlButton(
            icon: state.playing
                ? AssetsManager.pauseButton
                : AssetsManager.playButton,
            label: state.playing ? 'Pause' : 'Play',
            size: AppSize.s56,
            onTap: player.toggle,
          ),
          _ControlButton(
            icon: AssetsManager.skipForwardIcon,
            label: 'Next',
            onTap: player.next,
          ),
          Badge(
            label: const Text('1'),
            isLabelVisible: state.loop == LoopMode.one,
            backgroundColor: ColorManager.primaryEnabledColor,
            child: _ControlButton(
              icon: AssetsManager.repeatIcon,
              label: switch (state.loop) {
                LoopMode.off => 'Repeat off',
                LoopMode.all => 'Repeat all',
                LoopMode.one => 'Repeat this song',
              },
              size: AppSize.s32,
              active: state.loop != LoopMode.off,
              onTap: player.cycleLoop,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String icon;
  final String label;
  final double size;

  /// Null for buttons that are not a switch; otherwise whether it's on.
  final bool? active;
  final VoidCallback onTap;
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = AppSize.s24,
    this.active,
  });

  @override
  Widget build(BuildContext context) {
    final active = this.active;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SvgPicture.asset(
          icon,
          width: size,
          height: size,
          colorFilter: active == null
              ? null
              : ColorFilter.mode(
                  active
                      ? ColorManager.primaryPressedColor
                      : ColorManager.secondaryText,
                  BlendMode.srcIn,
                ),
        ),
      ),
    );
  }
}

class _LyricsPreview extends StatelessWidget {
  final List<String> lines;
  final VoidCallback onTap;
  const _LyricsPreview({required this.lines, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // * The line being sung, then the next, faded
          for (final (i, line) in lines.indexed) ...[
            if (i > 0) AppGap.h8,
            Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: i == 0
                  ? TextStyles.getSemiBoldStyle(
                      fontSize: FontSize.s18,
                      color: ColorManager.secondaryText,
                    )
                  : TextStyles.getRegularStyle(
                      fontSize: FontSize.s16,
                      color: ColorManager.inactiveLyricsText,
                    ),
            ),
          ],
          AppGap.h8,
          SvgPicture.asset(
            AssetsManager.chevronUpIcon,
            width: AppSize.s24,
            height: AppSize.s24,
          ),
          Text(
            "Lyrics",
            style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
          ),
        ],
      ),
    );
  }
}
