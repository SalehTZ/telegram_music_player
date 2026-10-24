import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stash/src/blocs/player/player_cubit.dart';
import 'package:stash/src/data/models/song_model.dart';

import '../support/demo_library.dart';
import '../support/fake_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Song> songs;
  late List<String> started;
  late PlayerCubit player;

  setUp(() async {
    songs = (await DemoMusicLibrary().songs()).take(4).toList();
    started = [];
    player = PlayerCubit(
      player: fakeAudioPlayer(),
      onSongStarted: (s) => started.add(s.title),
    );
  });
  tearDown(() => player.close());

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 50));

  test('plays a list from a song and moves through it', () async {
    await player.play(songs, 1);
    await settle();
    expect(player.state.song, songs[1]);
    expect(player.state.playing, isTrue);

    player.next();
    await settle();
    expect(player.state.song, songs[2]);

    player.previous();
    await settle();
    expect(player.state.song, songs[1]);
    // * Going back plays it again, so it counts again
    expect(started, [songs[1].title, songs[2].title, songs[1].title]);
  });

  test('plays a song next without losing the queue', () async {
    await player.play(songs, 0);
    await player.playNext(songs[3]);
    expect(player.state.queue.map((s) => s.id), [
      songs[0].id,
      songs[3].id,
      ...songs.skip(1).map((s) => s.id),
    ]);
  });

  test('repeat goes from off to all to one and back', () async {
    await player.play(songs, 0);
    final seen = <LoopMode>[];
    for (var i = 0; i < 3; i++) {
      player.cycleLoop();
      await settle();
      seen.add(player.state.loop);
    }
    expect(seen, [LoopMode.all, LoopMode.one, LoopMode.off]);
  });

  test('queued songs pick up their edited tags', () async {
    await player.play(songs, 0);
    final edited = Song(
      id: songs[0].id,
      title: 'Edited',
      artist: '',
      album: '',
      path: songs[0].path,
      uri: songs[0].uri,
      duration: songs[0].duration,
      added: songs[0].added,
    );
    player.refresh((id) => id == edited.id ? edited : null);
    expect(player.state.song!.title, 'Edited');
  });
}
