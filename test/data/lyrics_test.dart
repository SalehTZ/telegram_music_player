import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/data/lyrics/lyrics.dart';
import 'package:stash/src/data/online/cover_search.dart';
import 'package:stash/src/data/online/lyrics_search.dart';

void main() {
  test('reads LRC, including lines with two timestamps', () {
    final lyrics = Lyrics.parse('[ar:Arctic Monkeys]\n'
        '[00:12.50]Crawlin\' back to you\n'
        '[00:20.00][01:05.10]Ever thought of callin\' when\n'
        '[00:15:75]You\'ve had a few');
    expect(lyrics.timed.map((l) => l.time.inMilliseconds),
        [12500, 15750, 20000, 65100]);
    expect(lyrics.lines.first, "Crawlin' back to you");
    expect(lyrics.lineAt(const Duration(seconds: 5)), -1);
    expect(lyrics.lineAt(const Duration(seconds: 16)), 1);
    expect(Lyrics.parse(lyrics.format()).timed.length, 4);
  });

  test('reads plain lyrics without the blank edges', () {
    final lyrics = Lyrics.parse('\n\nFirst line\n\nSecond line\n\n');
    expect(lyrics.timed, isEmpty);
    expect(lyrics.lines, ['First line', '', 'Second line']);
    expect(lyrics.lineAt(Duration.zero), -1);
  });

  test('LRCLIB records prefer synced lyrics and skip empty ones', () {
    expect(
        LyricsSearch.parse(
                {'syncedLyrics': '[00:01.00]Hi', 'plainLyrics': 'Hi'})!
            .timed,
        hasLength(1));
    expect(
        LyricsSearch.parse({'syncedLyrics': null, 'plainLyrics': 'Hi'})!.lines,
        ['Hi']);
    expect(
        LyricsSearch.parse({'instrumental': true, 'plainLyrics': ''}), isNull);
    expect(LyricsSearch.parse(null), isNull);
  });

  test('cover results from iTunes and Deezer', () {
    final itunes = CoverSearch.parseItunes({
      'results': [
        {
          'trackName': 'Do I Wanna Know?',
          'artistName': 'Arctic Monkeys',
          'collectionName': 'AM',
          'artworkUrl100': 'https://is1.mzstatic.com/a/100x100bb.jpg',
        },
        {'trackName': 'No artwork'},
      ],
    });
    expect(
        itunes.single.imageUrl, 'https://is1.mzstatic.com/a/1000x1000bb.jpg');
    expect(itunes.single.thumbUrl, 'https://is1.mzstatic.com/a/300x300bb.jpg');
    expect(itunes.single.album, 'AM');

    final deezer = CoverSearch.parseDeezer({
      'data': [
        {
          'title': 'Get Lucky',
          'artist': {'name': 'Daft Punk'},
          'album': {
            'title': 'Random Access Memories',
            'cover_xl': 'https://e-cdns/1000.jpg'
          },
        },
      ],
    });
    expect(deezer.single.artist, 'Daft Punk');
    expect(deezer.single.thumbUrl, 'https://e-cdns/1000.jpg');
    expect(CoverSearch.parseDeezer({'error': 'quota'}), isEmpty);
    expect(CoverSearch.parseItunes(null), isEmpty);
  });
}
