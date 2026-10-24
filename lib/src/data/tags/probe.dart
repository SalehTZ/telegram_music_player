import 'dart:io';
import 'dart:typed_data';

import 'id3.dart';
import 'tags.dart';

/// What Stash needs from a song file to list it: its tags and how long it
/// plays. Only the parts of the file that hold them are read.
class Probe {
  final SongTag? tag;
  final Duration duration;
  const Probe(this.tag, this.duration);
}

/// Reads the tags and length of the audio file at [path]. Null when it isn't
/// a format Stash can read.
Future<Probe?> probe(String path, {required String format}) async {
  final file = await File(path).open();
  try {
    final length = await file.length();
    Future<Uint8List> read(int start, int count) async {
      await file.setPosition(start);
      return file.read(count);
    }

    final head = await read(0, 64 * 1024);
    bool at(Uint8List b, int offset, String mark) =>
        b.length >= offset + mark.length &&
        String.fromCharCodes(b, offset, offset + mark.length) == mark;

    final id3 = id3Length(head);
    if (at(head, id3, 'fLaC')) return await _flac(read, id3);
    if (at(head, 0, 'OggS')) return await _ogg(read, head, length);
    if (at(head, 4, 'ftyp')) return await _mp4(read, length);
    if (format == 'MP3') return await _mp3(read, id3, length);
    return null;
  } on TagException {
    return null;
  } on RangeError {
    return null;
  } finally {
    await file.close();
  }
}

typedef _Read = Future<Uint8List> Function(int start, int count);

int _uint16le(Uint8List b, int o) => b[o] | b[o + 1] << 8;
int _uint32le(Uint8List b, int o) =>
    _uint16le(b, o) | _uint16le(b, o + 2) << 16;

// ---- MP3

const _bitratesV1 = [
  0,
  32,
  40,
  48,
  56,
  64,
  80,
  96,
  112,
  128,
  160,
  192,
  224,
  256,
  320
];
const _bitratesV2 = [
  0,
  8,
  16,
  24,
  32,
  40,
  48,
  56,
  64,
  80,
  96,
  112,
  128,
  144,
  160
];
const _sampleRates = [44100, 48000, 32000];

Future<Probe> _mp3(_Read read, int id3, int length) async {
  final tagBytes = id3 == 0 ? null : await read(0, id3);
  final tag = tagBytes == null ? null : readTags(tagBytes, format: 'MP3');
  final frames = await read(id3, 64 * 1024);
  for (var i = 0; i + 4 <= frames.length; i++) {
    if (frames[i] != 0xff || frames[i + 1] & 0xe0 != 0xe0) continue;
    final version =
        (frames[i + 1] >> 3) & 3; // * 3 MPEG-1, 2 MPEG-2, 0 MPEG-2.5
    final layer = (frames[i + 1] >> 1) & 3; // * 1 is Layer III
    final bitrateIndex = frames[i + 2] >> 4;
    final rateIndex = (frames[i + 2] >> 2) & 3;
    if (version == 1 ||
        layer != 1 ||
        bitrateIndex == 0 ||
        bitrateIndex == 15 ||
        rateIndex == 3) {
      continue;
    }
    final mpeg1 = version == 3;
    final rate = _sampleRates[rateIndex] >>
        (mpeg1
            ? 0
            : version == 2
                ? 1
                : 2);
    final samples = mpeg1 ? 1152 : 576;
    final mono = frames[i + 3] >> 6 == 3;

    // * A VBR file says how many frames it has in its first frame
    final side = mpeg1 ? (mono ? 17 : 32) : (mono ? 9 : 17);
    final xing = i + 4 + side;
    if (xing + 12 <= frames.length) {
      final mark = String.fromCharCodes(frames, xing, xing + 4);
      if ((mark == 'Xing' || mark == 'Info') && frames[xing + 7] & 1 != 0) {
        return Probe(
            tag, _seconds(readUint32(frames, xing + 8) * samples / rate));
      }
    }
    final vbri = i + 36;
    if (vbri + 18 <= frames.length &&
        String.fromCharCodes(frames, vbri, vbri + 4) == 'VBRI') {
      return Probe(
          tag, _seconds(readUint32(frames, vbri + 14) * samples / rate));
    }
    // * Otherwise every frame has the same bitrate
    final kbps = (mpeg1 ? _bitratesV1 : _bitratesV2)[bitrateIndex];
    final audio = length - id3 - i;
    return Probe(tag, _seconds(audio * 8 / (kbps * 1000)));
  }
  return Probe(tag, Duration.zero);
}

