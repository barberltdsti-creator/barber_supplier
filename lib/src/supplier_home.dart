import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_theme.dart';
import 'supplier_repository.dart';

class SupplierHome extends StatefulWidget {
  const SupplierHome({
    super.key,
    required this.repository,
    required this.profile,
    required this.onRefreshProfile,
  });

  final SupplierRepository repository;
  final SupplierProfile profile;
  final VoidCallback onRefreshProfile;

  @override
  State<SupplierHome> createState() => _SupplierHomeState();
}

class _SupplierHomeState extends State<SupplierHome> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(repository: widget.repository, profile: widget.profile),
      ProductsPage(repository: widget.repository, profile: widget.profile),
      OrdersPage(repository: widget.repository, profile: widget.profile),
      AccountPage(profile: widget.profile),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Özet',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Ürünler',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Siparişler',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Hesabım',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.repository,
    required this.profile,
  });
  final SupplierRepository repository;
  final SupplierProfile profile;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<(List<SupplierProduct>, List<SupplierOrder>)> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<(List<SupplierProduct>, List<SupplierOrder>)> _load() async => (
    await widget.repository.getProducts(widget.profile.id),
    await widget.repository.getOrders(widget.profile.id),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => setState(() => future = _load()),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BarBer Tedarikçi',
                        style: TextStyle(
                          color: AppTheme.orange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.profile.companyName,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.navy,
                  child: Icon(Icons.store, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StatusBanner(status: widget.profile.status),
            const SizedBox(height: 20),
            FutureBuilder<(List<SupplierProduct>, List<SupplierOrder>)>(
              future: future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final products = snapshot.data!.$1;
                final orders = snapshot.data!.$2;
                final revenue = orders
                    .where((e) => e.status != 'cancelled')
                    .fold<double>(0, (sum, e) => sum + e.totalAmount);
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            icon: Icons.inventory_2_outlined,
                            label: 'Ürün',
                            value: '${products.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Metric(
                            icon: Icons.receipt_long_outlined,
                            label: 'Sipariş',
                            value: '${orders.length}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            icon: Icons.warning_amber_rounded,
                            label: 'Düşük stok',
                            value:
                                '${products.where((e) => e.stockQuantity < 10).length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Metric(
                            icon: Icons.payments_outlined,
                            label: 'Toplam satış',
                            value: _money(revenue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Son siparişler',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (orders.isEmpty)
                      const _Empty(
                        icon: Icons.receipt_long_outlined,
                        text: 'Henüz siparişiniz yok.',
                      )
                    else
                      ...orders
                          .take(4)
                          .map((order) => _OrderCard(order: order)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    required this.repository,
    required this.profile,
  });
  final SupplierRepository repository;
  final SupplierProfile profile;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<SupplierProduct>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.getProducts(widget.profile.id);
  }

  void reload() =>
      setState(() => future = widget.repository.getProducts(widget.profile.id));

  Future<void> addProduct() async {
    if (!widget.profile.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ürün eklemek için başvurunuzun onaylanması gerekiyor.',
          ),
        ),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProductForm(
        repository: widget.repository,
        supplierId: widget.profile.id,
      ),
    );
    if (saved == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ürünlerim',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addProduct,
        icon: const Icon(Icons.add),
        label: const Text('Ürün ekle'),
      ),
      body: FutureBuilder<List<SupplierProduct>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const _Empty(
              icon: Icons.inventory_2_outlined,
              text: 'İlk ürününüzü ekleyerek satışa başlayın.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final product = snapshot.data![i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1E8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.content_cut,
                            color: AppTheme.orange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_money(product.price)} • Stok: ${product.stockQuantity}',
                                style: TextStyle(
                                  color: product.stockQuantity < 10
                                      ? Colors.red
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: product.isActive,
                          onChanged: (value) async {
                            await widget.repository.setProductActive(
                              product.id,
                              value,
                            );
                            reload();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ProductForm extends StatefulWidget {
  const ProductForm({
    super.key,
    required this.repository,
    required this.supplierId,
  });
  final SupplierRepository repository;
  final String supplierId;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final name = TextEditingController();
  final category = TextEditingController();
  final sku = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController();
  final minimum = TextEditingController(text: '1');
  bool loading = false;

  Future<void> save() async {
    final parsedPrice = double.tryParse(price.text.replaceAll(',', '.'));
    final parsedStock = int.tryParse(stock.text);
    if (name.text.trim().isEmpty ||
        parsedPrice == null ||
        parsedStock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün adı, fiyat ve stok bilgilerini kontrol edin.'),
        ),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await widget.repository.saveProduct(
        supplierId: widget.supplierId,
        name: name.text,
        category: category.text,
        sku: sku.text,
        price: parsedPrice,
        stockQuantity: parsedStock,
        minimumOrderQuantity: int.tryParse(minimum.text) ?? 1,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ürün kaydedilemedi: $error')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Yeni ürün',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            for (final field in [
              (name, 'Ürün adı', TextInputType.text),
              (category, 'Kategori', TextInputType.text),
              (sku, 'Stok kodu (SKU)', TextInputType.text),
              (
                price,
                'Salon satış fiyatı',
                const TextInputType.numberWithOptions(decimal: true),
              ),
              (stock, 'Stok adedi', TextInputType.number),
              (minimum, 'Minimum sipariş adedi', TextInputType.number),
            ]) ...[
              TextField(
                controller: field.$1,
                keyboardType: field.$3,
                decoration: InputDecoration(labelText: field.$2),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: loading ? null : save,
              child: Text(loading ? 'Kaydediliyor…' : 'Ürünü yayınla'),
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({
    super.key,
    required this.repository,
    required this.profile,
  });
  final SupplierRepository repository;
  final SupplierProfile profile;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<SupplierOrder>> future;
  @override
  void initState() {
    super.initState();
    future = widget.repository.getOrders(widget.profile.id);
  }

  void reload() =>
      setState(() => future = widget.repository.getOrders(widget.profile.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Salon siparişleri',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<SupplierOrder>>(
        future: future,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const _Empty(
              icon: Icons.local_shipping_outlined,
              text: 'Yeni siparişler burada görünecek.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _OrderCard(
              order: snapshot.data![i],
              onStatus: (status) async {
                await widget.repository.updateOrderStatus(
                  snapshot.data![i].id,
                  status,
                );
                reload();
              },
            ),
          );
        },
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.profile});
  final SupplierProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tedarikçi hesabı',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: AppTheme.navy,
                    child: Icon(
                      Icons.storefront,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.companyName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (profile.contactName != null)
                    Text(
                      profile.contactName!,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  const SizedBox(height: 10),
                  _StatusChip(status: profile.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.business_outlined),
                  title: Text('Firma bilgileri'),
                  trailing: Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.account_balance_outlined),
                  title: Text('Banka ve ödeme bilgileri'),
                  trailing: Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Çıkış yap'),
                  onTap: () => Supabase.instance.client.auth.signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final approved = status == 'approved';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: approved ? const Color(0xFFEAF8EF) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            approved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
            color: approved ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              approved ? 'Mağazanız yayında' : 'Başvurunuz inceleniyor',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          _StatusChip(status: status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final label =
        {
          'approved': 'Onaylı',
          'pending': 'Bekliyor',
          'suspended': 'Askıda',
          'rejected': 'Reddedildi',
          'confirmed': 'Onaylandı',
          'preparing': 'Hazırlanıyor',
          'shipped': 'Kargoda',
          'delivered': 'Teslim edildi',
          'cancelled': 'İptal edildi',
        }[status] ??
        status;
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.orange),
          const SizedBox(height: 16),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, this.onStatus});
  final SupplierOrder order;
  final ValueChanged<String>? onStatus;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      order.salonName ?? 'Salon siparişi',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Text(
                _money(order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('dd.MM.yyyy HH:mm', 'tr').format(order.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ),
              if (onStatus != null)
                PopupMenuButton<String>(
                  onSelected: onStatus,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'confirmed',
                      child: Text('Siparişi onayla'),
                    ),
                    PopupMenuItem(
                      value: 'preparing',
                      child: Text('Hazırlanıyor'),
                    ),
                    PopupMenuItem(
                      value: 'shipped',
                      child: Text('Kargoya verildi'),
                    ),
                    PopupMenuItem(
                      value: 'delivered',
                      child: Text('Teslim edildi'),
                    ),
                  ],
                ),
              _StatusChip(status: order.status),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: Colors.black26),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

String _money(double value) => NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 2,
).format(value);
