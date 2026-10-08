import 'supplier_repository.dart';

class DemoSupplierRepository extends SupplierRepository {
  DemoSupplierRepository(super.client);

  static final products = <SupplierProduct>[
    const SupplierProduct(
      id: '1',
      name: 'Profesyonel Kesim Makası 6.0',
      price: 1890,
      stockQuantity: 24,
      isActive: true,
      category: 'Makas',
      sku: 'MKS-600',
    ),
    const SupplierProduct(
      id: '2',
      name: 'Kablosuz Ense Makinesi',
      price: 2450,
      stockQuantity: 7,
      isActive: true,
      category: 'Makineler',
      sku: 'ENS-21',
    ),
    const SupplierProduct(
      id: '3',
      name: 'Berber Boyun Bandı 5’li',
      price: 320,
      stockQuantity: 86,
      isActive: true,
      category: 'Sarf Malzeme',
      sku: 'BYN-05',
    ),
    const SupplierProduct(
      id: '4',
      name: 'Mat Wax 150 ml',
      price: 185,
      stockQuantity: 0,
      isActive: false,
      category: 'Bakım',
      sku: 'WAX-150',
    ),
  ];

  static final orders = <SupplierOrder>[
    SupplierOrder(
      id: '1',
      orderNumber: 'BT-20260805-A72F',
      status: 'pending',
      totalAmount: 5840,
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      salonName: 'Makas İstanbul',
    ),
    SupplierOrder(
      id: '2',
      orderNumber: 'BT-20260805-C91B',
      status: 'preparing',
      totalAmount: 2760,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      salonName: 'Centilmen Barber',
    ),
    SupplierOrder(
      id: '3',
      orderNumber: 'BT-20260804-F42D',
      status: 'shipped',
      totalAmount: 9140,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      salonName: 'Modern Erkek Kuaförü',
    ),
  ];

  @override
  Future<List<SupplierProduct>> getProducts(String supplierId) async =>
      List.of(products);

  @override
  Future<List<SupplierOrder>> getOrders(String supplierId) async =>
      List.of(orders);

  @override
  Future<void> setProductActive(String id, bool isActive) async {}

  @override
  Future<void> updateOrderStatus(String id, String status) async {}

  @override
  Future<void> saveProduct({
    String? id,
    required String supplierId,
    required String name,
    required String category,
    required String sku,
    required double price,
    required int stockQuantity,
    required int minimumOrderQuantity,
  }) async {}
}
