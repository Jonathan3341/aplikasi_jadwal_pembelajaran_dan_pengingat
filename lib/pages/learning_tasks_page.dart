
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class LearningTasksPage extends StatefulWidget {
  const LearningTasksPage({super.key});

  @override
  State<LearningTasksPage> createState() =>
      _LearningTasksPageState();
}

class _LearningTasksPageState
    extends State<LearningTasksPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, Object?>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result =
      await DatabaseService.instance.getTasks();

      if (!mounted) return;

      setState(() {
        _tasks = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Gagal membaca database: $e';
        _loading = false;
      });
    }
  }

  Future<void> _showTaskForm({
    Map<String, Object?>? task,
  }) async {
    final titleController = TextEditingController(
      text: task?['title'] as String? ?? '',
    );
    final descriptionController = TextEditingController(
      text: task?['description'] as String? ?? '',
    );
    final dueController = TextEditingController(
      text: task?['due_date'] as String? ?? '',
    );

    final formKey = GlobalKey<FormState>();

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            task == null ? 'Tambah Tugas' : 'Edit Tugas',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul tugas',
                    ),
                    validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Judul wajib diisi'
                        : null,
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                    ),
                    maxLines: 3,
                  ),
                  TextField(
                    controller: dueController,
                    decoration: const InputDecoration(
                      labelText: 'Tenggat (YYYY-MM-DD)',
                      hintText: '2026-11-15',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final dueText = dueController.text.trim();

                if (dueText.isNotEmpty &&
                    DateTime.tryParse(dueText) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Format tenggat tidak valid. Gunakan YYYY-MM-DD.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  if (task == null) {
                    await DatabaseService.instance.createTask(
                      title: titleController.text.trim(),
                      description:
                      descriptionController.text.trim(),
                      dueDate:
                      dueText.isEmpty ? null : dueText,
                    );
                  } else {
                    await DatabaseService.instance.updateTask(
                      id: task['id'] as int,
                      title: titleController.text.trim(),
                      description:
                      descriptionController.text.trim(),
                      dueDate:
                      dueText.isEmpty ? null : dueText,
                      isCompleted:
                      (task['is_completed'] as int) == 1,
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menyimpan tugas: $e'),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      );

      if (saved == true) {
        await _loadTasks();
      }
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      dueController.dispose();
    }
  }

  Future<void> _toggleTask(
      Map<String, Object?> task,
      bool completed,
      ) async {
    try {
      await DatabaseService.instance.updateTask(
        id: task['id'] as int,
        title: task['title'] as String,
        description: task['description'] as String? ?? '',
        dueDate: task['due_date'] as String?,
        isCompleted: completed,
      );

      await _loadTasks();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status: $e')),
      );
    }
  }

  Future<void> _deleteTask(
      Map<String, Object?> task,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('Hapus "${task['title']}"?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DatabaseService.instance.deleteTask(
        task['id'] as int,
      );
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus tugas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas Pembelajaran'),
        actions: [
          IconButton(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
        onPressed: () => _showTaskForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadTasks,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      )
          : _tasks.isEmpty
          ? const Center(
        child: Text(
          'Belum ada tugas. Tekan + untuk menambah.',
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          final completed =
              (task['is_completed'] as int) == 1;

          return Card(
            color: Colors.white,
            child: ListTile(
              leading: Checkbox(
                value: completed,
                onChanged: (value) {
                  if (value != null) {
                    _toggleTask(task, value);
                  }
                },
              ),
              title: Text(
                task['title'] as String,
                style: TextStyle(
                  decoration: completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text([
                if ((task['description'] as String?)
                    ?.isNotEmpty ==
                    true)
                  task['description'] as String,
                if (task['due_date'] != null)
                  'Tenggat: ${task['due_date']}',
              ].join('\n')),
              isThreeLine:
              (task['description'] as String?)
                  ?.isNotEmpty ==
                  true &&
                  task['due_date'] != null,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showTaskForm(task: task);
                  } else if (value == 'delete') {
                    _deleteTask(task);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
