import 'package:flutter/material.dart';

import '../blocs/library/library_cubit.dart';
import '../data/lyrics/lyrics.dart';
import '../data/models/song_model.dart';
import 'layout.dart';
import 'screens/duplicates_screen/duplicates_screen.dart';
import 'screens/edit_tags_screen/edit_tags_screen.dart';
import 'screens/lyrics_screen/lyrics_screen.dart';
import 'screens/player_screen/player_screen.dart';
import 'screens/song_list_screen/song_list_screen.dart';
import 'screens/tidy_screen/tidy_screen.dart';

Future<T?> _push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => ReadableWidth(child: page)),
    );

void openPlayer(BuildContext context) => _push(context, const PlayerScreen());

void openTidy(BuildContext context) => _push(context, const TidyScreen());

void openDuplicates(BuildContext context) =>
    _push(context, const DuplicatesScreen());

void openEditTags(BuildContext context, Song song) =>
    _push(context, EditTagsScreen(song: song));

/// The lyrics page. Calls [onFound] with lyrics found online.
void openLyrics(
  BuildContext context,
  Song song,
  Lyrics? lyrics, {
  ValueChanged<Lyrics>? onFound,
}) =>
    _push(context, LyricsScreen(song: song, lyrics: lyrics, onFound: onFound));

/// A page of songs that follows the library, e.g. a folder or a playlist.
void openSongList(
  BuildContext context, {
  required String title,
  required List<Song> Function(LibraryState state) select,
  String? playlistName,
}) =>
    _push(
      context,
      SongListScreen(title: title, select: select, playlistName: playlistName),
    );
