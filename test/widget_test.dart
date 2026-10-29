import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seller_hub/main.dart';
import 'package:seller_hub/core/di/injection_container.dart';
import 'package:seller_hub/core/router/app_router.dart';
import 'package:seller_hub/core/router/route_names.dart';
import 'package:seller_hub/presentation/auth/views/login_view.dart';
import 'package:seller_hub/presentation/dashboard/views/dashboard_view.dart';
import 'package:seller_hub/presentation/dashboard/views/collections_view.dart';
import 'package:seller_hub/presentation/dashboard/widgets/product_hover_preview_thumbnail.dart';
import 'package:seller_hub/presentation/dashboard/widgets/app_html_view.dart';

void main() {
  final mockHttpClient = MockClient((request) async {
    if (request.url.path == '/api/v1/auth/password/login') {
      return http.Response(
        jsonEncode({
          "success": true,
          "message": "Authentication successful",
          "data": {
            "accessToken": "eyJhbGciOiJIUzM4NCJ9.test_access_token",
            "refreshToken": "eyJhbGciOiJIUzM4NCJ9.test_refresh_token",
            "tokenType": "Bearer",
            "expiresInMs": 86400000,
            "userId": "6ab4ae6922033f1670582bdb",
            "phoneNumber": "9876543668",
            "role": "ROLE_ADMIN",
            "isProfileComplete": true
          },
          "timestamp": "2026-10-23T09:49:31.843224715"
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (request.url.path == '/api/v1/products') {
      final page = int.tryParse(request.url.queryParameters['page'] ?? '0') ?? 0;
      final size = int.tryParse(request.url.queryParameters['size'] ?? '20') ?? 20;

      final allProducts = [
        {
          "id": "6ad871a31df71c7f599dd954",
          "sku": "KKR - 35",
          "productCode": "PRD-6AB4ADA822033F1670582BDA-000035",
          "hsnCode": "3808",
          "title": "Beauveria Bassiana - Bio Pesticide",
          "technicalName": "Beauveria bassiana",
          "vendor": "Essential Bio Crop Science",
          "description": "<p>Beauveria Bassiana Bio Pesticide</p>",
          "images": [],
          "productImages": [
            {
              "id": "0ee2dd28-634a-4e79-957e-e548d07a6b5f",
              "displayOrder": 0,
              "midUrl": "https://storage.googleapis.com/test-img1.jpg",
              "lowUrl": "https://storage.googleapis.com/test-img1-low.jpg"
            }
          ],
          "technicalContent": "5x10^8 CFU/ml",
          "features": ["Biological insecticide"],
          "benefits": ["Controls whiteflies"],
          "modeOfAction": "Contact action",
          "dosage": "2 ml/L",
          "applicationMethod": "Foliar spray",
          "category": "Bio Pesticide",
          "categoryId": "6ad8582568a1edff7a609fee",
          "isAvailable": true,
          "isFeatured": true,
          "variants": [
            {
              "id": "d4642c25c62d3220a533aa5d",
              "label": "1 ltr (1000ml x 1)",
              "unit": "ml",
              "packSize": 1000,
              "packSizeUnit": "ml",
              "packQuantity": 1,
              "shippedBy": "essentialbiocropscience",
              "totalBaseQuantity": 1000,
              "totalBaseUnit": "ml",
              "displayRate": 510.0,
              "printedMrp": 1200.0,
              "discountRs": 690.0,
              "gstPercentage": 5.0,
              "discountPercentage": 57.5,
              "stock": 100,
              "pricePerBaseUnit": 0.51,
              "displayOrder": 1,
              "isDefault": true
            }
          ]
        },
        {
          "id": "6ad871a41df71c7f599dd973",
          "sku": "KKR - 66",
          "productCode": "PRD-6AB4ADA822033F1670582BDA-000066",
          "hsnCode": "3808",
          "title": "Black Scorpion insecticide - Lambda Cyhalothrin 4.9% CS",
          "technicalName": "Lambda Cyhalothrin 4.9% CS",
          "vendor": "Essential Bio Crop Science",
          "description": "<p>Black Scorpion Insecticide</p>",
          "images": [],
          "productImages": [],
          "technicalContent": "Lambda Cyhalothrin 4.9% CS",
          "features": ["Fast knockdown"],
          "benefits": ["Long residual control"],
          "modeOfAction": "Nerve axon sodium channel modulator",
          "dosage": "1.5 ml/L",
          "applicationMethod": "Foliar spray",
          "category": "Insecticides",
          "categoryId": "6ad8582568a1edff7a609fee",
          "isAvailable": true,
          "isFeatured": true,
          "variants": [
            {
              "id": "v2",
              "label": "500 ml",
              "unit": "ml",
              "packSize": 500,
              "packSizeUnit": "ml",
              "packQuantity": 1,
              "shippedBy": "essentialbiocropscience",
              "totalBaseQuantity": 500,
              "totalBaseUnit": "ml",
              "displayRate": 480.0,
              "printedMrp": 950.0,
              "discountRs": 470.0,
              "gstPercentage": 18.0,
              "discountPercentage": 49.5,
              "stock": 80,
              "pricePerBaseUnit": 0.96,
              "displayOrder": 1,
              "isDefault": true
            }
          ]
        },
        {
          "id": "6ad871a51df71c7f599dd984",
          "sku": "KKR - 77",
          "productCode": "PRD-6AB4ADA822033F1670582BDA-000077",
          "hsnCode": "3102",
          "title": "AgriBegri NitroKing - Concentrated Nitrogen Bio-Liquid 20%",
          "technicalName": "Organic Liquid Nitrogen 20% SL",
          "vendor": "AgriBegri Crop Science",
          "description": "<p>High-efficiency liquid organic nitrogen</p>",
          "images": [],
          "productImages": [],
          "technicalContent": "Total Organic Nitrogen (N): 20.0%",
          "features": ["100% bio-available nitrogen"],
          "benefits": ["Accelerates tillering"],
          "modeOfAction": "Systemic foliar absorption",
          "dosage": "2.5 ml/L",
          "applicationMethod": "Foliar or drip",
          "category": "Fertilizers",
          "categoryId": "6ad8582568a1edff7a609fee",
          "isAvailable": true,
          "isFeatured": true,
          "variants": [
            {
              "id": "v3",
              "label": "1 Litre",
              "unit": "ml",
              "packSize": 1000,
              "packSizeUnit": "ml",
              "packQuantity": 1,
              "shippedBy": "AgriBegri Express",
              "totalBaseQuantity": 1000,
              "totalBaseUnit": "ml",
              "displayRate": 420.0,
              "printedMrp": 599.0,
              "discountRs": 179.0,
              "gstPercentage": 5.0,
              "discountPercentage": 29.8,
              "stock": 240,
              "pricePerBaseUnit": 0.42,
              "displayOrder": 1,
              "isDefault": true
            }
          ]
        },
        {
          "id": "6ad871a61df71c7f599dd995",
          "sku": "KKR - 88",
          "productCode": "PRD-6AB4ADA822033F1670582BDA-000088",
          "hsnCode": "3808",
          "title": "BioShield Neem Gold 10,000 PPM Azadirachtin EC",
          "technicalName": "Azadirachtin 1.0% EC",
          "vendor": "Krishi Kranti Organics",
          "description": "<p>Cold-pressed pure neem kernel extract</p>",
          "images": [],
          "productImages": [],
          "technicalContent": "Azadirachtin 10000 PPM",
          "features": ["Certified organic"],
          "benefits": ["Controls sucking pests"],
          "modeOfAction": "Antifeedant and insect growth regulator",
          "dosage": "2 ml/L",
          "applicationMethod": "Foliar spray",
          "category": "Insecticides",
          "categoryId": "6ad8582568a1edff7a609fee",
          "isAvailable": true,
          "isFeatured": true,
          "variants": [
            {
              "id": "v4",
              "label": "500 ml",
              "unit": "ml",
              "packSize": 500,
              "packSizeUnit": "ml",
              "packQuantity": 1,
              "shippedBy": "Seller Standard",
              "totalBaseQuantity": 500,
              "totalBaseUnit": "ml",
              "displayRate": 580.0,
              "printedMrp": 750.0,
              "discountRs": 170.0,
              "gstPercentage": 18.0,
              "discountPercentage": 22.6,
              "stock": 45,
              "pricePerBaseUnit": 1.16,
              "displayOrder": 1,
              "isDefault": true
            }
          ]
        },
        {
          "id": "6ad871a71df71c7f599dd906",
          "sku": "KKR - 99",
          "productCode": "PRD-6AB4ADA822033F1670582BDA-000099",
          "hsnCode": "3105",
          "title": "Agribegri PhosphoMax - Water Soluble NPK 00:52:34",
          "technicalName": "Mono Potassium Phosphate",
          "vendor": "AgriBegri Crop Science",
          "description": "<p>Premium imported mono-potassium phosphate</p>",
          "images": [],
          "productImages": [],
          "technicalContent": "Water Soluble Phosphate (P2O5): 52%",
          "features": ["100% water soluble"],
          "benefits": ["Promotes vigorous root development"],
          "modeOfAction": "Osmotic uptake",
          "dosage": "5 g/L",
          "applicationMethod": "Drip or foliar",
          "category": "Fertilizers",
          "categoryId": "6ad8582568a1edff7a609fee",
          "isAvailable": true,
          "isFeatured": false,
          "variants": [
            {
              "id": "v5",
              "label": "1 kg Pouch",
              "unit": "kg",
              "packSize": 1,
              "packSizeUnit": "kg",
              "packQuantity": 1,
              "shippedBy": "AgriBegri Express",
              "totalBaseQuantity": 1,
              "totalBaseUnit": "kg",
              "displayRate": 235.0,
              "printedMrp": 310.0,
              "discountRs": 75.0,
              "gstPercentage": 5.0,
              "discountPercentage": 24.1,
              "stock": 180,
              "pricePerBaseUnit": 235.0,
              "displayOrder": 1,
              "isDefault": true
            }
          ]
        },
        {
          "id": "6ad871a81df71c7f599dd917",
          "sku": "KKR - 02",
          "productCode": "PRD-6AB4ADA822033F1670582BDA-000002",
          "hsnCode": "3104",
          "title": "Potassium Schoenite Fertilizer 23% K2O + 11% MgO",
          "technicalName": "Potassium Magnesium Sulphate",
          "vendor": "Essential Bio Crop Science",
          "description": "<p>Natural mineral based double sulphate fertilizer</p>",
          "images": [],
          "productImages": [],
          "technicalContent": "Potash: 23%, Magnesium: 11%, Sulphur: 16%",
          "features": ["Chlorine-free"],
          "benefits": ["Improves crop quality"],
          "modeOfAction": "Root assimilation",
          "dosage": "10 g/L",
          "applicationMethod": "Soil or foliar",
          "category": "Fertilizers",
          "categoryId": "6ad8582568a1edff7a609fee",
          "isAvailable": true,
          "isFeatured": false,
          "variants": [
            {
              "id": "v6",
              "label": "1 kg Pouch",
              "unit": "kg",
              "packSize": 1,
              "packSizeUnit": "kg",
              "packQuantity": 1,
              "shippedBy": "Platform Express Hub",
              "totalBaseQuantity": 1,
              "totalBaseUnit": "kg",
              "displayRate": 360.0,
              "printedMrp": 499.0,
              "discountRs": 139.0,
              "gstPercentage": 12.0,
              "discountPercentage": 27.9,
              "stock": 350,
              "pricePerBaseUnit": 360.0,
              "displayOrder": 1,
              "isDefault": true
            }
          ]
        }
      ];

      final startIndex = page * size;
      final endIndex = startIndex + size > allProducts.length ? allProducts.length : startIndex + size;
      final paginated = startIndex < allProducts.length ? allProducts.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

      return http.Response(
        jsonEncode({
          "success": true,
          "message": "Products retrieved successfully",
          "data": {
            "content": paginated,
            "page": page,
            "size": size,
            "totalElements": allProducts.length,
            "totalPages": (allProducts.length / size).ceil(),
            "first": page == 0,
            "last": endIndex >= allProducts.length,
            "count": paginated.length,
          },
          "timestamp": "2026-10-23T10:39:17.659095962"
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (request.url.path == '/api/v1/collections') {
      return http.Response(
        jsonEncode({
          "success": true,
          "message": "Collections retrieved",
          "data": {
            "count": 5,
            "items": [
              {
                "id": "6ad9b313fa32055b18fcb292",
                "name": "Shop By Crop",
                "slug": "shop-by-crop",
                "description": "Shop accordingly to crop",
                "isActive": true,
                "priority": 0,
                "subCollections": [
                  {
                    "id": "6ad9b313fa32055b18fcb290",
                    "name": "Rice",
                    "slug": "rice",
                    "isActive": true,
                    "image": "https://example.com/rice.webp",
                    "productCount": 1
                  },
                  {
                    "id": "6ad9b313fa32055b18fcb291",
                    "name": "Maize",
                    "slug": "maize",
                    "isActive": true,
                    "image": "https://example.com/maize.webp",
                    "productCount": 0
                  }
                ],
                "subCollectionCount": 2,
                "createdAt": "2026-10-22T06:54:11.346Z",
                "updatedAt": "2026-10-22T06:54:11.346Z",
                "productCount": 1,
                "bannerTitle": "Shop By Crop"
              },
              {
                "id": "6ad9ba15fa32055b18fcb29c",
                "name": "Shop By Disease & Pest",
                "slug": "shop-by-disease-pest",
                "description": "Browse products by the pests and diseases they target.",
                "isActive": true,
                "priority": 1,
                "subCollections": [
                  {
                    "id": "6ad9ba15fa32055b18fcb293",
                    "name": "Aphids",
                    "slug": "aphids",
                    "isActive": true,
                    "image": null,
                    "productCount": 0
                  }
                ],
                "subCollectionCount": 1,
                "createdAt": "2026-10-22T07:24:05.652Z",
                "updatedAt": "2026-10-22T07:24:05.652Z",
                "productCount": 0,
                "bannerTitle": null
              },
              {
                "id": "6ad9bab2fa32055b18fcb29d",
                "name": "Best Sellers",
                "slug": "best-sellers",
                "description": "Selected products.",
                "isActive": true,
                "priority": 2,
                "subCollections": [],
                "subCollectionCount": 0,
                "createdAt": "2026-10-22T07:26:42.990Z",
                "updatedAt": "2026-10-22T07:26:42.990Z",
                "productCount": 0,
                "bannerTitle": null
              }
            ]
          },
          "timestamp": "2026-10-24T05:26:03.205261204"
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (request.url.path == '/api/v1/admin/collections' && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          "success": true,
          "message": "Collection created",
          "data": {
            "id": "6adc44120338b30717b3debc",
            "name": body["name"] ?? "New Arrivalss",
            "slug": body["slug"] ?? "new-arrivalss",
            "description": body["description"] ?? "Recently added products selected for display.",
            "isActive": body["isActive"] ?? true,
            "priority": body["priority"] ?? 4,
            "subCollections": body["subCollections"] ?? [],
            "subCollectionCount": (body["subCollections"] as List?)?.length ?? 0,
            "createdAt": "2026-10-24T05:37:22.817028994Z",
            "updatedAt": "2026-10-24T05:37:22.817028994Z",
            "productCount": 0,
            "bannerTitle": body["bannerTitle"]
          },
          "timestamp": "2026-10-24T05:37:23.831649844"
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (request.url.path.startsWith('/api/v1/admin/collections/') && request.method == 'PUT') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final id = request.url.pathSegments.last;
      return http.Response(
        jsonEncode({
          "id": id,
          "name": body["name"] ?? "Shop By Crops",
          "slug": body["slug"] ?? "shop-by-crops",
          "description": body["description"] ?? "Shop accordingly to crop",
          "isActive": body["isActive"] ?? true,
          "priority": body["priority"] ?? 0,
          "subCollections": body["subCollections"] ?? [],
          "subCollectionCount": (body["subCollections"] as List?)?.length ?? 0,
          "createdAt": body["createdAt"] ?? "2026-10-22T06:54:11.346Z",
          "updatedAt": DateTime.now().toUtc().toIso8601String(),
          "productCount": body["productCount"] ?? 1,
          "bannerTitle": body["bannerTitle"]
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (request.url.path.startsWith('/api/v1/admin/collections/') && request.method == 'DELETE') {
      final id = request.url.pathSegments.last;
      return http.Response(
        jsonEncode({
          "success": true,
          "message": "Collection deactivated",
          "data": {
            "id": id,
            "name": "Shop By Crops",
            "slug": "shop-by-crops",
            "description": "Shop accordingly to crop",
            "isActive": false,
            "priority": 0,
            "subCollections": [
              {
                "id": "6ad9b313fa32055b18fcb290",
                "name": "Rice",
                "slug": "rice",
                "isActive": true,
                "image": "https://example.com/rice.webp",
                "productCount": 1
              },
              {
                "id": "6ad9b313fa32055b18fcb291",
                "name": "Maize",
                "slug": "maize",
                "isActive": true,
                "image": "https://example.com/maize.webp",
                "productCount": 0
              }
            ],
            "subCollectionCount": 2,
            "createdAt": "2026-10-22T06:54:11.346Z",
            "updatedAt": "2026-10-24T06:05:47.898263721Z",
            "productCount": 1,
            "bannerTitle": "Shop By Crop"
          },
          "timestamp": "2026-10-24T06:05:49.00084301"
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (request.url.path.contains('/api/v1/admin/products/') &&
        request.url.path.endsWith('/collections')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final collectionIds = List<String>.from(body['collectionIds'] ?? []);
      final subCollectionIds = List<String>.from(body['subCollectionIds'] ?? []);
      final combined = [...collectionIds, ...subCollectionIds];

      return http.Response(
        jsonEncode({
          "success": true,
          "message": "Product collections updated",
          "data": {
            "id": "6ad871a31df71c7f599dd954",
            "sku": "KKR - 35",
            "productCode": "PRD-6AB4ADA822033F1670582BDA-000035",
            "hsnCode": "3808",
            "sellerId": "6ab4ada822033f1670582bda",
            "title": "Beauveria Bassiana - Bio Pesticide",
            "technicalName": "Beauveria bassiana",
            "vendor": "Essential Bio Crop Science",
            "description": "<p>Beauveria Bassiana Bio Pesticide</p>",
            "images": [],
            "productImages": [],
            "technicalContent": "5x10^8 CFU/ml",
            "features": ["Biological insecticide"],
            "benefits": ["Controls whiteflies"],
            "modeOfAction": "Contact action",
            "dosage": "2 ml/L",
            "applicationMethod": "Foliar spray",
            "category": "Bio Pesticide",
            "categoryId": "6ad8582568a1edff7a609fee",
            "assignedCollections": combined,
            "isAvailable": true,
            "isFeatured": true,
            "variants": []
          },
          "timestamp": "2026-10-24T06:03:33.914384719"
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (request.url.path == '/api/v1/categories') {
      return http.Response(
        jsonEncode({
          "success": true,
          "message": "Categories retrieved successfully",
          "data": {
            "content": [
              {
                "id": "cat_crop_prot",
                "name": "Crop Protection",
                "slug": "crop-protection",
                "parentId": null,
                "level": 0,
                "sortOrder": 0,
                "isActive": true,
                "createdAt": "2026-09-24T10:09:58.331Z",
                "updatedAt": "2026-10-24T11:05:19.749Z"
              },
              {
                "id": "cat_bio_pest",
                "name": "Bio Pesticides",
                "slug": "bio-pesticides",
                "parentId": "cat_crop_prot",
                "level": 1,
                "sortOrder": 0,
                "isActive": true,
                "createdAt": "2026-10-21T10:01:51.906Z",
                "updatedAt": "2026-10-21T10:01:51.906Z"
              },
              {
                "id": "cat_bio_insect",
                "name": "Bio Insecticide",
                "slug": "bio-insecticide",
                "parentId": "cat_bio_pest",
                "level": 2,
                "sortOrder": 0,
                "isActive": true,
                "createdAt": "2026-10-21T10:01:51.917Z",
                "updatedAt": "2026-10-21T10:01:51.917Z"
              },
              {
                "id": "cat_seeds",
                "name": "Seeds",
                "slug": "seeds",
                "parentId": null,
                "level": 0,
                "sortOrder": 1,
                "displayOrder": 1,
                "iconUrl": "🌾",
                "isActive": true,
                "createdAt": "2026-09-30T06:11:11.258Z",
                "updatedAt": "2026-10-21T10:01:51.905Z"
              }
            ],
            "page": 0,
            "size": 100,
            "totalElements": 4,
            "totalPages": 1,
            "first": true,
            "last": true
          },
          "timestamp": "2026-10-27T06:03:50.306364353"
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (request.url.path == '/api/v1/admin/users') {
      final role = request.url.queryParameters['role'];
      if (role == 'SELLERS') {
        return http.Response(
          jsonEncode({
            "success": true,
            "message": "Admin users retrieved",
            "data": {
              "content": [
                {
                  "id": "6ab62c7f4aec9f42cea26a49",
                  "phoneNumber": "8776543244",
                  "email": "seller1email@example.com",
                  "firstName": "Vijay",
                  "lastName": "Pal",
                  "shopName": null,
                  "role": "ROLE_SELLER",
                  "address": {
                    "villageArea": "Test address",
                    "address2": "Postman test",
                    "cityTehsil": "Indore",
                    "state": "Madhya Pradesh",
                    "pincode": "452001"
                  },
                  "isVerified": true,
                  "isProfileComplete": true,
                  "kycStatus": null,
                  "isKycComplete": false,
                  "gstNumber": null,
                  "licenceImage": null,
                  "shopImage": null,
                  "shippingAddresses": [],
                  "isBlocked": false,
                  "isDeleted": false,
                  "createdAt": "2026-09-25T08:10:39.562",
                  "updatedAt": "2026-10-26T10:27:11.539"
                },
                {
                  "id": "6ab4ada822033f1670582bda",
                  "phoneNumber": "9876543288",
                  "email": "seller2email@example2.com",
                  "firstName": "Seller",
                  "lastName": "Sirname",
                  "shopName": null,
                  "role": "ROLE_SELLER",
                  "address": {
                    "villageArea": "Flat 402, Royal Palms",
                    "address2": "Opposite City Mall, MG Road",
                    "cityTehsil": "Indore",
                    "state": "Madhya Pradesh",
                    "pincode": "452001"
                  },
                  "isVerified": true,
                  "isProfileComplete": true,
                  "kycStatus": null,
                  "isKycComplete": false,
                  "gstNumber": null,
                  "licenceImage": null,
                  "shopImage": null,
                  "shippingAddresses": [],
                  "isBlocked": false,
                  "isDeleted": false,
                  "createdAt": "2026-09-24T04:57:12.063",
                  "updatedAt": "2026-10-24T07:59:43.219"
                },
                {
                  "id": "slr-krishi",
                  "phoneNumber": "9876543210",
                  "email": "contact@krishikranti.com",
                  "firstName": "Krishi Kranti",
                  "lastName": "Organics",
                  "shopName": "Krishi Kranti Organics",
                  "role": "ROLE_SELLER",
                  "address": {
                    "villageArea": "Krishi Kranti Bhawan, MIDC Area",
                    "address2": "",
                    "cityTehsil": "Nashik",
                    "state": "Maharashtra",
                    "pincode": "422007"
                  },
                  "isVerified": true,
                  "isProfileComplete": true,
                  "isBlocked": false,
                  "isDeleted": false
                },
                {
                  "id": "slr-bharat",
                  "phoneNumber": "9876543211",
                  "email": "info@bharatagro.com",
                  "firstName": "Bharat Agro",
                  "lastName": "Chemicals Ltd",
                  "shopName": "Bharat Agro Chemicals Ltd",
                  "role": "ROLE_SELLER",
                  "address": {
                    "villageArea": "Plot 88, GIDC Industrial Estate",
                    "address2": "",
                    "cityTehsil": "Ahmedabad",
                    "state": "Gujarat",
                    "pincode": "382445"
                  },
                  "isVerified": true,
                  "isProfileComplete": true,
                  "isBlocked": false,
                  "isDeleted": false
                }
              ],
              "page": 0,
              "size": 20,
              "totalElements": 1,
              "totalPages": 1,
              "first": true,
              "last": true
            },
            "timestamp": "2026-10-27T07:31:59.231575322"
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      } else {
        return http.Response(
          jsonEncode({
            "success": true,
            "message": "Admin users retrieved",
            "data": {
              "content": [
                {
                  "id": "6ab6248acf88a4428f9b1e26",
                  "phoneNumber": "9876543244",
                  "email": null,
                  "firstName": "Aashutosh",
                  "lastName": "Shrivastava",
                  "shopName": null,
                  "role": "ROLE_CUSTOMER",
                  "address": {
                    "villageArea": "Plot 42, Kisan Nagar",
                    "address2": "Near Krishi Mandi",
                    "cityTehsil": "Indore",
                    "state": "Madhya Pradesh",
                    "pincode": "452001"
                  },
                  "isVerified": true,
                  "isProfileComplete": true,
                  "kycStatus": null,
                  "isKycComplete": false,
                  "gstNumber": null,
                  "licenceImage": null,
                  "shopImage": null,
                  "shippingAddresses": [],
                  "isBlocked": false,
                  "isDeleted": false,
                  "createdAt": "2026-09-25T07:36:42.481",
                  "updatedAt": "2026-10-26T10:17:13.124"
                }
              ],
              "page": 0,
              "size": 20,
              "totalElements": 1,
              "totalPages": 1,
              "first": true,
              "last": true
            },
            "timestamp": "2026-10-27T07:33:58.288464551"
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
    }
    return http.Response('{"error": "Not found"}', 404);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    InjectionContainer.instance.reset();
    await InjectionContainer.instance.init(httpClient: mockHttpClient);
    AppRouter.router.go(RouteNames.login);
  });

  testWidgets('Seller Hub loads login screen with Password form', (WidgetTester tester) async {
    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text('Admin Sign In'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);

    // Password form fields & actions
    expect(find.text('Admin Email / Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In to Dashboard'), findsOneWidget);
  });

  testWidgets('Submitting valid login redirects to DashboardView with sidebar navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Enter login credentials
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pumpAndSettle();

    // Tap Sign In to Dashboard
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify redirected to Dashboard
    expect(find.byType(DashboardView), findsOneWidget);
    expect(find.text("Today's Orders"), findsOneWidget);
    expect(find.text('Gross Dispatch Value'), findsOneWidget);

    // Tap Catalog nav
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();

    expect(find.text('Agricultural Catalog & Master Inventory'), findsOneWidget);
    expect(find.text('Add Product'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    expect(find.byType(ProductHoverPreviewThumbnail), findsWidgets);

    // Tap product title to open full 38-field Product Details
    await tester.tap(find.text('Beauveria Bassiana - Bio Pesticide'));
    await tester.pumpAndSettle();

    // Verify Product Details View is displayed with agronomy and pricing
    expect(find.text('Pricing & Commercial Matrix'), findsOneWidget);
    expect(find.text('Agronomic Specifications & Field Efficacy'), findsOneWidget);

    // Tap breadcrumb back to return to catalog
    await tester.tap(find.text('Products Catalog'));
    await tester.pumpAndSettle();

    expect(find.text('Agricultural Catalog & Master Inventory'), findsOneWidget);
  });

  testWidgets('Tapping Edit from compact catalog opens Product Details in edit mode and allows saving updates', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Go to Products via Catalog
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();

    // Verify Edit buttons exist in compact catalog
    expect(find.byIcon(Icons.edit_outlined), findsWidgets);

    // Tap Edit on first product
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    // Verify in Edit Mode
    expect(find.text('EDIT MODE ACTIVE'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Cancel edit returns to view mode
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Product'), findsOneWidget);
    expect(find.text('EDIT MODE ACTIVE'), findsNothing);

    // Tap Edit Product button directly on details screen
    await tester.tap(find.text('Edit Product'));
    await tester.pumpAndSettle();

    expect(find.text('EDIT MODE ACTIVE'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('Products catalog supports proper pagination across pages and rows per page', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Go to Products via Catalog
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();

    // Verify pagination footer is visible with 6 authentic catalog products
    expect(find.textContaining('Showing 1 - 6 of 6 products'), findsOneWidget);
    expect(find.text('Rows per page:'), findsOneWidget);

    // Switch rows per page to 5
    await tester.tap(find.text('20').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Showing 1 - 5 of 6 products'), findsOneWidget);

    // Tap page 2
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Showing 6 - 6 of 6 products'), findsOneWidget);
  });

  testWidgets('Sellers navigation tab displays multi-tenant directory and opens Seller Profile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Tap Users nav in sidebar (defaults to Sellers sub-tab)
    await tester.tap(find.text('Users').first);
    await tester.pumpAndSettle();

    // Verify Sellers directory table loads
    expect(find.text('Onboard Seller'), findsNothing);
    expect(find.text('Krishi Kranti Organics'), findsWidgets);
    expect(find.text('Bharat Agro Chemicals Ltd'), findsWidgets);

    // Tap View Profile on the first seller
    await tester.tap(find.byIcon(Icons.visibility_rounded).first);
    await tester.pumpAndSettle();

    // Verify Seller Profile View opens
    expect(find.text('Back to Sellers Directory'), findsOneWidget);
    expect(find.text('Business & Legal'), findsOneWidget);
    expect(find.text('Bank & Settlement'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
  });

  testWidgets('Product catalog table supports multi-selection, bulk actions bar, and column sorting', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Go to Products via Catalog
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();

    // Verify sortable column headers are displayed
    expect(find.text('PRODUCT & COMPOSITION'), findsOneWidget);
    expect(find.text('SKU / HSN'), findsOneWidget);
    expect(find.text('SELLER / VENDOR'), findsOneWidget);
    expect(find.text('CATEGORY & PACK'), findsOneWidget);
    expect(find.text('PRICE / MRP'), findsOneWidget);
    expect(find.text('STOCK LEVEL'), findsOneWidget);
    expect(find.text('AVAILABILITY'), findsOneWidget);

    // Verify master Select-All checkbox is present and tap it
    final headerCheckbox = find.byType(Checkbox).first;
    await tester.tap(headerCheckbox);
    await tester.pumpAndSettle();

    // Verify Bulk Actions Bar appears with all 6 selected
    expect(find.text('6 products selected'), findsOneWidget);
    expect(find.text('Mark Active'), findsOneWidget);
    expect(find.text('Mark Hidden'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    // Tap Clear
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('6 products selected'), findsNothing);

    // Select only the first product checkbox (second checkbox on screen)
    final rowCheckbox = find.byType(Checkbox).at(1);
    await tester.tap(rowCheckbox);
    await tester.pumpAndSettle();

    expect(find.text('1 product selected'), findsOneWidget);

    // Tap Mark Hidden
    await tester.tap(find.text('Mark Hidden'));
    await tester.pumpAndSettle();

    // Sort by price by tapping header (1st tap: Ascending)
    await tester.tap(find.text('PRICE / MRP'));
    await tester.pumpAndSettle();

    // Verify sort reset pill appears
    expect(find.textContaining('Sorted by PRICE • Reset'), findsOneWidget);

    // 2nd tap: Descending
    await tester.tap(find.text('PRICE / MRP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sorted by PRICE • Reset'), findsOneWidget);

    // 3rd tap: Reset to natural order
    await tester.tap(find.text('PRICE / MRP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sorted by PRICE • Reset'), findsNothing);

    // Tap PRICE / MRP again, then reset using the pill button
    await tester.tap(find.text('PRICE / MRP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sorted by PRICE • Reset'), findsOneWidget);

    await tester.tap(find.textContaining('Sorted by PRICE • Reset'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sorted by PRICE • Reset'), findsNothing);

    // Verify catalog remains stable and responsive
    expect(find.text('Agricultural Catalog & Master Inventory'), findsOneWidget);

    // Test search bar by SKU and title
    final searchField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText?.startsWith('Search by SKU') == true,
    );
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Beauveria');
    await tester.pumpAndSettle();
    expect(find.text('Beauveria Bassiana - Bio Pesticide'), findsOneWidget);

    // Clear search using clear button
    final clearButton = find.byTooltip('Clear search');
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(find.text('Beauveria Bassiana - Bio Pesticide'), findsOneWidget);
  });

  testWidgets('Product Details View allows editing multi-variants, adding new SKUs, and displays original image', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Go to Products via Catalog
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();

    // Open first product details
    await tester.tap(find.text('Beauveria Bassiana - Bio Pesticide'));
    await tester.pumpAndSettle();

    // Verify variants card is present
    expect(find.textContaining('Packaging & Commercial Variants'), findsOneWidget);
    expect(find.text('Original Image'), findsOneWidget);
    expect(find.text('All Packaging SKUs Matrix'), findsOneWidget);
    expect(find.text('Edit Variants'), findsOneWidget);

    // Tap Edit Variants to activate editing mode
    final editVariantsFinder = find.text('Edit Variants');
    await tester.ensureVisible(editVariantsFinder);
    await tester.tap(editVariantsFinder);
    await tester.pumpAndSettle();

    // Verify Active Variant Editor is shown
    expect(find.textContaining('Editing SKU #1'), findsOneWidget);
    expect(find.text('Variant Label / Name *'), findsOneWidget);
    expect(find.text('Pack Quantity *'), findsOneWidget);
    expect(find.text('Add SKU'), findsWidgets);

    // Tap Add SKU
    final addSkuFinder = find.text('Add SKU').first;
    await tester.ensureVisible(addSkuFinder);
    await tester.tap(addSkuFinder);
    await tester.pumpAndSettle();

    // Verify a new SKU was added
    expect(find.textContaining('Editing SKU #2'), findsOneWidget);

    // Save changes
    final saveFinder = find.text('Save Changes');
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder);
    await tester.pumpAndSettle();

    // Verify view mode restored
    expect(find.text('EDIT MODE ACTIVE'), findsNothing);
  });

  testWidgets('AppHtmlView parses HTML descriptions and renders headings, paragraphs, and list items', (WidgetTester tester) async {
    const htmlSnippet = '<h2>Product Overview</h2><p><strong>Bio Pesticide</strong> works through contact action.</p><ul><li>Active: Beauveria</li><li>Formulation: Liquid</li></ul>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppHtmlView(
            htmlData: htmlSnippet,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppHtmlView), findsOneWidget);
    expect(find.byType(RichText), findsWidgets);

    // Verify rendered RichText spans contain the parsed HTML content
    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    final combinedPlainText = richTexts.map((r) => r.text.toPlainText()).join(' ');

    expect(combinedPlainText, contains('Product Overview'));
    expect(combinedPlainText, contains('Bio Pesticide'));
    expect(combinedPlainText, contains('works through contact action'));
    expect(combinedPlainText, contains('Beauveria'));
    expect(combinedPlainText, contains('Formulation: Liquid'));
  });

  testWidgets('AppHtmlView clamps to 4 lines and toggles more... and less...', (WidgetTester tester) async {
    const longHtml = '<h2>Overview</h2><p>Line 1 of detailed text.</p><p>Line 2 with more explanations.</p><p>Line 3 about crop protection.</p><p>Line 4 with application dosage.</p><p>Line 5 extra details.</p>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppHtmlView(
            htmlData: longHtml,
            collapsible: true,
            maxLines: 4,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial state shows "more..." button
    expect(find.text('more...'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

    // Tap "more..."
    await tester.tap(find.text('more...'));
    await tester.pumpAndSettle();

    // Verify expanded state shows "less..." button
    expect(find.text('less...'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

    // Tap "less..."
    await tester.tap(find.text('less...'));
    await tester.pumpAndSettle();

    // Verify collapsed back to "more..."
    expect(find.text('more...'), findsOneWidget);
  });

  testWidgets('Tapping Collections nav in sidebar loads CollectionsView, displays metrics, and allows expanding sub-collections', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in to Dashboard
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify redirected to DashboardView
    expect(find.byType(DashboardView), findsOneWidget);

    // Navigate to Catalog then switch to Collections tab
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collections'));
    await tester.pumpAndSettle();

    // Verify CollectionsView is displayed
    expect(find.byType(CollectionsView), findsOneWidget);
    expect(find.text('Storefront Collections & Taxonomy'), findsOneWidget);
    expect(find.text('Total Collections'), findsOneWidget);
    expect(find.text('Shop By Crop'), findsOneWidget);
    expect(find.text('Shop By Disease & Pest'), findsOneWidget);
    expect(find.text('Best Sellers'), findsOneWidget);

    // Initially sub-collections are collapsed
    expect(find.text('Rice'), findsNothing);

    // Tap "Shop By Crop" card header to expand its sub-collections
    await tester.tap(find.text('Shop By Crop'));
    await tester.pumpAndSettle();

    // Verify sub-collections "Rice" and "Maize" are rendered
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Maize'), findsOneWidget);
    expect(find.text('Mapped Sub-Collections & Category Taxonomy'), findsOneWidget);

    // Filter using search box
    final searchInput = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText?.startsWith('Search collections') == true,
    );
    expect(searchInput, findsOneWidget);
    await tester.enterText(searchInput, 'Disease');
    await tester.pumpAndSettle();

    // Verify filtered result
    expect(find.text('Shop By Disease & Pest'), findsOneWidget);
    expect(find.text('Shop By Crop'), findsNothing);
  });

  testWidgets('Creating a collection via CreateCollectionDialog integrates with POST /api/v1/admin/collections', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in to Dashboard
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Navigate to Catalog then switch to Collections tab
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collections'));
    await tester.pumpAndSettle();

    // Tap "Create Collection" button
    expect(find.text('Create Collection'), findsOneWidget);
    await tester.tap(find.text('Create Collection'));
    await tester.pumpAndSettle();

    // Verify Create Collection Dialog is open
    expect(find.text('Create New Collection'), findsOneWidget);
    expect(find.text('POST /api/v1/admin/collections'), findsOneWidget);

    // Fill in form fields
    // Find text fields inside the dialog
    final nameField = find.widgetWithText(TextFormField, 'e.g. New Arrivals');
    await tester.enterText(nameField, 'New Arrivals');
    await tester.pumpAndSettle();

    // Verify auto-generated slug
    expect(find.text('new-arrivals'), findsOneWidget);

    // Enter description
    final descField = find.widgetWithText(TextFormField, 'Recently added products selected for display.');
    await tester.enterText(descField, 'Recently added products selected for display.');
    await tester.pumpAndSettle();

    // Submit collection creation
    final submitButton = find.widgetWithText(ElevatedButton, 'Create Collection').last;
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify dialog is dismissed and collection appears in list
    expect(find.text('Create New Collection'), findsNothing);
    expect(find.text('New Arrivals'), findsWidgets);
  });

  testWidgets('Updating a collection via EditCollectionDialog integrates with PUT /api/v1/admin/collections/{id}', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in to Dashboard
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Navigate to Catalog then switch to Collections tab
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collections'));
    await tester.pumpAndSettle();

    // Verify initial "Shop By Crop" exists
    expect(find.text('Shop By Crop'), findsOneWidget);

    // Tap Edit button on "Shop By Crop"
    final editButton = find.byTooltip('Edit Collection').first;
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // Verify Edit Collection Dialog opens with pre-populated data
    expect(find.text('Update Collection'), findsOneWidget);
    expect(find.text('PUT /api/v1/admin/collections/6ad9b313fa32055b18fcb292'), findsOneWidget);

    // Modify title to "Shop By Crops" and slug to "shop-by-crops"
    final nameField = find.widgetWithText(TextFormField, 'Shop By Crop').first;
    await tester.enterText(nameField, 'Shop By Crops');
    await tester.pumpAndSettle();

    final slugField = find.widgetWithText(TextFormField, 'shop-by-crop');
    await tester.enterText(slugField, 'shop-by-crops');
    await tester.pumpAndSettle();

    // Save changes
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Collection');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify dialog is dismissed and collection title is updated
    expect(find.text('Update Collection'), findsNothing);
    expect(find.text('Shop By Crops'), findsOneWidget);
    expect(find.text('/shop-by-crops'), findsOneWidget);
  });

  testWidgets('Assigning collections to a product via AssignCollectionsDialog integrates with /api/v1/admin/products/{productId}/collections', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in to Dashboard
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Tap Catalog nav in sidebar
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();

    // Tap first product title to open ProductDetailsView
    await tester.tap(find.text('Beauveria Bassiana - Bio Pesticide'));
    await tester.pumpAndSettle();

    // Verify Product Details View contains Storefront Collections Assignment section
    expect(find.text('Storefront Collections Assignment'), findsOneWidget);

    // Tap "Assign / Manage Collections"
    final assignButton = find.text('Assign / Manage Collections');
    expect(assignButton, findsOneWidget);
    await tester.ensureVisible(assignButton);
    await tester.tap(assignButton);
    await tester.pumpAndSettle();

    // Verify AssignCollectionsDialog opens with collection items
    expect(find.text('Assign Storefront Collections'), findsOneWidget);
    expect(find.text('Shop By Crop'), findsOneWidget);

    // Select "Shop By Crop" collection checkbox
    final cropCheckbox = find.widgetWithText(CheckboxListTile, 'Shop By Crop');
    expect(cropCheckbox, findsOneWidget);
    await tester.tap(cropCheckbox);
    await tester.pumpAndSettle();

    // Save collections assignment
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Collections Assignment');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify dialog is dismissed and assigned collections section displays the assigned badge
    expect(find.text('Assign Storefront Collections'), findsNothing);
    expect(find.text('#6ad9b313fa32055b18fcb292'), findsOneWidget);
  });

  testWidgets('Deactivating a collection via CollectionsView integrates with DELETE /api/v1/admin/collections/{collectionId}', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in to Dashboard
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Navigate to Catalog then switch to Collections tab
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collections'));
    await tester.pumpAndSettle();

    // Verify initial "Shop By Crop" exists and is Active
    expect(find.text('Shop By Crop'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);

    // Find and tap the Deactivate icon button for "Shop By Crop"
    final deactivateIconFinder = find.byIcon(Icons.power_settings_new_rounded).first;
    await tester.ensureVisible(deactivateIconFinder);
    await tester.tap(deactivateIconFinder);
    await tester.pumpAndSettle();

    // Verify confirmation dialog is displayed
    expect(find.text('Deactivate Collection'), findsOneWidget);
    expect(find.textContaining('Are you sure you want to deactivate'), findsOneWidget);
    expect(find.text('DELETE /api/v1/admin/collections/6ad9b313fa32055b18fcb292'), findsOneWidget);

    // Tap "Deactivate" button in dialog
    final confirmDeactivateBtn = find.widgetWithText(ElevatedButton, 'Deactivate');
    expect(confirmDeactivateBtn, findsOneWidget);
    await tester.tap(confirmDeactivateBtn);
    await tester.pumpAndSettle();

    // Verify confirmation dialog is dismissed and success snackbar or inactive state is displayed
    expect(find.text('Deactivate Collection'), findsNothing);
    expect(find.textContaining('deactivated successfully'), findsOneWidget);
  });

  testWidgets('Assigning products to a collection from CollectionsView opens AssignProductsToCollectionDialog and dispatches product assignment', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in to Dashboard
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Navigate to Catalog then switch to Collections tab
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collections'));
    await tester.pumpAndSettle();

    // Find and tap "Assign Products" icon on the first collection card
    final assignProductsBtn = find.byTooltip('Assign Products').first;
    await tester.ensureVisible(assignProductsBtn);
    await tester.tap(assignProductsBtn);
    await tester.pumpAndSettle();

    // Verify AssignProductsToCollectionDialog is opened
    expect(find.text('Assign Products to Collection'), findsOneWidget);
    expect(find.text('Save Product Assignments'), findsOneWidget);

    // Tap "Save Product Assignments"
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Product Assignments');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify dialog is closed
    expect(find.text('Assign Products to Collection'), findsNothing);
  });

  testWidgets('AssignProductsView renders as a dedicated screen with multi-criteria filters, search, and navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in to Dashboard
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Navigate to Catalog then switch to Collections tab
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collections'));
    await tester.pumpAndSettle();

    // Open Assign Products View
    final assignProductsBtn = find.byTooltip('Assign Products').first;
    await tester.ensureVisible(assignProductsBtn);
    await tester.tap(assignProductsBtn);
    await tester.pumpAndSettle();

    // 1. Verify Screen Header & Navigation
    expect(find.text('Assign Products to Collection'), findsOneWidget);
    expect(find.byTooltip('Back to Collections'), findsOneWidget);
    expect(find.text('Save Product Assignments'), findsOneWidget);

    // 2. Verify Filters Toolbar Presence
    expect(find.widgetWithText(TextField, ''), findsWidgets);
    expect(find.text('All Categories'), findsOneWidget);
    expect(find.text('All Sellers'), findsOneWidget);
    expect(find.textContaining('All Products'), findsOneWidget);
    expect(find.text('All Stock'), findsOneWidget);

    // 3. Verify Selection Actions
    expect(find.textContaining('Select All Filtered'), findsOneWidget);
    expect(find.text('Deselect All'), findsOneWidget);

    // 4. Test Search Bar
    final searchInput = find.byType(TextField).first;
    await tester.enterText(searchInput, 'Rice');
    await tester.pumpAndSettle();

    // 5. Verify Back Button navigates back to Collections
    await tester.tap(find.byTooltip('Back to Collections'));
    await tester.pumpAndSettle();
    expect(find.text('Assign Products to Collection'), findsNothing);
    expect(find.text('Shop By Crop'), findsOneWidget);
  });

  testWidgets('Tapping Categories nav in sidebar loads CategoriesView with 3-tier hierarchy and metrics', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in to Dashboard
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Navigate to Catalog then switch to Categories tab
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    // 1. Verify Top App Bar Title
    expect(find.text('Product Categories Hierarchy'), findsOneWidget);

    // 2. Verify Metrics
    expect(find.text('Total Taxonomy Nodes'), findsOneWidget);
    expect(find.text('Major Roots (Level 0)'), findsOneWidget);
    expect(find.text('Sub-Categories (Level 1)'), findsOneWidget);
    expect(find.text('Leaf Nodes (Level 2)'), findsOneWidget);

    // 3. Verify Level Filters
    expect(find.text('All Levels (Tree View)'), findsOneWidget);
    expect(find.text('Level 0 (Major Roots)'), findsOneWidget);

    // 4. Verify Categories Tree loaded
    expect(find.text('Crop Protection'), findsOneWidget);
    expect(find.text('Seeds'), findsOneWidget);
  });

  testWidgets('Combined Catalog tab allows seamless switching between Products, Collections, and Categories via top segmented control and sidebar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in to Dashboard
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // 1. Verify Catalog item is present in sidebar
    expect(find.text('Catalog'), findsOneWidget);

    // 2. Tap Catalog item in sidebar -> navigates to Products
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle();

    expect(find.text('Product Catalog & Inventory'), findsOneWidget);
    expect(find.text('Agricultural Catalog & Master Inventory'), findsOneWidget);

    // 3. Verify Top Segmented Control in CatalogView
    // The segmented tabs allow switching directly within the view
    await tester.tap(find.text('Collections'));
    await tester.pumpAndSettle();

    // Verify CollectionsView is displayed
    expect(find.text('Storefront Collections'), findsOneWidget);
    expect(find.text('Total Collections'), findsOneWidget);

    // 4. Switch to Categories via top segmented control
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    // Verify CategoriesView is displayed
    expect(find.text('Product Categories Hierarchy'), findsOneWidget);
    expect(find.text('Total Taxonomy Nodes'), findsOneWidget);
    expect(find.text('Crop Protection'), findsOneWidget);

    // 5. Switch back to Products via top segmented control
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();

    // Verify ProductsCatalog is displayed again
    expect(find.text('Product Catalog & Inventory'), findsOneWidget);
  });

  testWidgets('Tapping Customers nav in sidebar loads CustomersView with live metrics, buyer records, and details dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Login
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Tap Users nav item in sidebar
    expect(find.text('Users'), findsOneWidget);
    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();

    // Tap Customers segmented tab in UsersView
    expect(find.text('Customers'), findsOneWidget);
    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();

    // Verify Customers top app bar
    expect(find.text('Customers & Buyer Directory'), findsOneWidget);

    // Verify Metrics
    expect(find.text('TOTAL CUSTOMERS'), findsOneWidget);
    expect(find.text('VERIFIED BUYERS'), findsOneWidget);

    // Verify Customer record from API
    expect(find.text('Aashutosh Shrivastava'), findsOneWidget);
    expect(find.text('9876543244'), findsOneWidget);
    expect(find.textContaining('Plot 42, Kisan Nagar'), findsOneWidget);

    // Tap Details icon button to open dedicated customer profile
    final detailsBtn = find.byTooltip('View details');
    expect(detailsBtn, findsOneWidget);
    await tester.tap(detailsBtn);
    await tester.pumpAndSettle();

    // Verify Customer Profile view opens just like Seller Profile
    expect(find.text('Customer Profile & Account Details'), findsOneWidget);
    expect(find.text('Back to Customers Directory'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('PERSONAL PROFILE'), findsOneWidget);
    expect(find.text('CONTACT DETAILS'), findsOneWidget);

    // Switch to Delivery Addresses tab
    await tester.tap(find.text('Delivery Addresses'));
    await tester.pumpAndSettle();
    expect(find.text('PRIMARY BILLING & DELIVERY ADDRESS'), findsOneWidget);
    expect(find.text('Indore'), findsWidgets);

    // Switch to KYC & Compliance tab
    await tester.tap(find.text('KYC & Compliance'));
    await tester.pumpAndSettle();
    expect(find.text('KYC & VERIFICATION STATUS'), findsOneWidget);

    // Switch to Orders History tab
    await tester.tap(find.text('Orders History'));
    await tester.pumpAndSettle();

    // Switch back to Personal tab and test Edit mode
    await tester.tap(find.text('Personal & Account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Save Profile'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Cancel edit
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);

    // Test Block Account action dialog
    await tester.tap(find.text('Block Account'));
    await tester.pumpAndSettle();
    expect(find.text('Block Customer Account?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Tap back to return to Customers Directory
    await tester.tap(find.text('Back to Customers Directory'));
    await tester.pumpAndSettle();

    expect(find.text('Customers & Buyer Directory'), findsOneWidget);
  });

  testWidgets('Combined Users tab allows seamless switching between Sellers and Customers via top segmented control and sidebar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Login
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Tap Users item in sidebar -> navigates to Sellers by default
    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();

    expect(find.text('Multi-Tenant Sellers Directory'), findsOneWidget);
    expect(find.text('Onboard Seller'), findsNothing);

    // Switch to Customers via top segmented control
    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();

    // Verify CustomersView is displayed
    expect(find.text('Customers & Buyer Directory'), findsOneWidget);
    expect(find.text('TOTAL CUSTOMERS'), findsOneWidget);

    // Switch back to Sellers via top segmented control
    await tester.tap(find.text('Sellers'));
    await tester.pumpAndSettle();

    // Verify Sellers is displayed again
    expect(find.text('Multi-Tenant Sellers Directory'), findsOneWidget);
  });
}


