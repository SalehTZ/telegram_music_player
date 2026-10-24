import 'dart:async';
import 'dart:typed_data';

import 'package:stash/src/data/library/music_library.dart';
import 'package:stash/src/data/models/song_model.dart';
import 'package:stash/src/data/tags/id3.dart';

const _telegram = '/storage/emulated/0/Music/Telegram';
const _downloads = '/storage/emulated/0/Download/Telegram';
const _music = '/storage/emulated/0/Music';

/// A small library the way Telegram leaves it: channel names stamped into
/// the tags, a file named "Artist - Title" with no tags at all, and a FLAC
/// Stash can't change. MP3s carry real ID3 tags, so edits run the real
/// writer.
class DemoMusicLibrary implements MusicLibrary {
  bool granted;
  Access answer;
  bool allowWrites;
  final Map<int, Uint8List> covers;

  int writeRequests = 0;
  int settingsOpened = 0;
  final _imports = StreamController<({List<String> saved, int failed})>();
  final _files = <int, Uint8List>{};
  late final List<Song> _songs;

  DemoMusicLibrary({
    this.granted = true,
    this.answer = Access.granted,
    this.allowWrites = true,
    bool persian = true,
    Map<int, Uint8List>? covers,
  }) : covers = covers ?? {} {
    var id = 0;
    final added = DateTime(2024, 6, 1);
    Song song(
      String folder,
      String file,
      String title,
      String artist,
      String album,
      int seconds, {
      String? lyrics,
    }) {
      id++;
      final path = '$folder/$file';
      if (file.endsWith('.mp3')) {
        _files[id] = writeId3(
          Uint8List.fromList([0xff, 0xfb, 0x90, 0x64, ...List.filled(64, 0)]),
          TagEdit(title: title, artist: artist, album: album, lyrics: lyrics),
        );
      }
      return Song(
        id: id,
        title: title,
        artist: artist,
        album: album,
        path: path,
        uri: 'content://media/external/audio/media/$id',
        duration: Duration(seconds: seconds),
        added: added.subtract(Duration(hours: id * 5)),
      );
    }

    _songs = [
      song(_telegram, 'Do I Wanna Know.mp3', 'Do I Wanna Know? @MusicArchive',
          'Arctic Monkeys', 'AM', 272,
          lyrics: "[00:12.50]Crawlin' back to you\n"
              "[00:16.20]Ever thought of callin' when"),
      song(_telegram, 'Get Lucky.mp3', 'Get Lucky',
          'Daft Punk | t.me/MusicArchive', 'Random Access Memories', 369),
      song(_telegram, 'Blinding Lights.mp3', 'Blinding Lights', 'The Weeknd',
          'After Hours', 200),
      song(
          _downloads,
          'Save Your Tears.mp3',
          'Save Your Tears (Join @NightTunes)',
          'The Weeknd',
          'After Hours',
          215),
      song(_downloads, 'Arctic Monkeys - R U Mine.mp3',
          'Arctic Monkeys - R U Mine', '', '', 201),
      if (persian)
        song(_telegram, 'Amire Bi Gazand.mp3', 'امیر بی گزند @PersianHits',
            'محسن چاوشی', '', 267),
      song(_downloads, 'Cruel Summer.mp3', 'Cruel Summer', 'Taylor Swift',
          'Lover @NightTunes', 178),
      song(_music, 'Happier Than Ever.mp3', 'Happier Than Ever',
          'Billie Eilish', 'Happier Than Ever', 298),
      song(_telegram, 'Instant Crush.flac', 'Instant Crush @MusicArchive',
          'Daft Punk', 'Random Access Memories', 337),
      song('$_music/Stash', 'Starboy.mp3', 'Starboy', 'The Weeknd', 'Starboy',
          230),
      song(_music, 'Midnight City.mp3', 'Midnight City', 'M83',
          "Hurry Up, We're Dreaming", 243),
    ];
  }

  Song byTitle(String start) =>
      _songs.firstWhere((s) => s.title.startsWith(start));

  /// Sends a "shared to Stash" result, like MainActivity does.
  void share(List<String> saved, {int failed = 0}) =>
      _imports.add((saved: saved, failed: failed));

  @override
  Stream<({List<String> saved, int failed})> get imports => _imports.stream;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<Access> requestPermission() async {
    granted = answer == Access.granted;
    return answer;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<List<Song>> songs() async => List.of(_songs);

  @override
  Future<Uint8List?> artwork(Song song, int size) async => covers[song.id];

  @override
  Future<Id3Tag?> readTag(Song song) async {
    final file = _files[song.id];
    return file == null ? null : readId3(file);
  }

  @override
  Future<bool> requestWriteAccess(List<Song> songs) async {
    writeRequests++;
    return allowWrites;
  }

  @override
  Future<void> writeTag(Song song, TagEdit edit) async {
    final file = _files[song.id];
    if (file == null) throw const Id3Exception('Not an MP3');
    final written = writeId3(file, edit);
    _files[song.id] = written;
    final tag = readId3(written)!;
    final i = _songs.indexWhere((s) => s.id == song.id);
    _songs[i] = Song(
      id: song.id,
      title: tag.title ?? '',
      artist: tag.artist ?? '',
      album: tag.album ?? '',
      path: song.path,
      uri: song.uri,
      duration: song.duration,
      added: song.added,
    );
    if (edit.cover != null) covers[song.id] = edit.cover!;
  }
}
