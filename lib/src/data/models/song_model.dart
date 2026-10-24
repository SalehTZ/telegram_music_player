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
    if (dot == -1 || dot < _lastSeparator(path)) return '';
    return path.substring(dot + 1).toUpperCase();
  }

  /// What favorites, history and playlists remember the song by. Unlike
  /// [id] it means the same file on every platform and after a rescan.
  String get key => path;

  /// Stash can rewrite the tags of MP3, FLAC, Ogg, Opus and M4A files.
  bool get canEditTags => editableFormats.contains(format);

  /// Average bitrate in kbps, from the file size, tags included.
  int get bitrate =>
      duration.inMilliseconds == 0 ? 0 : size * 8 ~/ duration.inMilliseconds;

  String get folder {
    final slash = _lastSeparator(path);
    return slash <= 0 ? path.substring(0, slash + 1) : path.substring(0, slash);
  }

  /// The file's name, e.g. "Song.mp3".
  String get fileName => path.substring(_lastSeparator(path) + 1);

  /// Saved from Telegram: "Music/Telegram", "Download/Telegram", the
  /// "Telegram Audio" folder older versions used, or Telegram Desktop's
  /// "Downloads/Telegram Desktop".
  bool get fromTelegram =>
      folder.toLowerCase().replaceAll('\\', '/').contains('/telegram');

  /// Windows paths use backslashes.
  static int _lastSeparator(String path) {
    final slash = path.lastIndexOf('/');
    final backslash = path.lastIndexOf('\\');
    return slash > backslash ? slash : backslash;
  }

  /// The last part of a folder path, e.g. "Telegram".
  static String folderName(String folder) =>
      folder.substring(_lastSeparator(folder) + 1);

  String get artistOrUnknown => artist.isEmpty ? 'Unknown artist' : artist;

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
