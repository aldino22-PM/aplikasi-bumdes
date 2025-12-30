import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_page.dart';
import '../data/product_repository.dart';
import '../data/order_repository.dart';
import '../domain/cart_item.dart';
import '../domain/order.dart';
import '../domain/sales_summary.dart';
import '../domain/product.dart';
import 'cart_controller.dart';
import 'add_product_page.dart';
import 'order_controller.dart';
import 'sales_controller.dart';
import 'notifications_controller.dart';
import '../domain/notification_item.dart';
import 'product_list_admin_page.dart';
import 'pdf_helpers.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;
  void _openSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Butuh bantuan?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Hubungi CS Mitra Baru melalui:'),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat, color: AppTheme.primary),
              ),
              title: const Text('WhatsApp'),
              subtitle: const Text('628123456789'),
              onTap: () {
                Navigator.of(ctx).pop();
                _launchUri(context, 'https://wa.me/628123456789');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call, color: AppTheme.primary),
              ),
              title: const Text('Telepon'),
              subtitle: const Text('0812-3456-789'),
              onTap: () {
                Navigator.of(ctx).pop();
                _launchUri(context, 'tel:08123456789');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openNotifications(
      BuildContext context, List<NotificationItem> notifications,
      {required bool isAdmin}) {
    if (isAdmin) {
      ref.read(notificationsAdminProvider.notifier).markAllRead();
    } else {
      ref.read(notificationsUserProvider.notifier).markAllRead();
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        if (notifications.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Belum ada notifikasi.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, index) {
            final n = notifications[index];
            return ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(n.body),
              trailing: Text(
                '${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: notifications.length,
        );
      },
    );
  }

  void _handleLogout(BuildContext context) {
    ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) {
      context.go(LoginPage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);
    final session = ref.watch(authControllerProvider).value;
    final role = session?.role ?? UserRole.user;
    final navItems = _navItemsForRole(role);
    final currentIndex =
        _currentIndex.clamp(0, navItems.length - 1).toInt();
    final body =
        _buildBodyForRole(context, role, products, currentIndex, session);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildAppBar(context),
      body: body,
      bottomNavigationBar: _BottomNav(
        items: navItems,
        currentIndex: currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  List<BottomNavigationBarItem> _navItemsForRole(UserRole role) {
    if (role == UserRole.admin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_outlined),
          activeIcon: Icon(Icons.verified),
          label: 'Verifikasi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_toggle_off),
          activeIcon: Icon(Icons.history),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory),
          label: 'Data Produk',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'Input Produk',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    }

    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Beranda',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart_outlined),
        activeIcon: Icon(Icons.shopping_cart),
        label: 'Keranjang',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_outlined),
        activeIcon: Icon(Icons.receipt_long),
        label: 'Pesanan',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history_outlined),
        activeIcon: Icon(Icons.history),
        label: 'Riwayat',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }

  Widget _buildBodyForRole(
    BuildContext context,
    UserRole role,
    AsyncValue<List<Product>> products,
    int currentIndex,
    AuthSession? session,
  ) {
    if (role == UserRole.admin) {
      switch (currentIndex) {
        case 0:
          return const _VerificationPage();
        case 1:
          return const _SalesHistoryPage();
        case 2:
          return const ProductListAdminPage();
        case 3:
          return const AddProductPage();
        default:
          return _ProfilePage(
            role: role,
            session: session,
            onLogout: () => _handleLogout(context),
          );
      }
    }

    switch (currentIndex) {
      case 0:
        return products.when(
          data: (items) => _HomeContent(items: items),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        );
      case 1:
        return _OrdersPage(onStartShopping: () => setState(() => _currentIndex = 0));
      case 2:
        return const _UserOrdersPage();
      case 3:
        return const _UserHistoryPage();
      default:
        return _ProfilePage(
          role: role,
          session: session,
          onLogout: () => _handleLogout(context),
        );
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final currentSession = ref.watch(authControllerProvider).value;
    final isAdmin = currentSession?.role == UserRole.admin;
    final notifications = isAdmin
        ? ref.watch(notificationsAdminProvider)
        : ref.watch(notificationsUserProvider);
    final hasUnread = notifications.any((n) => !n.isRead);
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Antar ke', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text('Jl. Raya Mitra Baru No.1',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _openSupport(context),
          icon: const Icon(Icons.support_agent),
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              onPressed: () =>
                  _openNotifications(context, notifications, isAdmin: isAdmin),
              icon: const Icon(Icons.notifications_none),
            ),
            if (hasUnread)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.items});

  final List<Product> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5FFF8), Color(0xFFE7FFF0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _HeroBanner(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sayur hidroponik pilihan',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Lihat semua'),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = items[index];
                  return _ProductCard(product: product);
                },
                childCount: items.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
              ),
              child: Row(
                children: const [
                  Icon(Icons.help_outline, color: Colors.black54),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Butuh bantuan? Hubungi CS Mitra Baru di menu Profil.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6DD5A9), Color(0xFF3CBA92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Panen Pagi',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Sayur hidroponik segar\nlangsung dari kebun Mitra Baru',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 10),
                _Bullet(text: 'Dipetik setiap pagi, lebih renyah'),
                _Bullet(text: 'Pengiriman instan & cold pack'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.network(
              'https://cdn.pixabay.com/photo/2023/04/20/03/26/mint-leaves-7938893_1280.jpg',
              fit: BoxFit.cover,
            ),
          )
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final weightLabel = product.weight.toLowerCase().contains('ikat')
        ? product.weight.replaceAll('ikat', 'package')
        : '${product.weight} per package';
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7F1EA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weightLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(product.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '/package',
                        style: TextStyle(color: Colors.black45, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: currentIndex,
      onTap: onChanged,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: true,
      selectedIconTheme: const IconThemeData(color: AppTheme.primary, size: 26),
      unselectedIconTheme:
          const IconThemeData(color: Colors.black54, size: 24),
      items: items,
    );
  }
}

