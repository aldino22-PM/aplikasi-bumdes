import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/presentation/home_page.dart';
import 'register_page.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const routeName = '/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(data: (session) {
        if (session != null) {
          context.go(HomePage.routeName);
        }
      }, error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      });
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -160,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bumdes Mitra Baru Hidroponik',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ayo hidup sehat dengan banyak makan sayuran,\n'
                            'dan jangan lupa pesan di sini ya!!',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=200&q=80',
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Masuk',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Login untuk mulai memesan layanan',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email wajib diisi';
                              }
                              if (!value.contains('@')) {
                                return 'Email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password wajib diisi';
                              }
                              if (value.length < 6) {
                                return 'Minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState?.validate() ??
                                          false) {
                                        ref
                                            .read(authControllerProvider
                                                .notifier)
                                            .login(
                                              _emailController.text.trim(),
                                              _passwordController.text.trim(),
                                            );
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Masuk'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.go(RegisterPage.routeName),
                            child: const Text('Daftar akun baru'),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: const [
                      Icon(Icons.verified_user, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Aman dengan enkripsi dan OTP',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
