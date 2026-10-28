
import 'package:flutter/material.dart';

import '../models/api_task.dart';
import '../services/api_service.dart';

class ApiTasksPage extends StatefulWidget {
  const ApiTasksPage({super.key});

  @override
  State<ApiTasksPage> createState() => _ApiTasksPageState();
}

class _ApiTasksPageState extends State<ApiTasksPage> {
  late Future<List<ApiTask>> _futureTasks;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setStateIfMounted(() {
      _futureTasks = ApiService.instance.fetchTasks();
    });
  }

  void setStateIfMounted(VoidCallback callback) {
    if (mounted) {
      setState(callback);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas dari REST API'),
        actions: [
          IconButton(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang data',
          ),
        ],
      ),
      body: FutureBuilder<List<ApiTask>>(
        future: _futureTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Mengambil data dari server...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Gagal mengambil data dari REST API.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadTasks,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return const Center(
              child: Text('API tidak mengembalikan data tugas.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              return Card(
                color: Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: task.completed
                        ? Colors.green.shade100
                        : const Color(0xFFFFE2CC),
                    child: Icon(
                      task.completed
                          ? Icons.check
                          : Icons.assignment_outlined,
                      color: task.completed
                          ? Colors.green
                          : const Color(0xFFFF7A00),
                    ),
                  ),
                  title: Text(task.title),
                  subtitle: Text(
                    'ID: ${task.id} • Pengguna: ${task.userId}',
                  ),
                  trailing: Text(
                    task.completed ? 'Selesai' : 'Belum',
                    style: TextStyle(
                      color: task.completed
                          ? Colors.green
                          : Colors.orange.shade800,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
