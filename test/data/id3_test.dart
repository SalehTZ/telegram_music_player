import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/data/tags/id3.dart';

/// Fake MPEG audio: frame sync bytes, then a pattern we can check survived.
final audio = Uint8List.fromList(
    [0xff, 0xfb, 0x90, 0x64, ...List.generate(500, (i) => i % 251)]);

List<int> syncsafe(int v) =>
    [(v >> 21) & 0x7f, (v >> 14) & 0x7f, (v >> 7) & 0x7f, v & 0x7f];

/// A v2.4 tag in UTF-8 with a custom TXXX frame the app doesn't know about.
Uint8List v24File({bool footer = false}) {
  List<int> frame(String id, List<int> data) =>
      [...ascii.encode(id), ...syncsafe(data.length), 0, 0, ...data];
  final frames = [
    ...frame('TIT2', [3, ...utf8.encode('Old title @SomeChannel')]),
    ...frame('TPE1', [3, ...utf8.encode('Artist')]),
    ...frame('TXXX', [3, ...utf8.encode('mood'), 0, ...utf8.encode('calm')]),
  ];
  return Uint8List.fromList([
    ...ascii.encode('ID3'),
    4,
    0,
    footer ? 0x10 : 0,
    ...syncsafe(frames.length),
    ...frames,
    if (footer) ...[
      ...ascii.encode('3DI'),
      4,
      0,
      0x10,
      ...syncsafe(frames.length)
    ],
    ...audio,
  ]);
}

void expectAudioKept(Uint8List file) =>
    expect(file.sublist(file.length - audio.length), audio);

void main() {
  test('a file without a tag gets a v2.3 tag and keeps its audio', () {
    final out = writeId3(
        audio, const TagEdit(title: 'Song', artist: 'Band', year: '2013'));
    final tag = readId3(out)!;
    expect(tag.version, 3);
    expect(tag.title, 'Song');
    expect(tag.artist, 'Band');
    expect(tag.year, '2013');
    expectAudioKept(out);
  });

  test('Persian text survives in v2.3 (UTF-16) and v2.4 (UTF-8)', () {
    const title = 'آهنگ زیبا';
    final v23 = readId3(
        writeId3(audio, const TagEdit(title: title, lyrics: 'یک خط\nخط دو')))!;
    expect(v23.title, title);
    expect(v23.lyrics, 'یک خط\nخط دو');
    final v24 = readId3(writeId3(v24File(), const TagEdit(title: title)))!;
    expect(v24.version, 4);
    expect(v24.title, title);
  });

  test('editing a v2.4 tag keeps the frames it did not touch', () {
    final out = writeId3(v24File(), const TagEdit(title: 'Old title'));
    final tag = readId3(out)!;
    expect(tag.title, 'Old title');
    expect(tag.artist, 'Artist');
    expect(utf8.decode(out, allowMalformed: true), contains('calm'));
    expectAudioKept(out);
  });

  test('a v2.4 footer is not mistaken for audio', () {
    final out = writeId3(v24File(footer: true), const TagEdit(artist: 'New'));
    expect(readId3(out)!.artist, 'New');
    expectAudioKept(out);
    expect(utf8.decode(out, allowMalformed: true).contains('3DI'), isFalse);
  });

  test('an empty value removes the field, null leaves it alone', () {
    final out = writeId3(v24File(), const TagEdit(artist: ''));
    final tag = readId3(out)!;
    expect(tag.artist, isNull);
    expect(tag.title, 'Old title @SomeChannel');
  });

  test('a new cover replaces the old pictures', () {
    final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]);
    final png = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 4, 5, 6]);
    final first = writeId3(audio, TagEdit(cover: jpeg));
    expect(readId3(first)!.cover, jpeg);
    final second = writeId3(first, TagEdit(cover: png));
    expect(readId3(second)!.cover, png);
    expect(utf8.decode(second, allowMalformed: true), contains('image/png'));
  });

  test('editing twice gives the same result as editing once', () {
    const edit = TagEdit(title: 'A', album: 'B');
    final once = writeId3(audio, edit);
    expect(writeId3(once, edit), once);
  });

  test('an edit that fits leaves the audio where it was', () {
    final first = writeId3(audio, const TagEdit(title: 'A long first title'));
    final shorter = writeId3(first, const TagEdit(title: 'Short'));
    expect(shorter.length, first.length);
    expect(id3Length(shorter), id3Length(first));
    expect(readId3(shorter)!.title, 'Short');

    // * A cover bigger than the padding needs a new, longer tag
    final grown = writeId3(first, TagEdit(cover: Uint8List(4000)..[0] = 0xff));
    expect(id3Length(grown), greaterThan(id3Length(first)));
    expectAudioKept(grown);
  });

  test('tags it cannot rewrite safely are refused', () {
    Uint8List header(int version, int flags) => Uint8List.fromList(
        [...ascii.encode('ID3'), version, 0, flags, 0, 0, 0, 0, ...audio]);
    expect(() => writeId3(header(2, 0), const TagEdit(title: 'x')),
        throwsA(isA<Id3Exception>()));
    expect(() => writeId3(header(3, 0x80), const TagEdit(title: 'x')),
        throwsA(isA<Id3Exception>()));

    final damaged = v24File()
      ..[16] = 0x7f; // * TIT2's size now runs past the tag
    expect(() => writeId3(damaged, const TagEdit(title: 'x')),
        throwsA(isA<Id3Exception>()));
  });
}
