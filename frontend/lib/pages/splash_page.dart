import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_page.dart';
import 'main_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final isValid = await AuthService.instance.validateSession();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isValid ? const MainPage() : const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, size: 64, color: Color(0xFFFF7A00)),
            SizedBox(height: 16),
            Text(
              'Jadwal Pembelajaran',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFFFF7A00)),
          ],
        ),
      ),
    );
  }
}
