import 'package:flutter/material.dart';

import 'app_data.dart';
import 'pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppData.instance.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jadwal Pembelajaran',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF7A00)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      home: const SplashPage(),
    );
  }
}
