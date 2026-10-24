import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/assets_manager.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../../utils/duration_extension.dart';
import '../../widgets/appbar/appbar_widget.dart';
import '../../widgets/common/album_art_widget/album_art_image_large.dart';
import '../../widgets/common/progress_bar/song_progress_bar.dart';

class PlayerScreen extends StatefulWidget {
  final Song song;
  final Duration initialPosition;
  const PlayerScreen({
    super.key,
    required this.song,
    this.initialPosition = Duration.zero,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // TODO read these from the AudioPlayerBloc instead of local UI state
  bool _isPlaying = true;
  late Duration _position = widget.initialPosition;

  Duration get _duration => widget.song.duration;

  void _seek(double fraction) {
    setState(() => _position = _duration * fraction);
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : _position.inMilliseconds / _duration.inMilliseconds;
    final lyricsLines = song.lyrics
        ?.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .take(2)
        .toList();

    return Scaffold(
      appBar: const AppBarWidget(
        isMainScreen: false,
        hasSecondAction: true,
        // TODO open song options, e.g. edit tags or album art
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
                  child: LargeAlbumArtImage(
                    imageData: song.albumArtUrl,
                    size: null,
                  ),
                ),
              ),

              AppGap.h20,
              // * Song name and artist
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyles.getBoldStyle(fontSize: FontSize.s24),
              ),
              AppGap.h24,
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyles.getRegularStyle(
                  fontSize: FontSize.s18,
                  color: ColorManager.secondaryText,
                ),
              ),

              AppGap.h40,
              // * Controls
              _PlayerControls(
                isPlaying: _isPlaying,
                onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
              ),

              AppGap.h40,
              // * Progress
              SongProgressBar(progress: progress, onSeek: _seek),
              AppGap.h10,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _position.toClock(),
                    style: TextStyles.getRegularStyle(
                      fontSize: FontSize.s20,
                      color: ColorManager.playerTimeText,
                    ),
                  ),
                  Text(
                    "-${(_duration - _position).toClock()}",
                    style: TextStyles.getRegularStyle(
                      fontSize: FontSize.s20,
                      color: ColorManager.playerTimeText,
                    ),
                  ),
                ],
              ),

              // * Lyrics preview
              if (lyricsLines != null && lyricsLines.isNotEmpty) ...[
                AppGap.h20,
                _LyricsPreview(
                  lines: lyricsLines,
                  // TODO open the full lyrics view
                  onTap: () {},
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  const _PlayerControls({
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    // TODO connect shuffle, skip and repeat to the AudioPlayerBloc
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.p10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlButton(icon: AssetsManager.shuffleIcon, onTap: () {}),
          _ControlButton(icon: AssetsManager.skipBackIcon, onTap: () {}),
          _ControlButton(
            icon: isPlaying
                ? AssetsManager.pauseButton
                : AssetsManager.playButton,
            size: AppSize.s56,
            onTap: onPlayPause,
          ),
          _ControlButton(icon: AssetsManager.skipForwardIcon, onTap: () {}),
          _ControlButton(
            icon: AssetsManager.repeatIcon,
            size: AppSize.s32,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String icon;
  final double size;
  final VoidCallback onTap;
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.size = AppSize.s24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SvgPicture.asset(icon, width: size, height: size),
    );
  }
}

class _LyricsPreview extends StatelessWidget {
  final List<String> lines;
  final VoidCallback onTap;
  const _LyricsPreview({
    required this.lines,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // * Upcoming lines, faded
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lines.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.getRegularStyle(
                fontSize: FontSize.s18,
                color: ColorManager.inactiveLyricsText,
              ),
            ),
            if (lines.length > 1) ...[
              AppGap.h20,
              Text(
                lines[1],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.getSemiBoldStyle(
                  fontSize: FontSize.s20,
                  color: ColorManager.inactiveLyricsText,
                ),
              ),
            ],
          ],
        ),

        // * Button to open the lyrics
        Positioned(
          bottom: -AppPadding.p10,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
          ),
        ),
      ],
    );
  }
}
