import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/blocs/library/library_cubit.dart';
import 'package:stash/src/data/library/local_store.dart';

import '../support/demo_library.dart';

void main() {
  late Directory dir;
  late File file;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('stash');
    file = File('${dir.path}/library.json');
  });
  tearDown(() => dir.delete(recursive: true));

  Future<LibraryCubit> start(DemoMusicLibrary library) async {
    final cubit = LibraryCubit(library: library, store: LocalStore(file));
    addTearDown(cubit.close);
    await cubit.start();
    return cubit;
  }

  // * Saves run one after the other, so saving the same state again waits
  // * for the ones the cubit started
  Future<Map<String, Object?>> saved(LibraryCubit cubit) async {
    await cubit.store.save(cubit.state.toJson());
    return LocalStore(file).load();
  }

  test('turns the media ids that Stash 0.2 saved into song keys', () async {
    file.writeAsStringSync(jsonEncode({
      'favorites': [3, 1, 404],
      'history': [2, 999],
      'playlists': [
        {
          'name': 'Gym',
          'songs': [1, 2]
        }
      ],
    }));
    final library = DemoMusicLibrary();
    final cubit = await start(library);

    final state = cubit.state;
    expect(state.favoriteSongs.map((s) => s.id), [1, 3]);
    expect(state.recentlyPlayed.map((s) => s.id), [2]);
    expect(state.songsFor(state.playlists.single.songKeys).map((s) => s.id),
        [1, 2]);

    final songs = await library.songs();
    expect((await saved(cubit))['favorites'], [
      songs[2].key,
      songs[0].key,
    ]);
  });

  test('waits for the permission before turning the ids into keys', () async {
    file.writeAsStringSync(jsonEncode({
      'favorites': [1],
    }));
    final library = DemoMusicLibrary(granted: false);
    final cubit = await start(library);
    expect(cubit.state.favorites, isEmpty);
    expect((await LocalStore(file).load())['favorites'], [1]);

    await cubit.allow();
    expect(cubit.state.favoriteSongs.map((s) => s.id), [1]);
    expect((await saved(cubit))['favorites'], [library.byTitle('Do I').key]);
  });

  test('remembers songs by key', () async {
    final library = DemoMusicLibrary();
    final cubit = await start(library);
    final song = library.byTitle('Get Lucky');
    cubit.toggleFavorite(song);
    cubit.markPlayed(song);
    cubit.createPlaylist('Gym', first: song);
    await saved(cubit);

    final again = await start(DemoMusicLibrary());
    expect(again.state.isFavorite(song), isTrue);
    expect(again.state.recentlyPlayed, [song]);
    expect(again.state.songsFor(again.state.playlists.single.songKeys), [song]);
  });
}
