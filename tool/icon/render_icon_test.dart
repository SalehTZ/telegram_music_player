// Renders the launcher, notification and README icons for every platform from
// the mark in code, so the logo stays editable in one place:
//
//   flutter test tool/icon/render_icon_test.dart
import 'dart:io';
import 'dart:typed_data';
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
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(await _png(tester, px, child));
}

Future<Uint8List> _png(WidgetTester tester, double px, Widget child) async {
  tester.view.physicalSize = Size.square(px);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(RepaintBoundary(key: _key, child: child));
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_key));
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    return image.toByteData(format: ui.ImageByteFormat.png);
  });
  return bytes!.buffer.asUint8List();
}

/// A Windows .ico holding one PNG per size, which Vista and later read.
Uint8List _ico(Map<int, Uint8List> pngs) {
  final header = BytesBuilder()
    ..add(_le(0, 2) + _le(1, 2) + _le(pngs.length, 2));
  final images = BytesBuilder();
  var offset = 6 + 16 * pngs.length;
  for (final MapEntry(key: px, value: png) in pngs.entries) {
    header
      ..add([px >= 256 ? 0 : px, px >= 256 ? 0 : px, 0, 0])
      ..add(_le(1, 2) + _le(32, 2) + _le(png.length, 4) + _le(offset, 4));
    images.add(png);
    offset += png.length;
  }
  return (header..add(images.takeBytes())).takeBytes();
}

List<int> _le(int value, int bytes) =>
    [for (var i = 0; i < bytes; i++) (value >> (8 * i)) & 0xff];

/// The mark on a dark rounded tile, for launchers without adaptive icons.
Widget _tile(double px, {double margin = 0.04}) => Padding(
      padding: EdgeInsets.all(px * margin),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorManager.backgroundColor,
          borderRadius: BorderRadius.circular(px * 0.2),
        ),
        child: Center(child: StashMark(size: px * 0.66)),
      ),
    );

/// The mark on a full square, which iOS rounds itself.
Widget _square(double px) => ColoredBox(
      color: ColorManager.backgroundColor,
      child: Center(child: StashMark(size: px * 0.66)),
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

  testWidgets('desktop and iOS icons', (tester) async {
    addTearDown(tester.view.reset);
    // * Linux menus, the .deb and the AppImage
    await _render(
        tester, 'linux/packaging/ir.salehtz.stash.png', 512, _tile(512));

    File('windows/runner/resources/app_icon.ico').writeAsBytesSync(_ico({
      for (final px in [16, 24, 32, 48, 64, 128, 256])
        px: await _png(tester, px.toDouble(), _tile(px.toDouble())),
    }));

    // * Apple's grid keeps the tile about a tenth in from each edge
    const macos = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final px in [16, 32, 64, 128, 256, 512, 1024]) {
      await _render(tester, '$macos/app_icon_$px.png', px.toDouble(),
          _tile(px.toDouble(), margin: 0.1));
    }

    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final iosSizes = {
      20.0: [1, 2, 3],
      29.0: [1, 2, 3],
      40.0: [1, 2, 3],
      60.0: [2, 3],
      76.0: [1, 2],
      83.5: [2],
      1024.0: [1],
    };
    for (final MapEntry(key: pt, value: scales) in iosSizes.entries) {
      final name = pt == pt.roundToDouble() ? '${pt.round()}' : '$pt';
      for (final scale in scales) {
        await _render(tester, '$ios/Icon-App-${name}x$name@${scale}x.png',
            pt * scale, _square(pt * scale));
      }
    }
  });
}
