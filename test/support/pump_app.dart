import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/app.dart';
import 'package:stash/src/data/library/local_store.dart';

import 'demo_library.dart';
import 'fake_audio.dart';

/// Starts the app on [library] in a phone-sized window, or one of [size].
Future<DemoMusicLibrary> pumpApp(
  WidgetTester tester, {
  DemoMusicLibrary? library,
  Size size = const Size(430, 932),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final demo = library ?? DemoMusicLibrary();
  await tester.pumpWidget(MusicPlayerApp(
    library: demo,
    store: LocalStore.memory(),
    player: fakeAudioPlayer(),
  ));
  await tester.pumpAndSettle();
  return demo;
}

/// Takes the app down and lets the player's position timer see it, so no
/// timer is left running when the test ends.
Future<void> closeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await settlePlayer(tester);
  await tester.pump(const Duration(seconds: 1));
}

/// Lets the player finish loading a song: part of just_audio's work runs
/// outside the test's fake clock.
Future<void> settlePlayer(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}
