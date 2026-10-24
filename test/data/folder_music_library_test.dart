import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/data/library/folder_music_library.dart';
import 'package:stash/src/data/tags/tags.dart';

void main() {
  late Directory dir;
  late Directory music;
  late File cache;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('stash');
    music = await Directory('${dir.path}/Music/Telegram Desktop')
        .create(recursive: true);
    for (final name in ['sine.flac', 'sine_vbr.mp3', 'sine.m4a']) {
      await File('test/fixtures/$name').copy('${music.path}/$name');
    }
    await File('${music.path}/notes.txt').writeAsString('not a song');
    cache = File('${dir.path}/scan.json');
  });
  tearDown(() => dir.delete(recursive: true));

  FolderMusicLibrary library() =>
      FolderMusicLibrary([Directory('${dir.path}/Music')], cache: cache);

  test('lists the songs in its folders with their tags', () async {
    final songs = await library().songs();
    expect(songs.map((s) => s.fileName).toSet(),
        {'sine.flac', 'sine_vbr.mp3', 'sine.m4a'});
    for (final song in songs) {
      expect(song.title, 'Song@Channel');
      expect(song.artist, 'Band');
      expect(song.duration, greaterThan(const Duration(milliseconds: 900)));
      expect(song.fromTelegram, isTrue);
      expect(Uri.parse(song.uri).toFilePath(), song.path);
    }
  });

  test('only reads files again when they changed', () async {
    await library().songs();
    final saved = jsonDecode(cache.readAsStringSync()) as Map;
    final flac = saved.keys.firstWhere((k) => (k as String).endsWith('.flac'));
    saved[flac]['title'] = 'From the cache';
    cache.writeAsStringSync(jsonEncode(saved));

    var songs = await library().songs();
    expect(songs.firstWhere((s) => s.format == 'FLAC').title, 'From the cache');

    await File(flac).setLastModified(DateTime(2030));
    songs = await library().songs();
    expect(songs.firstWhere((s) => s.format == 'FLAC').title, 'Song@Channel');
  });

  test('writes tags in place and keeps ids across rescans', () async {
    final songs = library();
    final first = await songs.songs();
    for (final song in first) {
      final before = File(song.path).lengthSync();
      await songs.writeTag(song, const TagEdit(title: 'Song'));
      expect(File(song.path).lengthSync(), before, reason: song.fileName);
      expect((await songs.readTag(song))!.title, 'Song');
    }
    final again = await songs.songs();
    expect(again.map((s) => s.id).toSet(), first.map((s) => s.id).toSet());
    expect(again.map((s) => s.title).toSet(), {'Song'});
  });

  test('rewrites the whole file when the tags grow', () async {
    final songs = library();
    final mp3 = (await songs.songs()).firstWhere((s) => s.format == 'MP3');
    final cover = File('test/fixtures/sine.flac').readAsBytesSync();
    await songs.writeTag(mp3, TagEdit(lyrics: 'x' * 5000, cover: cover));
    expect((await songs.readTag(mp3))!.lyrics, 'x' * 5000);
    expect(File('${mp3.path}.stash-tmp').existsSync(), isFalse);
  });

  test('deletes songs', () async {
    final songs = library();
    final flac = (await songs.songs()).firstWhere((s) => s.format == 'FLAC');
    expect(await songs.delete([flac]), isTrue);
    expect((await songs.songs()).map((s) => s.format), isNot(contains('FLAC')));
  });

  test('a missing folder is skipped', () async {
    final songs =
        await FolderMusicLibrary([Directory('${dir.path}/nowhere')]).songs();
    expect(songs, isEmpty);
  });
}
