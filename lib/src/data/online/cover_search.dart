import 'web.dart';

class CoverResult {
  /// The full size cover, and a small one for the results grid.
  final String imageUrl;
  final String thumbUrl;
  final String title;
  final String artist;
  final String album;
  final String source;
  const CoverResult({
    required this.imageUrl,
    required this.thumbUrl,
    required this.title,
    required this.artist,
    required this.album,
    required this.source,
  });
}

/// Album covers from the iTunes and Deezer search APIs, which need no key.
class CoverSearch {
  static Future<List<CoverResult>> search(String query) async {
    final term = Uri.encodeQueryComponent(query);
    final results = await Future.wait([
      _safely(() async => parseItunes(await Web.getJson(Uri.parse(
          'https://itunes.apple.com/search?term=$term&media=music&entity=song&limit=12')))),
      _safely(() async => parseDeezer(await Web.getJson(
          Uri.parse('https://api.deezer.com/search?q=$term&limit=12')))),
    ]);
    if (results.every((r) => r == null)) {
      throw const CoverSearchException();
    }
    final seen = <String>{};
    return [
      for (final list in results)
        for (final cover in list ?? const <CoverResult>[])
          if (seen.add(
              '${cover.album.toLowerCase()}|${cover.artist.toLowerCase()}'))
            cover,
    ];
  }

  /// One failing service shouldn't hide the other's results.
  static Future<List<CoverResult>?> _safely(
    Future<List<CoverResult>> Function() run,
  ) async {
    try {
      return await run();
    } catch (_) {
      return null;
    }
  }

  static List<CoverResult> parseItunes(Object? json) => [
        for (final r in (json as Map?)?['results'] as List? ?? const [])
          if (r['artworkUrl100'] is String)
            CoverResult(
              // * The 100px URL serves any size up to the original's
              imageUrl: (r['artworkUrl100'] as String)
                  .replaceFirst('100x100bb', '1000x1000bb'),
              thumbUrl: (r['artworkUrl100'] as String)
                  .replaceFirst('100x100bb', '300x300bb'),
              title: r['trackName'] ?? '',
              artist: r['artistName'] ?? '',
              album: r['collectionName'] ?? '',
              source: 'iTunes',
            ),
      ];

  static List<CoverResult> parseDeezer(Object? json) => [
        for (final r in (json as Map?)?['data'] as List? ?? const [])
          if (r['album']?['cover_xl'] is String)
            CoverResult(
              imageUrl: r['album']['cover_xl'],
              thumbUrl: r['album']['cover_medium'] ?? r['album']['cover_xl'],
              title: r['title'] ?? '',
              artist: r['artist']?['name'] ?? '',
              album: r['album']['title'] ?? '',
              source: 'Deezer',
            ),
      ];
}

class CoverSearchException implements Exception {
  const CoverSearchException();

  @override
  String toString() => "Couldn't reach iTunes or Deezer";
}
