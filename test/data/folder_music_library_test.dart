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

  FolderMusicLibrary library({File? settings}) {
    final library = FolderMusicLibrary([Directory('${dir.path}/Music')],
        cache: cache, settings: settings);
    addTearDown(library.dispose);
    return library;
  }

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

  test('a folder it can\'t open is skipped, not the whole scan', () async {
    final locked = await Directory('${music.path}/Locked').create();
    await File('test/fixtures/sine.ogg').copy('${locked.path}/sine.ogg');
    await Process.run('chmod', ['000', locked.path]);
    addTearDown(() => Process.run('chmod', ['755', locked.path]));

    // * Root reads it anyway, so only the songs around it are certain
    final songs = await library().songs();
    expect(songs.map((s) => s.fileName),
        containsAll(['sine.flac', 'sine_vbr.mp3', 'sine.m4a']));
  }, skip: Platform.isWindows);

  test('keeps the folders the user picked', () async {
    final settings = File('${dir.path}/folders.json');
    final other = await Directory('${dir.path}/Other').create();
    await File('test/fixtures/sine.ogg').copy('${other.path}/sine.ogg');

    final songs = library(settings: settings);
    expect(await songs.addFolder(other.path), isTrue);
    // * Already inside a listed folder
    expect(await songs.addFolder(music.path), isFalse);
    expect((await songs.songs()).length, 4);

    final again = library(settings: settings);
    await again.removeFolder('${dir.path}/Music');
    expect((await again.songs()).map((s) => s.fileName), ['sine.ogg']);
    expect(library(settings: settings).folders, isNot(contains(music.path)));
    expect((await library(settings: settings).songs()).length, 1);
  });

  test('a folder around listed ones takes their place', () async {
    final songs = library(settings: File('${dir.path}/folders.json'));
    await songs.songs();
    expect(await songs.addFolder(dir.path), isTrue);
    expect(songs.folders, [dir.path]);
  });

  test('dropped songs are copied in and folders added', () async {
    final songs = library(settings: File('${dir.path}/folders.json'));
    final outside = await Directory('${dir.path}/Desktop').create();
    final mp3 = await File('test/fixtures/sine_cbr.mp3')
        .copy('${outside.path}/dropped.mp3');
    final text = await File('${outside.path}/notes.txt').writeAsString('x');
    final album = await Directory('${dir.path}/Album').create();
    await File('test/fixtures/sine.opus').copy('${album.path}/sine.opus');

    final results = songs.imports.first;
    final added = await songs.importPaths([
      mp3.path,
      mp3.path,
      text.path,
      album.path,
      '${music.path}/sine.flac',
    ]);
    expect(added, 1);
    final result = await results;
    // * The second copy gets a name of its own; the song already in the
    // * library is left where it is
    expect(result.saved, ['dropped.mp3', 'dropped (2).mp3']);
    expect(result.failed, 1);
    expect(
      File('${dir.path}/Music/Stash/dropped (2).mp3').existsSync(),
      isTrue,
    );
    expect((await songs.songs()).length, 6);
  });

  test('songs added from outside are noticed', () async {
    final songs = library();
    await songs.songs();
    final changed = songs.changes.first;
    // * Into a folder that was there before the scan, as Linux watches each
    await File('test/fixtures/sine.ogg').copy('${music.path}/new.ogg');
    await changed.timeout(const Duration(seconds: 5));
    expect((await songs.songs()).length, 4);
  });
}
