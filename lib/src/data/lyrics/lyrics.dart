class LyricLine {
  final Duration time;
  final String text;
  const LyricLine(this.time, this.text);
}

/// A song's lyrics, timed line by line when they come as LRC.
class Lyrics {
  final List<String> lines;

  /// Empty when the lyrics have no timestamps.
  final List<LyricLine> timed;
  const Lyrics(this.lines, this.timed);

  static final _stamp = RegExp(r'\[(\d{1,3}):(\d{1,2}(?:[.:]\d{1,3})?)\]');

  /// Reads plain text or LRC ("[01:02.50]A line"), ignoring LRC's
  /// [ar:...] style header tags.
  factory Lyrics.parse(String text) {
    final timed = <LyricLine>[];
    final lines = <String>[];
    for (final raw in text.split(RegExp(r'\r?\n'))) {
      final stamps = _stamp.allMatches(raw).toList();
      final words = raw.replaceAll(_stamp, '').trim();
      if (stamps.isEmpty) {
        if (!RegExp(r'^\[[a-z]+:.*\]$').hasMatch(raw.trim())) {
          lines.add(raw.trim());
        }
        continue;
      }
      for (final m in stamps) {
        final seconds = double.parse(m[2]!.replaceFirst(':', '.'));
        timed.add(LyricLine(
          Duration(
            minutes: int.parse(m[1]!),
            milliseconds: (seconds * 1000).round(),
          ),
          words,
        ));
      }
    }
    timed.sort((a, b) => a.time.compareTo(b.time));
    return Lyrics(
      timed.isEmpty ? _trim(lines) : [for (final l in timed) l.text],
      timed,
    );
  }

  bool get isEmpty => lines.every((l) => l.isEmpty);

  /// The timed line playing at [position], or -1 before the first one.
  int lineAt(Duration position) {
    var index = -1;
    for (var i = 0; i < timed.length && timed[i].time <= position; i++) {
      index = i;
    }
    return index;
  }

  /// The lyrics as LRC when timed, otherwise as plain text, for saving.
  String format() => timed.isEmpty
      ? lines.join('\n')
      : [
          for (final l in timed)
            '[${_two(l.time.inMinutes)}:${_two(l.time.inSeconds % 60)}'
                '.${_two(l.time.inMilliseconds % 1000 ~/ 10)}]${l.text}',
        ].join('\n');

  static String _two(int n) => n.toString().padLeft(2, '0');

  static List<String> _trim(List<String> lines) {
    var start = 0, end = lines.length;
    while (start < end && lines[start].isEmpty) {
      start++;
    }
    while (end > start && lines[end - 1].isEmpty) {
      end--;
    }
    return lines.sublist(start, end);
  }
}
