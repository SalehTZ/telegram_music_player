import 'package:flutter/material.dart';

import '../../../../constants/colors_manager.dart';

/// The app's mark: a record sliding out of a chat bubble, since the songs
/// arrive in chats. The record's label and the gap around the bubble are cut
/// out, so the background shows through them.
class StashMark extends StatelessWidget {
  final double size;
  const StashMark({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const StashMarkPainter(),
    );
  }
}

class StashMarkPainter extends CustomPainter {
  const StashMarkPainter();

  // * Drawn on a 100 x 100 grid
  static const _record = Offset(64, 36);

  static final _bubble = Path()
    ..moveTo(24, 34)
    ..lineTo(48, 34)
    ..arcToPoint(const Offset(60, 46), radius: const Radius.circular(12))
    ..lineTo(60, 70)
    ..arcToPoint(const Offset(48, 82), radius: const Radius.circular(12))
    ..lineTo(24, 82)
    // * The tail at the bottom left, like an incoming message
    ..quadraticBezierTo(16, 82, 8, 90)
    ..quadraticBezierTo(12, 80, 12, 70)
    ..lineTo(12, 46)
    ..arcToPoint(const Offset(24, 34), radius: const Radius.circular(12))
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final clear = Paint()..blendMode = BlendMode.clear;
    canvas
      ..saveLayer(Offset.zero & size, Paint())
      ..scale(size.shortestSide / 100)
      // * Record with its label punched out and a spindle dot
      ..drawCircle(
        _record,
        26,
        Paint()..color = ColorManager.primaryEnabledColor,
      )
      ..drawCircle(_record, 9, clear)
      ..drawCircle(_record, 2.4, Paint()..color = ColorManager.white)
      // * Bubble in front, with a gap cut into the record around it
      ..drawPath(
        _bubble,
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8,
      )
      ..drawPath(_bubble, Paint()..color = ColorManager.white)
      ..restore();
  }

  @override
  bool shouldRepaint(StashMarkPainter oldDelegate) => false;
}
