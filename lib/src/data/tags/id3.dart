import 'dart:convert';
import 'dart:typed_data';

/// Thrown when a file's tag can't be read or safely rewritten.
class Id3Exception implements Exception {
  final String message;
  const Id3Exception(this.message);

  @override
  String toString() => message;
}

/// Changes to a song's tags. A null field stays as it is, an empty string
/// removes it, and a cover replaces every picture in the tag.
class TagEdit {
  final String? title;
  final String? artist;
  final String? album;
  final String? year;
  final String? genre;
  final String? lyrics;
  final Uint8List? cover;

  const TagEdit({
    this.title,
    this.artist,
    this.album,
    this.year,
    this.genre,
    this.lyrics,
    this.cover,
  });

  bool get isEmpty =>
      title == null &&
      artist == null &&
      album == null &&
      year == null &&
      genre == null &&
      lyrics == null &&
      cover == null;
}

/// The ID3v2.3 or v2.4 tag at the start of an MP3 file.
class Id3Tag {
  final int version;
  final List<_Frame> _frames;
  Id3Tag._(this.version, this._frames);

  String? get title => _text('TIT2');
  String? get artist => _text('TPE1');
  String? get album => _text('TALB');
  String? get genre => _text('TCON');
  String? get year {
    final value = _text('TYER') ?? _text('TDRC');
    return value == null || value.length <= 4 ? value : value.substring(0, 4);
  }

  /// Unsynchronised lyrics (USLT), the first frame that has text.
  String? get lyrics {
    for (final frame in _readable('USLT')) {
      final d = frame.data;
      if (d.length < 5) continue;
      final encoding = d[0];
      final end = _terminator(d, 4, encoding);
      if (end < 0) continue;
      final text = _clean(_decode(encoding, d.sublist(end + _width(encoding))));
      if (text != null) return text;
    }
    return null;
  }

  /// The front cover, or the first picture when none is marked as the front.
  Uint8List? get cover {
    Uint8List? first;
    for (final frame in _readable('APIC')) {
      final d = frame.data;
      final mimeEnd = d.indexOf(0, 1);
      if (mimeEnd < 0 || mimeEnd + 2 > d.length) continue;
      final encoding = d[0];
      final type = d[mimeEnd + 1];
      final end = _terminator(d, mimeEnd + 2, encoding);
      if (end < 0) continue;
      final picture = Uint8List.sublistView(d, end + _width(encoding));
      if (picture.isEmpty) continue;
      if (type == 3) return picture;
      first ??= picture;
    }
    return first;
  }

  String? _text(String id) {
    for (final frame in _readable(id)) {
      if (frame.data.isEmpty) continue;
      final text = _clean(_decode(frame.data[0], frame.data.sublist(1)));
      if (text != null) return text;
    }
    return null;
  }

  /// Frames with this id whose data is stored plainly: not compressed,
  /// encrypted, grouped or unsynchronised.
  Iterable<_Frame> _readable(String id) => _frames.where(
        (f) => f.id == id && f.flags & (version == 4 ? 0x4f : 0xe0) == 0,
      );
}

class _Frame {
  final String id;
  final int flags;
  final Uint8List data;

  /// The frame header and data as they are in the file.
  final Uint8List raw;
  _Frame(this.id, this.flags, this.data, this.raw);
}

const _headerSize = 10;

/// Reads the ID3v2 tag at the start of [file], or returns null if there is
/// none. Throws an [Id3Exception] for tags it can't rewrite safely.
Id3Tag? readId3(Uint8List file) {
  if (!_hasTag(file)) return null;
  final version = file[3];
  if (version != 3 && version != 4) {
    throw Id3Exception('ID3v2.$version tags are not supported');
  }
  final flags = file[5];
  if (flags & 0x80 != 0) {
    throw const Id3Exception('Unsynchronised ID3 tags are not supported');
  }
  final end = _headerSize + _syncsafe(file, 6);
  if (end > file.length) throw const Id3Exception('The tag is cut short');

  var pos = _headerSize;
  if (flags & 0x40 != 0) {
    pos += version == 4 ? _syncsafe(file, pos) : _int32(file, pos) + 4;
  }
  final frames = <_Frame>[];
  while (pos + _headerSize <= end && file[pos] != 0) {
    final idBytes = file.sublist(pos, pos + 4);
    if (!idBytes.every((c) => _isIdChar(c))) {
      throw const Id3Exception('The tag is damaged');
    }
    final size =
        version == 4 ? _syncsafe(file, pos + 4) : _int32(file, pos + 4);
    final next = pos + _headerSize + size;
    if (next > end) throw const Id3Exception('The tag is damaged');
    frames.add(_Frame(
      ascii.decode(idBytes),
      file[pos + 9],
      Uint8List.sublistView(file, pos + _headerSize, next),
      Uint8List.sublistView(file, pos, next),
    ));
    pos = next;
  }
  return Id3Tag._(version, frames);
}

