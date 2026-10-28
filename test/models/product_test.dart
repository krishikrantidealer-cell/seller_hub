import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/data/models/api/product_response_dto.dart';

void main() {
  group('Product API Integration Tests with Real Backend Payload', () {
    final Map<String, dynamic> sampleBackendResponse = {
      "success": true,
      "message": "Products retrieved successfully",
      "data": {
        "content": [
          {
            "id": "6ad871a31df71c7f599dd954",
            "sellerId": "6ab4ada822033f1670582bda",
            "sku": "KKR - 35",
            "productCode": "PRD-6AB4ADA822033F1670582BDA-000035",
            "hsnCode": "3808",
            "title": "Beauveria Bassiana - Bio Pesticide",
            "technicalName": null,
            "vendor": "Essential Bio Crop Science",
            "description":
                "<p><strong>Beauveria Bassiana Bio Pesticide</strong> is an entomopathogenic fungus-based biological insecticide that naturally infects and controls a broad spectrum of insect pests through contact action.</p>",
            "images": [],
            "productImages": [
              {
                "id": "0ee2dd28-634a-4e79-957e-e548d07a6b5f",
                "displayOrder": 0,
                "midUrl":
                    "https://storage.googleapis.com/sellerhub-prod-media-us/Sellers/6ab4ada822033f1670582bda/products/6ad871a31df71c7f599dd954/mid/0ee2dd28.jpg",
                "lowUrl":
                    "https://storage.googleapis.com/sellerhub-prod-media-us/Sellers/6ab4ada822033f1670582bda/products/6ad871a31df71c7f599dd954/low/0ee2dd28.jpg"
              }
            ],
            "technicalContent": null,
            "features": [],
            "benefits": [],
            "modeOfAction": null,
            "suitableCrops": [],
            "targetPests": [],
            "targetDiseases": [],
            "dosage": null,
            "applicationMethod": null,
            "categoryId": "6ad8582568a1edff7a609fee",
            "assignedCollections": ["6ad9ba15fa32055b18fcb29c"],
            "dimensions": null,
            "isAvailable": true,
            "isFeatured": false,
            "variants": [
              {
                "id": "d4642c25c62d3220a533aa5d",
                "label": "1 ltr (1000ml x 1)",
                "unit": "ml",
                "packSize": 1000,
                "packSizeUnit": "ml",
                "packQuantity": 1,
                "packUnit": null,
                "shippedBy": "essentialbiocropscience",
                "swg": null,
                "totalBaseQuantity": 1000,
                "totalBaseUnit": "ml",
                "dimensions": null,
                "displayRate": 510.0,
                "printedMrp": 1200.0,
                "discountRs": 0.0,
                "gstPercentage": 5.0,
                "discountPercentage": 0.0,
                "stock": 100,
                "pricePerBaseUnit": 0.51,
                "displayOrder": 1,
                "isDefault": true
              },
              {
                "id": "0323f60256fa35dc455d3c30",
                "label": "3 ltr (1000ml x 3)",
                "unit": "ml",
                "packSize": 1000,
                "packSizeUnit": "ml",
                "packQuantity": 3,
                "packUnit": null,
                "shippedBy": "essentialbiocropscience",
                "swg": null,
                "totalBaseQuantity": 3000,
                "totalBaseUnit": "ml",
                "dimensions": null,
                "displayRate": 1210.0,
                "printedMrp": 3600.0,
                "discountRs": 0.0,
                "gstPercentage": 5.0,
                "discountPercentage": 0.0,
                "stock": 100,
                "pricePerBaseUnit": 0.4033,
                "displayOrder": 2,
                "isDefault": false
              }
            ],
            "averageRating": null,
            "totalReviews": 0,
            "refundPolicy": null,
            "productWeight": null,
            "productWeightUnit": null
          }
        ]
      }
    };

    test('ProductResponseDto correctly parses the new response wrapper', () {
      final dto = ProductResponseDto.fromJson(sampleBackendResponse);
      expect(dto.success, isTrue);
      expect(dto.message, 'Products retrieved successfully');
      expect(dto.data, isNotNull);
      expect(dto.data!.content.length, 1);
      expect(dto.data!.totalElements, 1);
    });

    test('Product.fromJson parses all fields and falls back gracefully', () {
      final productMap = (sampleBackendResponse['data'] as Map<String, dynamic>)['content'][0] as Map<String, dynamic>;
      final product = Product.fromJson(productMap);

      expect(product.id, '6ad871a31df71c7f599dd954');
      expect(product.sellerId, '6ab4ada822033f1670582bda');
      expect(product.sku, 'KKR - 35');
      expect(product.productCode, 'PRD-6AB4ADA822033F1670582BDA-000035');
      expect(product.hsnCode, '3808');
      expect(product.title, 'Beauveria Bassiana - Bio Pesticide');
      expect(product.vendor, 'Essential Bio Crop Science');
      expect(product.categoryId, '6ad8582568a1edff7a609fee');
      expect(product.assignedCollections, ['6ad9ba15fa32055b18fcb29c']);
      expect(product.collectionIds, ['6ad9ba15fa32055b18fcb29c']);

      // Null safety tests
      expect(product.technicalName, '');
      expect(product.technicalContent, '');
      expect(product.dosage, '');
      expect(product.applicationMethod, '');
      expect(product.ratings, 0.0);
      expect(product.averageRating, 0.0);
      expect(product.totalReviews, 0);

      // Images parsing: images was [], but productImages has 1 image
      expect(product.productImages.length, 1);
      expect(product.images.length, 1);
      expect(product.primaryImageUrl, contains('0ee2dd28.jpg'));
      expect(product.thumbnailUrl, contains('0ee2dd28.jpg'));
      expect(product.image, contains('0ee2dd28.jpg'));

      // Variants resolution
      expect(product.variants.length, 2);
      expect(product.hasMultipleVariants, isTrue);
      expect(product.defaultVariant, isNotNull);
      expect(product.defaultVariant!.id, 'd4642c25c62d3220a533aa5d');
      expect(product.displayRate, 510.0);
      expect(product.printedMrp, 1200.0);
      expect(product.stock, 100);
      expect(product.packSize, '1000');
      expect(product.unit, 'ml');
      expect(product.variant, '1 ltr (1000ml x 1)');

      // Discount auto-calculation when backend sends 0.0
      expect(product.discountRs, 690.0); // 1200 - 510
      expect(product.discountPercentage, closeTo(57.5, 0.1)); // (690 / 1200) * 100
    });

    test('Product.toAdminCreatePayload generates exact payload for POST /api/v1/admin/products', () {
      final product = Product(
        sellerId: '6ab4ada822033f1670582bda',
        sku: 'EBS-ADM-SKU-1793010415573',
        productCode: 'PRD-6AB4ADA822033F1670582BDA-000074',
        hsnCode: '3808',
        title: 'Postman Admin Test Product 1793010415573',
        technicalName: 'Bio Organic Nutrient Formulation',
        vendor: 'EBS Agro Sciences',
        description: 'High grade bio solution for organic farming.',
        images: const [],
        categoryId: '6ab4f6f619ec643fd9bf3621',
        category: 'Bio Organic Nutrients',
        productWeight: 500,
        productWeightUnit: 'g',
        productDimensions: const ProductDimensions(
          length: 20,
          width: 10,
          height: 10,
          unit: 'cm',
        ),
        variants: const [
          ProductVariant(
            label: '500 ml Bottle',
            unit: 'ml',
            packSize: 500,
            packSizeUnit: 'ml',
            packQuantity: 1,
            packUnit: 'bottle',
            shippedBy: 'EBS Direct',
            displayRate: 450,
            printedMrp: 500,
            costPrice: 250,
            discountRs: 50,
            gstPercentage: 5,
            discountPercentage: 10,
            stock: 100,
          ),
        ],
        isAvailable: false,
        ratings: 0,
        refundPolicy: '',
      );

      final payload = product.toAdminCreatePayload();

      expect(payload['sellerId'], '6ab4ada822033f1670582bda');
      expect(payload['sku'], 'EBS-ADM-SKU-1793010415573');
      expect(payload['hsnCode'], '3808');
      expect(payload['title'], 'Postman Admin Test Product 1793010415573');
      expect(payload['technicalName'], 'Bio Organic Nutrient Formulation');
      expect(payload['vendor'], 'EBS Agro Sciences');
      expect(payload['description'], 'High grade bio solution for organic farming.');
      expect(payload['categoryId'], '6ab4f6f619ec643fd9bf3621');
      expect(payload['productWeight'], 500.0);
      expect(payload['productWeightUnit'], 'g');
      expect(payload['dimensions'], {
        'length': 20.0,
        'width': 10.0,
        'height': 10.0,
        'unit': 'cm',
      });
      expect(payload['variants'], isA<List>());
      final variant = (payload['variants'] as List).first as Map<String, dynamic>;
      expect(variant['label'], '500 ml Bottle');
      expect(variant['unit'], 'ml');
      expect(variant['packSize'], 500);
      expect(variant['packSizeUnit'], 'ml');
      expect(variant['packQuantity'], 1);
      expect(variant['packUnit'], 'bottle');
      expect(variant['shippedBy'], 'EBS Direct');
      expect(variant['displayRate'], 450.0);
      expect(variant['printedMrp'], 500.0);
      expect(variant['costPrice'], 250.0);
      expect(variant['discountRs'], 50.0);
      expect(variant['gstPercentage'], 5.0);
      expect(variant['discountPercentage'], 10.0);
      expect(variant['stock'], 100);
    });

    test('Product.fromJson parses the POST /api/v1/admin/products response exactly', () {
      final Map<String, dynamic> createProductResponse = {
        "success": true,
        "message": "Product created",
        "data": {
          "id": "6ae19cfb680b613f9bb25dd2",
          "sku": "EBS-ADM-SKU-1793010415573",
          "productCode": "PRD-6AB4ADA822033F1670582BDA-000074",
          "hsnCode": "3808",
          "sellerId": "6ab4ada822033f1670582bda",
          "title": "Postman Admin Test Product 1793010415573",
          "technicalName": "Bio Organic Nutrient Formulation",
          "vendor": "EBS Agro Sciences",
          "description": "High grade bio solution for organic farming.",
          "images": [],
          "technicalContent": null,
          "features": [],
          "benefits": [],
          "modeOfAction": null,
          "suitableCrops": [],
          "targetPests": [],
          "targetDiseases": [],
          "dosage": null,
          "applicationMethod": null,
          "categoryId": "6ab4f6f619ec643fd9bf3621",
          "assignedCollections": [],
          "dimensions": {
            "length": 20.0,
            "width": 10.0,
            "height": 10.0,
            "unit": "cm"
          },
          "isAvailable": false,
          "isFeatured": false,
          "variants": [
            {
              "id": "6ae19cfa680b613f9bb25dd1",
              "label": "500 ml Bottle",
              "unit": "ml",
              "packSize": 500,
              "packSizeUnit": "ml",
              "packQuantity": 1,
              "packUnit": "bottle",
              "shippedBy": "EBS Direct",
              "swg": null,
              "totalBaseQuantity": 500,
              "totalBaseUnit": "ml",
              "dimensions": null,
              "displayRate": 450.0,
              "printedMrp": 500.0,
              "costPrice": 250.0,
              "discountRs": 50.0,
              "gstPercentage": 5.0,
              "discountPercentage": 10.0,
              "stock": 100,
              "pricePerBaseUnit": 0.9,
              "displayOrder": null,
              "isDefault": false
            }
          ],
          "averageRating": null,
          "totalReviews": 0,
          "refundPolicy": null,
          "productWeight": 500.0,
          "productWeightUnit": "g",
          "status": "INACTIVE",
          "isDeleted": false,
          "deletedAt": null,
          "createdAt": "2026-10-28T06:58:02.819376801",
          "updatedAt": "2026-10-28T06:58:02.819376801"
        },
        "timestamp": "2026-10-28T06:58:04.113234418"
      };

      final product = Product.fromJson(createProductResponse['data'] as Map<String, dynamic>);

      expect(product.id, '6ae19cfb680b613f9bb25dd2');
      expect(product.sku, 'EBS-ADM-SKU-1793010415573');
      expect(product.productCode, 'PRD-6AB4ADA822033F1670582BDA-000074');
      expect(product.sellerId, '6ab4ada822033f1670582bda');
      expect(product.title, 'Postman Admin Test Product 1793010415573');
      expect(product.technicalName, 'Bio Organic Nutrient Formulation');
      expect(product.categoryId, '6ab4f6f619ec643fd9bf3621');
      expect(product.productWeight, 500.0);
      expect(product.productWeightUnit, 'g');
      expect(product.status, 'INACTIVE');
      expect(product.isDeleted, isFalse);
      expect(product.deletedAt, isNull);
      expect(product.isAvailable, isFalse);
      expect(product.productDimensions.length, 20.0);
      expect(product.productDimensions.width, 10.0);
      expect(product.productDimensions.height, 10.0);
      expect(product.productDimensions.unit, 'cm');

      // Variants
      expect(product.variants.length, 1);
      final v = product.defaultVariant!;
      expect(v.id, '6ae19cfa680b613f9bb25dd1');
      expect(v.label, '500 ml Bottle');
      expect(v.unit, 'ml');
      expect(v.packSize, 500);
      expect(v.packQuantity, 1);
      expect(v.displayRate, 450.0);
      expect(v.printedMrp, 500.0);
      expect(v.costPrice, 250.0);
      expect(v.discountRs, 50.0);
      expect(v.gstPercentage, 5.0);
      expect(v.discountPercentage, 10.0);
      expect(v.stock, 100);
      expect(v.pricePerBaseUnit, 0.9);
      expect(product.displayRate, 450.0);
      expect(product.printedMrp, 500.0);
      expect(product.stock, 100);
    });
  });
}
