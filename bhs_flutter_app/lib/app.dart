import 'package:flutter/material.dart';

import 'screens/splash/splash_screen.dart';

class BhsApp extends StatelessWidget {
  const BhsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BHARATHI JHARIJANA SANGAM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white),
        cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const SplashScreen(),
    );
  }
}
