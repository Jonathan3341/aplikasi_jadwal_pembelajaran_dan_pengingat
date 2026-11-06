import 'package:flutter/material.dart';
import 'admin_unassigned_students_page.dart';
import 'admin_classes_page.dart';
import 'admin_schedule_page.dart';

class AdminDashboardPage extends StatelessWidget {
  final Map<String, dynamic> profile;

  const AdminDashboardPage({super.key, required this.profile});

  static const Color primaryColor = Color(0xFFFF7A00);

  @override
  Widget build(BuildContext context) {
    final name = profile['name']?.toString() ?? 'Administrator';
    final email = profile['email']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Dashboard Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5D0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 32,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat datang,',
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(email, style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 5),
                          const Text(
                            'Administrator',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Manajemen Akademik',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.class_outlined),
                  title: const Text('Manajemen Kelas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminClassesPage(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFE2CC),
                    child: Icon(
                      Icons.person_add_alt_1,
                      color: Color(0xFFFF7A00),
                    ),
                  ),
                  title: const Text('Mahasiswa Tanpa Kelas'),
                  subtitle: const Text(
                    'Cari dan tempatkan mahasiswa ke kelas akademik.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const AdminUnassignedStudentsPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              _managementCard(
                context,
                icon: Icons.calendar_month_outlined,
                title: 'Jadwal Pembelajaran',
                description: 'Atur mata kuliah, dosen, ruangan, hari, dan jam per kelas.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminSchedulesPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Sistem',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Jadwal resmi kampus dikelola oleh Admin. '
                      'Mahasiswa hanya dapat melihat jadwal '
                      'berdasarkan kelas akademik mereka.',
                      style: TextStyle(color: Colors.black54, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _managementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFE2CC),
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(description),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
