import 'dart:typed_data';

import 'flac.dart';
import 'id3.dart';
import 'mp4.dart';
import 'ogg.dart';

/// Thrown when a file's tag can't be read or safely rewritten.
class TagException implements Exception {
  final String message;
  const TagException(this.message);

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

/// The tags of a song, whatever its format.
abstract class SongTag {
  String? get title;
  String? get artist;
  String? get album;
  String? get year;
  String? get genre;
  String? get lyrics;

  /// The front cover, or the first picture when none is marked as the front.
  Uint8List? get cover;
}

/// File extensions whose tags Stash can change.
const editableFormats = {'MP3', 'FLAC', 'OGG', 'OGA', 'OPUS', 'M4A', 'M4B'};

enum _Kind { id3, flac, ogg, mp4 }

/// What's inside [file], told by its first bytes rather than its name. Only
/// an MP3 has no mark of its own, so [format] (the file extension) decides it.
_Kind _kind(Uint8List file, String format) {
  bool at(int offset, String mark) =>
      file.length >= offset + mark.length &&
      String.fromCharCodes(file, offset, offset + mark.length) == mark;
  // * FLAC files sometimes carry an ID3 tag in front
  if (at(id3Length(file), 'fLaC')) return _Kind.flac;
  if (at(0, 'OggS')) return _Kind.ogg;
  if (at(4, 'ftyp')) return _Kind.mp4;
  // * An ID3 tag in front of any other format would damage the file
  if (format == 'MP3') return _Kind.id3;
  throw TagException(format.isEmpty
      ? "Stash can't change the tags of this file"
      : "Stash can't change the tags of $format files");
}

/// The tags in [file], or null when it has none.
SongTag? readTags(Uint8List file, {required String format}) =>
    switch (_kind(file, format)) {
      _Kind.id3 => readId3(file),
      _Kind.flac => readFlac(file),
      _Kind.ogg => readOgg(file),
      _Kind.mp4 => readMp4(file),
    };

/// Returns [file] with [edit] applied, keeping the audio and every tag the
/// edit doesn't name.
Uint8List writeTags(Uint8List file, TagEdit edit, {required String format}) =>
    switch (_kind(file, format)) {
      _Kind.id3 => writeId3(file, edit),
      _Kind.flac => writeFlac(file, edit),
      _Kind.ogg => writeOgg(file, edit),
      _Kind.mp4 => writeMp4(file, edit),
    };

/// Big-endian integers, as FLAC and MP4 store them.
int readUint32(Uint8List b, int o) =>
    b[o] << 24 | b[o + 1] << 16 | b[o + 2] << 8 | b[o + 3];

List<int> uint32(int v) =>
    [(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff];

bool isPng(Uint8List b) =>
    b.length > 4 &&
    b[0] == 0x89 &&
    b[1] == 0x50 &&
    b[2] == 0x4e &&
    b[3] == 0x47;