class _VerificationPage extends ConsumerWidget {
  const _VerificationPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(orderListProvider);
    return SafeArea(
      child: ordersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat pesanan: $e')),
        data: (orders) => RefreshIndicator(
          onRefresh: () => ref.read(orderListProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Verifikasi Pembelian',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cek bukti transfer dan tandai pesanan yang sudah diverifikasi.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                const Text('Belum ada pesanan.', style: TextStyle(color: Colors.black87)),
              ...orders.map(
                (order) => _VerificationCard(
                  orderId: order.id,
                  customer: order.customer,
                  items: order.itemsDescription,
                  total: order.total,
                  contact: order.contact.isEmpty ? '628123456789' : order.contact,
                  time: order.createdAt,
                  status: order.status,
                  onVerify: () =>
                      ref.read(orderListProvider.notifier).verify(order.id),
                  onPack: () {
                    ref.read(orderListProvider.notifier).markPacking(order.id);
                    ref.read(notificationsUserProvider.notifier).addNotification(
                      'Pesanan dipacking',
                      'Pesanan #${order.id} telah diverifikasi dan akan segera dipacking lalu diantarkan ke alamat Anda.',
                    );
                  },
                  onReject: () =>
                      ref.read(orderListProvider.notifier).reject(order.id),
                  onPrint: () => _exportReceiptPdf(context, order),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FBF7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0F2E9)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Data di atas memuat pesanan dari API. Tarik untuk refresh.',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesHistoryPage extends ConsumerWidget {
  const _SalesHistoryPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(salesRangeProvider);
    final summary = ref.watch(salesSummaryProvider);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Riwayat Penjualan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const Spacer(),
                _RangeChip(label: '1 Hari', value: 'day', current: range),
                const SizedBox(width: 8),
                _RangeChip(label: '1 Minggu', value: 'week', current: range),
                const SizedBox(width: 8),
                _RangeChip(label: '1 Bulan', value: 'month', current: range),
              ],
            ),
          ),
          summary.when(
            loading: () => const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Expanded(
              child: Center(child: Text('Gagal memuat riwayat: $e')),
            ),
            data: (data) {
              final orders = data.orders;
              return Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(salesSummaryProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Total Pendapatan',
                              value: _formatCurrency(data.totalRevenue),
                              icon: Icons.payments,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: 'Jumlah Pesanan',
                              value: '${data.ordersCount}',
                              icon: Icons.receipt_long,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: orders.isEmpty
                            ? null
                            : () => _exportSalesPdf(context, data, range),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Cetak PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (orders.isEmpty)
                        const Text('Belum ada penjualan pada rentang ini.',
                            style: TextStyle(color: Colors.black87)),
                      ...orders.map(
                        (order) => _VerificationCard(
                          orderId: order.id,
                          customer: order.customer,
                          items: order.itemsDescription,
                          total: order.total,
                          contact: order.contact,
                          time: order.createdAt,
                          status: order.status,
                          onVerify: () {},
                          showVerifyButton: false,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends ConsumerWidget {
  const _RangeChip({required this.label, required this.value, required this.current});
  final String label;
  final String value;
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ref.read(salesRangeProvider.notifier).state = value,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.orderId,
    required this.customer,
    required this.items,
    required this.total,
    required this.contact,
    required this.time,
    required this.status,
    required this.onVerify,
    this.onReject,
    this.onPack,
    this.onPrint,
    this.showVerifyButton = true,
  });

  final String orderId;
  final String customer;
  final String items;
  final int total;
  final String contact;
  final String time;
  final OrderStatus status;
  final VoidCallback onVerify;
  final VoidCallback? onReject;
  final VoidCallback? onPack;
  final VoidCallback? onPrint;
  final bool showVerifyButton;

  @override
  Widget build(BuildContext context) {
    final isVerified = status == OrderStatus.verified;
    final isDelivered = status == OrderStatus.delivered;
    final isPacking = status == OrderStatus.packing;
    final isCancelled = status == OrderStatus.cancelled;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderId,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            customer,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(items, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 6),
          Text(_formatCurrency(total),
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.primary)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (showVerifyButton)
                ElevatedButton.icon(
                  onPressed: (isVerified || isDelivered || isCancelled)
                      ? null
                      : () {
                          onVerify();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$orderId ditandai untuk pengantaran'),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.verified),
                  label: Text(
                    isDelivered
                        ? 'Selesai'
                        : isVerified
                            ? 'Pengantaran'
                            : 'Pengantaran',
                  ),
                ),
              if (showVerifyButton) const SizedBox(width: 8),
              if (showVerifyButton)
                OutlinedButton.icon(
                  onPressed:
                      (isCancelled ||
                              isPacking ||
                              isVerified ||
                              isDelivered ||
                              onPack == null)
                      ? null
                      : () {
                          onPack?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$orderId masuk tahap packing')),
                          );
                        },
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Verifikasi & Packing'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueGrey.shade700,
                    side: BorderSide(color: Colors.blueGrey.shade200),
                  ),
                ),
              if (showVerifyButton && (onPack != null)) const SizedBox(width: 8),
              if (showVerifyButton)
                OutlinedButton.icon(
                  onPressed:
                      (isVerified || isDelivered || isCancelled || onReject == null)
                      ? null
                      : () {
                          onReject?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('$orderId ditolak/dibatalkan')),
                          );
                        },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
              if (showVerifyButton && (onReject != null))
                const SizedBox(width: 8),
              if (showVerifyButton && (onPrint != null))
                OutlinedButton.icon(
                  onPressed: onPrint,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Cetak receipt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal.shade700,
                    side: BorderSide(color: Colors.teal.shade200),
                  ),
                ),
              if (showVerifyButton && (onPrint != null))
                const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _launchUri(context, 'https://wa.me/$contact'),
                icon: const Icon(Icons.chat),
                label: Text(isVerified ? 'Hubungi lagi' : 'Hubungi'),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final isVerified = status == OrderStatus.verified;
    final isDelivered = status == OrderStatus.delivered;
    final isCancelled = status == OrderStatus.cancelled;
    final isPacking = status == OrderStatus.packing;
    final color = isDelivered
        ? const Color(0xFFE8F5E9)
        : isVerified
            ? const Color(0xFFD8F5E5)
            : isCancelled
                ? const Color(0xFFFFE4E1)
                : isPacking
                    ? const Color(0xFFE3F2FD)
                    : const Color(0xFFFDF3DA);
    final textColor = isDelivered
        ? const Color(0xFF2E7D32)
        : isVerified
            ? const Color(0xFF1B8C5A)
            : isCancelled
                ? const Color(0xFFD32F2F)
                : isPacking
                    ? const Color(0xFF1565C0)
                    : const Color(0xFFD48900);
    final label = isDelivered
        ? 'Selesai'
        : isVerified
            ? 'Pengantaran'
            : isCancelled
                ? 'Ditolak'
                : isPacking
                    ? 'Verifikasi & Packing'
                    : 'Menunggu';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _OrdersPage extends StatelessWidget {
  const _OrdersPage({required this.onStartShopping});

  final VoidCallback onStartShopping;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final cart = ref.watch(cartProvider);
        final total = ref.watch(cartTotalProvider);
        if (cart.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_bag_outlined,
                      size: 48, color: Colors.green.shade700),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Keranjang Kosong',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Belum ada produk di keranjang Anda. Mulai belanja sekarang!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onStartShopping,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Mulai Belanja'),
                )
              ],
            ),
          );
        }
        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Alamat pengantaran',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(height: 6),
                  Text('Jl. Raya Mitra Baru No.1, 0.8 km'),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final item = cart[index];
                  return _OrderItemCard(item: item);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: cart.length,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total belanja',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        'Rp$total',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppTheme.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _submitOrder(context, ref, total, cart),
                  child: const Text('Checkout'),
                )
              ],
            ),
          )
          ],
        );
      },
    );
  }
}

