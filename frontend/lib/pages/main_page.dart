import 'package:flutter/material.dart';

import '../app_data.dart';
import '../notification_service.dart';

import '../services/auth_service.dart';

import 'home_page.dart';
import 'reminder_page.dart';
import 'schedule_page.dart';
import 'profile_page.dart';
import 'admin_dashboard_page.dart';

import '../widgets/app_bottom_nav.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  String? userRole;
  Map<String, dynamic>? userProfile;

  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Ambil profil dan role dari backend.
      final profile = await AuthService.instance.getProfile();

      final role = profile['role']?.toString();

      if (role != 'Admin' && role != 'Murid' && role != 'Guru') {
        throw Exception('Role akun tidak dikenali.');
      }

      // Notifikasi dan jadwal mahasiswa hanya diinisialisasi
      // untuk akun Murid.
      if (role == 'Murid') {
        await NotificationService.instance.init();

        await AppData.instance.loadSchedulesFromApi(
          userId: profile['id'].toString(),
        );

        await NotificationService.instance.rescheduleAll();
      }

      if (!mounted) return;

      setState(() {
        userProfile = profile;
        userRole = role;
        isLoading = false;
        loadError = null;
      });
    } catch (error) {
      debugPrint('Gagal menginisialisasi aplikasi: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = error.toString();
      });
    }
  }

  void _navigateToTab(int index) {
    final pageCount = userRole == 'Admin'
        ? 2
        : userRole == 'Murid'
        ? 4
        : 0;

    if (index < 0 || index >= pageCount) return;

    setState(() {
      currentIndex = index;
    });
  }

  List<Widget> _buildPages() {
    if (userRole == 'Admin') {
      return [
        AdminDashboardPage(profile: userProfile ?? {}),
        const ProfilePage(),
      ];
    }

    if (userRole == 'Murid') {
      return [
        HomePage(onNavigate: _navigateToTab),
        const SchedulePage(),
        const ReminderPage(),
        const ProfilePage(),
      ];
    }

    return [
      const Scaffold(
        body: Center(child: Text('Dashboard Guru sedang dalam pengembangan.')),
      ),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
        ),
      );
    }

    if (loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'Gagal memuat profil pengguna.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                    });

                    _initializeApp();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (userRole == 'Guru') {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Dashboard Guru sedang dalam pengembangan.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final pages = _buildPages();

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: _navigateToTab,
        isAdmin: userRole == 'Admin',
      ),
    );
  }
}
