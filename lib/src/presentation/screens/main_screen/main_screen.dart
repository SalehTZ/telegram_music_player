import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../blocs/player/player_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/values_manager.dart';
import '../../layout.dart';
import '../../widgets/appbar/appbar_widget.dart';
import '../../widgets/audio_player/now_playing_bar.dart';
import '../../widgets/audio_player/player_panel.dart';
import '../../widgets/drawer/app_drawer.dart';
import '../../widgets/music_folders/music_folders.dart';
import '../folders_screen/folders_screen.dart';
import '../home_screen/home_screen.dart';
import '../playlists_screen/playlists_screen.dart';
import '../songs_screen/songs_screen.dart';
import 'library_gate.dart';

/// Holds the app bar, drawer and mini player, and switches the page
/// in between when an item of the drawer is picked. A wide window keeps the
/// drawer open as a side bar, and a wider one shows the player beside it.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DrawerPage _page = DrawerPage.home;
  late final List<StreamSubscription<String>> _messages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    void show(String message) => ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    _messages = [
      context.read<LibraryCubit>().notices.listen(show),
      context.read<PlayerCubit>().errors.listen(show),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final m in _messages) {
      m.cancel();
    }
    super.dispose();
  }

  // * Back from Telegram or the settings: pick up new songs or the permission
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<LibraryCubit>().refresh();
    }
  }

  void _select(DrawerPage page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    final wide = Layout.isWide(context);
    final panel = Layout.hasPlayerPanel(context);
    final bottom = panel ? AppPadding.p20 : WithNowPlaying.bottomSpace(context);
    final page = switch (_page) {
      DrawerPage.home => HomeScreen(bottomPadding: bottom),
      DrawerPage.folders => FoldersScreen(bottomPadding: bottom),
      DrawerPage.playlists => PlaylistsScreen(bottomPadding: bottom),
      DrawerPage.songs => SongsScreen(bottomPadding: bottom),
    };
    final library = BlocBuilder<LibraryCubit, LibraryState>(
      buildWhen: (a, b) => a.status != b.status,
      builder: (context, state) => state.status != LibraryStatus.ready
          ? LibraryGate(status: state.status)
          : panel
              ? page
              : WithNowPlaying(child: page),
    );

    return PopScope(
      canPop: _page == DrawerPage.home,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final scaffold = _scaffoldKey.currentState;
        if (scaffold != null && scaffold.isDrawerOpen) {
          scaffold.closeDrawer();
        } else {
          setState(() => _page = DrawerPage.home);
        }
      },
      child: DropToAdd(
        child: Scaffold(
          key: _scaffoldKey,
          appBar: wide ? null : const AppBarWidget(),
          drawer: wide ? null : AppDrawer(page: _page, onPageSelected: _select),
          drawerScrimColor: ColorManager.transparent,
          body: !wide
              ? library
              : Row(
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        border: BorderDirectional(
                          end: BorderSide(color: ColorManager.hairline),
                        ),
                      ),
                      child: NavPanel(
                        width: AppSize.s240,
                        page: _page,
                        onPageSelected: _select,
                      ),
                    ),
                    Expanded(
                      child: SafeArea(
                        left: false,
                        right: false,
                        bottom: false,
                        child: library,
                      ),
                    ),
                    if (panel) const PlayerPanel(),
                  ],
                ),
        ),
      ),
    );
  }
}
