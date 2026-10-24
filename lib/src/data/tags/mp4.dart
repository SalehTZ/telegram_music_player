import 'dart:convert';
import 'dart:typed_data';

import 'tags.dart';

/// An MP4 box ("atom"): its type, where it starts and ends, and where its
/// content starts after the header.
class _Atom {
  final String type;
  final int start;
  final int content;
  final int end;
  _Atom(this.type, this.start, this.content, this.end);
}

List<_Atom> _atoms(Uint8List b, int start, int end) {
  final atoms = <_Atom>[];
  var pos = start;
  while (pos + 8 <= end) {
    var size = readUint32(b, pos);
    var header = 8;
    if (size == 1) {
      if (pos + 16 > end) break;
      size = readUint32(b, pos + 8) << 32 | readUint32(b, pos + 12);
      header = 16;
    } else if (size == 0) {
      size = end - pos;
    }
    if (size < header || pos + size > end) {
      throw const TagException('The file is damaged');
    }
    atoms.add(_Atom(latin1.decode(b.sublist(pos + 4, pos + 8)), pos,
        pos + header, pos + size));
    pos += size;
  }
  return atoms;
}

_Atom? _child(Uint8List b, _Atom parent, String type, {int skip = 0}) =>
    _atoms(b, parent.content + skip, parent.end)
        .where((a) => a.type == type)
        .firstOrNull;

// * "meta" is a full box: 4 bytes of version and flags before its children
const _metaSkip = 4;

const _title = '©nam';
const _artist = '©ART';
const _album = '©alb';
const _year = '©day';
const _genre = '©gen';
const _lyrics = '©lyr';
const _cover = 'covr';

/// The iTunes-style tags of an M4A file.
class Mp4Tag implements SongTag {
  final Map<String, List<(int, Uint8List)>> _items;
  Mp4Tag._(this._items);

  String? _text(String name) {
    final values = [
      for (final (type, data) in _items[name] ?? const <(int, Uint8List)>[])
        if (type == 1) utf8.decode(data, allowMalformed: true).trim(),
    ].where((v) => v.isNotEmpty);
    return values.isEmpty ? null : values.join(' / ');
  }

  @override
  String? get title => _text(_title);
  @override
  String? get artist => _text(_artist);
  @override
  String? get album => _text(_album);
  @override
  String? get genre => _text(_genre);
  @override
  String? get lyrics => _text(_lyrics);
  @override
  String? get year {
    final value = _text(_year);
    return value == null || value.length <= 4 ? value : value.substring(0, 4);
  }

  @override
  Uint8List? get cover =>
      _items[_cover]?.where((d) => d.$2.isNotEmpty).firstOrNull?.$2;
}

/// The atoms from the file down to "ilst", the ones that exist.
({_Atom moov, _Atom? udta, _Atom? meta, _Atom? ilst}) _path(Uint8List file) {
  final moov =
      _atoms(file, 0, file.length).where((a) => a.type == 'moov').firstOrNull;
  if (moov == null) throw const TagException('The file is damaged');
  final udta = _child(file, moov, 'udta');
  final meta = udta == null ? null : _child(file, udta, 'meta');
  final ilst =
      meta == null ? null : _child(file, meta, 'ilst', skip: _metaSkip);
  return (moov: moov, udta: udta, meta: meta, ilst: ilst);
}

Mp4Tag? readMp4(Uint8List file) {
  final ilst = _path(file).ilst;
  if (ilst == null) return null;
  final items = <String, List<(int, Uint8List)>>{};
  for (final item in _atoms(file, ilst.content, ilst.end)) {
    for (final data in _atoms(file, item.content, item.end)) {
      if (data.type != 'data' || data.content + 8 > data.end) continue;
      items.putIfAbsent(item.type, () => []).add((
        readUint32(file, data.content) & 0xffffff,
        Uint8List.sublistView(file, data.content + 8, data.end),
      ));
    }
  }
  return Mp4Tag._(items);
}

Uint8List _box(String type, List<int> content) => Uint8List.fromList([
      ...uint32(content.length + 8),
      ...latin1.encode(type),
      ...content,
    ]);

Uint8List _item(String name, int type, List<int> data) =>
    _box(name, _box('data', [...uint32(type), 0, 0, 0, 0, ...data]));

/// [parent] with its child [old] replaced by [child], or [child] added at
/// the end when [old] is null. [skip] bytes after the header stay in front.
Uint8List _replace(Uint8List b, _Atom parent, _Atom? old, Uint8List child,
    {int skip = 0}) {
  final content = BytesBuilder(copy: false)
    ..add(Uint8List.sublistView(b, parent.content, parent.content + skip));
  for (final atom in _atoms(b, parent.content + skip, parent.end)) {
    if (atom.start == old?.start) {
      content.add(child);
    } else {
      content.add(Uint8List.sublistView(b, atom.start, atom.end));
    }
  }
  if (old == null) content.add(child);
  return _box(parent.type, content.takeBytes());
}

