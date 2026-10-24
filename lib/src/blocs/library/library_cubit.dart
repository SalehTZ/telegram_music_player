import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/library/artwork_cache.dart';
import '../../data/library/local_store.dart';
import '../../data/library/music_library.dart';
import '../../data/lyrics/lyrics.dart';
import '../../data/models/song_model.dart';
import '../../data/tags/tags.dart';
import '../../data/tags/tag_cleaner.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final MusicLibrary library;
  final LocalStore store;
  final ArtworkCache artwork;
  final _notices = StreamController<String>.broadcast();
  StreamSubscription? _imports;

  LibraryCubit({required this.library, required this.store})
      : artwork = ArtworkCache(library),
        super(LibraryState());

  /// One-line messages for a snack bar, like the result of an import.
  Stream<String> get notices => _notices.stream;

  Future<void> start() async {
    final saved = await store.load();
    // * Stash 0.2 and older saved media ids, which only make sense once the
    // * songs are loaded
    if (_savesIds(saved)) {
      _legacy = saved;
    } else {
      emit(_restore(saved, (key) => key as String));
    }
    _imports = library.imports.listen(_onImported);
    await refresh();
  }

  Map<String, Object?>? _legacy;

  static bool _savesIds(Map<String, Object?> saved) => [
        ...(saved['favorites'] as List? ?? const []),
        ...(saved['history'] as List? ?? const []),
        for (final p in (saved['playlists'] as List? ?? const []).cast<Map>())
          ...(p['songs'] as List),
      ].any((key) => key is int);

  /// [saved] read into the state, each song turned into its key by [keyOf],
  /// which gives null for a song that's gone.
  LibraryState _restore(
    Map<String, Object?> saved,
    String? Function(Object? key) keyOf,
  ) {
    List<String> keys(Object? list) => [
          for (final key in (list as List? ?? const []))
            if (keyOf(key) case final key?) key
        ];
    return state.copyWith(
      favorites: keys(saved['favorites']),
      history: keys(saved['history']),
      playlists: [
        for (final p in (saved['playlists'] as List? ?? const []).cast<Map>())
          Playlist(p['name'] as String, keys(p['songs'])),
      ],
    );
  }

  /// Loads the songs again, or waits for the permission while it's missing.
  Future<void> refresh() async {
    try {
      if (!await library.hasPermission()) {
        if (state.status != LibraryStatus.blocked) {
          emit(state.copyWith(status: LibraryStatus.needsPermission));
        }
        return;
      }
      final songs = await library.songs();
      emit(state.copyWith(status: LibraryStatus.ready, songs: songs));
      if (_legacy case final legacy?) {
        _legacy = null;
        final keys = {for (final s in songs) s.id: s.key};
        _change(_restore(legacy, (id) => keys[id]));
      }
    } on PlatformException {
      emit(state.copyWith(status: LibraryStatus.failed));
    }
  }

  Future<void> allow() async {
    switch (await library.requestPermission()) {
      case Access.granted:
        await refresh();
      case Access.denied:
        emit(state.copyWith(status: LibraryStatus.needsPermission));
      case Access.blocked:
        emit(state.copyWith(status: LibraryStatus.blocked));
    }
  }

  Future<void> openSettings() => library.openSettings();

  void toggleFavorite(Song song) => _change(state.copyWith(
        favorites: state.isFavorite(song)
            ? [...state.favorites.where((key) => key != song.key)]
            : [...state.favorites, song.key],
      ));

  void markPlayed(Song song) => _change(state.copyWith(
        history: [
          song.key,
          ...state.history.where((key) => key != song.key).take(99),
        ],
      ));

  /// Adds a playlist and returns it. Names stay unique: a second "Gym"
  /// becomes "Gym 2".
  Playlist createPlaylist(String name, {Song? first}) {
    var unique = name.trim();
    for (var n = 2; state.playlists.any((p) => p.name == unique); n++) {
      unique = '${name.trim()} $n';
    }
    final playlist = Playlist(unique, [if (first != null) first.key]);
    _change(state.copyWith(playlists: [...state.playlists, playlist]));
    return playlist;
  }

  void deletePlaylist(Playlist playlist) => _change(state.copyWith(
        playlists: [...state.playlists.where((p) => p != playlist)],
      ));

  void addToPlaylist(Playlist playlist, Song song) =>
      _replacePlaylist(playlist, [
        ...playlist.songKeys.where((key) => key != song.key),
        song.key,
      ]);

  void removeFromPlaylist(Playlist playlist, Song song) => _replacePlaylist(
      playlist, [...playlist.songKeys.where((key) => key != song.key)]);

  void _replacePlaylist(Playlist playlist, List<String> songKeys) =>
      _change(state.copyWith(playlists: [
        for (final p in state.playlists)
          p == playlist ? Playlist(p.name, songKeys) : p,
      ]));

  void _change(LibraryState next) {
    emit(next);
    store.save(next.toJson());
  }

  /// The lyrics saved in the song's file, if it has any.
  Future<Lyrics?> lyricsFor(Song song) async {
    try {
      final text = (await library.readTag(song))?.lyrics;
      final lyrics = text == null ? null : Lyrics.parse(text);
      return lyrics == null || lyrics.isEmpty ? null : lyrics;
    } on Exception {
      return null;
    }
  }

  /// Writes [edit] into the song's file. Returns why it failed, or null.
  Future<String?> editTags(Song song, TagEdit edit) async {
    try {
      if (!await library.requestWriteAccess([song])) {
        return 'Stash needs your OK to change this file.';
      }
      await library.writeTag(song, edit);
      if (edit.cover != null) artwork.replace(song, edit.cover);
      await refresh();
      return null;
    } on TagException catch (e) {
      return e.message;
    } on PlatformException catch (e) {
      return e.message ?? "Couldn't save the file.";
    } on FileSystemException catch (e) {
      return "Couldn't read the file: ${e.message}";
    }
  }

  /// Takes the channel stamps out of [songs], asking once for all of them.
  /// Null when the user said no; otherwise the songs that couldn't be saved.
  Future<List<Song>?> tidy(
    List<Song> songs, {
    required void Function(int done) onProgress,
  }) async {
    try {
      if (!await library.requestWriteAccess(songs)) return null;
    } on PlatformException {
      return null;
    }
    final failed = <Song>[];
    for (final (i, song) in songs.indexed) {
      final fix = state.fixes[song.id];
      if (fix != null) {
        try {
          await library.writeTag(song, fix);
        } on Exception {
          failed.add(song);
        }
      }
      onProgress(i + 1);
    }
    await refresh();
    return failed;
  }

  void _onImported(({List<String> saved, int failed}) result) {
    refresh();
    final saved = result.saved;
    _notices.add([
      if (saved.length == 1) 'Saved ${saved.single} to Music/Stash',
      if (saved.length > 1) 'Saved ${saved.length} songs to Music/Stash',
      if (result.failed > 0)
        "Couldn't save ${result.failed} ${result.failed == 1 ? 'file' : 'files'}",
    ].join('. '));
  }

  @override
  Future<void> close() {
    _imports?.cancel();
    _notices.close();
    return super.close();
  }
}
