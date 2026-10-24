import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../../data/tags/id3.dart';
import '../../widgets/appbar/appbar_widget.dart';
import '../../widgets/common/page_title/page_title.dart';
import '../home_screen/tidy_card.dart';

/// Every song whose tags carry channel stamps, as they are and as they'll
/// be, cleaned together after one OK from Android.
class TidyScreen extends StatefulWidget {
  const TidyScreen({super.key});

  @override
  State<TidyScreen> createState() => _TidyScreenState();
}

class _TidyScreenState extends State<TidyScreen> {
  final _skipped = <int>{};

  /// Songs cleaned so far while running, null while not.
  int? _done;
  int _total = 0;

  /// What happened, once it ran.
  String? _result;

  Future<void> _run(List<Song> songs) async {
    setState(() {
      _done = 0;
      _total = songs.length;
    });
    final failed = await context.read<LibraryCubit>().tidy(
      songs,
      onProgress: (done) {
        if (mounted) setState(() => _done = done);
      },
    );
    if (!mounted) return;
    final cleaned = songs.length - (failed?.length ?? songs.length);
    setState(() {
      _done = null;
      _result = failed == null
          ? 'Nothing changed: Stash needs your OK to change these files.'
          : [
              cleaned == 1 ? 'Cleaned 1 song.' : 'Cleaned $cleaned songs.',
              if (failed.isNotEmpty)
                "Couldn't save ${failed.map((s) => s.title).take(3).join(', ')}"
                    "${failed.length > 3 ? ' and ${failed.length - 3} more' : ''}.",
            ].join(' ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final songs = [
          for (final s in state.songs)
            if (state.fixes.containsKey(s.id)) s,
        ];
        final editable = [...songs.where((s) => s.canEditTags)];
        final locked = [...songs.where((s) => !s.canEditTags)];
        final chosen = [...editable.where((s) => !_skipped.contains(s.id))];
        final running = _done != null;

        return Scaffold(
          appBar: const AppBarWidget(isMainScreen: false),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppPadding.p20, AppPadding.p20, AppPadding.p20, AppPadding.p40),
            children: [
              PageTitle(
                title: 'Tidy up',
                subtitle: songs.isEmpty
                    ? 'Every tag is clean.'
                    : 'Only the tags change. The audio stays as it is.',
              ),
              if (_result != null) ...[
                AppGap.h16,
                Text(
                  _result!,
                  style: TextStyles.getMediumStyle(fontSize: FontSize.s16),
                ),
              ],
              if (state.channels.isNotEmpty) ...[
                AppGap.h20,
                Wrap(
                  spacing: AppSize.s8,
                  runSpacing: AppSize.s8,
                  children: [
                    for (final c in state.channels)
                      ChannelChip(name: c.name, songs: c.songs),
                  ],
                ),
              ],
              AppGap.h12,
              for (final song in editable)
                _FixRow(
                  song: song,
                  fix: state.fixes[song.id]!,
                  checked: !_skipped.contains(song.id),
                  onChanged: running
                      ? null
                      : (on) => setState(() => on
                          ? _skipped.remove(song.id)
                          : _skipped.add(song.id)),
                ),
              if (locked.isNotEmpty) ...[
                AppGap.h24,
                Text(
                  'Not MP3, so Stash can\'t change these',
                  style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s16),
                ),
                for (final song in locked)
                  _FixRow(song: song, fix: state.fixes[song.id]!),
              ],
            ],
          ),
          bottomNavigationBar: editable.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppPadding.p20,
                        AppPadding.p12, AppPadding.p20, AppPadding.p12),
                    child: running
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cleaning $_done of $_total',
                                style: TextStyles.getMediumStyle(
                                    fontSize: FontSize.s14),
                              ),
                              AppGap.h8,
                              LinearProgressIndicator(
                                value: _total == 0 ? null : _done! / _total,
                              ),
                            ],
                          )
                        : FilledButton(
                            onPressed:
                                chosen.isEmpty ? null : () => _run(chosen),
                            child: Text(chosen.length == 1
                                ? 'Clean 1 song'
                                : 'Clean ${chosen.length} songs'),
                          ),
                  ),
                ),
        );
      },
    );
  }
}

/// One song's tags before and after, field by field.
class _FixRow extends StatelessWidget {
  final Song song;
  final TagEdit fix;

  /// Null for songs that can't be changed.
  final bool? checked;
  final ValueChanged<bool>? onChanged;
  const _FixRow({
    required this.song,
    required this.fix,
    this.checked,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final changes = [
      if (fix.title != null) ('Title', song.title, fix.title!),
      if (fix.artist != null) ('Artist', song.artist, fix.artist!),
      if (fix.album != null) ('Album', song.album, fix.album!),
    ];
    final locked = checked == null;
    final label = TextStyles.getRegularStyle(
      fontSize: FontSize.s14,
      color: ColorManager.secondaryText,
    );
    final before = label.copyWith(decoration: TextDecoration.lineThrough);
    final after = TextStyles.getMediumStyle(
      fontSize: FontSize.s16,
      color: locked ? ColorManager.secondaryText : ColorManager.white,
    );
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!checked!),
      borderRadius: const BorderRadius.all(AppRadius.rad8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.p12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!locked)
              Checkbox(
                value: checked,
                onChanged:
                    onChanged == null ? null : (on) => onChanged!(on ?? false),
              ),
            if (!locked) AppGap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (name, old, cleaned) in changes) ...[
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '$name  '),
                        TextSpan(
                          text: old.isEmpty ? 'empty' : old,
                          style: old.isEmpty ? null : before,
                        ),
                      ]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: label,
                    ),
                    Text(cleaned, style: after),
                    AppGap.h4,
                  ],
                  if (locked)
                    Text(song.format,
                        style: TextStyles.getRegularStyle(
                          color: ColorManager.secondaryText,
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
