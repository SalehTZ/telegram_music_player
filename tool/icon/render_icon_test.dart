// Renders the launcher, notification and README icons from the mark in code, so
// the logo stays editable in one place:
//
//   flutter test tool/icon/render_icon_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/constants/colors_manager.dart';
import 'package:stash/src/presentation/widgets/common/logo/stash_mark.dart';

const _res = 'android/app/src/main/res';
const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};
const _key = ValueKey('icon');

Future<void> _render(
    WidgetTester tester, String path, double px, Widget child) async {
  tester.view.physicalSize = Size.square(px);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(RepaintBoundary(key: _key, child: child));
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_key));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// The mark on a dark rounded tile, for launchers without adaptive icons.
Widget _tile(double px) => Padding(
      padding: EdgeInsets.all(px * 0.04),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorManager.backgroundColor,
          borderRadius: BorderRadius.circular(px * 0.2),
        ),
        child: Center(child: StashMark(size: px * 0.66)),
      ),
    );

/// The white mark for the playback notification, 24dp with 2dp of air.
Widget _notification(double px) => Center(
      child: CustomPaint(
        size: Size.square(px * 20 / 24),
        painter: const StashMarkPainter(silhouette: true),
      ),
    );

/// The mark alone, sized to stay inside the adaptive icon's safe zone.
Widget _foreground(double px) => Center(child: StashMark(size: px * 0.5));

void main() {
  testWidgets('launcher icons', (tester) async {
    addTearDown(tester.view.reset);
    for (final MapEntry(key: name, value: scale) in _densities.entries) {
      await _render(tester, '$_res/mipmap-$name/ic_launcher.png', 48 * scale,
          _tile(48 * scale));
      await _render(tester, '$_res/mipmap-$name/ic_launcher_foreground.png',
          108 * scale, _foreground(108 * scale));
      await _render(tester, '$_res/drawable-$name/ic_notification.png',
          24 * scale, _notification(24 * scale));
    }
    await _render(tester, 'docs/icon.png', 512, _tile(512));
  });
}
