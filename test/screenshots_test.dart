// Renders the README screenshots. Skipped unless an output folder is given:
//
//   flutter test test/screenshots_test.dart \
//     --dart-define=SCREENSHOT_DIR=docs/screenshots
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telegram_music_player/src/app.dart';
import 'package:telegram_music_player/src/presentation/widgets/audio_player/mini_music_player.dart';
import 'package:telegram_music_player/src/presentation/widgets/common/round_button/round_button_widget.dart';

const screenshotDir = String.fromEnvironment('SCREENSHOT_DIR');
const _rootKey = ValueKey('screenshot-root');

Future<void> _loadFonts() async {
  final loader = FontLoader('Poppins');
  for (final weight in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
  }
  await loader.load();
}

/// Waits for images and SVGs, which load outside the fake test clock.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  await _settle(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_rootKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$screenshotDir/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets(
    'README screenshots',
    (tester) async {
      await _loadFonts();
      Directory(screenshotDir).createSync(recursive: true);

      // Same frame as the Figma design, with an Android sized status bar.
      tester.view.physicalSize = const Size(430, 932) * 2;
      tester.view.devicePixelRatio = 2;
      tester.view.padding = const FakeViewPadding(top: 24 * 2, bottom: 16 * 2);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const RepaintBoundary(key: _rootKey, child: MusicPlayerApp()),
      );
      await _capture(tester, 'home');

      await tester.tap(find.byType(RoundButtonWidget));
      await _capture(tester, 'drawer');

      await tester.tap(find.text('Songs'));
      await _capture(tester, 'songs');

      await tester.tap(find.byType(MiniPlayer));
      await _capture(tester, 'player');
    },
    skip: screenshotDir.isEmpty,
  );
}
