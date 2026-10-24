import 'dart:typed_data';

import '../models/song_model.dart';
import '../tags/tags.dart';

/// What became of asking for the permission to read music. [blocked] means
/// Android won't ask again, so only the system settings can grant it.
enum Access { granted, denied, blocked }

/// The songs on the phone, and the file access Stash needs to fix them.
abstract class MusicLibrary {
  Future<bool> hasPermission();

  /// Asks for permission to read the music on the phone.
  Future<Access> requestPermission();

  /// Opens Stash's page in the system settings, for when the permission was
  /// denied for good.
  Future<void> openSettings();

  /// Every song on the phone, newest first.
  Future<List<Song>> songs();

  /// The cover embedded in [song], about [size] pixels wide.
  Future<Uint8List?> artwork(Song song, int size);

  /// The tags in the song's file, or null when it has none.
  Future<SongTag?> readTag(Song song);

  /// Asks once to change [songs]. Android 11 and later show a system dialog
  /// for files other apps saved, like the ones from Telegram.
  Future<bool> requestWriteAccess(List<Song> songs);

  /// Deletes the files of [songs] after one OK from the user, which Android
  /// 11 and later ask for in a system dialog. False when the user said no.
  Future<bool> delete(List<Song> songs);

  /// Writes [edit] into the song's file and waits until the library knows.
  Future<void> writeTag(Song song, TagEdit edit);

  /// Songs shared to Stash from other apps, after they were saved to
  /// Music/Stash: the saved file names and how many could not be saved.
  Stream<({List<String> saved, int failed})> get imports;

  /// Fires when songs were added, changed or removed by something other
  /// than Stash, so the library is worth loading again.
  Stream<void> get changes;
}

/// A library of folders the user picks, as on a computer.
abstract interface class PickedFolders {
  /// The folders Stash looks in, with everything inside them.
  List<String> get folders;

  /// Adds [path], unless a folder already listed holds it. False when it
  /// was already there.
  Future<bool> addFolder(String path);

  Future<void> removeFolder(String path);

  /// Copies the audio files among [paths] into the first folder's "Stash"
  /// folder, and adds the folders among them. The result arrives on
  /// [MusicLibrary.imports]. Returns how many folders were added.
  Future<int> importPaths(List<String> paths);
}
