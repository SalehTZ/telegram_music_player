import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/song_model.dart';
import '../tags/id3.dart';
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
  Future<Id3Tag?> readTag(Song song) async {
    if (!song.canEditTags) return null;
    final file = await File(song.path).open();
    try {
      final length = id3Length(await file.read(10));
      if (length == 0) return null;
      await file.setPosition(0);
      return readId3(await file.read(length));
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
  Future<void> writeTag(Song song, TagEdit edit) async {
    // * An ID3 tag in front of any other format would damage the file
    if (!song.canEditTags) {
      throw Id3Exception('Stash can only change MP3 files, not ${song.format}');
    }
    final before = await File(song.path).readAsBytes();
    final after = writeId3(before, edit);
    // * When the tag kept its size only the tag is written, so the audio is
    // * never at risk. Otherwise the whole file is rewritten.
    final inPlace =
        after.length == before.length && id3Length(after) == id3Length(before);
    final temp = File(
      '${(await getTemporaryDirectory()).path}/stash-${song.id}.mp3',
    );
    await temp.writeAsBytes(
      inPlace ? Uint8List.sublistView(after, 0, id3Length(after)) : after,
      flush: true,
    );
    try {
      await _channel.invokeMethod('writeFile', {
        'uri': song.uri,
        'path': song.path,
        'source': temp.path,
        'truncate': !inPlace,
      });
    } finally {
      await temp.delete();
    }
  }
}
