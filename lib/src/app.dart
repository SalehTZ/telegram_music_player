import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import 'blocs/library/library_cubit.dart';
import 'blocs/player/player_cubit.dart';
import 'constants/colors_manager.dart';
import 'constants/themes_manager.dart';
import 'data/library/local_store.dart';
import 'data/library/music_library.dart';
import 'presentation/screens/main_screen/main_screen.dart';

class MusicPlayerApp extends StatelessWidget {
  final MusicLibrary library;
  final LocalStore store;

  /// Tests pass a player that leaves the audio session alone.
  final AudioPlayer? player;

  const MusicPlayerApp({
    super.key,
    required this.library,
    required this.store,
    this.player,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LibraryCubit(library: library, store: store)..start(),
        ),
        BlocProvider(
          create: (context) => PlayerCubit(
            player: player,
            onSongStarted: context.read<LibraryCubit>().markPlayed,
          ),
        ),
      ],
      // * Edited songs keep playing under their new tags
      child: BlocListener<LibraryCubit, LibraryState>(
        listenWhen: (a, b) => !identical(a.songs, b.songs),
        listener: (context, state) =>
            context.read<PlayerCubit>().refresh(state.byId),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          // * Light status bar icons on the dark design
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: ColorManager.transparent,
            systemNavigationBarColor: ColorManager.backgroundColor,
          ),
          child: MaterialApp(
            title: "Stash",
            debugShowCheckedModeBanner: false,
            theme: ThemesManager.nightTheme,
            home: const MainScreen(),
          ),
        ),
      ),
    );
  }
}
