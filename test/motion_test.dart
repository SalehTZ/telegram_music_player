import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/presentation/motion.dart';

const _box = ValueKey('box');

Widget _app(Widget child, {bool reduced = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(body: child),
      ),
    );

double _opacityOf(WidgetTester tester, Finder finder) => tester
    .widgetList<FadeTransition>(
        find.ancestor(of: finder, matching: find.byType(FadeTransition)))
    .fold(1.0, (o, f) => o * f.opacity.value);

void main() {
  testWidgets('a press shrinks, or only dims under reduced motion',
      (tester) async {
    for (final reduced in [false, true]) {
      await tester.pumpWidget(_app(
        const Pressable(child: _Box()),
        reduced: reduced,
      ));
      final gesture =
          await tester.startGesture(tester.getCenter(find.byKey(_box)));
      await tester.pumpAndSettle();
      if (reduced) {
        expect(find.byType(AnimatedScale), findsNothing);
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          lessThan(1),
        );
      } else {
        expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
          lessThan(1),
        );
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a press turns into a scroll once the finger moves',
      (tester) async {
    await tester.pumpWidget(
      _app(const Pressable(child: _Box())),
    );
    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_box)));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.up();
  });

  testWidgets('rows arrive one after the other, only when the list opens',
      (tester) async {
    await tester.pumpWidget(_app(ArrivalScope(
      child: Column(children: Arrive.all(const [Text('a'), Text('b')])),
    )));
    await tester.pump(const Duration(milliseconds: 100));
    // * The second row starts a step later
    expect(
      _opacityOf(tester, find.text('a')),
      greaterThan(_opacityOf(tester, find.text('b'))),
    );
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, find.text('b')), 1);

    // * Without a scope nothing waits
    await tester.pumpWidget(_app(const Arrive(index: 3, child: Text('c'))));
    expect(_opacityOf(tester, find.text('c')), 1);
  });

  testWidgets('a switched child only fades under reduced motion',
      (tester) async {
    Widget switcher(String text) => _app(
          MotionSwitcher(rise: 20, child: Text(text, key: ValueKey(text))),
          reduced: true,
        );
    await tester.pumpWidget(switcher('old'));
    await tester.pumpWidget(switcher('new'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      find.ancestor(of: find.text('new'), matching: find.byType(Transform)),
      findsNothing,
    );
    expect(_opacityOf(tester, find.text('new')), lessThan(1));
    await tester.pumpAndSettle();
    expect(find.text('old'), findsNothing);
  });
}

/// Something a finger can land on.
class _Box extends StatelessWidget {
  const _Box();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        key: _box,
        color: Colors.white,
        child: SizedBox.square(dimension: 100),
      );
}