/// Returns the M4A [file] with [edit] applied. A "free" atom after the
/// movie header takes up the change in size when it can, so the audio
/// doesn't move; otherwise the audio's offsets are moved with it.
Uint8List writeMp4(Uint8List file, TagEdit edit) {
  final path = _path(file);
  final replaced = {
    if (edit.title != null) _title,
    if (edit.artist != null) _artist,
    if (edit.album != null) _album,
    if (edit.genre != null) ...[_genre, 'gnre'],
    if (edit.year != null) _year,
    if (edit.lyrics != null) _lyrics,
    if (edit.cover != null) _cover,
  };

  final items = BytesBuilder(copy: false);
  if (path.ilst case final ilst?) {
    for (final item in _atoms(file, ilst.content, ilst.end)) {
      if (!replaced.contains(item.type)) {
        items.add(Uint8List.sublistView(file, item.start, item.end));
      }
    }
  }
  for (final (name, value) in [
    (_title, edit.title),
    (_artist, edit.artist),
    (_album, edit.album),
    (_year, edit.year),
    (_genre, edit.genre),
    (_lyrics, edit.lyrics),
  ]) {
    if (value != null && value.isNotEmpty) {
      items.add(_item(name, 1, utf8.encode(value)));
    }
  }
  final cover = edit.cover;
  if (cover != null && cover.isNotEmpty) {
    items.add(_item(_cover, isPng(cover) ? 14 : 13, cover));
  }

  final ilst = _box('ilst', items.takeBytes());
  final meta = switch (path.meta) {
    final meta? => _replace(file, meta, path.ilst, ilst, skip: _metaSkip),
    null => _box('meta', [
        0, 0, 0, 0,
        // * The handler that marks these as iTunes tags
        ..._box('hdlr', [
          ...List.filled(8, 0),
          ...ascii.encode('mdirappl'),
          ...List.filled(9, 0),
        ]),
        ...ilst,
      ]),
  };
  final udta = switch (path.udta) {
    final udta? => _replace(file, udta, path.meta, meta),
    null => _box('udta', meta),
  };
  final moov = _replace(file, path.moov, path.udta, udta);

  // * The free space right after the movie header can grow or shrink
  final top = _atoms(file, 0, file.length);
  final next = top.where((a) => a.start == path.moov.end).firstOrNull;
  final free = next != null && (next.type == 'free' || next.type == 'skip')
      ? next
      : null;
  final oldEnd = free?.end ?? path.moov.end;
  final room = oldEnd - path.moov.start;
  final Uint8List padding;
  if (moov.length == room) {
    padding = Uint8List(0);
  } else if (moov.length + 8 <= room) {
    padding = _box('free', Uint8List(room - moov.length - 8));
  } else {
    padding = _box('free', Uint8List(1024));
  }
  final shift = moov.length + padding.length - room;
  if (shift != 0 && top.any((a) => a.type == 'moof')) {
    throw const TagException("Stash can't change the tags of this M4A file");
  }
  if (shift != 0) _moveChunks(moov, from: oldEnd, by: shift);

  return (BytesBuilder(copy: false)
        ..add(Uint8List.sublistView(file, 0, path.moov.start))
        ..add(moov)
        ..add(padding)
        ..add(Uint8List.sublistView(file, oldEnd)))
      .takeBytes();
}

/// Moves every audio chunk offset at or after [from] by [by], in place in
/// the [moov] atom.
void _moveChunks(Uint8List moov, {required int from, required int by}) {
  final root = _atoms(moov, 0, moov.length).single;
  final view = ByteData.sublistView(moov);
  for (final trak in _atoms(moov, root.content, root.end)) {
    if (trak.type != 'trak') continue;
    final stbl = [
      'mdia',
      'minf',
      'stbl'
    ].fold<_Atom?>(trak, (a, type) => a == null ? null : _child(moov, a, type));
    if (stbl == null) continue;
    for (final table in _atoms(moov, stbl.content, stbl.end)) {
      final wide = table.type == 'co64';
      if (table.type != 'stco' && !wide) continue;
      final count = readUint32(moov, table.content + 4);
      var pos = table.content + 8;
      for (var i = 0; i < count; i++, pos += wide ? 8 : 4) {
        if (pos + (wide ? 8 : 4) > table.end) {
          throw const TagException('The file is damaged');
        }
        final offset = wide ? view.getUint64(pos) : view.getUint32(pos);
        if (offset < from) continue;
        final moved = offset + by;
        if (wide) {
          view.setUint64(pos, moved);
        } else if (moved > 0xffffffff) {
          throw const TagException('The file is too big to change');
        } else {
          view.setUint32(pos, moved);
        }
      }
    }
  }
}
