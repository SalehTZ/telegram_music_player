import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/data/tags/probe.dart';

void main() {
  // * Lengths as ffprobe gives them
  const cases = {
    'sine.flac': ('FLAC', 1000),
    'sine.ogg': ('OGG', 1000),
    'sine.opus': ('OPUS', 1000),
    'sine.m4a': ('M4A', 1000),
    'sine_faststart.m4a': ('M4A', 1000),
    'sine_vbr.mp3': ('MP3', 3056),
    'sine_cbr.mp3': ('MP3', 3056),
  };

  for (final MapEntry(key: name, value: (format, ms)) in cases.entries) {
    test('$name: tags and length', () async {
      final found = (await probe('test/fixtures/$name', format: format))!;
      expect(found.tag!.title, 'Song@Channel');
      expect(found.tag!.artist, 'Band');
      expect(found.duration.inMilliseconds, closeTo(ms, 60));
    });
  }

  test('a file Stash can not read gives null', () async {
    expect(await probe('test/fixtures/sine.flac', format: 'WMA'), isNotNull,
        reason: 'read by its content, not its name');
    expect(await probe('pubspec.yaml', format: 'WMA'), isNull);
  });
}
