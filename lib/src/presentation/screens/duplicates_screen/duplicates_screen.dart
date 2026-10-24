import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../widgets/appbar/appbar_widget.dart';
import '../../widgets/common/page_title/page_title.dart';

/// Songs saved more than once, with every copy but the best one picked to
/// be deleted together after one OK from Android.
class DuplicatesScreen extends StatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  State<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<DuplicatesScreen> {
  /// The copy to keep in each group, by the group's first song. Unset
  /// groups keep their first (best) copy.
  final _kept = <Song, Song>{};

  /// Copies the user chose to keep as well.
  final _spared = <Song>{};
  bool _deleting = false;
  String? _result;

  Future<void> _delete(Map<Song, Song> keeping) async {
    setState(() => _deleting = true);
    final error = await context.read<LibraryCubit>().deleteCopies(keeping);
    if (!mounted) return;
    setState(() {
      _deleting = false;
      _kept.clear();
      _spared.clear();
      _result = error ??
          (keeping.length == 1
              ? 'Deleted 1 copy.'
              : 'Deleted ${keeping.length} copies.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final groups = state.duplicates;
        final keeping = <Song, Song>{
          for (final group in groups)
            for (final copy in group)
              if (copy != (_kept[group.first] ?? group.first) &&
                  !_spared.contains(copy))
                copy: _kept[group.first] ?? group.first,
        };

        return Scaffold(
          appBar: const AppBarWidget(isMainScreen: false),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppPadding.p20, AppPadding.p20, AppPadding.p20, AppPadding.p40),
            children: [
              PageTitle(
                title: 'Duplicates',
                subtitle: groups.isEmpty
                    ? 'Every song is saved once.'
                    : 'The best copy of each is kept: lossless first, then '
                        'the higher bitrate. Tap a copy to keep it instead.',
              ),
              if (_result != null) ...[
                AppGap.h16,
                Text(
                  _result!,
                  style: TextStyles.getMediumStyle(fontSize: FontSize.s16),
                ),
              ],
              for (final group in groups) ...[
                AppGap.h24,
                Text(
                  [group.first.title, group.first.artist]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s16),
                ),
                for (final copy in group)
                  _CopyRow(
                    song: copy,
                    kept: copy == (_kept[group.first] ?? group.first),
                    delete: keeping.containsKey(copy),
                    onKeep: _deleting
                        ? null
                        : () => setState(() => _kept[group.first] = copy),
                    onDelete: _deleting
                        ? null
                        : (on) => setState(() =>
                            on ? _spared.remove(copy) : _spared.add(copy)),
                  ),
              ],
            ],
          ),
          bottomNavigationBar: groups.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppPadding.p20,
                        AppPadding.p12, AppPadding.p20, AppPadding.p12),
                    child: FilledButton(
                      onPressed: keeping.isEmpty || _deleting
                          ? null
                          : () => _delete(keeping),
                      child: Text(keeping.length == 1
                          ? 'Delete 1 copy'
                          : 'Delete ${keeping.length} copies'),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// One copy: where it is and how good it is, kept or picked for deleting.
class _CopyRow extends StatelessWidget {
  final Song song;
  final bool kept;
  final bool delete;
  final VoidCallback? onKeep;
  final ValueChanged<bool>? onDelete;
  const _CopyRow({
    required this.song,
    required this.kept,
    required this.delete,
    this.onKeep,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final detail = TextStyles.getRegularStyle(
      fontSize: FontSize.s14,
      color: ColorManager.secondaryText,
    );
    final quality = [
      song.format,
      if (song.bitrate > 0) '${song.bitrate} kbps',
      if (song.size > 0) '${(song.size / (1 << 20)).toStringAsFixed(1)} MB',
    ].join(' · ');
    return InkWell(
      onTap: kept ? null : onKeep,
      borderRadius: const BorderRadius.all(AppRadius.rad8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.p12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.path.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.getMediumStyle(
                      fontSize: FontSize.s16,
                      color: delete
                          ? ColorManager.secondaryText
                          : ColorManager.white,
                    ).copyWith(
                        decoration: delete ? TextDecoration.lineThrough : null),
                  ),
                  Text(quality, style: detail),
                  Text(song.folder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: detail),
                ],
              ),
            ),
            AppGap.w12,
            if (kept)
              Text(
                'Keep',
                style: TextStyles.getSemiBoldStyle(
                  fontSize: FontSize.s14,
                  color: ColorManager.primaryPressedColor,
                ),
              )
            else
              Checkbox(
                value: delete,
                onChanged:
                    onDelete == null ? null : (on) => onDelete!(on ?? false),
              ),
          ],
        ),
      ),
    );
  }
}
