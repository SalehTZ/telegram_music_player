import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../models/song_model.dart';
import '../tags/probe.dart';
import '../tags/tags.dart';
import 'music_library.dart';

/// The songs in folders on a computer, for platforms without a media
/// library like Android's: Linux, Windows and macOS. Stash reads the tags
/// itself and keeps what it read in [cache], so a rescan only opens files
/// that changed.
class FolderMusicLibrary implements MusicLibrary {
  final List<Directory> folders;
  final File? cache;

  /// Ids stay the same for a path as long as Stash runs, so the player and
  /// the covers keep up with rescans.
  final _ids = <String, int>{};
  Map<String, Map<String, Object?>>? _scanned;

  FolderMusicLibrary(this.folders, {this.cache});

  /// The user's music folder and Telegram Desktop's downloads.
  static List<Directory> defaultFolders() {
    final env = Platform.environment;
    final home = Platform.isWindows ? env['USERPROFILE'] : env['HOME'];
    if (home == null) return const [];
    final sep = Platform.pathSeparator;
    return [
      Directory(_xdgMusic(home) ?? '$home${sep}Music'),
      Directory('$home${sep}Downloads${sep}Telegram Desktop'),
    ];
  }

  /// The music folder Linux desktops name in ~/.config/user-dirs.dirs, which
  /// can be translated, like "~/Musik".
  static String? _xdgMusic(String home) {
    if (!Platform.isLinux) return null;
    try {
      final dirs = File('$home/.config/user-dirs.dirs').readAsLinesSync();
      for (final line in dirs) {
        final match = RegExp(r'^XDG_MUSIC_DIR="(.*)"').firstMatch(line);
        if (match != null) return match[1]!.replaceAll(r'$HOME', home);
      }
    } on FileSystemException {
      // * No such file: use ~/Music
    }
    return null;
  }

  static const _audio = {
    'MP3',
    'FLAC',
    'OGG',
    'OGA',
    'OPUS',
    'M4A',
    'M4B',
    'AAC',
    'WAV',
    'WMA',
  };

  @override
  Stream<({List<String> saved, int failed})> get imports =>
      const Stream.empty();

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<Access> requestPermission() async => Access.granted;

  @override
  Future<void> openSettings() async {}

  @override
  Future<List<Song>> songs() async {
    final scanned = _scanned ??= await _loadCache();
    final found = <String, Map<String, Object?>>{};
    for (final folder in folders) {
      if (!await folder.exists()) continue;
      await for (final entry
          in folder.list(recursive: true, followLinks: false)) {
        if (entry is! File) continue;
        final path = entry.path;
        final format = _format(path);
        if (!_audio.contains(format)) continue;
        try {
          final stat = await entry.stat();
          final known = scanned[path];
          found[path] = known != null &&
                  known['modified'] == stat.modified.millisecondsSinceEpoch &&
                  known['size'] == stat.size
              ? known
              : await _read(path, format, stat);
        } on FileSystemException {
          // * Gone or unreadable since the folder was listed
        }
      }
    }
    _scanned = found;
    await _saveCache(found);
    final songs = [
      for (final MapEntry(key: path, value: row) in found.entries)
        Song(
          id: _ids.putIfAbsent(path, () => _ids.length + 1),
          title: row['title'] as String,
          artist: row['artist'] as String,
          album: row['album'] as String,
          path: path,
          uri: Uri.file(path).toString(),
          duration: Duration(milliseconds: row['duration'] as int),
          added: DateTime.fromMillisecondsSinceEpoch(row['modified'] as int),
          size: row['size'] as int,
        ),
    ];
    return songs..sort((a, b) => b.added.compareTo(a.added));
  }

  static String _format(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '' : path.substring(dot + 1).toUpperCase();
  }

  Future<Map<String, Object?>> _read(
      String path, String format, FileStat stat) async {
    Probe? found;
    try {
      found = await probe(path, format: format);
    } on FileSystemException {
      found = null;
    }
    final tag = found?.tag;
    final name = path.substring(path.lastIndexOf(Platform.pathSeparator) + 1);
    final dot = name.lastIndexOf('.');
    return {
      // * Like Android, a song with no title goes by its file name
      'title': tag?.title ?? (dot > 0 ? name.substring(0, dot) : name),
      'artist': tag?.artist ?? '',
      'album': tag?.album ?? '',
      'duration': found?.duration.inMilliseconds ?? 0,
      'modified': stat.modified.millisecondsSinceEpoch,
      'size': stat.size,
    };
  }

  Future<Map<String, Map<String, Object?>>> _loadCache() async {
    final file = cache;
    if (file == null || !await file.exists()) return {};
    try {
      final data = jsonDecode(await file.readAsString()) as Map;
      return {
        for (final MapEntry(:key, :value) in data.entries)
          key as String: (value as Map).cast<String, Object?>(),
      };
    } on FormatException {
      return {};
    }
  }

  Future<void> _saveCache(Map<String, Map<String, Object?>> found) async {
    final file = cache;
    if (file == null) return;
    try {
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(found));
      await temp.rename(file.path);
    } on FileSystemException {
      // * Only makes the next start slower
    }
  }

  /// The tag bytes are re-read from the file each time; [ArtworkCache]
  /// keeps the covers it was given.
  @override
  Future<Uint8List?> artwork(Song song, int size) async {
    final cover = (await readTag(song))?.cover;
    if (cover == null) return null;
    final codec = await ui.instantiateImageCodec(cover, targetWidth: size);
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    return png?.buffer.asUint8List();
  }

  @override
  Future<SongTag?> readTag(Song song) async {
    if (!song.canEditTags) return null;
    return (await probe(song.path, format: song.format))?.tag;
  }

  /// Nothing to ask: the files are the user's own.
  @override
  Future<bool> requestWriteAccess(List<Song> songs) async => true;

  @override
  Future<bool> delete(List<Song> songs) async {
    for (final song in songs) {
      await File(song.path).delete();
    }
    return true;
  }

  @override
  Future<void> writeTag(Song song, TagEdit edit) async {
    if (!song.canEditTags) {
      throw TagException("Stash can't change ${song.format} files");
    }
    final file = File(song.path);
    final before = await file.readAsBytes();
    final after = writeTags(before, edit, format: song.format);
    if (after.length == before.length) {
      // * Only the start changed: write that much in place, so the audio
      // * after the tags is never at risk
      var end = after.length;
      while (end > 0 && after[end - 1] == before[end - 1]) {
        end--;
      }
      final open = await file.open(mode: FileMode.writeOnlyAppend);
      try {
        await open.setPosition(0);
        await open.writeFrom(after, 0, end);
        await open.flush();
      } finally {
        await open.close();
      }
    } else {
      // * Written next to the song first, so a crash leaves the old file
      final temp = File('${song.path}.stash-tmp');
      await temp.writeAsBytes(after, flush: true);
      await temp.rename(song.path);
    }
  }
}
