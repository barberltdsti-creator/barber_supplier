import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
      AdsPage(repository: widget.repository, profile: widget.profile),
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
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Reklam',
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

  Future<void> toggleProduct(SupplierProduct product, bool value) async {
    await widget.repository.setProductActive(product.id, value);
    reload();
  }

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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 132),
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final product = snapshot.data![i];
                return _ProductListCard(
                  product: product,
                  onToggle: (value) => toggleProduct(product, value),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProductListCard extends StatelessWidget {
  const _ProductListCard({required this.product, required this.onToggle});

  final SupplierProduct product;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final lowStock = product.stockQuantity < 10;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onToggle(!product.isActive),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProductThumb(product: product, size: 62),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _money(product.price),
                          style: TextStyle(
                            color: lowStock ? Colors.red : Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Stok: ${product.stockQuantity}',
                          style: TextStyle(
                            color: lowStock ? Colors.red : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (product.isFeatured) ...[
                      const SizedBox(height: 5),
                      const Text(
                        'Öne çıkarılmış ürün',
                        style: TextStyle(
                          color: AppTheme.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ProductActiveControl(
                value: product.isActive,
                onChanged: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductActiveControl extends StatelessWidget {
  const _ProductActiveControl({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: value,
      label: value ? 'Ürün aktif' : 'Ürün pasif',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          child: Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
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
  final description = TextEditingController();
  XFile? image;
  bool loading = false;

  @override
  void dispose() {
    for (final controller in [
      name,
      category,
      sku,
      price,
      stock,
      minimum,
      description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked != null) setState(() => image = picked);
  }

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
      final productId = await widget.repository.saveProduct(
        supplierId: widget.supplierId,
        name: name.text,
        category: category.text,
        sku: sku.text,
        price: parsedPrice,
        stockQuantity: parsedStock,
        minimumOrderQuantity: int.tryParse(minimum.text) ?? 1,
        description: description.text,
      );
      final selectedImage = image;
      if (selectedImage != null) {
        final bytes = await selectedImage.readAsBytes();
        final extension = selectedImage.name.split('.').last;
        await widget.repository.uploadProductImage(
          supplierId: widget.supplierId,
          productId: productId,
          bytes: bytes,
          extension: extension,
        );
      }
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
            InkWell(
              onTap: loading ? null : pickImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 142,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9EBF0)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppTheme.orange,
                        size: 34,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        image == null ? 'Ürün görseli seç' : image!.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
            TextField(
              controller: description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ürün açıklaması',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
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

class AdsPage extends StatefulWidget {
  const AdsPage({super.key, required this.repository, required this.profile});
  final SupplierRepository repository;
  final SupplierProfile profile;

  @override
  State<AdsPage> createState() => _AdsPageState();
}

class _AdsPageState extends State<AdsPage> {
  late Future<(List<SupplierProduct>, List<AdCampaign>)> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<(List<SupplierProduct>, List<AdCampaign>)> _load() async => (
    await widget.repository.getProducts(widget.profile.id),
    await widget.repository.getAdCampaigns(widget.profile.id),
  );

  void reload() => setState(() => future = _load());

  Future<void> createCampaign(List<SupplierProduct> products) async {
    if (!widget.profile.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reklam vermek için mağazanızın onaylanması gerekiyor.',
          ),
        ),
      );
      return;
    }
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce en az bir ürün ekleyin.')),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AdCampaignForm(
        repository: widget.repository,
        supplierId: widget.profile.id,
        products: products,
      ),
    );
    if (saved == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reklam ve öne çıkarma',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<(List<SupplierProduct>, List<AdCampaign>)>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!.$1;
          final campaigns = snapshot.data!.$2;
          final previewProduct = products.isEmpty ? null : products.first;
          return RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                _AdPreview(product: previewProduct),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => createCampaign(products),
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Reklam başvurusu oluştur'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kampanyalarım',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (campaigns.isEmpty)
                  const _Empty(
                    icon: Icons.campaign_outlined,
                    text: 'Henüz reklam kampanyanız yok.',
                  )
                else
                  ...campaigns.map((campaign) => _CampaignCard(campaign)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AdCampaignForm extends StatefulWidget {
  const AdCampaignForm({
    super.key,
    required this.repository,
    required this.supplierId,
    required this.products,
  });

  final SupplierRepository repository;
  final String supplierId;
  final List<SupplierProduct> products;

  @override
  State<AdCampaignForm> createState() => _AdCampaignFormState();
}

class _AdCampaignFormState extends State<AdCampaignForm> {
  late SupplierProduct selected = widget.products.first;
  final title = TextEditingController();
  final budget = TextEditingController(text: '1000');
  final note = TextEditingController();
  String placement = 'marketplace_featured';
  bool loading = false;

  @override
  void dispose() {
    title.dispose();
    budget.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final parsedBudget = double.tryParse(budget.text.replaceAll(',', '.'));
    if (title.text.trim().isEmpty || parsedBudget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlık ve bütçe alanlarını kontrol edin.'),
        ),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await widget.repository.createAdCampaign(
        supplierId: widget.supplierId,
        productId: selected.id,
        title: title.text,
        budget: parsedBudget,
        placement: placement,
        previewNote: note.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reklam başvurusu kaydedilemedi: $error')),
        );
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
              'Reklam başvurusu',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<SupplierProduct>(
              initialValue: selected,
              items: widget.products
                  .map(
                    (product) => DropdownMenuItem(
                      value: product,
                      child: Text(product.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selected = value!),
              decoration: const InputDecoration(
                labelText: 'Öne çıkarılacak ürün',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Kampanya başlığı'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: placement,
              items: const [
                DropdownMenuItem(
                  value: 'marketplace_featured',
                  child: Text('Ürün siparişi vitrini'),
                ),
                DropdownMenuItem(
                  value: 'category_top',
                  child: Text('Kategori üst sırası'),
                ),
                DropdownMenuItem(
                  value: 'search_boost',
                  child: Text('Arama sonucu öne çıkarma'),
                ),
              ],
              onChanged: (value) => setState(() => placement = value!),
              decoration: const InputDecoration(labelText: 'Reklam yeri'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budget,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Aylık bütçe'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Önizleme notu',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            _AdPreview(product: selected, compact: true),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: loading ? null : save,
              child: Text(loading ? 'Kaydediliyor…' : 'Başvuruyu gönder'),
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

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product, this.size = 58});
  final SupplierProduct product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFFFF1E8),
        child: imageUrl == null || imageUrl.isEmpty
            ? const Icon(Icons.content_cut, color: AppTheme.orange)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined),
              ),
      ),
    );
  }
}

class _AdPreview extends StatelessWidget {
  const _AdPreview({required this.product, this.compact = false});
  final SupplierProduct? product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('Reklam önizlemesi için önce ürün ekleyin.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.orange),
                const SizedBox(width: 8),
                Text(
                  compact ? 'Önizleme' : 'Salon ekranında böyle görünecek',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                const _SponsoredPill(),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _ProductThumb(product: product!, size: compact ? 72 : 88),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product!.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product!.category ?? 'BarBer tedarik ürünü',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _money(product!.price),
                        style: const TextStyle(
                          color: AppTheme.orange,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsoredPill extends StatelessWidget {
  const _SponsoredPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1E8),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const Text(
      'Sponsorlu',
      style: TextStyle(
        color: AppTheme.orange,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard(this.campaign);
  final AdCampaign campaign;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 58,
              height: 58,
              color: const Color(0xFFFFF1E8),
              child: campaign.productImageUrl == null
                  ? const Icon(Icons.campaign_outlined, color: AppTheme.orange)
                  : Image.network(
                      campaign.productImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.campaign_outlined),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${campaign.productName ?? 'Ürün'} • ${_money(campaign.budget)}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          _StatusChip(status: campaign.status),
        ],
      ),
    ),
  );
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