/// Returns [file] with [edit] applied to its ID3v2 tag, keeping every other
/// frame and the audio as they were. Files without a tag get a v2.3 one.
Uint8List writeId3(Uint8List file, TagEdit edit) {
  final tag = readId3(file);
  final version = tag?.version ?? 3;
  final replaced = {
    if (edit.title != null) 'TIT2',
    if (edit.artist != null) 'TPE1',
    if (edit.album != null) 'TALB',
    if (edit.genre != null) 'TCON',
    if (edit.year != null) ...['TYER', 'TDRC'],
    if (edit.lyrics != null) 'USLT',
    if (edit.cover != null) 'APIC',
  };

  final body = BytesBuilder(copy: false);
  for (final frame in tag?._frames ?? const <_Frame>[]) {
    if (!replaced.contains(frame.id)) body.add(frame.raw);
  }
  void text(String id, String? value) {
    if (value == null || value.isEmpty) return;
    final (encoding, bytes) = _encode(value, version);
    body.add(_frame(id, [encoding, ...bytes], version));
  }

  text('TIT2', edit.title);
  text('TPE1', edit.artist);
  text('TALB', edit.album);
  text('TCON', edit.genre);
  text(version == 4 ? 'TDRC' : 'TYER', edit.year);
  if (edit.lyrics?.isNotEmpty ?? false) {
    final (encoding, bytes) = _encode(edit.lyrics!, version);
    body.add(_frame(
      'USLT',
      [
        encoding,
        ...ascii.encode('eng'),
        ...List.filled(_width(encoding), 0),
        ...bytes
      ],
      version,
    ));
  }
  final cover = edit.cover;
  if (cover != null && cover.isNotEmpty) {
    final mime = _isPng(cover) ? 'image/png' : 'image/jpeg';
    body.add(
        _frame('APIC', [0, ...ascii.encode(mime), 0, 3, 0, ...cover], version));
  }

  // * When the new tag fits in the old one's space it fills it, so the audio
  // * stays put and only the start of the file has to be written. Otherwise
  // * leave room to grow.
  final frames = body.takeBytes();
  final space = id3Length(file) - _headerSize;
  final padding = frames.length <= space ? space - frames.length : 1024;
  return (BytesBuilder(copy: false)
        ..add([0x49, 0x44, 0x33, version, 0, 0])
        ..add(_toSyncsafe(frames.length + padding))
        ..add(frames)
        ..add(Uint8List(padding))
        ..add(Uint8List.sublistView(file, id3Length(file))))
      .takeBytes();
}

bool _hasTag(Uint8List f) =>
    f.length >= _headerSize && f[0] == 0x49 && f[1] == 0x44 && f[2] == 0x33;

/// Bytes the ID3v2 tag takes at the start of a file, read from the file's
/// first 10 bytes. 0 when there is no tag.
int id3Length(Uint8List f) {
  if (!_hasTag(f)) return 0;
  final footer = f[3] == 4 && f[5] & 0x10 != 0;
  return _headerSize + _syncsafe(f, 6) + (footer ? _headerSize : 0);
}

bool _isIdChar(int c) => (c >= 0x41 && c <= 0x5a) || (c >= 0x30 && c <= 0x39);

bool _isPng(Uint8List b) =>
    b.length > 4 &&
    b[0] == 0x89 &&
    b[1] == 0x50 &&
    b[2] == 0x4e &&
    b[3] == 0x47;

int _syncsafe(Uint8List b, int o) =>
    (b[o] & 0x7f) << 21 |
    (b[o + 1] & 0x7f) << 14 |
    (b[o + 2] & 0x7f) << 7 |
    (b[o + 3] & 0x7f);

int _int32(Uint8List b, int o) =>
    b[o] << 24 | b[o + 1] << 16 | b[o + 2] << 8 | b[o + 3];

List<int> _toSyncsafe(int v) =>
    [(v >> 21) & 0x7f, (v >> 14) & 0x7f, (v >> 7) & 0x7f, v & 0x7f];

List<int> _toInt32(int v) =>
    [(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff];

Uint8List _frame(String id, List<int> data, int version) => Uint8List.fromList([
      ...ascii.encode(id),
      ...(version == 4 ? _toSyncsafe(data.length) : _toInt32(data.length)),
      0,
      0,
      ...data,
    ]);

/// Latin-1 when it fits, otherwise UTF-8 in v2.4 and UTF-16 in v2.3, which
/// has no UTF-8.
(int, List<int>) _encode(String value, int version) {
  if (value.codeUnits.every((c) => c < 0x100)) return (0, latin1.encode(value));
  if (version == 4) return (3, utf8.encode(value));
  return (
    1,
    [
      0xff,
      0xfe,
      for (final c in value.codeUnits) ...[c & 0xff, c >> 8]
    ],
  );
}

String _decode(int encoding, List<int> bytes) {
  switch (encoding) {
    case 0:
      return latin1.decode(bytes);
    case 3:
      return utf8.decode(bytes, allowMalformed: true);
    case 1:
    case 2:
      var bigEndian = encoding == 2;
      var start = 0;
      if (encoding == 1 && bytes.length >= 2) {
        if (bytes[0] == 0xfe && bytes[1] == 0xff) {
          bigEndian = true;
          start = 2;
        } else if (bytes[0] == 0xff && bytes[1] == 0xfe) {
          start = 2;
        }
      }
      return String.fromCharCodes([
        for (var i = start; i + 1 < bytes.length; i += 2)
          bigEndian
              ? bytes[i] << 8 | bytes[i + 1]
              : bytes[i + 1] << 8 | bytes[i],
      ]);
    default:
      throw Id3Exception('Unknown text encoding $encoding');
  }
}

/// Joins the values of a text frame and drops byte order marks and padding.
String? _clean(String text) {
  final value = text
      .split('\u0000')
      .map((part) => part.replaceAll(RegExp('[﻿￾]'), '').trim())
      .where((part) => part.isNotEmpty)
      .join(' / ');
  return value.isEmpty ? null : value;
}

int _width(int encoding) => encoding == 1 || encoding == 2 ? 2 : 1;

/// Index of the string terminator at or after [start], or -1.
int _terminator(Uint8List d, int start, int encoding) {
  if (_width(encoding) == 2) {
    for (var i = start; i + 1 < d.length; i += 2) {
      if (d[i] == 0 && d[i + 1] == 0) return i;
    }
    return -1;
  }
  return d.indexOf(0, start);
}
