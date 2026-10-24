import 'dart:typed_data';

import 'id3.dart';
import 'tags.dart';
import 'vorbis.dart';

const _streamInfo = 0;
const _padding = 1;
const _comment = 4;
const _picture = 6;

/// A block of a FLAC file's metadata, before the audio.
class _Block {
  final int type;
  final Uint8List data;
  _Block(this.type, this.data);
}

/// Where "fLaC" starts, after an ID3 tag some files carry in front.
int _start(Uint8List file) => id3Length(file);

/// The metadata blocks and where the audio starts.
(List<_Block>, int) _blocks(Uint8List file) {
  var pos = _start(file) + 4;
  final blocks = <_Block>[];
  while (true) {
    if (pos + 4 > file.length) {
      throw const TagException('The file is cut short');
    }
    final header = file[pos];
    final length = file[pos + 1] << 16 | file[pos + 2] << 8 | file[pos + 3];
    final end = pos + 4 + length;
    if (end > file.length) throw const TagException('The tag is damaged');
    blocks
        .add(_Block(header & 0x7f, Uint8List.sublistView(file, pos + 4, end)));
    pos = end;
    if (header & 0x80 != 0) return (blocks, pos);
  }
}

/// The Vorbis comments and pictures of a FLAC file, or null when it has
/// neither.
VorbisComments? readFlac(Uint8List file) {
  final (blocks, _) = _blocks(file);
  VorbisComments? comments;
  final pictures = <FlacPicture>[];
  for (final block in blocks) {
    if (block.type == _comment && comments == null) {
      comments = VorbisComments.parse(block.data, 0).$1;
    } else if (block.type == _picture) {
      pictures.add(FlacPicture.parse(block.data));
    }
  }
  if (comments == null && pictures.isEmpty) return null;
  return VorbisComments(
      comments?.vendor ?? 'Stash', comments?.fields ?? const [], pictures);
}

/// Returns the FLAC [file] with [edit] applied. Blocks Stash doesn't know
/// stay as they are, and padding takes up any change in size, so the audio
/// doesn't move when the new tags fit in the old space.
Uint8List writeFlac(Uint8List file, TagEdit edit) {
  final (blocks, audio) = _blocks(file);
  if (blocks.isEmpty || blocks.first.type != _streamInfo) {
    throw const TagException('The file is damaged');
  }
  final tag = readFlac(file) ?? VorbisComments('Stash', const []);
  final cover = edit.cover;
  final kept = [
    for (final b in blocks)
      if (b.type != _padding &&
          b.type != _comment &&
          !(b.type == _picture && cover != null))
        b,
  ];
  final pictures = [
    if (cover != null && cover.isNotEmpty) FlacPicture.frontCover(cover),
  ];
  final next = [
    kept.first,
    _Block(_comment, tag.apply(edit).encode()),
    ...kept.skip(1),
    for (final p in pictures) _Block(_picture, p.encode()),
  ];
  if (next.any((b) => b.data.length >= 1 << 24)) {
    throw const TagException('The cover is too big for a FLAC file');
  }

  final space = audio - _start(file) - 4;
  final used = next.fold(0, (sum, b) => sum + 4 + b.data.length);
  // * Fill the old space when the tags fit, with room for a padding header,
  // * otherwise leave room to grow
  final padding = used == space
      ? null
      : used + 4 <= space
          ? space - used - 4
          : 4096;
  if (padding != null) next.add(_Block(_padding, Uint8List(padding)));

  final out = BytesBuilder(copy: false)
    ..add(Uint8List.sublistView(file, 0, _start(file) + 4));
  for (final (i, b) in next.indexed) {
    final last = i == next.length - 1 ? 0x80 : 0;
    final n = b.data.length;
    out
      ..add([b.type | last, (n >> 16) & 0xff, (n >> 8) & 0xff, n & 0xff])
      ..add(b.data);
  }
  out.add(Uint8List.sublistView(file, audio));
  return out.takeBytes();
}
