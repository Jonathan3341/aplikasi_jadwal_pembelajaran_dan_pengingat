import 'dart:async';

import 'package:flutter/material.dart';

import 'app_data.dart';
import 'notification_service.dart';
import 'pages/calendar_page.dart';
import 'pages/home_page.dart';
import 'pages/reminder_page.dart';
import 'pages/schedule_page.dart';
import 'widgets/app_bottom_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppData.instance.load();
  runApp(const MyApp());

  // Jalankan notifikasi setelah UI tampil agar startup tidak terasa berat.
  unawaited(_initNotifications());
}

Future<void> _initNotifications() async {
  await NotificationService.instance.init();
  await NotificationService.instance.rescheduleAll();
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7A00),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  static const pages = [
    HomePage(),
    SchedulePage(),
    ReminderPage(),
    CalendarPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
      ),
    );
  }
}
