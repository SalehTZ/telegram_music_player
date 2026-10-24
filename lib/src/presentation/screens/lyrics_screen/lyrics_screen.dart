import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../blocs/player/player_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/lyrics/lyrics.dart';
import '../../../data/models/song_model.dart';
import '../../../data/online/lyrics_search.dart';
import '../../../data/tags/id3.dart';
import '../../../data/tags/tag_cleaner.dart';
import '../../widgets/appbar/appbar_widget.dart';
import '../../widgets/common/page_title/page_title.dart';

enum _Search { idle, searching, notFound, failed }

/// A song's lyrics, following along when they are timed, with a search on
/// LRCLIB when the file has none.
class LyricsScreen extends StatefulWidget {
  final Song song;
  final Lyrics? lyrics;
  final ValueChanged<Lyrics>? onFound;
  const LyricsScreen({
    super.key,
    required this.song,
    required this.lyrics,
    this.onFound,
  });

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  late Lyrics? _lyrics = widget.lyrics;
  _Search _search = _Search.idle;
  bool _fromWeb = false;
  bool _saving = false;
  final _lineKeys = <GlobalKey>[];
  int _shownLine = -1;

  Song get song => widget.song;

  Future<void> _find() async {
    setState(() => _search = _Search.searching);
    try {
      final found = await LyricsSearch.find(
        title: TagCleaner.clean(song.title),
        artist: TagCleaner.clean(song.artist),
        album: TagCleaner.clean(song.album),
        duration: song.duration,
      );
      if (!mounted) return;
      if (found == null) {
        setState(() => _search = _Search.notFound);
        return;
      }
      setState(() {
        _lyrics = found;
        _fromWeb = true;
        _search = _Search.idle;
      });
      widget.onFound?.call(found);
    } on Exception {
      if (mounted) setState(() => _search = _Search.failed);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await context
        .read<LibraryCubit>()
        .editTags(song, TagEdit(lyrics: _lyrics!.format()));
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (error == null) _fromWeb = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Saved the lyrics into the song')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = _lyrics;
    return Scaffold(
      appBar: const AppBarWidget(isMainScreen: false),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppPadding.p20, AppPadding.p20, AppPadding.p20, 0),
              child: PageTitle(
                title: song.title,
                subtitle: song.artistOrUnknown,
              ),
            ),
            Expanded(
              child: lyrics == null ? _searchState() : _lines(lyrics),
            ),
            if (_fromWeb) _saveBar(),
          ],
        ),
      ),
    );
  }

  Widget _lines(Lyrics lyrics) {
    final player = context.read<PlayerCubit>();
    final playing = player.state.song?.id == song.id;
    if (lyrics.timed.isEmpty || !playing) {
      return _LineList(
        lines: lyrics.lines,
        current: -1,
        dimmed: false,
        keys: _keysFor(lyrics.lines.length),
      );
    }
    return StreamBuilder<Duration>(
      stream: player.position,
      initialData: player.positionNow,
      builder: (context, snapshot) {
        final current = lyrics.lineAt(snapshot.data ?? Duration.zero);
        if (current != _shownLine && current >= 0) {
          _shownLine = current;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final line = _lineKeys[current].currentContext;
            if (line != null) {
              Scrollable.ensureVisible(
                line,
                alignment: 0.3,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
        return _LineList(
          lines: lyrics.lines,
          current: current,
          dimmed: true,
          keys: _keysFor(lyrics.lines.length),
          onTapLine: (i) => player.seek(lyrics.timed[i].time),
        );
      },
    );
  }

  List<GlobalKey> _keysFor(int count) {
    while (_lineKeys.length < count) {
      _lineKeys.add(GlobalKey());
    }
    return _lineKeys;
  }

  Widget _searchState() {
    final grey = TextStyles.getRegularStyle(
      fontSize: FontSize.s16,
      color: ColorManager.secondaryText,
    );
    final (message, button) = switch (_search) {
      _Search.idle => ('There are no lyrics in this file.', 'Search LRCLIB'),
      _Search.searching => ('Searching LRCLIB…', null),
      _Search.notFound => ('LRCLIB has no lyrics for this song.', null),
      _Search.failed => (
          "Couldn't reach LRCLIB. Check your connection.",
          'Try again'
        ),
    };
    return ListView(
      padding: const EdgeInsets.all(AppPadding.p20),
      children: [
        Text(message, style: grey),
        AppGap.h20,
        if (_search == _Search.searching)
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: CircularProgressIndicator(),
          ),
        if (button != null) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(onPressed: _find, child: Text(button)),
          ),
          AppGap.h12,
          Text(
            'This sends the title and artist to lrclib.net.',
            style: TextStyles.getRegularStyle(
              color: ColorManager.secondaryText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _saveBar() {
    return Container(
      padding: const EdgeInsets.all(AppPadding.p20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ColorManager.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              song.canEditTags
                  ? 'Found on LRCLIB'
                  : 'Found on LRCLIB. Stash can save lyrics into MP3 files only.',
              style: TextStyles.getRegularStyle(
                fontSize: FontSize.s14,
                color: ColorManager.secondaryText,
              ),
            ),
          ),
          if (song.canEditTags) ...[
            AppGap.w12,
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save to song'),
            ),
          ],
        ],
      ),
    );
  }
}

class _LineList extends StatelessWidget {
  final List<String> lines;

  /// The line being sung, or -1.
  final int current;

  /// Timed lyrics fade the lines that aren't being sung.
  final bool dimmed;
  final List<GlobalKey> keys;
  final ValueChanged<int>? onTapLine;
  const _LineList({
    required this.lines,
    required this.current,
    required this.dimmed,
    required this.keys,
    this.onTapLine,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppPadding.p20, AppPadding.p24, AppPadding.p20, AppPadding.p40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, line) in lines.indexed)
            GestureDetector(
              key: keys[i],
              behavior: HitTestBehavior.opaque,
              onTap: onTapLine == null ? null : () => onTapLine!(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppPadding.p8),
                child: Text(
                  line,
                  style: dimmed
                      ? TextStyles.getSemiBoldStyle(
                          fontSize: FontSize.s24,
                          color: i == current
                              ? ColorManager.white
                              : ColorManager.inactiveLyricsText,
                        )
                      : TextStyles.getMediumStyle(fontSize: FontSize.s18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
