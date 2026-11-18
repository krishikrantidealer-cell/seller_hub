import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/product.dart';

void main() {
  test('Product.copyWith with explicit variants preserves first/default variant', () {
    const v1 = ProductVariant(
      id: 'v1',
      displayOrder: 1,
      isDefault: true,
      label: '100 ML',
      unit: 'ml',
      packSize: 100,
      packQuantity: 1,
      displayRate: 200,
      printedMrp: 250,
      stock: 10,
    );
    const v2 = ProductVariant(
      id: 'v2',
      displayOrder: 2,
      isDefault: false,
      label: '250 ML',
      unit: 'ml',
      packSize: 250,
      packQuantity: 1,
      displayRate: 450,
      printedMrp: 500,
      stock: 20,
    );
    const v3 = ProductVariant(
      id: 'v3',
      displayOrder: 3,
      isDefault: false,
      label: '500 ML',
      unit: 'ml',
      packSize: 500,
      packQuantity: 1,
      displayRate: 800,
      printedMrp: 900,
      stock: 30,
    );
    const v4 = ProductVariant(
      id: 'v4',
      displayOrder: 4,
      isDefault: false,
      label: '1 L',
      unit: 'l',
      packSize: 1,
      packQuantity: 1,
      displayRate: 1500,
      printedMrp: 1700,
      stock: 40,
    );

    final product = Product(
      id: 'p1',
      title: 'Test Product',
      brandName: 'Test Brand',
      vendor: 'Test Vendor',
      category: 'Test Cat',
      variants: [v1, v2, v3],
    );

    final updated = product.copyWith(
      variant: v4.label,
      displayRate: v4.displayRate,
      printedMrp: v4.printedMrp,
      stock: v4.stock,
      variants: [v1, v2, v3, v4],
    );

    expect(updated.variants.length, 4);
    expect(updated.variants[0].label, '100 ML');
    expect(updated.variants[0].displayRate, 200);
    expect(updated.variants[1].label, '250 ML');
    expect(updated.variants[2].label, '500 ML');
    expect(updated.variants[3].label, '1 L');
    expect(updated.variants[3].displayRate, 1500);
  });
}
