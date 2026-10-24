import '../data/models/song_model.dart';

/// "24 songs · 1 h 32 min"
String describeSongs(List<Song> songs) {
  final total = songs.fold(Duration.zero, (sum, s) => sum + s.duration);
  final count = songs.length == 1 ? '1 song' : '${songs.length} songs';
  if (total.inMinutes == 0) return count;
  final length = total.inHours > 0
      ? '${total.inHours} h ${total.inMinutes.remainder(60)} min'
      : '${total.inMinutes} min';
  return '$count · $length';
}

/// "Music/Telegram" instead of "/storage/emulated/0/Music/Telegram".
String displayPath(String path) =>
    path.replaceFirst(RegExp(r'^/storage/emulated/\d+/'), '');
