import 'package:flutter/material.dart';

import '../app_data.dart';
import '../services/auth_service.dart';

import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = AuthService.instance.getProfile();
  }

  Future<void> _refreshProfile() async {
    setState(_loadProfile);
    await _profileFuture;
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await AuthService.instance.logout();

      AppData.instance.clearSchedules();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout gagal: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _refreshProfile,
            tooltip: 'Refresh profil',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_off_outlined,
                      size: 52,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Profil tidak dapat dimuat.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _refreshProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data!;

          final name = profile['name']?.toString().trim() ?? '';
          final email = profile['email']?.toString() ?? '';
          final nim = profile['nim']?.toString() ?? '';
          final major = profile['major']?.toString() ?? '';
          final role = profile['role']?.toString() ?? 'Murid';
          final id = profile['id']?.toString() ?? '-';

          final displayName = name.isEmpty ? 'Pengguna' : name;

          return RefreshIndicator(
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================================
                  // PROFILE HEADER
                  // ==================================

                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE5D0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: Color(0xFFFF7A00),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE2CC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(
                                color: Color(0xFFFF7A00),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================
                  // PERSONAL INFORMATION
                  // ==================================
                  _sectionTitle('Informasi Pribadi'),

                  Card(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _infoTile(
                          icon: Icons.badge_outlined,
                          title: 'NIM',
                          value: nim.isEmpty ? 'Belum diisi' : nim,
                        ),
                        const Divider(height: 1),
                        _infoTile(
                          icon: Icons.school_outlined,
                          title: 'Jurusan',
                          value: major.isEmpty ? 'Belum diisi' : major,
                        ),
                        const Divider(height: 1),
                        _infoTile(
                          icon: Icons.email_outlined,
                          title: 'Email',
                          value: email,
                        ),
                        const Divider(height: 1),
                        _infoTile(
                          icon: Icons.fingerprint,
                          title: 'ID Pengguna',
                          value: id,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================
                  // ACADEMIC PERFORMANCE
                  // ==================================
                  _sectionTitle('Performa Akademik'),

                  Card(
                    color: Colors.white,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            color: Color(0xFFFF7A00),
                            size: 38,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Belum ada data penilaian',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Nilai dan perkembangan akademik akan '
                            'ditampilkan setelah guru melakukan '
                            'penilaian terhadap tugas kamu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================
                  // SUBMITTED ASSIGNMENTS
                  // ==================================
                  _sectionTitle('Riwayat Pengumpulan Tugas'),

                  Card(
                    color: Colors.white,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            color: Color(0xFFFF7A00),
                            size: 38,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Belum ada riwayat pengumpulan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Tugas yang kamu kumpulkan melalui fitur '
                            'Hand In akan ditampilkan di bagian ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================
                  // LOGOUT
                  // ==================================
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Logout',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // REUSABLE WIDGETS
  // ==========================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF7A00)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}