Duration _seconds(num seconds) =>
    Duration(milliseconds: (seconds * 1000).round());

// ---- FLAC

Future<Probe> _flac(_Read read, int id3) async {
  // * Walk the block headers to find where the metadata ends
  var pos = id3 + 4;
  while (true) {
    final header = await read(pos, 4);
    if (header.length < 4) throw const TagException('The file is cut short');
    pos += 4 + (header[1] << 16 | header[2] << 8 | header[3]);
    if (header[0] & 0x80 != 0) break;
  }
  final metadata = await read(0, pos);
  final info = id3 + 8; // * STREAMINFO is always first
  final rate = metadata[info + 10] << 12 |
      metadata[info + 11] << 4 |
      metadata[info + 12] >> 4;
  final total =
      (metadata[info + 13] & 0x0f) << 32 | readUint32(metadata, info + 14);
  return Probe(
    readTags(metadata, format: 'FLAC'),
    rate == 0 ? Duration.zero : _seconds(total / rate),
  );
}

// ---- Ogg Vorbis and Opus

Future<Probe> _ogg(_Read read, Uint8List head, int length) async {
  SongTag? tag;
  try {
    tag = readTags(head, format: 'OGG');
  } on TagException {
    // * The headers go past what was read, like a big cover: read them all
    tag = readTags(await read(0, length), format: 'OGG');
  }
  // * The identification header is the first packet, on the first page
  final first = 27 + head[26];
  final opus = String.fromCharCodes(head, first, first + 8) == 'OpusHead';
  final rate = opus ? 48000 : _uint32le(head, first + 12);
  final skip = opus ? _uint16le(head, first + 10) : 0;
  final serial = _uint32le(head, 14);

  // * The last page's granule position counts every sample
  final tailStart = length > 64 * 1024 ? length - 64 * 1024 : 0;
  final tail = await read(tailStart, length - tailStart);
  for (var i = tail.length - 27; i >= 0; i--) {
    if (tail[i] != 0x4f || String.fromCharCodes(tail, i, i + 4) != 'OggS') {
      continue;
    }
    if (_uint32le(tail, i + 14) != serial) continue;
    final granule = _uint32le(tail, i + 6) | _uint32le(tail, i + 10) << 32;
    if (granule < 0 || rate == 0) break;
    return Probe(tag, _seconds((granule - skip).clamp(0, granule) / rate));
  }
  return Probe(tag, Duration.zero);
}

// ---- M4A

Future<Probe> _mp4(_Read read, int length) async {
  // * Find the movie header among the top-level atoms, wherever it is
  var pos = 0;
  while (pos + 8 <= length) {
    final header = await read(pos, 16);
    var size = readUint32(header, 0);
    if (size == 1) size = readUint32(header, 8) << 32 | readUint32(header, 12);
    if (size == 0) size = length - pos;
    if (size < 8) break;
    if (String.fromCharCodes(header, 4, 8) == 'moov') {
      final moov = await read(pos, size);
      // * An empty "ftyp" in front marks it as MP4 for the tag reader
      final alone =
          Uint8List.fromList([0, 0, 0, 8, ...'ftyp'.codeUnits, ...moov]);
      return Probe(readTags(alone, format: 'M4A'), _movieLength(moov));
    }
    pos += size;
  }
  throw const TagException('The file is damaged');
}

/// The length in the "mvhd" atom of [moov].
Duration _movieLength(Uint8List moov) {
  var pos = 8;
  while (pos + 8 <= moov.length) {
    final size = readUint32(moov, pos);
    if (size < 8) break;
    if (String.fromCharCodes(moov, pos + 4, pos + 8) == 'mvhd') {
      final v1 = moov[pos + 8] == 1;
      final at = pos + 12 + (v1 ? 16 : 8);
      final scale = readUint32(moov, at);
      final units = v1
          ? readUint32(moov, at + 4) << 32 | readUint32(moov, at + 8)
          : readUint32(moov, at + 4);
      return scale == 0 ? Duration.zero : _seconds(units / scale);
    }
    pos += size;
  }
  return Duration.zero;
}
