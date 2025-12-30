import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const routeName = '/splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        context.go(LoginPage.routeName);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF006D5B), Color(0xFF009879)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    'data:image/jpeg;base64,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',
                    height: 72,
                    width: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'BUMDES MITRA BARU',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Bumdes Mitra Baru Hidroponik',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mari Berbelanja',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
