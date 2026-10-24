import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/library/artwork_cache.dart';
import '../../data/library/local_store.dart';
import '../../data/library/music_library.dart';
import '../../data/lyrics/lyrics.dart';
import '../../data/models/song_model.dart';
import '../../data/tags/id3.dart';
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
    emit(state.copyWith(
      favorites: (saved['favorites'] as List?)?.cast<int>(),
      history: (saved['history'] as List?)?.cast<int>(),
      playlists: [
        for (final p in (saved['playlists'] as List? ?? const []).cast<Map>())
          Playlist(p['name'] as String, (p['songs'] as List).cast<int>()),
      ],
    ));
    _imports = library.imports.listen(_onImported);
    await refresh();
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
            ? [...state.favorites.where((id) => id != song.id)]
            : [...state.favorites, song.id],
      ));

  void markPlayed(Song song) => _change(state.copyWith(
        history: [
          song.id,
          ...state.history.where((id) => id != song.id).take(99),
        ],
      ));

  /// Adds a playlist and returns it. Names stay unique: a second "Gym"
  /// becomes "Gym 2".
  Playlist createPlaylist(String name, {Song? first}) {
    var unique = name.trim();
    for (var n = 2; state.playlists.any((p) => p.name == unique); n++) {
      unique = '${name.trim()} $n';
    }
    final playlist = Playlist(unique, [if (first != null) first.id]);
    _change(state.copyWith(playlists: [...state.playlists, playlist]));
    return playlist;
  }

  void deletePlaylist(Playlist playlist) => _change(state.copyWith(
        playlists: [...state.playlists.where((p) => p != playlist)],
      ));

  void addToPlaylist(Playlist playlist, Song song) =>
      _replacePlaylist(playlist, [
        ...playlist.songIds.where((id) => id != song.id),
        song.id,
      ]);

  void removeFromPlaylist(Playlist playlist, Song song) => _replacePlaylist(
      playlist, [...playlist.songIds.where((id) => id != song.id)]);

  void _replacePlaylist(Playlist playlist, List<int> songIds) =>
      _change(state.copyWith(playlists: [
        for (final p in state.playlists)
          p == playlist ? Playlist(p.name, songIds) : p,
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
    } on Id3Exception catch (e) {
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
    if (!await library.requestWriteAccess(songs)) return null;
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
