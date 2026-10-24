import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'src/app.dart';
import 'src/data/library/device_music_library.dart';
import 'src/data/library/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'ir.salehtz.stash.playback',
    androidNotificationChannelName: 'Playback',
    androidNotificationIcon: 'drawable/ic_notification',
    androidNotificationOngoing: true,
  );
  runApp(MusicPlayerApp(
    library: DeviceMusicLibrary(),
    store: await LocalStore.open(),
  ));
}
