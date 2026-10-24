import '../lyrics/lyrics.dart';
import 'web.dart';

/// Lyrics from LRCLIB (lrclib.net), free and often time-synced.
class LyricsSearch {
  static Future<Lyrics?> find({
    required String title,
    required String artist,
    String? album,
    Duration? duration,
  }) async {
    final exact = await Web.getJson(Uri.https('lrclib.net', '/api/get', {
      'track_name': title,
      'artist_name': artist,
      if (album != null && album.isNotEmpty) 'album_name': album,
      if (duration != null) 'duration': '${duration.inSeconds}',
    }));
    final found = parse(exact);
    if (found != null) return found;

    final matches = await Web.getJson(Uri.https('lrclib.net', '/api/search', {
      'track_name': title,
      'artist_name': artist,
    }));
    for (final match in matches is List ? matches : const []) {
      final lyrics = parse(match);
      if (lyrics != null) return lyrics;
    }
    return null;
  }

  /// One LRCLIB record, preferring the synced lyrics.
  static Lyrics? parse(Object? json) {
    if (json is! Map) return null;
    for (final key in ['syncedLyrics', 'plainLyrics']) {
      final text = json[key];
      if (text is String && text.trim().isNotEmpty) {
        final lyrics = Lyrics.parse(text);
        if (!lyrics.isEmpty) return lyrics;
      }
    }
    return null;
  }
}
