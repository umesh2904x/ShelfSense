import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/product_service.dart';
import 'add_edit_product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Product>> _productsStream;
  ProductCategory? _selectedCategory;
  bool? _notificationsEnabled;
  bool _notificationStatusLoading = true;
  bool _requestingNotifications = false;
  String? _notificationError;

  @override
  void initState() {
    super.initState();
    _productsStream = context.read<ProductService>().getProductsStream();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotificationStatus();
    });
  }

  Future<void> _loadNotificationStatus() async {
    final notifications = context.read<NotificationService>();
    try {
      await notifications.initialize();
      if (mounted) {
        setState(() {
          if (notifications.isSupported) {
            _notificationsEnabled = notifications.notificationsEnabled;
          }
          _notificationStatusLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notificationError = e.toString();
          _notificationStatusLoading = false;
        });
      }
    }
  }

  Future<void> _enableNotifications() async {
    final notifications = context.read<NotificationService>();
    final products = context.read<ProductService>();
    setState(() => _requestingNotifications = true);
    try {
      final granted = await notifications.requestPermission();
      if (mounted) {
        setState(() {
          _notificationsEnabled = granted;
          _notificationError = null;
        });
      }
      if (granted) {
        final existingProducts = await products.getProductsStream().first;
        for (final product in existingProducts) {
          await notifications.scheduleReminders(product);
        }
      }
      if (mounted) {
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notifications are off. Allow them in your device settings to receive reminders.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _notificationError = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not enable reminders: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _requestingNotifications = false);
    }
  }

  Future<void> _signOut() async {
    final authService = context.read<AuthService>();
    final notificationService = context.read<NotificationService>();
    await authService.signOut();
    await notificationService.cancelAll();
  }

  void _navigateToAddEdit({Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(product: product),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB8403A),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final notificationService = context.read<NotificationService>();
      final productService = context.read<ProductService>();
      await notificationService.cancelReminders(product.id);
      await productService.deleteProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F0E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.eco_outlined,
                color: Color(0xFF34785A),
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'ShelfSense',
              style:
                  TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF34785A)),
            );
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final allProducts = snapshot.data ?? [];
          final products = _selectedCategory == null
              ? allProducts
              : allProducts
                  .where((product) => product.category == _selectedCategory)
                  .toList();
          final expiringCount = allProducts
              .where((product) => product.status == ExpiryStatus.warning)
              .length;
          final expiredCount = allProducts
              .where((product) => product.status == ExpiryStatus.expired)
              .length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth =
                  constraints.maxWidth > 960 ? 920.0 : constraints.maxWidth;
              return Center(
                child: SizedBox(
                  width: contentWidth,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    children: [
                      _buildOverviewHeading(),
                      const SizedBox(height: 16),
                      _buildNotificationStatus(),
                      const SizedBox(height: 16),
                      _buildSummary(
                          allProducts.length, expiringCount, expiredCount),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your products',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: const Color(0xFF24352C),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          Text(
                            '${products.length} ${products.length == 1 ? 'item' : 'items'}',
                            style: const TextStyle(
                              color: Color(0xFF7B887F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryFilter(),
                      const SizedBox(height: 12),
                      if (products.isEmpty)
                        _buildEmptyState(allProducts.isEmpty)
                      else
                        ...products.map(
                          (product) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildProductCard(product),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        backgroundColor: const Color(0xFF34785A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
      ),
    );
  }

  Widget _buildOverviewHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your essentials',
          style: TextStyle(
            color: Color(0xFF29372F),
            fontSize: 25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          DateFormat('EEEE, MMMM d').format(DateTime.now()),
          style: const TextStyle(
            color: Color(0xFF7B887F),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationStatus() {
    final notifications = context.read<NotificationService>();
    final supported = notifications.isSupported;
    final enabled = _notificationsEnabled == true;
    final checking = _notificationStatusLoading;
    final color = !supported
        ? const Color(0xFF66736A)
        : enabled
            ? const Color(0xFF34785A)
            : const Color(0xFF9A671D);
    final background = !supported
        ? const Color(0xFFEDF0ED)
        : enabled
            ? const Color(0xFFE8F2EB)
            : const Color(0xFFFFF3E1);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            !supported
                ? Icons.info_outline_rounded
                : enabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checking
                      ? 'Checking notification access'
                      : _notificationError != null
                          ? 'Could not check notifications'
                          : !supported
                              ? 'Reminders unavailable here'
                              : enabled
                                  ? 'Expiry reminders are on'
                                  : 'Get expiry reminders',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  checking
                      ? 'Checking whether this device can send expiry alerts.'
                      : _notificationError != null
                          ? _notificationError!
                          : !supported
                              ? 'Scheduled reminders are supported in the Android and iOS apps.'
                              : enabled
                                  ? 'Alerts arrive 7 days before, 3 days before, and on the expiry date at 9 AM.'
                                  : 'Turn on notifications to get alerts 7 days before, 3 days before, and on expiry day.',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.88),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (supported && !enabled && !checking) ...[
            const SizedBox(width: 8),
            _requestingNotifications
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF9A671D),
                    ),
                  )
                : TextButton(
                    onPressed: _enableNotifications,
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      _notificationError == null ? 'Enable' : 'Retry',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(int total, int expiring, int expired) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 24) / 3;
        return Row(
          children: [
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                label: 'Tracked',
                count: total,
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF34785A),
                background: const Color(0xFFE7F2EB),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                label: 'Expiring',
                count: expiring,
                icon: Icons.schedule_rounded,
                color: const Color(0xFFB76A14),
                background: const Color(0xFFFFF1DD),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                label: 'Expired',
                count: expired,
                icon: Icons.error_outline_rounded,
                color: const Color(0xFFB8403A),
                background: const Color(0xFFFFE9E6),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 9),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF748078),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = <(ProductCategory?, String)>[
      (null, 'All'),
      (ProductCategory.grocery, 'Grocery'),
      (ProductCategory.medicine, 'Medicine'),
      (ProductCategory.cosmetics, 'Cosmetics'),
      (ProductCategory.other, 'Other'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (category, label) = categories[index];
          final selected = _selectedCategory == category;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = category),
            showCheckmark: false,
            selectedColor: const Color(0xFF34785A),
            backgroundColor: Colors.white,
            side: BorderSide(
              color:
                  selected ? const Color(0xFF34785A) : const Color(0xFFE3E9E4),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF647168),
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final color = _statusColor(product.status);
    final categoryIcon = switch (product.category) {
      ProductCategory.grocery => Icons.shopping_basket_outlined,
      ProductCategory.medicine => Icons.medical_services_outlined,
      ProductCategory.cosmetics => Icons.spa_outlined,
      ProductCategory.other => Icons.inventory_2_outlined,
    };
    final daysLeft = product.daysLeft;
    final expiryLabel = daysLeft < 0
        ? 'Expired ${-daysLeft} ${-daysLeft == 1 ? 'day' : 'days'} ago'
        : daysLeft == 0
            ? 'Expires today'
            : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left';

    return Card(
      child: InkWell(
        onTap: () => _navigateToAddEdit(product: product),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(categoryIcon, color: const Color(0xFF34785A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF29372F),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.category.displayName}  ·  Qty ${product.quantity}',
                          style: const TextStyle(
                            color: Color(0xFF7B887F),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Product actions',
                    onSelected: (action) {
                      if (action == 'edit') {
                        _navigateToAddEdit(product: product);
                      } else if (action == 'delete') {
                        _deleteProduct(product);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFEDF0ED)),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: Color(0xFF87928A),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Expires ${DateFormat('MMM d, yyyy').format(product.expiryDate)}',
                      style: const TextStyle(
                        color: Color(0xFF68756D),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(product.status, color),
                  const SizedBox(width: 8),
                  Text(
                    expiryLabel,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(ExpiryStatus status, Color color) {
    final label = switch (status) {
      ExpiryStatus.safe => 'Fresh',
      ExpiryStatus.warning => 'Soon',
      ExpiryStatus.expired => 'Expired',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _statusColor(ExpiryStatus status) {
    return switch (status) {
      ExpiryStatus.safe => const Color(0xFF34785A),
      ExpiryStatus.warning => const Color(0xFFB76A14),
      ExpiryStatus.expired => const Color(0xFFB8403A),
    };
  }

  Widget _buildEmptyState(bool noProducts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2EC),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF34785A),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              noProducts ? 'Your list is ready' : 'Nothing in this category',
              style: const TextStyle(
                color: Color(0xFF29372F),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              noProducts
                  ? 'Add groceries, medicine, soap, skincare, or anything else you want to keep track of.'
                  : 'Try another category or add a product here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7B887F),
                height: 1.45,
              ),
            ),
            if (noProducts) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _navigateToAddEdit(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add your first product'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Color(0xFFB8403A),
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load your products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() {}),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
