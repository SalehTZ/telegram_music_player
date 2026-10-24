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
    // * just_audio has no player of its own on Linux and Windows; macOS has
    JustAudioMediaKit.ensureInitialized(linux: true, windows: true);
    try {
      // * Media keys and the system's now playing: MPRIS on Linux, the
      // * media overlay on Windows and Control Center on macOS
      await JustAudioBackground.init(
        // * Names Stash on the session bus and in the controls
        androidNotificationChannelId: 'stash',
        androidNotificationChannelName: 'Stash',
      );
    } catch (_) {
      // * No session bus or the like: play without them
      if (!Platform.isMacOS) JustAudioMediaKit.registerWith();
    }
    final support = (await getApplicationSupportDirectory()).path;
    library = FolderMusicLibrary(
      FolderMusicLibrary.defaultFolders(),
      cache: File('$support/scan.json'),
      settings: File('$support/folders.json'),
    );
  }
  runApp(MusicPlayerApp(library: library, store: await LocalStore.open()));
}