class _UserOrdersPage extends ConsumerWidget {
  const _UserOrdersPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(orderListProvider);
    return SafeArea(
      child: ordersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat pesanan: $e')),
        data: (orders) {
          final active = orders
              .where((o) =>
                  o.status == OrderStatus.pending ||
                  o.status == OrderStatus.packing ||
                  o.status == OrderStatus.verified)
              .toList();
          return RefreshIndicator(
            onRefresh: () => ref.read(orderListProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Text(
                      'Pesanan Aktif',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pantau status pesanan aktif Anda.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                if (active.isNotEmpty)
                  const Text('Menunggu / Packing',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ...active.map(
                  (order) => _VerificationCard(
                    orderId: order.id,
                    customer: order.customer,
                    items: order.itemsDescription,
                    total: order.total,
                    contact:
                        order.contact.isEmpty ? '628123456789' : order.contact,
                    time: order.createdAt,
                    status: order.status,
                    onVerify: () => ref
                        .read(orderListProvider.notifier)
                        .markDelivered(order.id),
                    showVerifyButton: false,
                  ),
                ),
                if (active.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Text(
                      'Belum ada pesanan aktif.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UserHistoryPage extends ConsumerWidget {
  const _UserHistoryPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(orderListProvider);
    return SafeArea(
      child: ordersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat riwayat: $e')),
        data: (orders) {
          final history = orders
              .where((o) =>
                  o.status == OrderStatus.verified ||
                  o.status == OrderStatus.delivered ||
                  o.status == OrderStatus.cancelled)
              .toList();
          return RefreshIndicator(
            onRefresh: () => ref.read(orderListProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Riwayat Pesanan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pesanan yang sudah diverifikasi, selesai, atau ditolak admin.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Text(
                      'Belum ada riwayat pesanan.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ...history.map(
                  (order) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _VerificationCard(
                        orderId: order.id,
                        customer: order.customer,
                        items: order.itemsDescription,
                        total: order.total,
                        contact:
                            order.contact.isEmpty ? '628123456789' : order.contact,
                        time: order.createdAt,
                        status: order.status,
                        onVerify: () {},
                        showVerifyButton: false,
                      ),
                      if (order.status == OrderStatus.verified)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final messenger = ScaffoldMessenger.of(context);
                              ref
                                  .read(orderListProvider.notifier)
                                  .markDelivered(order.id);
                              ref.read(notificationsAdminProvider.notifier).addNotification(
                                    'Pesanan diterima',
                                    'Pesanan #${order.id} telah dikonfirmasi diterima oleh customer.',
                                  );
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Pesanan #${order.id} diterima. Terima kasih!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Pesanan diterima'),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatPage extends StatelessWidget {
  const _ChatPage();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage({
    required this.onLogout,
    required this.role,
    required this.session,
  });

  final VoidCallback onLogout;
  final UserRole role;
  final AuthSession? session;

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  String displayName = 'Mitra Baru';
  String subtitle = 'Bumdes Hidroponik';
  String phone = '0812-3456-789';
  String whatsapp = '628123456789';
  String email = 'halo@mitrabaru.id';

  final TextEditingController _nameController =
      TextEditingController(text: 'Mitra Baru');
  final TextEditingController _subtitleController =
      TextEditingController(text: 'Bumdes Hidroponik');
  final TextEditingController _phoneController =
      TextEditingController(text: '0812-3456-789');
  final TextEditingController _waController =
      TextEditingController(text: '628123456789');
  final TextEditingController _emailController =
      TextEditingController(text: 'halo@mitrabaru.id');

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    if (session != null) {
      displayName = session.name.isNotEmpty ? session.name : displayName;
      email = session.email.isNotEmpty ? session.email : email;
      subtitle = widget.role == UserRole.admin ? 'Admin' : 'Pengguna';
      _nameController.text = displayName;
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _phoneController.dispose();
    _waController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _openEditDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: _subtitleController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                displayName = _nameController.text.trim().isEmpty
                    ? displayName
                    : _nameController.text.trim();
                subtitle = _subtitleController.text.trim().isEmpty
                    ? subtitle
                    : _subtitleController.text.trim();
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil diperbarui (lokal)')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _openEditContactDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Kontak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telepon'),
            ),
            TextField(
              controller: _waController,
              decoration: const InputDecoration(labelText: 'WhatsApp'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                phone = _phoneController.text.trim().isEmpty
                    ? phone
                    : _phoneController.text.trim();
                whatsapp = _waController.text.trim().isEmpty
                    ? whatsapp
                    : _waController.text.trim();
                email = _emailController.text.trim().isEmpty
                    ? email
                    : _emailController.text.trim();
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kontak diperbarui (lokal)')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionName =
        (widget.session?.name ?? '').isNotEmpty ? widget.session!.name : displayName;
    final sessionEmail =
        (widget.session?.email ?? '').isNotEmpty ? widget.session!.email : email;
    final roleLabel = widget.role == UserRole.admin ? 'Admin' : 'Pengguna';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                  child: const Icon(Icons.person, size: 32, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sessionName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(
                      roleLabel,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _openEditDialog,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Ubah'),
                )
              ],
            ),
            const SizedBox(height: 16),
            _ProfileCard(
              title: 'Kontak',
              trailing: TextButton.icon(
                onPressed: _openEditContactDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Ubah'),
              ),
              items: [
                _ProfileRow(icon: Icons.call, label: 'Telepon', value: phone),
                _ProfileRow(icon: Icons.chat, label: 'WhatsApp', value: whatsapp),
                _ProfileRow(icon: Icons.email_outlined, label: 'Email', value: sessionEmail),
              ],
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: 'Alamat',
              items: const [
                _ProfileRow(
                  icon: Icons.location_on_outlined,
                  label: 'Gudang Mitra Baru',
                  value: 'Jl. Raya Mitra Baru No.1, 0.8 km',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: 'Pengaturan',
              items: const [
                _ProfileRow(icon: Icons.notifications_none, label: 'Notifikasi', value: 'Aktif'),
                _ProfileRow(icon: Icons.lock_outline, label: 'Keamanan', value: 'Ganti PIN/Password'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.title, required this.items, this.trailing});

  final String title;
  final List<_ProfileRow> items;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style:
                      const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          ...items.expand((row) => [
                row,
                if (row != items.last)
                  const Divider(height: 16, thickness: 0.8, color: Color(0xFFEAEAEA)),
              ]),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderItemCard extends ConsumerWidget {
  const _OrderItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.product.image,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text('Rp${item.product.price}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: () => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(item.product.id, item.quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(item.quantity.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: () => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(item.product.id, item.quantity + 1),
                    ),
                  ],
                )
              ],
            ),
          ),
          Text(
            'Rp${item.total}',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

void _showCheckoutDialog(
    BuildContext context, int total, List<CartItem> cart) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total belanja: Rp$total'),
            const SizedBox(height: 8),
            const Text(
              'Silakan screenshot pesanan ini sebagai bukti.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Rincian pesanan:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...cart.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity} x ${item.product.title}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('Rp${item.total}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Kontak:'),
            const SizedBox(height: 6),
            _ContactRow(
              label: 'WhatsApp',
              value: '628123456789',
              uri: 'https://wa.me/628123456789',
            ),
            _ContactRow(
              label: 'Telepon',
              value: '0812-3456-789',
              uri: 'tel:08123456789',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          )
        ],
      );
    },
  );
}

Future<void> _exportSalesPdf(
    BuildContext context, SalesSummary summary, String range) async {
  final doc = pw.Document();
  final generatedAt = DateTime.now().toLocal();
  final title = 'Laporan Penjualan ${_rangeLabel(range)}';
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context ctx) {
        return [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BUMDES Mitra Baru',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(title,
                      style: pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey700)),
                  pw.Text(
                    'Dibuat: ${generatedAt.toString().split(".").first}',
                    style: pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  _rangeLabel(range),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1B8C5A)),
                ),
              )
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Container(height: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pdfStatCard('Total Pendapatan',
                  _formatCurrency(summary.totalRevenue), PdfColors.green800),
              pw.SizedBox(width: 12),
              pdfStatCard('Jumlah Pesanan', '${summary.ordersCount}',
                  PdfColors.blueGrey800),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['ID', 'Waktu', 'Pelanggan', 'Rincian', 'Total', 'Status'],
            data: summary.orders.map((o) {
              final statusLabel =
                  o.status == OrderStatus.verified ? 'Terverifikasi' : o.status == OrderStatus.packing ? 'Packing' : o.status == OrderStatus.cancelled ? 'Ditolak' : 'Menunggu';
              return [
                o.id,
                o.createdAt,
                o.customer,
                o.itemsDescription,
                _formatCurrency(o.total),
                statusLabel,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E7D32)),
            cellStyle: const pw.TextStyle(fontSize: 10),
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerLeft,
            },
          ),
        ];
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => doc.save());
}

Future<void> _exportReceiptPdf(BuildContext context, OrderSummary order) async {
  final doc = pw.Document();
  final statusLabel = order.status == OrderStatus.delivered
      ? 'Selesai'
      : order.status == OrderStatus.verified
          ? 'Pengantaran'
          : order.status == OrderStatus.packing
              ? 'Verifikasi & Packing'
              : order.status == OrderStatus.cancelled
                  ? 'Ditolak'
                  : 'Menunggu';
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BUMDES Mitra Baru',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Receipt Pesanan #${order.id}',
                    style: pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey700)),
                pw.Text(order.createdAt,
                    style:
                        pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.green100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                statusLabel,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1B8C5A)),
              ),
            )
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 14),
        pw.Text('Detail Pesanan',
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Bullet(
            text: 'Pelanggan: ${order.customer}',
            style: const pw.TextStyle(fontSize: 11)),
        pw.Bullet(
            text: 'Kontak: ${order.contact.isEmpty ? '-' : order.contact}',
            style: const pw.TextStyle(fontSize: 11)),
        pw.Bullet(
            text: 'Rincian: ${order.itemsDescription}',
            style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(10),
            color: PdfColors.grey100,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text(_formatCurrency(order.total),
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Text('Terima kasih telah berbelanja di BUMDES Mitra Baru.',
            style:
                pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => doc.save());
}

String _rangeLabel(String range) {
  switch (range) {
    case 'week':
      return '1 Minggu';
    case 'month':
      return '1 Bulan';
    default:
      return '1 Hari';
  }
}

String _formatCurrency(int value) {
  final digits = value.toString().split('');
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final fromEnd = digits.length - i - 1;
    if (fromEnd > 0 && fromEnd % 3 == 0) {
      buffer.write('.');
    }
  }
  return 'Rp ${buffer.toString()}';
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.label, required this.value, this.uri});

  final String label;
  final String value;
  final String? uri;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: uri == null ? null : () => _launchUri(context, uri!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              label == 'WhatsApp' ? Icons.chat : Icons.phone,
              size: 18,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Text('$label: $value'),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchUri(BuildContext context, String uri) async {
  try {
    final parsed = Uri.parse(uri);
    final ok = await launchUrl(parsed, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gagal membuka tautan')));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gagal membuka tautan')));
    }
  }
}

