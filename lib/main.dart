import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app.dart';
import 'src/data/library/device_music_library.dart';
import 'src/data/library/folder_music_library.dart';
import 'src/data/library/local_store.dart';
import 'src/data/library/music_library.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final MusicLibrary library;
  if (Platform.isAndroid) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'ir.salehtz.stash.playback',
      androidNotificationChannelName: 'Playback',
      androidNotificationIcon: 'drawable/ic_notification',
      androidNotificationOngoing: true,
    );
    library = DeviceMusicLibrary();
  } else {
    // * just_audio has no player of its own on Linux and Windows
    JustAudioMediaKit.ensureInitialized(linux: true, windows: true);
    library = FolderMusicLibrary(
      FolderMusicLibrary.defaultFolders(),
      cache: File('${(await getApplicationSupportDirectory()).path}/scan.json'),
    );
  }
  runApp(MusicPlayerApp(library: library, store: await LocalStore.open()));
}
