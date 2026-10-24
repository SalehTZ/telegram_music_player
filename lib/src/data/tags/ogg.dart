import 'dart:typed_data';

import 'tags.dart';
import 'vorbis.dart';

/// One page of an Ogg stream.
class _Page {
  final int start;
  final int end;
  final int flags;
  final int serial;

  /// Sizes of the lacing segments, each up to 255 bytes.
  final List<int> segments;
  final int dataStart;
  _Page(this.start, this.end, this.flags, this.serial, this.segments,
      this.dataStart);
}

_Page _page(Uint8List file, int pos) {
  if (pos + 27 > file.length ||
      String.fromCharCodes(file, pos, pos + 4) != 'OggS') {
    throw const TagException('The file is damaged');
  }
  final count = file[pos + 26];
  final dataStart = pos + 27 + count;
  if (dataStart > file.length) {
    throw const TagException('The file is cut short');
  }
  final segments = file.sublist(pos + 27, dataStart);
  final end = dataStart + segments.fold<int>(0, (a, b) => a + b);
  if (end > file.length) throw const TagException('The file is cut short');
  final serial = ByteData.sublistView(file).getUint32(pos + 14, Endian.little);
  return _Page(pos, end, file[pos + 5], serial, segments, dataStart);
}

/// The codec's header packets at the start of the file, and where the first
/// page after them starts.
class _Headers {
  final bool opus;
  final List<Uint8List> packets;
  final int serial;
  final int pages;
  final int end;
  _Headers(this.opus, this.packets, this.serial, this.pages, this.end);

  /// Where the comments start in the comment packet.
  int get commentStart => opus ? 8 : 7;
}

_Headers _headers(Uint8List file) {
  final first = _page(file, 0);
  final packets = <Uint8List>[];
  var current = BytesBuilder(copy: false);
  int? wanted;
  var opus = false;
  var pos = 0;
  var pages = 0;
  while (wanted == null || packets.length < wanted) {
    if (pos >= file.length) throw const TagException('The file is cut short');
    final page = _page(file, pos);
    if (page.serial != first.serial) {
      throw const TagException("Stash can't change Ogg files with more than "
          'one stream');
    }
    var at = page.dataStart;
    for (final size in page.segments) {
      current.add(Uint8List.sublistView(file, at, at + size));
      at += size;
      if (size < 255) {
        packets.add(current.takeBytes());
        current = BytesBuilder(copy: false);
        if (packets.length == 1) {
          final id = packets.first;
          if (_starts(id, '\x01vorbis')) {
            wanted = 3;
          } else if (_starts(id, 'OpusHead')) {
            wanted = 2;
            opus = true;
          } else {
            throw const TagException(
                'Stash can change Ogg Vorbis and Opus files only');
          }
        }
      }
    }
    pos = page.end;
    pages++;
    if (wanted != null && packets.length > wanted) {
      throw const TagException('The file is damaged');
    }
  }
  if (current.isNotEmpty) throw const TagException('The file is damaged');
  final comment = packets[1];
  if (!_starts(comment, opus ? 'OpusTags' : '\x03vorbis')) {
    throw const TagException('The tag is damaged');
  }
  return _Headers(opus, packets, first.serial, pages, pos);
}

bool _starts(Uint8List data, String mark) =>
    data.length >= mark.length &&
    String.fromCharCodes(data, 0, mark.length) == mark;

/// The Vorbis comments of an Ogg Vorbis or Opus file.
VorbisComments readOgg(Uint8List file) {
  final headers = _headers(file);
  return VorbisComments.parse(headers.packets[1], headers.commentStart).$1;
}

/// Returns the Ogg [file] with [edit] applied. The header pages are written
/// again and the pages after them renumbered when their count changed.
Uint8List writeOgg(Uint8List file, TagEdit edit) {
  final headers = _headers(file);
  final packet = headers.packets[1];
  final (comments, end) = VorbisComments.parse(packet, headers.commentStart);
  final mark = Uint8List.sublistView(packet, 0, headers.commentStart);
  // * Vorbis ends the packet with a framing bit, Opus may keep extra data
  final rest = Uint8List.sublistView(packet, end);
  final newComment = Uint8List.fromList([
    ...mark,
    ...comments.apply(edit, pictureField: true).encode(),
    ...rest,
  ]);

  final out = BytesBuilder(copy: false);
  // * The first page holds only the identification header
  final first = _page(file, 0);
  out.add(Uint8List.sublistView(file, 0, first.end));
  final pages = _paginate(
    [newComment, ...headers.packets.skip(2)],
    serial: headers.serial,
    sequence: 1,
  );
  for (final page in pages) {
    out.add(page);
  }

  // * Every later page of the stream moves by as many pages as the headers
  // * grew or shrank
  final shift = 1 + pages.length - headers.pages;
  var pos = headers.end;
  while (pos < file.length) {
    final page = _page(file, pos);
    final bytes = Uint8List.fromList(file.sublist(page.start, page.end));
    if (shift != 0 && page.serial == headers.serial) {
      final view = ByteData.sublistView(bytes);
      view.setUint32(
          18, view.getUint32(18, Endian.little) + shift, Endian.little);
      _sign(bytes);
    }
    out.add(bytes);
    pos = page.end;
  }
  return out.takeBytes();
}

/// [packets] laid out on pages of up to 255 segments, granule position 0 as
/// header pages have.
List<Uint8List> _paginate(
  List<Uint8List> packets, {
  required int serial,
  required int sequence,
}) {
  final segments = <(int, Uint8List)>[];
  for (final packet in packets) {
    var at = 0;
    while (true) {
      final size = (packet.length - at).clamp(0, 255);
      segments.add((size, Uint8List.sublistView(packet, at, at + size)));
      at += size;
      if (size < 255) break;
    }
  }
  final pages = <Uint8List>[];
  var continued = false;
  for (var i = 0; i < segments.length; i += 255) {
    final chunk = segments.sublist(i, (i + 255).clamp(0, segments.length));
    final header = ByteData(27)
      ..setUint32(0, 0x5367674f, Endian.little) // * "OggS"
      ..setUint8(4, 0)
      ..setUint8(5, continued ? 1 : 0)
      ..setUint32(14, serial, Endian.little)
      ..setUint32(18, sequence++, Endian.little)
      ..setUint8(26, chunk.length);
    final page = (BytesBuilder(copy: false)
          ..add(header.buffer.asUint8List())
          ..add([for (final (size, _) in chunk) size])
          ..add([for (final (_, data) in chunk) ...data]))
        .takeBytes();
    _sign(page);
    pages.add(page);
    continued = chunk.last.$1 == 255;
  }
  return pages;
}

final _crcTable = List<int>.generate(256, (i) {
  var r = i << 24;
  for (var j = 0; j < 8; j++) {
    r = r & 0x80000000 != 0 ? ((r << 1) ^ 0x04c11db7) : r << 1;
  }
  return r & 0xffffffff;
});

/// Writes the page's checksum into it.
void _sign(Uint8List page) {
  page.setRange(22, 26, const [0, 0, 0, 0]);
  var crc = 0;
  for (final b in page) {
    crc = ((crc << 8) & 0xffffffff) ^ _crcTable[((crc >> 24) & 0xff) ^ b];
  }
  ByteData.sublistView(page).setUint32(22, crc, Endian.little);
}
