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
  final _majorController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _majorController.dispose();

    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        nim: _nimController.text,
        major: _majorController.text,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
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
      appBar: AppBar(title: const Text('Buat Akun')),
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 28),

                  // Nama lengkap
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

                  // NIM
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

                  // Jurusan
                  TextFormField(
                    controller: _majorController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Jurusan',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Jurusan wajib diisi.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  //email
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

                      if (!value.contains('@')) {
                        return 'Format email tidak valid.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  //password
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

                  //confrim password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi Password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
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
                      onPressed: _isLoading ? null : _register,
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
