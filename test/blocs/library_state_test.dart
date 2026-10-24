import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/blocs/library/library_cubit.dart';

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
}
