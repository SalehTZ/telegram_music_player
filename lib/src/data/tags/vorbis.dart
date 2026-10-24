import 'dart:convert';
import 'dart:typed_data';

import 'tags.dart';

/// Vorbis comments, the tags of FLAC, Ogg Vorbis and Opus files: a vendor
/// string and a list of "KEY=value" fields.
class VorbisComments implements SongTag {
  final String vendor;
  final List<(String, String)> fields;

  /// FLAC keeps pictures in their own blocks; Ogg files keep them here.
  final List<FlacPicture> pictures;

  VorbisComments(this.vendor, this.fields, [this.pictures = const []]);

  @override
  String? get title => _get(['TITLE']);
  @override
  String? get artist => _get(['ARTIST']);
  @override
  String? get album => _get(['ALBUM']);
  @override
  String? get genre => _get(['GENRE']);
  @override
  String? get year {
    final value = _get(['DATE', 'YEAR']);
    return value == null || value.length <= 4 ? value : value.substring(0, 4);
  }

  @override
  String? get lyrics => _get(['LYRICS', 'UNSYNCEDLYRICS']);

  @override
  Uint8List? get cover => FlacPicture.front([
        ...pictures,
        for (final value in _all('METADATA_BLOCK_PICTURE'))
          if (FlacPicture.tryParse(value) case final picture?) picture,
      ]);

  Iterable<String> _all(String key) => [
        for (final (k, v) in fields)
          if (k.toUpperCase() == key) v
      ];

  /// The values of the first key that has any, joined like ID3's.
  String? _get(List<String> keys) {
    for (final key in keys) {
      final values = [
        for (final v in _all(key))
          if (v.trim().isNotEmpty) v.trim()
      ];
      if (values.isNotEmpty) return values.join(' / ');
    }
    return null;
  }

  /// These comments with [edit] applied. With [pictureField] the cover is
  /// kept as a METADATA_BLOCK_PICTURE field, as Ogg files do.
  VorbisComments apply(TagEdit edit, {bool pictureField = false}) {
    final replaced = {
      if (edit.title != null) 'TITLE',
      if (edit.artist != null) 'ARTIST',
      if (edit.album != null) 'ALBUM',
      if (edit.genre != null) 'GENRE',
      if (edit.year != null) ...['DATE', 'YEAR'],
      if (edit.lyrics != null) ...['LYRICS', 'UNSYNCEDLYRICS'],
      if (edit.cover != null) ...['METADATA_BLOCK_PICTURE', 'COVERART'],
    };
    final cover = edit.cover;
    return VorbisComments(vendor, [
      for (final field in fields)
        if (!replaced.contains(field.$1.toUpperCase())) field,
      for (final (key, value) in [
        ('TITLE', edit.title),
        ('ARTIST', edit.artist),
        ('ALBUM', edit.album),
        ('DATE', edit.year),
        ('GENRE', edit.genre),
        ('LYRICS', edit.lyrics),
      ])
        if (value != null && value.isNotEmpty) (key, value),
      if (pictureField && cover != null && cover.isNotEmpty)
        (
          'METADATA_BLOCK_PICTURE',
          base64.encode(FlacPicture.frontCover(cover).encode())
        ),
    ]);
  }

  /// Reads the comments at [start] of [data] and where they end.
  static (VorbisComments, int) parse(Uint8List data, int start) {
    final view = ByteData.sublistView(data);
    var pos = start;
    String text() {
      if (pos + 4 > data.length) throw const TagException('The tag is damaged');
      final length = view.getUint32(pos, Endian.little);
      pos += 4;
      if (pos + length > data.length) {
        throw const TagException('The tag is damaged');
      }
      final value = utf8.decode(
        Uint8List.sublistView(data, pos, pos + length),
        allowMalformed: true,
      );
      pos += length;
      return value;
    }

    final vendor = text();
    if (pos + 4 > data.length) throw const TagException('The tag is damaged');
    final count = view.getUint32(pos, Endian.little);
    pos += 4;
    final fields = <(String, String)>[];
    for (var i = 0; i < count; i++) {
      final field = text();
      final eq = field.indexOf('=');
      if (eq > 0) fields.add((field.substring(0, eq), field.substring(eq + 1)));
    }
    return (VorbisComments(vendor, fields), pos);
  }

  Uint8List encode() {
    final out = BytesBuilder(copy: false);
    void text(String value) {
      final bytes = utf8.encode(value);
      out
        ..add(_uint32le(bytes.length))
        ..add(bytes);
    }

    text(vendor);
    out.add(_uint32le(fields.length));
    for (final (key, value) in fields) {
      text('$key=$value');
    }
    return out.takeBytes();
  }
}

List<int> _uint32le(int v) =>
    [v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff];

/// A FLAC PICTURE block, which Ogg files also keep, base64 encoded, in a
/// METADATA_BLOCK_PICTURE comment.
class FlacPicture {
  /// 3 is the front cover.
  final int type;
  final Uint8List data;

  /// The block as it was read, so pictures Stash doesn't change stay exact.
  final Uint8List? _raw;

  FlacPicture(this.type, this.data, [this._raw]);

  factory FlacPicture.frontCover(Uint8List image) => FlacPicture(3, image);

  static FlacPicture parse(Uint8List block) {
    try {
      var pos = 0;
      int next() {
        final v = readUint32(block, pos);
        pos += 4;
        return v;
      }

      final type = next();
      final mime = next();
      pos += mime;
      final description = next();
      pos += description;
      pos += 16; // * Width, height, depth and colors
      final length = next();
      if (pos + length > block.length) throw RangeError('picture');
      return FlacPicture(
          type, Uint8List.sublistView(block, pos, pos + length), block);
    } on RangeError {
      throw const TagException('A picture in the tag is damaged');
    }
  }

  static FlacPicture? tryParse(String base64Value) {
    try {
      return parse(base64.decode(base64Value.trim()));
    } on FormatException {
      return null;
    } on TagException {
      return null;
    }
  }

  static Uint8List? front(List<FlacPicture> pictures) {
    final usable = pictures.where((p) => p.data.isNotEmpty);
    return (usable.where((p) => p.type == 3).firstOrNull ?? usable.firstOrNull)
        ?.data;
  }

  Uint8List encode() {
    if (_raw case final raw?) return raw;
    final mime = ascii.encode(isPng(data) ? 'image/png' : 'image/jpeg');
    return Uint8List.fromList([
      ...uint32(type),
      ...uint32(mime.length),
      ...mime,
      ...uint32(0),
      // * Width, height, depth and colors may be 0 for unknown
      ...List.filled(16, 0),
      ...uint32(data.length),
      ...data,
    ]);
  }
}
