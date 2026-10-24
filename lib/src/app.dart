import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/audio_player/audio_player_bloc.dart';
import 'constants/colors_manager.dart';
import 'constants/themes_manager.dart';
import 'presentation/screens/main_screen/main_screen.dart';

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // * Light status bar icons on the dark design
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: ColorManager.transparent,
        systemNavigationBarColor: ColorManager.backgroundColor,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: GlobalKey<NavigatorState>(),
        theme: ThemesManager.nightTheme,
        home: BlocProvider(
          create: (context) => AudioPlayerBloc(),
          child: const MainScreen(),
        ),
      ),
    );
  }
}
