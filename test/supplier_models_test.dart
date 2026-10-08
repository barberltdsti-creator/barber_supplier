import 'package:barber_supplier/src/supplier_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supplier profile approval state is explicit', () {
    final pending = SupplierProfile.fromJson({
      'id': 'supplier-1',
      'company_name': 'Test Tedarik',
      'status': 'pending',
    });
    final approved = SupplierProfile.fromJson({
      'id': 'supplier-2',
      'company_name': 'Onaylı Tedarik',
      'status': 'approved',
    });

    expect(pending.isApproved, isFalse);
    expect(approved.isApproved, isTrue);
  });

  test('product numeric fields are parsed safely', () {
    final product = SupplierProduct.fromJson({
      'id': 'product-1',
      'name': 'Profesyonel Makas',
      'price': 1299.90,
      'stock_quantity': 12,
      'is_active': true,
    });

    expect(product.price, 1299.90);
    expect(product.stockQuantity, 12);
    expect(product.isActive, isTrue);
  });
}
