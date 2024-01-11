import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/audio_player/audio_player_bloc.dart';
import 'constants/themes_manager.dart';
import 'presentation/screens/home_screen/home_screen.dart';

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: GlobalKey<NavigatorState>(),
      theme: ThemesManager.nightTheme,
      home: BlocProvider(
        create: (context) => AudioPlayerBloc(),
        child: const HomeScreen(),
      ),
    );
  }
}
