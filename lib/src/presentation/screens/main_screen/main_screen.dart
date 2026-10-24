import 'package:flutter/material.dart';

import '../../../constants/colors_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/fake_music_data.dart';
import '../../../data/models/song_model.dart';
import '../../widgets/appbar/appbar_widget.dart';
import '../../widgets/audio_player/mini_music_player.dart';
import '../../widgets/drawer/app_drawer.dart';
import '../home_screen/home_screen.dart';
import '../player_screen/player_screen.dart';
import '../songs_screen/songs_screen.dart';

/// Holds the app bar, drawer and mini player, and switches the page
/// in between when an item of the drawer is picked.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DrawerPage _page = DrawerPage.home;

  void _onPageSelected(DrawerPage page) {
    // TODO add the folders and playlists pages once they are designed
    if (page == DrawerPage.folders || page == DrawerPage.playlists) return;
    setState(() => _page = page);
  }

  void _openPlayer(Song song, {Duration position = Duration.zero}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          song: song,
          initialPosition: position,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const miniPlayerSpace = MiniPlayer.height + AppPadding.p8 * 2;
    final contentBottomPadding =
        miniPlayerSpace + AppPadding.p20 + MediaQuery.paddingOf(context).bottom;
    final page = switch (_page) {
      DrawerPage.songs => SongsScreen(
          bottomPadding: contentBottomPadding,
          onSongTap: _openPlayer,
        ),
      _ => HomeScreen(
          bottomPadding: contentBottomPadding,
          onSongTap: _openPlayer,
        ),
    };

    return PopScope(
      canPop: _page == DrawerPage.home,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final scaffold = _scaffoldKey.currentState;
        if (scaffold != null && scaffold.isDrawerOpen) {
          scaffold.closeDrawer();
        } else {
          setState(() => _page = DrawerPage.home);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: const AppBarWidget(),
        drawer: AppDrawer(onPageSelected: _onPageSelected),
        drawerScrimColor: ColorManager.transparent,
        body: Stack(
          children: [
            Positioned.fill(child: page),

            // * Mini player floating over the page
            Positioned(
              left: AppPadding.p20,
              right: AppPadding.p20,
              bottom: AppPadding.p8,
              child: SafeArea(
                top: false,
                child: MiniPlayer(
                  song: fakeNowPlayingSong,
                  progress: fakeNowPlayingPosition.inMilliseconds /
                      fakeNowPlayingSong.duration.inMilliseconds,
                  onTap: () => _openPlayer(
                    fakeNowPlayingSong,
                    position: fakeNowPlayingPosition,
                  ),
                  // TODO connect to the AudioPlayerBloc
                  onPlayPause: () {},
                  onSkipNext: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
