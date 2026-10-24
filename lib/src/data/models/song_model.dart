import '../tags/tags.dart';

/// A song in the phone's media library.
class Song {
  /// The media library's id for the file.
  final int id;
  final String title;

  /// Empty when the file doesn't name one.
  final String artist;
  final String album;

  /// Where the file is, e.g. "/storage/emulated/0/Music/Telegram/x.mp3".
  final String path;

  /// The media library's content URI for the file, used to play and write it.
  final String uri;
  final Duration duration;
  final DateTime added;

  /// File size in bytes.
  final int size;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.uri,
    required this.duration,
    required this.added,
    this.size = 0,
  });

  /// File format taken from the file extension, e.g. "MP3" or "FLAC".
  String get format {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot < path.lastIndexOf('/')) return '';
    return path.substring(dot + 1).toUpperCase();
  }

  /// What favorites, history and playlists remember the song by. Unlike
  /// [id] it means the same file on every platform and after a rescan.
  String get key => path;

  /// Stash can rewrite the tags of MP3, FLAC, Ogg, Opus and M4A files.
  bool get canEditTags => editableFormats.contains(format);

  String get folder {
    final slash = path.lastIndexOf('/');
    return slash <= 0 ? '/' : path.substring(0, slash);
  }

  /// Saved from Telegram: "Music/Telegram", "Download/Telegram", or the
  /// "Telegram Audio" folder older versions used.
  bool get fromTelegram => folder.toLowerCase().contains('/telegram');

  String get artistOrUnknown => artist.isEmpty ? 'Unknown artist' : artist;

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
