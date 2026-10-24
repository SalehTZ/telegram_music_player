import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Favorites, play history and playlists, kept as JSON in the app's own
/// data folder.
class LocalStore {
  final File? _file;
  Future<void> _lastSave = Future.value();

  LocalStore(File this._file);

  /// Keeps nothing, for tests and screenshots.
  LocalStore.memory() : _file = null;

  static Future<LocalStore> open() async => LocalStore(
        File('${(await getApplicationSupportDirectory()).path}/library.json'),
      );

  Future<Map<String, Object?>> load() async {
    final file = _file;
    if (file == null || !await file.exists()) return {};
    try {
      return jsonDecode(await file.readAsString()) as Map<String, Object?>;
    } on FormatException {
      return {};
    }
  }

  /// Saves one after the other, each through a temporary file, so a crash
  /// mid-write leaves the last good copy.
  Future<void> save(Map<String, Object?> data) {
    final file = _file;
    if (file == null) return Future.value();
    return _lastSave = _lastSave.then((_) async {
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(data), flush: true);
      await temp.rename(file.path);
    });
  }
}
