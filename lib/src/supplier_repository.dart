import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupplierProfile {
  const SupplierProfile({
    required this.id,
    required this.companyName,
    required this.status,
    this.contactName,
    this.phone,
  });

  final String id;
  final String companyName;
  final String status;
  final String? contactName;
  final String? phone;

  bool get isApproved => status == 'approved';

  factory SupplierProfile.fromJson(Map<String, dynamic> json) =>
      SupplierProfile(
        id: json['id'] as String,
        companyName: json['company_name'] as String? ?? 'Tedarikçi',
        status: json['status'] as String? ?? 'pending',
        contactName: json['contact_name'] as String?,
        phone: json['phone'] as String?,
      );
}

class SupplierProduct {
  const SupplierProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stockQuantity,
    required this.isActive,
    this.category,
    this.sku,
    this.description,
    this.imageUrl,
    this.featuredUntil,
  });

  final String id;
  final String name;
  final double price;
  final int stockQuantity;
  final bool isActive;
  final String? category;
  final String? sku;
  final String? description;
  final String? imageUrl;
  final DateTime? featuredUntil;

  bool get isFeatured =>
      featuredUntil != null && featuredUntil!.isAfter(DateTime.now());

  factory SupplierProduct.fromJson(Map<String, dynamic> json) =>
      SupplierProduct(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Ürün',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] as bool? ?? false,
        category: json['category'] as String?,
        sku: json['sku'] as String?,
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        featuredUntil: DateTime.tryParse(
          json['featured_until'] as String? ?? '',
        ),
      );
}

class SupplierOrder {
  const SupplierOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.salonName,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final String? salonName;

  factory SupplierOrder.fromJson(Map<String, dynamic> json) => SupplierOrder(
    id: json['id'] as String,
    orderNumber: json['order_number'] as String? ?? '-',
    status: json['status'] as String? ?? 'pending',
    totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
    salonName: (json['salons'] as Map<String, dynamic>?)?['name'] as String?,
  );
}

class AdCampaign {
  const AdCampaign({
    required this.id,
    required this.title,
    required this.placement,
    required this.status,
    required this.budget,
    required this.createdAt,
    this.productName,
    this.productImageUrl,
    this.startsAt,
    this.endsAt,
    this.previewNote,
  });

  final String id;
  final String title;
  final String placement;
  final String status;
  final double budget;
  final DateTime createdAt;
  final String? productName;
  final String? productImageUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? previewNote;

  factory AdCampaign.fromJson(Map<String, dynamic> json) {
    final product = json['supplier_products'] as Map<String, dynamic>?;
    return AdCampaign(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Reklam kampanyası',
      placement: json['placement'] as String? ?? 'marketplace_featured',
      status: json['status'] as String? ?? 'draft',
      budget: (json['budget'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      productName: product?['name'] as String?,
      productImageUrl: product?['image_url'] as String?,
      startsAt: DateTime.tryParse(json['starts_at'] as String? ?? ''),
      endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
      previewNote: json['preview_note'] as String?,
    );
  }
}

class SupplierRepository {
  SupplierRepository(this.client);

  final SupabaseClient client;

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Oturum bulunamadı.');
    return id;
  }

  Future<SupplierProfile?> getMyProfile() async {
    final data = await client
        .from('supplier_profiles')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();
    return data == null ? null : SupplierProfile.fromJson(data);
  }

  Future<void> submitApplication({
    required String companyName,
    required String contactName,
    required String phone,
    required String taxNumber,
    required String taxOffice,
  }) async {
    await client.from('supplier_profiles').insert({
      'user_id': _userId,
      'company_name': companyName.trim(),
      'contact_name': contactName.trim(),
      'phone': phone.trim(),
      'tax_number': taxNumber.trim(),
      'tax_office': taxOffice.trim(),
      'status': 'pending',
    });
  }

  Future<List<SupplierProduct>> getProducts(String supplierId) async {
    final data = await client
        .from('supplier_products')
        .select()
        .eq('supplier_id', supplierId)
        .order('created_at', ascending: false)
        .limit(100);
    return data.map(SupplierProduct.fromJson).toList();
  }

  Future<String> saveProduct({
    String? id,
    required String supplierId,
    required String name,
    required String category,
    required String sku,
    required double price,
    required int stockQuantity,
    required int minimumOrderQuantity,
    String? description,
  }) async {
    final payload = {
      'supplier_id': supplierId,
      'name': name.trim(),
      'category': category.trim(),
      'sku': sku.trim().isEmpty ? null : sku.trim(),
      'description': description?.trim().isEmpty ?? true
          ? null
          : description!.trim(),
      'price': price,
      'stock_quantity': stockQuantity,
      'minimum_order_quantity': minimumOrderQuantity,
      'is_active': true,
    };
    if (id == null) {
      final data = await client
          .from('supplier_products')
          .insert(payload)
          .select('id')
          .single();
      return data['id'] as String;
    } else {
      await client.from('supplier_products').update(payload).eq('id', id);
      return id;
    }
  }

  Future<String> uploadProductImage({
    required String supplierId,
    required String productId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final normalizedExtension = extension.replaceAll('.', '').toLowerCase();
    final path =
        '$supplierId/$productId/${DateTime.now().millisecondsSinceEpoch}.$normalizedExtension';
    final contentType = switch (normalizedExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    await client.storage
        .from('product-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    final publicUrl = client.storage.from('product-images').getPublicUrl(path);
    await client.from('product_images').insert({
      'product_id': productId,
      'supplier_id': supplierId,
      'storage_path': path,
      'public_url': publicUrl,
      'is_primary': true,
    });
    await client
        .from('supplier_products')
        .update({'image_url': publicUrl})
        .eq('id', productId);
    return publicUrl;
  }

  Future<void> setProductActive(String id, bool isActive) async {
    await client
        .from('supplier_products')
        .update({'is_active': isActive})
        .eq('id', id);
  }

  Future<List<SupplierOrder>> getOrders(String supplierId) async {
    final data = await client
        .from('marketplace_orders')
        .select('*, salons(name)')
        .eq('supplier_id', supplierId)
        .order('created_at', ascending: false)
        .limit(100);
    return data.map(SupplierOrder.fromJson).toList();
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await client.rpc(
      'supplier_update_order_status',
      params: {'p_order_id': id, 'p_status': status},
    );
  }

  Future<List<AdCampaign>> getAdCampaigns(String supplierId) async {
    final data = await client
        .from('ad_campaigns')
        .select('*, supplier_products(name, image_url)')
        .eq('supplier_id', supplierId)
        .order('created_at', ascending: false)
        .limit(50);
    return data.map(AdCampaign.fromJson).toList();
  }

  Future<void> createAdCampaign({
    required String supplierId,
    required String productId,
    required String title,
    required double budget,
    required String placement,
    String? previewNote,
  }) async {
    await client.from('ad_campaigns').insert({
      'supplier_id': supplierId,
      'product_id': productId,
      'title': title.trim(),
      'budget': budget,
      'placement': placement,
      'status': 'pending',
      'preview_note': previewNote?.trim(),
    });
  }
}
