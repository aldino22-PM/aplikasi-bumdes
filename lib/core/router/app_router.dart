import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/home/presentation/product_detail_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/home/domain/product.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashPage.routeName,
    routes: [
      GoRoute(
        path: SplashPage.routeName,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: LoginPage.routeName,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: RegisterPage.routeName,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: HomePage.routeName,
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Product) {
            return ProductDetailPage(product: extra);
          }
          // fallback jika tidak ada extra: tampilkan placeholder
          return const Scaffold(
            body: Center(child: Text('Produk tidak ditemukan')),
          );
        },
      ),
    ],
  );
});

class AppRouter {
  static void goToDetail(BuildContext context, String id) {
    GoRouter.of(context).push('/product/$id');
  }
}
