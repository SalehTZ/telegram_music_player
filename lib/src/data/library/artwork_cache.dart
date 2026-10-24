import 'dart:typed_data';

import '../models/song_model.dart';
import 'music_library.dart';

/// Covers loaded from the library, kept so scrolling back doesn't load them
/// again.
class ArtworkCache {
  final MusicLibrary _library;
  final _covers = <String, Future<Uint8List?>>{};
  final _loaded = <String, Uint8List?>{};

  // * Thumbnails are about 30 KB, so this is a few MB at most
  static const _limit = 150;

  ArtworkCache(this._library);

  Future<Uint8List?> get(Song song, ArtworkSize size) {
    final key = _key(song, size);
    final cover = _covers.remove(key) ??
        _library.artwork(song, size.pixels).catchError((_) => null).then((c) {
          if (_covers.containsKey(key)) _loaded[key] = c;
          return c;
        });
    _covers[key] = cover;
    if (_covers.length > _limit) {
      final oldest = _covers.keys.first;
      _covers.remove(oldest);
      _loaded.remove(oldest);
    }
    return cover;
  }

  /// The cover when it already loaded, so lists don't flash a placeholder
  /// while scrolling back.
  Uint8List? peek(Song song, ArtworkSize size) => _loaded[_key(song, size)];

  static String _key(Song song, ArtworkSize size) =>
      '${song.id}@${size.pixels}';

  /// Shows [cover] for [song] right away, before the library catches up
  /// with the new file. Null forgets what was cached.
  void replace(Song song, Uint8List? cover) {
    for (final size in ArtworkSize.values) {
      final key = _key(song, size);
      _covers.remove(key);
      _loaded.remove(key);
      if (cover != null) {
        _covers[key] = Future.value(cover);
        _loaded[key] = cover;
      }
    }
  }
}

/// The sizes covers are loaded in, so the cache can share them.
enum ArtworkSize {
  small(200),
  large(800);

  final int pixels;
  const ArtworkSize(this.pixels);
}
