import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/data/tags/tags.dart';

/// One second of a sine wave in each format, tagged by ffmpeg with title
/// "Song@Channel", artist "Band" and album "Album".
const fixtures = {
  'sine.flac': 'FLAC',
  'sine.ogg': 'OGG',
  'sine.opus': 'OPUS',
  'sine.m4a': 'M4A',
  'sine_faststart.m4a': 'M4A',
};

Uint8List fixture(String name) => File('test/fixtures/$name').readAsBytesSync();

/// A tiny JPEG-looking cover; the writers don't decode it.
final jpeg =
    Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, ...List.filled(3000, 7)]);
final png = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, ...List.filled(40, 1)]);

void main() {
  for (final MapEntry(key: name, value: format) in fixtures.entries) {
    group(name, () {
      test('reads what ffmpeg wrote', () {
        final tag = readTags(fixture(name), format: format)!;
        expect(tag.title, 'Song@Channel');
        expect(tag.artist, 'Band');
        expect(tag.album, 'Album');
        expect(tag.cover, isNull);
      });

      test('writes every field and keeps the ones it was not given', () {
        const edit = TagEdit(
          title: 'آهنگ زیبا',
          year: '2013',
          genre: 'Pop',
          lyrics: '[00:01.00]یک خط\n[00:02.00]Line two',
        );
        final out = writeTags(fixture(name), edit, format: format);
        final tag = readTags(out, format: format)!;
        expect(tag.title, 'آهنگ زیبا');
        expect(tag.artist, 'Band');
        expect(tag.album, 'Album');
        expect(tag.year, '2013');
        expect(tag.genre, 'Pop');
        expect(tag.lyrics, edit.lyrics);
      });

      test('adds, replaces and removes the cover', () {
        final once =
            writeTags(fixture(name), TagEdit(cover: jpeg), format: format);
        expect(readTags(once, format: format)!.cover, jpeg);
        final twice = writeTags(once, TagEdit(cover: png), format: format);
        expect(readTags(twice, format: format)!.cover, png);
        final none =
            writeTags(twice, TagEdit(cover: Uint8List(0)), format: format);
        expect(readTags(none, format: format)!.cover, isNull);
      });

      test('an empty field is removed', () {
        final out =
            writeTags(fixture(name), const TagEdit(artist: ''), format: format);
        expect(readTags(out, format: format)!.artist, isNull);
      });

      test('writing the same edit twice changes nothing more', () {
        final edit = TagEdit(title: 'Song', cover: jpeg);
        final once = writeTags(fixture(name), edit, format: format);
        expect(writeTags(once, edit, format: format), once);
      });

      // * Ogg has no padding, so its files are always written whole
      if (format != 'OGG' && format != 'OPUS') {
        test('a shorter tag fits in the old space', () {
          final grown = writeTags(fixture(name),
              const TagEdit(title: 'A much longer title than before'),
              format: format);
          final shorter =
              writeTags(grown, const TagEdit(title: 'Short'), format: format);
          expect(shorter.length, grown.length);
          expect(readTags(shorter, format: format)!.title, 'Short');
        });
      }
    });
  }

  test('FLAC audio after the metadata is kept byte for byte', () {
    final file = fixture('sine.flac');
    final out =
        writeTags(file, TagEdit(title: 'x', cover: jpeg), format: 'FLAC');
    // * The last few kilobytes are audio frames in both
    expect(out.sublist(out.length - 8000), file.sublist(file.length - 8000));
  });

  test('a big cover moves the M4A audio and its offsets with it', () {
    for (final name in ['sine.m4a', 'sine_faststart.m4a']) {
      final file = fixture(name);
      final cover = Uint8List.fromList([0xff, 0xd8, ...List.filled(20000, 3)]);
      final out = writeTags(file, TagEdit(cover: cover), format: 'M4A');
      expect(out.length, greaterThan(file.length + 20000));
      expect(readTags(out, format: 'M4A')!.cover, cover);
    }
  });

  test('a file that is not what its name says is read by its content', () {
    final tag = readTags(fixture('sine.m4a'), format: 'MP3')!;
    expect(tag.title, 'Song@Channel');
  });

  test('formats without a writer are refused', () {
    expect(
        () =>
            writeTags(Uint8List(100), const TagEdit(title: 'x'), format: 'WMA'),
        throwsA(isA<TagException>()));
  });
}
