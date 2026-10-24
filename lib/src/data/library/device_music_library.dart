import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/song_model.dart';
import '../tags/id3.dart';
import '../tags/tags.dart';
import 'music_library.dart';

/// The phone's media library, through MainActivity.java.
class DeviceMusicLibrary implements MusicLibrary {
  static const _channel = MethodChannel('ir.salehtz.stash/files');

  // * Not a broadcast stream: songs shared while Stash starts wait here until
  // * the library listens.
  final _imports = StreamController<({List<String> saved, int failed})>();

  DeviceMusicLibrary() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'imported') await _takeImports();
    });
    _takeImports();
  }

  Future<void> _takeImports() async {
    final result =
        await _channel.invokeMapMethod<String, Object?>('takeImported');
    final saved = (result?['saved'] as List?)?.cast<String>() ?? const [];
    final failed = result?['failed'] as int? ?? 0;
    if (saved.isNotEmpty || failed > 0) {
      _imports.add((saved: saved, failed: failed));
    }
  }

  @override
  Stream<({List<String> saved, int failed})> get imports => _imports.stream;

  @override
  Future<bool> hasPermission() async =>
      await _channel.invokeMethod<bool>('hasPermission') ?? false;

  @override
  Future<Access> requestPermission() async {
    final result = await _channel.invokeMethod<String>('requestPermission');
    return Access.values.byName(result ?? 'denied');
  }

  @override
  Future<void> openSettings() => _channel.invokeMethod('openSettings');

  @override
  Future<List<Song>> songs() async {
    final rows = await _channel.invokeListMethod<Map>('songs') ?? const [];
    return [
      for (final row in rows)
        Song(
          id: row['id'] as int,
          title: row['title'] as String? ?? '',
          artist: _known(row['artist'] as String?),
          album: _known(row['album'] as String?),
          path: row['path'] as String? ?? '',
          uri: row['uri'] as String,
          duration: Duration(milliseconds: row['duration'] as int? ?? 0),
          added: DateTime.fromMillisecondsSinceEpoch(
            (row['added'] as int? ?? 0) * 1000,
          ),
          size: row['size'] as int? ?? 0,
        ),
    ];
  }

  // * Android fills missing tags with "<unknown>"
  static String _known(String? value) =>
      value == null || value == '<unknown>' ? '' : value;

  @override
  Future<Uint8List?> artwork(Song song, int size) =>
      _channel.invokeMethod<Uint8List>(
        'artwork',
        {'id': song.id, 'path': song.path, 'size': size},
      );

  @override
  Future<SongTag?> readTag(Song song) async {
    if (!song.canEditTags) return null;
    // * An MP3's tag is at the start, so only that much is read
    final file = await File(song.path).open();
    try {
      final length = song.format == 'MP3' ? id3Length(await file.read(10)) : 0;
      if (length == 0) {
        return readTags(await File(song.path).readAsBytes(),
            format: song.format);
      }
      await file.setPosition(0);
      return readTags(await file.read(length), format: song.format);
    } finally {
      await file.close();
    }
  }

  @override
  Future<bool> requestWriteAccess(List<Song> songs) async =>
      await _channel.invokeMethod<bool>(
        'requestWriteAccess',
        {
          'uris': [for (final song in songs) song.uri]
        },
      ) ??
      false;

  @override
  Future<bool> delete(List<Song> songs) async =>
      await _channel.invokeMethod<bool>(
        'delete',
        {
          'uris': [for (final song in songs) song.uri],
          'paths': [for (final song in songs) song.path],
        },
      ) ??
      false;

  @override
  Future<void> writeTag(Song song, TagEdit edit) async {
    if (!song.canEditTags) {
      throw TagException("Stash can't change ${song.format} files");
    }
    final before = await File(song.path).readAsBytes();
    final after = writeTags(before, edit, format: song.format);
    // * When the file kept its size only the bytes up to the last change are
    // * written, so the audio after the tags is never at risk. Otherwise the
    // * whole file is rewritten.
    final changed =
        after.length == before.length ? _changedUpTo(before, after) : null;
    final temp = File(
      '${(await getTemporaryDirectory()).path}/stash-${song.id}.tmp',
    );
    await temp.writeAsBytes(
      changed == null ? after : Uint8List.sublistView(after, 0, changed),
      flush: true,
    );
    try {
      await _channel.invokeMethod('writeFile', {
        'uri': song.uri,
        'path': song.path,
        'source': temp.path,
        'truncate': changed == null,
      });
    } finally {
      await temp.delete();
    }
  }

  /// How many bytes from the start hold every difference between [a] and
  /// [b], which are the same length.
  static int _changedUpTo(Uint8List a, Uint8List b) {
    var end = a.length;
    while (end > 0 && a[end - 1] == b[end - 1]) {
      end--;
    }
    return end;
  }
}
