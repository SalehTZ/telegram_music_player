// Renders the README screenshots from the demo library. Skipped unless an
// output folder is given:
//
//   flutter test test/screenshots_test.dart \
//     --dart-define=SCREENSHOT_DIR=docs/screenshots
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/app.dart';
import 'package:stash/src/data/library/local_store.dart';
import 'package:stash/src/presentation/widgets/audio_player/mini_music_player.dart';
import 'package:stash/src/presentation/widgets/common/round_button/round_button_widget.dart';
import 'package:stash/src/presentation/widgets/song_list_item/song_list_item_widget.dart';

import 'support/demo_library.dart';
import 'support/fake_audio.dart';
import 'support/pump_app.dart';

const screenshotDir = String.fromEnvironment('SCREENSHOT_DIR');
const _rootKey = ValueKey('screenshot-root');

Future<void> _loadFonts() async {
  final loader = FontLoader('Poppins');
  for (final weight in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
  }
  await loader.load();

  // * Material icons ship with the SDK, not with the test renderer
  final icons = File('${Platform.environment['FLUTTER_ROOT']}'
      '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync()))))
      .load();
}

/// Plain two-colour covers for the demo songs, so the screenshots show
/// covers without using anyone's album art.
Future<Uint8List> _cover(int seed) async {
  const palettes = [
    (Color(0xFFC8553D), Color(0xFFF2D0A4)),
    (Color(0xFF1D3557), Color(0xFFA8DADC)),
    (Color(0xFF2D6A4F), Color(0xFFD8F3DC)),
    (Color(0xFF6D597A), Color(0xFFE56B6F)),
    (Color(0xFF264653), Color(0xFFE9C46A)),
    (Color(0xFF3D405B), Color(0xFFF2CC8F)),
    (Color(0xFF8C2F39), Color(0xFFFCB9B2)),
    (Color(0xFF14213D), Color(0xFFFCA311)),
  ];
  final (ground, ink) = palettes[seed % palettes.length];
  const size = 400.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(const Rect.fromLTWH(0, 0, size, size), Paint()..color = ground);
  final paint = Paint()..color = ink;
  switch (seed % 4) {
    case 0:
      canvas.drawCircle(
          const Offset(size * 0.62, size * 0.42), size * 0.3, paint);
    case 1:
      for (var i = 0; i < 5; i++) {
        canvas.drawRect(
            Rect.fromLTWH(0, size * (0.15 + i * 0.16), size, size * 0.06),
            paint);
      }
    case 2:
      canvas.drawCircle(const Offset(0, size), size * 0.75, paint);
    default:
      canvas.drawPath(
        Path()
          ..moveTo(0, size)
          ..lineTo(size, 0)
          ..lineTo(size, size)
          ..close(),
        paint,
      );
      canvas.drawCircle(
          const Offset(size * 0.3, size * 0.3),
          size * 0.12,
          Paint()
            ..color = ground.withRed(min(255, (ground.r * 255).round() + 40)));
  }
  final image = await recorder.endRecording().toImage(400, 400);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// Waits for covers and SVGs, which load outside the fake test clock.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump(const Duration(milliseconds: 400));
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

      // * The untagged file keeps the placeholder. The test renderer can't
      // * fall back to a font with Persian letters, so that song sits out.
      final covers = <int, Uint8List>{};
      await tester.runAsync(() async {
        for (var id = 1; id <= 10; id++) {
          if (id != 5) covers[id] = await _cover(id * 3);
        }
      });
      final library = DemoMusicLibrary(persian: false, covers: covers);

      // * The Figma frame, with an Android sized status bar
      tester.view.physicalSize = const Size(430, 932) * 2;
      tester.view.devicePixelRatio = 2;
      tester.view.padding = const FakeViewPadding(top: 24 * 2, bottom: 16 * 2);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(RepaintBoundary(
        key: _rootKey,
        child: MusicPlayerApp(
          library: library,
          store: LocalStore.memory(),
          player: fakeAudioPlayer(),
        ),
      ));
      await tester.pumpAndSettle();
      await _capture(tester, 'home');

      await tester.tap(find.text('Tidy up'));
      await tester.pumpAndSettle();
      await _capture(tester, 'tidy');
      await tester.tap(find.text('Clean 5 songs'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RoundButtonWidget).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RoundButtonWidget));
      await tester.pumpAndSettle();
      await _capture(tester, 'drawer');
      await tester.tap(find.text('Folders'));
      await tester.pumpAndSettle();
      await _capture(tester, 'folders');

      await tester.tap(find.byType(RoundButtonWidget));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Songs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Do I Wanna Know?'));
      await settlePlayer(tester);
      await _capture(tester, 'songs');

      await tester.tap(find.byType(MiniPlayer));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await _capture(tester, 'player');
      await tester.tap(find.byType(RoundButtonWidget).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final item = find.ancestor(
        of: find.text('Blinding Lights'),
        matching: find.byType(SongListItemWidget),
      );
      await tester.tap(find.descendant(
        of: item,
        matching: find
            .byWidgetPredicate((w) => w.runtimeType.toString() == 'SvgPicture'),
      ));
      // * The first frame starts the sheet's slide; the next one ends it
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Edit tags and cover'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await _capture(tester, 'edit');

      await closeApp(tester);
    },
    skip: screenshotDir.isEmpty,
  );
}
