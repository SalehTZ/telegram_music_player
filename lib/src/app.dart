import 'package:flutter/material.dart';

import 'screens/home_screen/home_screen.dart';

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: GlobalKey<NavigatorState>(),
      home: const HomeScreen(),
    );
  }
}
