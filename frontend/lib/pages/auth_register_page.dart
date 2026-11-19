
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<Map<String, dynamic>> _classes = [];

  int? _selectedClassId;

  bool _isLoading = false;
  bool _isLoadingClasses = true;
  bool _obscurePassword = true;

  String? _classLoadError;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // Mengambil daftar kelas dari backend.
  Future<void> _loadClasses() async {
    setState(() {
      _isLoadingClasses = true;
      _classLoadError = null;
    });

    try {
      final classes =
      await AuthService.instance.fetchRegistrationClasses();

      if (!mounted) return;

      setState(() {
        _classes = classes;
        _selectedClassId = null;
        _isLoadingClasses = false;

        if (classes.isEmpty) {
          _classLoadError = 'Belum ada kelas yang tersedia.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _classes = [];
        _isLoadingClasses = false;
        _classLoadError =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Dropdown pemilihan kelas.
  Widget _buildClassField() {
    if (_isLoadingClasses) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Kelas',
          prefixIcon: Icon(Icons.school_outlined),
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Memuat daftar kelas...'),
          ],
        ),
      );
    }

    if (_classLoadError != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Kelas',
          prefixIcon: const Icon(Icons.school_outlined),
          border: const OutlineInputBorder(),
          errorText: _classLoadError,
          suffixIcon: IconButton(
            tooltip: 'Muat ulang kelas',
            onPressed: _loadClasses,
            icon: const Icon(Icons.refresh),
          ),
        ),
        child: const Text('Daftar kelas tidak tersedia'),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedClassId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Pilih Kelas',
        prefixIcon: Icon(Icons.school_outlined),
        border: OutlineInputBorder(),
      ),
      hint: const Text('Pilih kelas kamu'),
      items: _classes.map((academicClass) {
        final id = (academicClass['id'] as num).toInt();
        final className =
            academicClass['class_name']?.toString() ?? '';
        final major = academicClass['major']?.toString() ?? '';
        final year = academicClass['cohort_year']?.toString() ?? '';

        return DropdownMenuItem<int>(
          value: id,
          child: Text(
            '$className - $major ($year)',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedClassId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Silakan pilih kelas.';
        }

        return null;
      },
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassId == null) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        nim: _nimController.text,
        classId: _selectedClassId!,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Akun'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 64,
                    color: Color(0xFFFF7A00),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Daftar Akun Baru',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Nama lengkap.
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama lengkap wajib diisi.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // NIM.
                  TextFormField(
                    controller: _nimController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'NIM',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'NIM wajib diisi.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pemilihan kelas.
                  _buildClassField(),
                  const SizedBox(height: 16),

                  // Email.
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi.';
                      }

                      if (!RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(value.trim())) {
                        return 'Format email tidak valid.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password.
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi.';
                      }

                      if (value.length < 8) {
                        return 'Password minimal 8 karakter.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Konfirmasi password.
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi Password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password wajib diisi.';
                      }

                      if (value != _passwordController.text) {
                        return 'Konfirmasi password tidak sama.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _isLoading ||
                          _isLoadingClasses ||
                          _classes.isEmpty ||
                          _classLoadError != null
                          ? null
                          : _register,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Daftar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
