import 'package:flutter_test/flutter_test.dart';
import 'package:telegram_music_player/src/app.dart';
import 'package:telegram_music_player/src/presentation/screens/player_screen/player_screen.dart';
import 'package:telegram_music_player/src/presentation/widgets/audio_player/mini_music_player.dart';
import 'package:telegram_music_player/src/presentation/widgets/common/round_button/round_button_widget.dart';
import 'package:telegram_music_player/src/presentation/widgets/song_list_item/song_list_item_widget.dart';

void main() {
  testWidgets('shows the home sections and the mini player', (tester) async {
    await tester.pumpWidget(const MusicPlayerApp());

    expect(find.text('Recently Played'), findsOneWidget);
    expect(find.text('Artists'), findsOneWidget);
    expect(find.byType(MiniPlayer), findsOneWidget);
  });

  testWidgets('opens the songs page from the drawer', (tester) async {
    await tester.pumpWidget(const MusicPlayerApp());

    await tester.tap(find.byType(RoundButtonWidget));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Songs'));
    await tester.pumpAndSettle();

    expect(find.text('Recently Played'), findsNothing);
    expect(find.byType(SongListItemWidget), findsWidgets);
  });

  testWidgets('opens the player from the mini player and goes back',
      (tester) async {
    await tester.pumpWidget(const MusicPlayerApp());

    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.text('Lyrics'), findsOneWidget);

    await tester.tap(find.byType(RoundButtonWidget).first);
    await tester.pumpAndSettle();
    expect(find.byType(PlayerScreen), findsNothing);
  });
}