Future<void> _submitOrder(
    BuildContext context, WidgetRef ref, int total, List<CartItem> cart) async {
  final messenger = ScaffoldMessenger.of(context);
  final summaryItems = List<CartItem>.from(cart);
  try {
    final session = ref.read(authControllerProvider).value;
    final userId = session?.userId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Tidak ada user_id. Silakan login ulang.');
    }
    final orderId = await ref
        .read(orderRepositoryProvider)
        .createOrder(cart, total, userId: userId);
    // refresh daftar pesanan setelah checkout
    await ref.read(orderListProvider.notifier).load();
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Rincian pesanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID Pesanan: #$orderId',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppTheme.primary)),
              const Text(
                'Screenshot rincian ini lalu hubungi nomor di bawah.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('Rincian pesanan:'),
              const SizedBox(height: 8),
              ...summaryItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity} x ${item.product.title}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('Rp${item.total}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Total: Rp$total',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text('Hubungi kami via WhatsApp:'),
              TextButton.icon(
                onPressed: () =>
                    _launchUri(context, 'https://wa.me/628123456789'),
                icon: const Icon(Icons.chat),
                label: const Text('628123456789'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      ref.read(cartProvider.notifier).clear();
      messenger.showSnackBar(
        const SnackBar(content: Text('Keranjang telah di-checkout')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(
          content: Text('Gagal menyimpan pesanan: ${e.toString()}')));
    }
  }
}
