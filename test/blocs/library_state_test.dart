import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/blocs/library/library_cubit.dart';
import 'package:stash/src/data/models/song_model.dart';

import '../support/demo_library.dart';

void main() {
  late LibraryState state;
  setUp(() async {
    final songs = await DemoMusicLibrary().songs();
    String key(int id) => songs.firstWhere((s) => s.id == id).key;
    state = LibraryState(
      songs: songs,
      favorites: [key(3), key(1), '/storage/emulated/0/Music/gone.mp3'],
      history: [key(2), '/storage/emulated/0/Music/gone.mp3', key(1)],
    );
  });

  test('counts each channel once per song, whatever its case or link', () {
    expect(state.channels, [
      (name: '@MusicArchive', songs: 3),
      (name: '@NightTunes', songs: 2),
      (name: '@PersianHits', songs: 1),
    ]);
  });

  test('lists Telegram folders first', () {
    expect(state.folders.map((f) => f.name), [
      '/storage/emulated/0/Music/Telegram',
      '/storage/emulated/0/Download/Telegram',
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Music/Stash',
    ]);
  });

  test('groups artists by their cleaned name', () {
    final daftPunk = state.artists.firstWhere((a) => a.name == 'Daft Punk');
    expect(daftPunk.songs, hasLength(2));
    expect(state.artists.first.name, 'The Weeknd');
    expect(state.artists.any((a) => a.name.isEmpty), isFalse);
  });

  test('skips songs that are gone from the phone', () {
    expect(state.favoriteSongs.map((s) => s.id), [1, 3]);
    expect(state.recentlyPlayed.map((s) => s.id), [2, 1]);
  });

  test('finds what to fix, MP3 or not', () {
    expect(state.fixes, hasLength(7));
    expect(state.fixes[3], isNull, reason: 'Blinding Lights is clean');
  });

  test('groups copies of a song, the best first', () {
    expect(state.duplicates, hasLength(1));
    final copies = state.duplicates.single;
    expect(copies.map((s) => s.bitrate), [320, 128]);
    expect(copies.map((s) => s.title).toSet(), {'Blinding Lights'});
  });

  test('copies need the same name and about the same length', () {
    Song song(int id, String title, String artist, int seconds,
            {int kbps = 128, String format = 'mp3'}) =>
        Song(
          id: id,
          title: title,
          artist: artist,
          album: '',
          path: '/m/$id.$format',
          uri: 'content://$id',
          duration: Duration(seconds: seconds),
          added: DateTime(2024),
          size: seconds * kbps * 125,
        );
    final groups = LibraryState(songs: [
      song(1, 'Song @Channel', 'Band', 200),
      song(2, 'SONG', 'band', 202, kbps: 320),
      song(3, 'Song', 'Band', 201, format: 'flac', kbps: 900),
      song(4, 'Song', 'Band', 260), // * A live version, longer
      song(5, 'Song (Remix)', 'Band', 200),
      song(6, 'Band - Song', '', 200),
    ]).duplicates;
    expect(groups.single.map((s) => s.id), [3, 2, 1, 6]);
  });
}
