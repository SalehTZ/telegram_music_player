import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/blocs/library/library_cubit.dart';
import 'package:stash/src/data/library/music_library.dart';
import 'package:stash/src/presentation/screens/home_screen/tidy_card.dart';
import 'package:stash/src/presentation/screens/player_screen/player_screen.dart';
import 'package:stash/src/presentation/widgets/audio_player/mini_music_player.dart';
import 'package:stash/src/presentation/widgets/common/round_button/round_button_widget.dart';
import 'package:stash/src/presentation/widgets/song_list_item/song_list_item_widget.dart';

import 'support/demo_library.dart';
import 'support/pump_app.dart';

Future<void> openPage(WidgetTester tester, String name) async {
  await tester.tap(find.byType(RoundButtonWidget));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

Future<void> openMenuOf(WidgetTester tester, String title) async {
  final item = find.ancestor(
    of: find.text(title),
    matching: find.byType(SongListItemWidget),
  );
  await tester.tap(
    find.descendant(of: item.first, matching: find.byType(SvgPicture)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks for access to music, then shows the library',
      (tester) async {
    await pumpApp(tester, library: DemoMusicLibrary(granted: false));
    expect(find.text('Let Stash find your music'), findsOneWidget);

    await tester.tap(find.text('Allow access to music'));
    await tester.pumpAndSettle();
    expect(find.text('Recently added'), findsOneWidget);
    expect(find.text('7 songs need tidying'), findsOneWidget);
    expect(find.byType(ChannelChip), findsNWidgets(3));
  });

  testWidgets('when Android stops asking, it sends you to the settings',
      (tester) async {
    final library = await pumpApp(
      tester,
      library: DemoMusicLibrary(granted: false, answer: Access.blocked),
    );
    await tester.tap(find.text('Allow access to music'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open settings'));
    expect(library.settingsOpened, 1);
  });

  testWidgets('tidy up cleans every stamped song it can after one OK',
      (tester) async {
    final library = await pumpApp(tester);
    await tester.tap(find.text('Tidy up'));
    await tester.pumpAndSettle();
    expect(find.text("Stash can't change these files"), findsOneWidget);

    await tester.tap(find.text('Clean 6 songs'));
    await tester.pumpAndSettle();
    expect(library.writeRequests, 1);
    expect(find.text('Cleaned 6 songs.'), findsOneWidget);

    expect(library.byTitle('Do I Wanna Know').title, 'Do I Wanna Know?');
    expect(library.byTitle('Get Lucky').artist, 'Daft Punk');
    expect(library.byTitle('Save Your Tears').title, 'Save Your Tears');
    expect(library.byTitle('R U Mine').artist, 'Arctic Monkeys');
    expect(library.byTitle('امیر').title, 'امیر بی گزند');
    expect(library.byTitle('Cruel Summer').album, 'Lover');
    // * The WMA is left alone
    expect(
        library.byTitle('Instant Crush').title, 'Instant Crush @MusicArchive');
    // * And the cleaned tags kept what wasn't stamped
    final tag = await library.readTag(library.byTitle('Do I Wanna Know'));
    expect(tag!.lyrics, contains("Crawlin' back to you"));
  });

  testWidgets('saying no to Android changes nothing', (tester) async {
    final library = await pumpApp(
      tester,
      library: DemoMusicLibrary(allowWrites: false),
    );
    await tester.tap(find.text('Tidy up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clean 6 songs'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing changed'), findsOneWidget);
    expect(library.byTitle('Do I Wanna Know').title,
        'Do I Wanna Know? @MusicArchive');
  });

  testWidgets('a song plays in the mini player and the player', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester);
    await openPage(tester, 'Songs');
    await tester.tap(find.text('Blinding Lights'));
    await settlePlayer(tester);
    expect(
      find.descendant(
        of: find.byType(MiniPlayer),
        matching: find.text('Blinding Lights'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(MiniPlayer));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PlayerScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('Play'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Repeat off'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('Repeat all'), findsOneWidget);
    await closeApp(tester);
    semantics.dispose();
  });

  testWidgets('a song menu adds to favorites and to a new playlist',
      (tester) async {
    await pumpApp(tester);
    await openPage(tester, 'Songs');

    await openMenuOf(tester, 'Blinding Lights');
    await tester.tap(find.text('Add to favorites'));
    await tester.pumpAndSettle();

    await openMenuOf(tester, 'Blinding Lights');
    await tester.tap(find.text('Add to playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Gym');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Added to Gym'), findsOneWidget);

    await openPage(tester, 'Playlists');
    final favorites = find.ancestor(
      of: find.text('Favorites'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(of: favorites, matching: find.text('1')),
      findsOneWidget,
    );
    expect(find.text('Gym'), findsOneWidget);
  });

  testWidgets('the tag editor takes the stamps out and saves', (tester) async {
    final library = await pumpApp(tester);
    await openPage(tester, 'Songs');
    await openMenuOf(tester, 'Do I Wanna Know? @MusicArchive');
    await tester.tap(find.text('Edit tags and cover'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Take them out'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Year'), '2013');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final tag = await library.readTag(library.byTitle('Do I Wanna Know'));
    expect(tag!.title, 'Do I Wanna Know?');
    expect(tag.year, '2013');
    expect(tag.album, 'AM');
    expect(tag.lyrics, contains("Crawlin' back to you"));
  });

  testWidgets('search finds songs by artist', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextFormField), 'weeknd');
    await tester.pumpAndSettle();
    expect(find.text('4 songs'), findsOneWidget);
    expect(find.byType(SongListItemWidget), findsNWidgets(4));
  });

  testWidgets('duplicates keep the best copy and its favorite', (tester) async {
    final library = await pumpApp(tester);
    final worse = library.byTitle('Blinding Lights');
    expect(worse.bitrate, 128);
    final cubit = tester
        .element(find.byType(Scaffold).first)
        .read<LibraryCubit>()
      ..toggleFavorite(worse);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('See duplicates'),
      200,
      scrollable: find
          .ancestor(
              of: find.byType(TidyCard), matching: find.byType(Scrollable))
          .first,
    );
    await tester.tap(find.text('See duplicates'));
    await tester.pumpAndSettle();
    expect(find.text('Keep'), findsOneWidget);
    await tester.tap(find.text('Delete 1 copy'));
    await tester.pumpAndSettle();

    expect(library.deleteRequests, 1);
    expect(find.text('Deleted 1 copy.'), findsOneWidget);
    final kept = cubit.state.songs.where((s) => s.title == 'Blinding Lights');
    expect(kept.single.bitrate, 320);
    expect(cubit.state.isFavorite(kept.single), isTrue);
    expect(cubit.state.duplicates, isEmpty);
  });

  testWidgets('a song shared to Stash is announced', (tester) async {
    final library = await pumpApp(tester);
    library.share(['Song from a channel.mp3']);
    await tester.pumpAndSettle();
    expect(
      find.text('Saved Song from a channel.mp3 to Music/Stash'),
      findsOneWidget,
    );
  });
}
