import 'dart:io';

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

/// "Music/Telegram" instead of "/storage/emulated/0/Music/Telegram", and
/// "~/Music" instead of "/home/you/Music".
String displayPath(String path) {
  final home =
      Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'];
  if (!Platform.isAndroid && home != null && home.length > 1) {
    if (path == home) return '~';
    if (path.startsWith('$home${Platform.pathSeparator}')) {
      return '~${path.substring(home.length)}';
    }
  }
  return path.replaceFirst(RegExp(r'^/storage/emulated/\d+/'), '');
}
