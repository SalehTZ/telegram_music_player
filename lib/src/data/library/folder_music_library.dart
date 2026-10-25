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
/// that changed. The folders are watched, so new songs show up by
/// themselves.
class FolderMusicLibrary implements MusicLibrary, PickedFolders {
  /// The folders to look in until the user picks their own.
  final List<Directory> defaults;
  final File? cache;

  /// Where the folders the user picked are kept.
  final File? settings;

  /// Ids stay the same for a path as long as Stash runs, so the player and
  /// the covers keep up with rescans.
  final _ids = <String, int>{};
  Map<String, Map<String, Object?>>? _scanned;
  List<String>? _folders;
  final _imports =
      StreamController<({List<String> saved, int failed})>.broadcast();
  final _changes = StreamController<void>.broadcast();
  final _watches = <String, StreamSubscription<FileSystemEvent>>{};
  Timer? _settle;

  FolderMusicLibrary(this.defaults, {this.cache, this.settings});

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
  Stream<({List<String> saved, int failed})> get imports => _imports.stream;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<String> get folders =>
      _folders ?? [for (final folder in defaults) folder.path];

  Future<List<String>> _current() async {
    if (_folders case final folders?) return folders;
    final file = settings;
    if (file != null && await file.exists()) {
      try {
        final saved = jsonDecode(await file.readAsString()) as Map;
        return _folders = (saved['folders'] as List).cast<String>();
      } on FormatException {
        // * Damaged: start over from the defaults
      }
    }
    return _folders = folders;
  }

  Future<void> _saveFolders(List<String> folders) async {
    _folders = folders;
    final file = settings;
    if (file == null) return;
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode({'folders': folders}), flush: true);
    await temp.rename(file.path);
  }

  static String _clean(String path) {
    final sep = Platform.pathSeparator;
    final absolute = Directory(path).absolute.path;
    if (absolute.length <= 1 || !absolute.endsWith(sep)) return absolute;
    final trimmed = absolute.substring(0, absolute.length - 1);
    // * "D:\\" stays as it is: "D:" is the folder Windows is in on drive D
    return trimmed.endsWith(':') ? absolute : trimmed;
  }

  /// Whether [path] is [folder] or somewhere inside it.
  static bool _inside(String path, String folder) {
    final sep = Platform.pathSeparator;
    return path == folder ||
        path.startsWith(folder.endsWith(sep) ? folder : '$folder$sep');
  }

  @override
  Future<bool> addFolder(String path) async {
    final folder = _clean(path);
    final current = await _current();
    if (current.any((f) => _inside(folder, f))) return false;
    // * A folder around ones already listed takes their place
    await _saveFolders([...current.where((f) => !_inside(f, folder)), folder]);
    return true;
  }

  @override
  Future<void> removeFolder(String path) async {
    final current = await _current();
    await _saveFolders([...current.where((f) => f != path)]);
  }

  @override
  Future<int> importPaths(List<String> paths) async {
    final saved = <String>[];
    var failed = 0;
    var added = 0;
    for (final path in paths) {
      try {
        if (await FileSystemEntity.isDirectory(path)) {
          if (await addFolder(path)) added++;
          continue;
        }
        if (!_audio.contains(_format(path))) {
          failed++;
          continue;
        }
        final current = await _current();
        // * Already in the library
        if (current.any((f) => _inside(_clean(path), f))) continue;
        if (current.isEmpty) {
          if (defaults.isEmpty) throw const FileSystemException('No folder');
          await addFolder(defaults.first.path);
        }
        final sep = Platform.pathSeparator;
        final target = await Directory('${(await _current()).first}${sep}Stash')
            .create(recursive: true);
        final name =
            _freeName(target, path.substring(path.lastIndexOf(sep) + 1));
        await File(path).copy('${target.path}$sep$name');
        saved.add(name);
      } on FileSystemException {
        failed++;
      }
    }
    if (saved.isNotEmpty || failed > 0) {
      _imports.add((saved: saved, failed: failed));
    }
    return added;
  }

  /// [name], or "name (2).mp3" and so on when [folder] already has it.
  static String _freeName(Directory folder, String name) {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final ext = dot > 0 ? name.substring(dot) : '';
    var free = name;
    for (var n = 2;
        File('${folder.path}${Platform.pathSeparator}$free').existsSync();
        n++) {
      free = '$base ($n)$ext';
    }
    return free;
  }

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
    final roots = await _current();
    final dirs = <String>[];
    for (final root in roots) {
      final folder = Directory(root);
      if (!await folder.exists()) continue;
      dirs.add(folder.path);
      final entries = folder
          .list(recursive: true, followLinks: false)
          // * A folder Stash can't open, like "System Volume Information" on
          // * a drive, is skipped instead of ending the whole scan
          .handleError((_) {}, test: (e) => e is FileSystemException);
      await for (final entry in entries) {
        if (entry is Directory) dirs.add(entry.path);
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
    _watch(dirs);
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

  /// Watches [dirs] for songs coming and going. Linux watches one folder at
  /// a time, so it gets every folder; the others watch the top folders with
  /// everything inside.
  void _watch(List<String> dirs) {
    if (!FileSystemEntity.isWatchSupported) return;
    final roots = {
      for (final d in dirs)
        if (_folders!.contains(d)) d
    };
    final wanted = Platform.isLinux ? dirs.toSet() : roots;
    for (final gone in _watches.keys.toSet().difference(wanted)) {
      _watches.remove(gone)?.cancel();
    }
    for (final dir in wanted.difference(_watches.keys.toSet())) {
      try {
        _watches[dir] = Directory(dir)
            .watch(recursive: !Platform.isLinux)
            .listen(_onEvent, onError: (_) => _watches.remove(dir));
      } on FileSystemException {
        // * Out of watches: the folder is still read on each refresh
      }
    }
  }

  void _onEvent(FileSystemEvent event) {
    // * Folders matter too: a new one may hold songs
    if (!event.isDirectory && !_audio.contains(_format(event.path))) return;
    // * Copying a song in sends many events: wait until they stop
    _settle?.cancel();
    _settle = Timer(const Duration(seconds: 1), () => _changes.add(null));
  }

  /// Stops watching the folders.
  void dispose() {
    _settle?.cancel();
    for (final watch in _watches.values) {
      watch.cancel();
    }
    _watches.clear();
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
