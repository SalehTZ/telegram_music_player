import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/library/artwork_cache.dart';
import '../../../data/models/song_model.dart';
import '../../../data/tags/tags.dart';
import '../../../data/tags/tag_cleaner.dart';
import '../../layout.dart';
import '../../widgets/appbar/appbar_widget.dart';
import '../../widgets/common/artwork/artwork_image.dart';
import '../../widgets/common/page_title/page_title.dart';
import 'cover_search_screen.dart';

/// Title, artist, album, year, genre, lyrics and cover of one song.
class EditTagsScreen extends StatefulWidget {
  final Song song;
  const EditTagsScreen({super.key, required this.song});

  @override
  State<EditTagsScreen> createState() => _EditTagsScreenState();
}

class _EditTagsScreenState extends State<EditTagsScreen> {
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _album = TextEditingController();
  final _year = TextEditingController();
  final _genre = TextEditingController();
  final _lyrics = TextEditingController();

  /// What the file says now, to only write the fields that changed.
  Map<TextEditingController, String> _before = {};
  Uint8List? _newCover;
  bool _loading = true;
  bool _saving = false;

  /// The tag couldn't be read, so it can't be safely rewritten either.
  bool _locked = false;
  String? _error;

  Song get song => widget.song;
  List<TextEditingController> get _fields =>
      [_title, _artist, _album, _year, _genre, _lyrics];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    SongTag? tag;
    try {
      tag = await context.read<LibraryCubit>().library.readTag(song);
    } on Exception catch (e) {
      _locked = true;
      _error = e is TagException
          ? "${e.message}, so Stash can't change this file."
          : "Couldn't read the file's tags.";
    }
    if (!mounted) return;
    _before = {
      _title: tag?.title ?? song.title,
      _artist: tag?.artist ?? song.artist,
      _album: tag?.album ?? song.album,
      _year: tag?.year ?? '',
      _genre: tag?.genre ?? '',
      _lyrics: tag?.lyrics ?? '',
    };
    for (final MapEntry(key: field, value: text) in _before.entries) {
      field.text = text;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  /// Fills in the fields without the channel stamps.
  void _clean() {
    final fix = TagCleaner.fixFor(
      title: _title.text,
      artist: _artist.text,
      album: _album.text,
    );
    if (fix == null) return;
    setState(() {
      if (fix.title != null) _title.text = fix.title!;
      if (fix.artist != null) _artist.text = fix.artist!;
      if (fix.album != null) _album.text = fix.album!;
    });
  }

  Future<void> _findCover() async {
    final query = [
      TagCleaner.clean(_artist.text),
      TagCleaner.clean(_album.text)
    ]
        .where((s) => s.isNotEmpty && !s.toLowerCase().contains('telegram'))
        .join(' ');
    final cover = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => ReadableWidth(
          child: CoverSearchScreen(
            query: query.isEmpty ? TagCleaner.clean(_title.text) : query,
          ),
        ),
      ),
    );
    if (cover != null && mounted) setState(() => _newCover = cover);
  }

  Future<void> _save() async {
    String? changed(TextEditingController field) =>
        field.text.trim() == _before[field] ? null : field.text.trim();
    final edit = TagEdit(
      title: changed(_title),
      artist: changed(_artist),
      album: changed(_album),
      year: changed(_year),
      genre: changed(_genre),
      lyrics: changed(_lyrics),
      cover: _newCover,
    );
    if (edit.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<LibraryCubit>().editTags(song, edit);
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved')));
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editable = song.canEditTags && !_saving && !_locked;
    final hasStamps = _title.text.isNotEmpty &&
        TagCleaner.fixFor(
              title: _title.text,
              artist: _artist.text,
              album: _album.text,
            ) !=
            null;
    return Scaffold(
      appBar: const AppBarWidget(isMainScreen: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppPadding.p20, AppPadding.p20,
                  AppPadding.p20, AppPadding.p40),
              children: [
                PageTitle(
                  title: song.canEditTags ? 'Edit tags' : 'Tags',
                  subtitle: song.fileName,
                ),
                if (!song.canEditTags) ...[
                  AppGap.h16,
                  _Notice(
                    text: 'Stash can change the tags of MP3, FLAC, Ogg, '
                        'Opus and M4A files. This one is ${song.format}.',
                  ),
                ],
                if (song.canEditTags && hasStamps) ...[
                  AppGap.h16,
                  _Notice(
                    text:
                        'These tags carry channel or website names, or garbled text.',
                    action: TextButton(
                      onPressed: editable ? _clean : null,
                      child: const Text('Take them out'),
                    ),
                  ),
                ],
                AppGap.h24,
                // * Cover, with the new one shown before it is saved
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox.square(
                      dimension: AppSize.s136,
                      child: _newCover == null
                          ? ArtworkImage(
                              song: song,
                              quality: ArtworkSize.large,
                              borderRadius:
                                  const BorderRadius.all(AppRadius.rad12),
                            )
                          : ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(AppRadius.rad12),
                              child:
                                  Image.memory(_newCover!, fit: BoxFit.cover),
                            ),
                    ),
                    AppGap.w16,
                    if (song.canEditTags)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_newCover != null) ...[
                              Text(
                                'New cover, saved with the tags',
                                style: TextStyles.getRegularStyle(
                                  color: ColorManager.secondaryText,
                                ),
                              ),
                              AppGap.h8,
                            ],
                            OutlinedButton(
                              onPressed: editable ? _findCover : null,
                              child: const Text('Find a cover'),
                            ),
                            if (_newCover != null)
                              TextButton(
                                onPressed: editable
                                    ? () => setState(() => _newCover = null)
                                    : null,
                                child: const Text('Keep the old one'),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                AppGap.h24,
                _Field(label: 'Title', controller: _title, enabled: editable),
                _Field(label: 'Artist', controller: _artist, enabled: editable),
                _Field(label: 'Album', controller: _album, enabled: editable),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Year',
                        controller: _year,
                        enabled: editable,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    AppGap.w12,
                    Expanded(
                      flex: 2,
                      child: _Field(
                        label: 'Genre',
                        controller: _genre,
                        enabled: editable,
                      ),
                    ),
                  ],
                ),
                _Field(
                  label: 'Lyrics',
                  controller: _lyrics,
                  enabled: editable,
                  lines: 6,
                ),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyles.getRegularStyle(
                      fontSize: FontSize.s14,
                      color: ColorManager.likeButtonColor,
                    ),
                  ),
                  AppGap.h12,
                ],
                if (song.canEditTags)
                  FilledButton(
                    onPressed: editable ? _save : null,
                    child: Text(_saving ? 'Saving…' : 'Save'),
                  ),
              ],
            ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final int lines;
  final TextInputType? keyboardType;
  const _Field({
    required this.label,
    required this.controller,
    required this.enabled,
    this.lines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.p12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        minLines: lines,
        maxLines: lines == 1 ? 1 : 12,
        keyboardType: keyboardType,
        style: TextStyles.getRegularStyle(fontSize: FontSize.s16),
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: lines > 1,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final Widget? action;
  const _Notice({required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppPadding.p16, AppPadding.p12, AppPadding.p8, AppPadding.p12),
      decoration: const BoxDecoration(
        color: ColorManager.searchBarBackground,
        borderRadius: BorderRadius.all(AppRadius.rad12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyles.getRegularStyle(fontSize: FontSize.s14),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
