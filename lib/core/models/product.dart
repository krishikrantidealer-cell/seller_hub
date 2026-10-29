import 'package:equatable/equatable.dart';

/// Dimensions model supporting both structured MongoDB Object & formatted text
class ProductDimensions extends Equatable {
  final double length;
  final double width;
  final double height;
  final String unit;

  const ProductDimensions({
    this.length = 0.0,
    this.width = 0.0,
    this.height = 0.0,
    this.unit = 'cm',
  });

  factory ProductDimensions.fromJson(dynamic json) {
    if (json == null) return const ProductDimensions();
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      return ProductDimensions(
        length: _parseDouble(map['length']),
        width: _parseDouble(map['width']),
        height: _parseDouble(map['height']),
        unit: map['unit']?.toString() ?? 'cm',
      );
    } else if (json is String && json.isNotEmpty) {
      final parts = json.split(RegExp(r'[xX*]')).map((s) => s.trim()).toList();
      if (parts.length >= 3) {
        return ProductDimensions(
          length: _parseDouble(parts[0]),
          width: _parseDouble(parts[1]),
          height: _parseDouble(parts[2]),
          unit: json.contains('mm') ? 'mm' : (json.contains('m') ? 'm' : 'cm'),
        );
      }
    }
    return const ProductDimensions();
  }

  Map<String, dynamic> toJson() => {
    'length': length,
    'width': width,
    'height': height,
    'unit': unit,
  };

  String get formatted => '${length.toStringAsFixed(0)} x ${width.toStringAsFixed(0)} x ${height.toStringAsFixed(0)} $unit';

  @override
  List<Object?> get props => [length, width, height, unit];
}

/// Media Image representation matching backend Cloud Storage URLs
class ProductImage extends Equatable {
  final String id;
  final int displayOrder;
  final String midUrl;
  final String lowUrl;
  final String originalUrl;
  final String originalObjectName;
  final String midObjectName;
  final String lowObjectName;

  const ProductImage({
    this.id = '',
    this.displayOrder = 0,
    this.midUrl = '',
    this.lowUrl = '',
    this.originalUrl = '',
    this.originalObjectName = '',
    this.midObjectName = '',
    this.lowObjectName = '',
  });

  static const String defaultGcsBucketBase = 'https://storage.googleapis.com/sellerhub-prod-media-us';

  /// Determines whether a signed Google Cloud Storage URL has expired.
  static bool isUrlExpired(String? url) {
    if (url == null || url.isEmpty) return false;
    if (!url.contains('X-Goog-Date=') || !url.contains('X-Goog-Expires=')) return false;
    try {
      final uri = Uri.parse(url);
      final dateStr = uri.queryParameters['X-Goog-Date'];
      final expiresStr = uri.queryParameters['X-Goog-Expires'];
      if (dateStr == null || expiresStr == null || dateStr.length < 15) return false;
      final expiresSec = int.tryParse(expiresStr) ?? 900;
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      final hour = int.parse(dateStr.substring(9, 11));
      final min = int.parse(dateStr.substring(11, 13));
      final sec = int.parse(dateStr.substring(13, 15));
      final signedUtc = DateTime.utc(year, month, day, hour, min, sec);
      // 60-second grace window before hard expiration
      final expireUtc = signedUtc.add(Duration(seconds: expiresSec - 60));
      return DateTime.now().toUtc().isAfter(expireUtc);
    } catch (_) {
      return false;
    }
  }

  /// Whether any signed asset in this ProductImage is expired
  bool get isExpired {
    final candidate = midUrl.isNotEmpty ? midUrl : lowUrl;
    return isUrlExpired(candidate);
  }

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    final id = _parseString(json['id'] ?? json['_id']);
    final displayOrder = _parseInt(json['displayOrder'] ?? json['DisplayOrder'], 0);

    final originalObj = _parseString(json['originalObjectName'] ?? json['OriginalObjectName']);
    final midObj = _parseString(json['midObjectName'] ?? json['MidObjectName']);
    final lowObj = _parseString(json['lowObjectName'] ?? json['LowObjectName']);

    String mid = _parseString(json['midUrl'] ?? json['MidUrl']);
    String low = _parseString(json['lowUrl'] ?? json['LowUrl']);
    String original = _parseString(json['originalUrl'] ?? json['OriginalUrl']);

    // If signed URLs are not present, synthesize from GCS object name paths
    if (mid.isEmpty && midObj.isNotEmpty) {
      mid = midObj.startsWith('http') ? midObj : '$defaultGcsBucketBase/$midObj';
    }
    if (low.isEmpty && lowObj.isNotEmpty) {
      low = lowObj.startsWith('http') ? lowObj : '$defaultGcsBucketBase/$lowObj';
    }
    if (original.isEmpty && originalObj.isNotEmpty) {
      original = originalObj.startsWith('http') ? originalObj : '$defaultGcsBucketBase/$originalObj';
    }

    // Fallbacks
    if (mid.isEmpty && low.isNotEmpty) mid = low;
    if (low.isEmpty && mid.isNotEmpty) low = mid;
    if (original.isEmpty && mid.isNotEmpty) original = mid;
    if (original.isEmpty && low.isNotEmpty) original = low;
    if (mid.isEmpty && original.isNotEmpty) mid = original;

    return ProductImage(
      id: id,
      displayOrder: displayOrder,
      midUrl: mid,
      lowUrl: low,
      originalUrl: original,
      originalObjectName: originalObj,
      midObjectName: midObj,
      lowObjectName: lowObj,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    '_id': id,
    'displayOrder': displayOrder,
    'midUrl': midUrl,
    'lowUrl': lowUrl,
    if (originalUrl.isNotEmpty) 'originalUrl': originalUrl,
    if (originalObjectName.isNotEmpty) 'originalObjectName': originalObjectName,
    if (midObjectName.isNotEmpty) 'midObjectName': midObjectName,
    if (lowObjectName.isNotEmpty) 'lowObjectName': lowObjectName,
  };

  @override
  List<Object?> get props => [
    id,
    displayOrder,
    midUrl,
    lowUrl,
    originalUrl,
    originalObjectName,
    midObjectName,
    lowObjectName,
  ];
}

/// Variant model encapsulating commercial, pricing, packaging & inventory specs
class ProductVariant extends Equatable {
  final String id;
  final int displayOrder;
  final bool isDefault;
  final String label;
  final String unit;
  final int packSize;
  final String packSizeUnit;
  final int packQuantity;
  final String packUnit;
  final String shippedBy;
  final double swg;
  final int totalBaseQuantity;
  final String totalBaseUnit;
  final ProductDimensions dimensions;
  final double displayRate;
  final double printedMrp;
  final double costPrice;
  final double discountRs;
  final double gstPercentage;
  final double discountPercentage;
  final int stock;
  final double pricePerBaseUnit;

  const ProductVariant({
    this.id = '',
    this.displayOrder = 1,
    this.isDefault = true,
    this.label = '',
    this.unit = 'ml',
    this.packSize = 1,
    this.packSizeUnit = 'ml',
    this.packQuantity = 1,
    this.packUnit = 'bottle',
    this.shippedBy = 'Seller',
    this.swg = 0.0,
    this.totalBaseQuantity = 1,
    this.totalBaseUnit = 'ml',
    this.dimensions = const ProductDimensions(),
    this.displayRate = 0.0,
    this.printedMrp = 0.0,
    this.costPrice = 0.0,
    this.discountRs = 0.0,
    this.gstPercentage = 18.0,
    this.discountPercentage = 0.0,
    this.stock = 0,
    this.pricePerBaseUnit = 0.0,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final disp = _parseDouble(json['displayRate'] ?? json['Display Rate']);
    final mrp = _parseDouble(json['printedMrp'] ?? json['Printed MRP']);
    double disc = _parseDouble(json['discountRs'] ?? json['DiscountRS']);
    if (disc <= 0.0 && mrp > disp) {
      disc = mrp - disp;
    }
    double discPct = _parseDouble(json['discountPercentage'] ?? json['Discount Percentage']);
    if (discPct <= 0.0 && mrp > 0 && disc > 0) {
      discPct = (disc / mrp * 100);
    }
    final totalBaseQty = _parseInt(json['totalBaseQuantity'], 1000);
    double pricePerBaseUnit = _parseDouble(json['pricePerBaseUnit']);
    if (pricePerBaseUnit <= 0.0 && totalBaseQty > 0 && disp > 0) {
      pricePerBaseUnit = disp / totalBaseQty;
    }

    return ProductVariant(
      id: _parseString(json['_id'] ?? json['id']),
      displayOrder: _parseInt(json['displayOrder'], 1),
      isDefault: json['isDefault'] == true,
      label: _parseString(json['label'] ?? json['Varient'] ?? json['variant']),
      unit: _parseString(json['unit'] ?? json['Unit'] ?? 'ml'),
      packSize: _parseInt(json['packSize'] ?? json['Pack Size'], 1),
      packSizeUnit: _parseString(json['packSizeUnit'] ?? json['unit'] ?? 'ml'),
      packQuantity: _parseInt(json['packQuantity'], 1),
      packUnit: _parseString(json['packUnit'] ?? 'bottle'),
      shippedBy: _parseString(json['shippedBy'] ?? json['Shipped By'] ?? 'Seller Standard'),
      swg: _parseDouble(json['swg'] ?? json['SWG']),
      totalBaseQuantity: totalBaseQty,
      totalBaseUnit: _parseString(json['totalBaseUnit'] ?? 'ml'),
      dimensions: ProductDimensions.fromJson(json['dimensions'] ?? json['Dimmensions']),
      displayRate: disp,
      printedMrp: mrp,
      costPrice: _parseDouble(json['costPrice'] ?? json['Cost Price']),
      discountRs: disc,
      gstPercentage: _parseDouble(json['gstPercentage'] ?? json['GST'] ?? 5.0, 5.0),
      discountPercentage: discPct,
      stock: _parseInt(json['stock'] ?? json['Stock']),
      pricePerBaseUnit: pricePerBaseUnit,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'id': id,
    'displayOrder': displayOrder,
    'isDefault': isDefault,
    'label': label,
    'unit': unit,
    'packSize': packSize,
    'packSizeUnit': packSizeUnit,
    'packQuantity': packQuantity,
    'packUnit': packUnit,
    'shippedBy': shippedBy,
    'swg': swg,
    'totalBaseQuantity': totalBaseQuantity,
    'totalBaseUnit': totalBaseUnit,
    'dimensions': dimensions.toJson(),
    'displayRate': displayRate,
    'printedMrp': printedMrp,
    'costPrice': costPrice,
    'discountRs': discountRs,
    'gstPercentage': gstPercentage,
    'discountPercentage': discountPercentage,
    'stock': stock,
    'pricePerBaseUnit': pricePerBaseUnit,
  };

  Map<String, dynamic> toAdminPayload() => {
    'label': label.isNotEmpty ? label : '500 ml Bottle',
    'unit': unit.isNotEmpty ? unit : 'ml',
    'packSize': packSize > 0 ? packSize : 500,
    'packSizeUnit': packSizeUnit.isNotEmpty ? packSizeUnit : (unit.isNotEmpty ? unit : 'ml'),
    'packQuantity': packQuantity > 0 ? packQuantity : 1,
    'packUnit': packUnit.isNotEmpty ? packUnit : 'bottle',
    'shippedBy': shippedBy.isNotEmpty ? shippedBy : 'EBS Direct',
    'displayRate': displayRate > 0 ? displayRate : 450.0,
    'printedMrp': printedMrp > 0 ? printedMrp : 500.0,
    'costPrice': costPrice > 0 ? costPrice : 250.0,
    'discountRs': discountRs > 0 ? discountRs : 50.0,
    'gstPercentage': gstPercentage > 0 ? gstPercentage : 5.0,
    'discountPercentage': discountPercentage > 0 ? discountPercentage : 10.0,
    'stock': stock > 0 ? stock : 100,
  };

  ProductVariant copyWith({
    String? id,
    int? displayOrder,
    bool? isDefault,
    String? label,
    String? unit,
    int? packSize,
    String? packSizeUnit,
    int? packQuantity,
    String? packUnit,
    String? shippedBy,
    double? swg,
    int? totalBaseQuantity,
    String? totalBaseUnit,
    ProductDimensions? dimensions,
    double? displayRate,
    double? printedMrp,
    double? costPrice,
    double? discountRs,
    double? gstPercentage,
    double? discountPercentage,
    int? stock,
    double? pricePerBaseUnit,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      displayOrder: displayOrder ?? this.displayOrder,
      isDefault: isDefault ?? this.isDefault,
      label: label ?? this.label,
      unit: unit ?? this.unit,
      packSize: packSize ?? this.packSize,
      packSizeUnit: packSizeUnit ?? this.packSizeUnit,
      packQuantity: packQuantity ?? this.packQuantity,
      packUnit: packUnit ?? this.packUnit,
      shippedBy: shippedBy ?? this.shippedBy,
      swg: swg ?? this.swg,
      totalBaseQuantity: totalBaseQuantity ?? this.totalBaseQuantity,
      totalBaseUnit: totalBaseUnit ?? this.totalBaseUnit,
      dimensions: dimensions ?? this.dimensions,
      displayRate: displayRate ?? this.displayRate,
      printedMrp: printedMrp ?? this.printedMrp,
      costPrice: costPrice ?? this.costPrice,
      discountRs: discountRs ?? this.discountRs,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      stock: stock ?? this.stock,
      pricePerBaseUnit: pricePerBaseUnit ?? this.pricePerBaseUnit,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayOrder,
    isDefault,
    label,
    packSize,
    displayRate,
    printedMrp,
    stock,
    pricePerBaseUnit,
  ];
}

/// Enterprise Agri-Commerce Product Model compatible with MongoDB BSON and Flat 38-Field Schema
class Product extends Equatable {
  final String id;
  final String sku;
  final String productCode;
  final String hsnCode;
  final String sellerId;
  final String title;
  final String technicalName;
  final String vendor;
  final String sellerName;
  final String description;
  final List<String> images;
  final List<ProductImage> productImages;
  final String technicalContent;
  final List<String> featuresList;
  final List<String> benefitsList;
  final String modeOfAction;
  final List<String> suitableCropsList;
  final List<String> targetPestsList;
  final List<String> targetDiseasesList;
  final String dosage;
  final String applicationMethod;
  final String category;
  final String categoryId;
  final String collections;
  final List<String> collectionIds;
  final String subCollections;
  final List<String> subCollectionIds;
  final List<String> assignedCollections;
  final bool isAvailable;
  final bool isFeatured;
  final List<ProductVariant> variants;
  final double ratings;
  final int totalReviews;
  final String refundPolicy;
  final double productWeight;
  final String productWeightUnit;
  final ProductDimensions productDimensions;
  final String status;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;

  // Fallback flat fields for direct access
  final String _flatVariant;
  final String _flatPackSize;
  final double _flatDisplayRate;
  final double _flatPrintedMrp;
  final double _flatCostPrice;
  final double _flatDiscountRs;
  final String _flatUnit;
  final double _flatGst;
  final double _flatDiscountPercentage;
  final String _flatShippedBy;
  final String _flatSwg;
  final int _flatStock;
  final String _flatDimensions;

  Product({
    this.id = '',
    this.sku = '',
    this.productCode = '',
    this.hsnCode = '3808',
    this.sellerId = '',
    required this.title,
    this.technicalName = '',
    String vendor = '',
    String sellerName = '',
    this.description = '',
    this.images = const [],
    this.productImages = const [],
    this.technicalContent = '',
    String features = '',
    List<String>? featuresList,
    String benefits = '',
    List<String>? benefitsList,
    this.modeOfAction = '',
    String suitableCrop = '',
    List<String>? suitableCropsList,
    String targetPests = '',
    List<String>? targetPestsList,
    String targetDiseases = '',
    List<String>? targetDiseasesList,
    this.dosage = '',
    this.applicationMethod = '',
    this.category = '',
    this.categoryId = '',
    this.collections = '',
    this.collectionIds = const [],
    this.subCollections = '',
    this.subCollectionIds = const [],
    this.assignedCollections = const [],
    this.isAvailable = false,
    this.isFeatured = false,
    this.variants = const [],
    this.ratings = 0.0,
    this.totalReviews = 0,
    this.refundPolicy = '',
    this.productWeight = 0.0,
    this.productWeightUnit = 'g',
    this.productDimensions = const ProductDimensions(),
    this.status = 'ACTIVE',
    this.isDeleted = false,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.version = 1,
    // Flat field properties
    String variant = '',
    String packSize = '',
    double displayRate = 0.0,
    double printedMrp = 0.0,
    double costPrice = 0.0,
    double discountRs = 0.0,
    String unit = '',
    double gst = 18.0,
    double discountPercentage = 0.0,
    String shippedBy = 'Seller',
    String swg = '',
    int stock = 0,
    String dimensions = '',
  })  : vendor = vendor.isNotEmpty ? vendor : sellerName,
        sellerName = sellerName.isNotEmpty ? sellerName : vendor,
        featuresList = featuresList ?? (features.isNotEmpty ? [features] : const []),
        benefitsList = benefitsList ?? (benefits.isNotEmpty ? [benefits] : const []),
        suitableCropsList = suitableCropsList ?? (suitableCrop.isNotEmpty ? [suitableCrop] : const []),
        targetPestsList = targetPestsList ?? (targetPests.isNotEmpty ? [targetPests] : const []),
        targetDiseasesList = targetDiseasesList ?? (targetDiseases.isNotEmpty ? [targetDiseases] : const []),
        _flatVariant = variant,
        _flatPackSize = packSize,
        _flatDisplayRate = displayRate,
        _flatPrintedMrp = printedMrp,
        _flatCostPrice = costPrice,
        _flatDiscountRs = discountRs,
        _flatUnit = unit,
        _flatGst = gst,
        _flatDiscountPercentage = discountPercentage,
        _flatShippedBy = shippedBy,
        _flatSwg = swg,
        _flatStock = stock,
        _flatDimensions = dimensions;

  // Active / Default Variant resolution
  ProductVariant? get defaultVariant {
    if (variants.isEmpty) return null;
    return variants.firstWhere((v) => v.isDefault, orElse: () => variants.first);
  }

  int get variantsCount => variants.isNotEmpty ? variants.length : 1;
  bool get hasMultipleVariants => variants.length > 1;
  double get averageRating => ratings;

  double get minDisplayRate {
    if (variants.isEmpty) return displayRate;
    return variants.map((v) => v.displayRate).reduce((a, b) => a < b ? a : b);
  }

  double get maxDisplayRate {
    if (variants.isEmpty) return displayRate;
    return variants.map((v) => v.displayRate).reduce((a, b) => a > b ? a : b);
  }

  double get minMrp {
    if (variants.isEmpty) return printedMrp;
    return variants.map((v) => v.printedMrp).reduce((a, b) => a < b ? a : b);
  }

  double get maxMrp {
    if (variants.isEmpty) return printedMrp;
    return variants.map((v) => v.printedMrp).reduce((a, b) => a > b ? a : b);
  }

  int get totalStock {
    if (variants.isEmpty) return stock;
    return variants.fold(0, (sum, v) => sum + v.stock);
  }

  String get priceRangeFormatted {
    if (variants.isEmpty) return '₹${displayRate.toStringAsFixed(0)}';
    if (minDisplayRate == maxDisplayRate) return '₹${minDisplayRate.toStringAsFixed(0)}';
    return '₹${minDisplayRate.toStringAsFixed(0)} - ₹${maxDisplayRate.toStringAsFixed(0)}';
  }

  String get mrpRangeFormatted {
    if (variants.isEmpty) return '₹${printedMrp.toStringAsFixed(0)}';
    if (minMrp == maxMrp) return '₹${minMrp.toStringAsFixed(0)}';
    return '₹${minMrp.toStringAsFixed(0)} - ₹${maxMrp.toStringAsFixed(0)}';
  }

  String get resolvedCategory {
    if (category.isNotEmpty && category.trim().isNotEmpty) return category;
    final t = '$title $description'.toLowerCase();
    if (t.contains('insecticide') || t.contains('insect')) return 'Insecticides';
    if (t.contains('fungicide') || t.contains('fungi')) return 'Fungicides';
    if (t.contains('bio fertilizer') || t.contains('fertilizer') || t.contains('fertiliser')) return 'Fertilizers';
    if (t.contains('bio pesticide') || t.contains('pesticide')) return 'Bio Pesticides';
    if (t.contains('herbicide') || t.contains('weedicide')) return 'Herbicides';
    if (t.contains('seed')) return 'Seeds';
    if (t.contains('stimulant') || t.contains('growth')) return 'Bio Stimulants';
    return 'Agri Inputs';
  }

  String get image => thumbnailUrl;
  double get price => displayRate;

  /// Returns true if any image associated with this product is expired
  bool get hasExpiredImages {
    if (productImages.isEmpty) return false;
    return productImages.any((img) => img.isExpired);
  }

  /// All valid candidate image URLs in order of preference
  List<String> get candidateImageUrls {
    final list = <String>[];
    for (final img in productImages) {
      if (!img.isExpired) {
        if (img.midUrl.isNotEmpty && !list.contains(img.midUrl)) list.add(img.midUrl);
        if (img.lowUrl.isNotEmpty && !list.contains(img.lowUrl)) list.add(img.lowUrl);
        if (img.originalUrl.isNotEmpty && !list.contains(img.originalUrl)) list.add(img.originalUrl);
      }
    }
    for (final img in images) {
      if (!ProductImage.isUrlExpired(img) && !list.contains(img)) list.add(img);
    }
    // Fallback if all were flagged expired
    if (list.isEmpty) {
      for (final img in productImages) {
        if (img.midUrl.isNotEmpty && !list.contains(img.midUrl)) list.add(img.midUrl);
        if (img.lowUrl.isNotEmpty && !list.contains(img.lowUrl)) list.add(img.lowUrl);
      }
      for (final img in images) {
        if (!list.contains(img)) list.add(img);
      }
    }
    return list;
  }

  String get thumbnailUrl {
    if (productImages.isNotEmpty) {
      // Prioritize non-expired images
      for (final img in productImages) {
        if (!img.isExpired) {
          if (img.lowUrl.isNotEmpty) return img.lowUrl;
          if (img.midUrl.isNotEmpty) return img.midUrl;
          if (img.originalUrl.isNotEmpty) return img.originalUrl;
        }
      }
      final first = productImages.first;
      if (first.lowUrl.isNotEmpty) return first.lowUrl;
      if (first.midUrl.isNotEmpty) return first.midUrl;
      if (first.originalUrl.isNotEmpty) return first.originalUrl;
    }
    if (images.isNotEmpty) {
      for (final img in images) {
        if (!ProductImage.isUrlExpired(img)) return img;
      }
      return images.first;
    }
    return '';
  }

  String get primaryImageUrl {
    if (productImages.isNotEmpty) {
      for (final img in productImages) {
        if (!img.isExpired) {
          if (img.midUrl.isNotEmpty) return img.midUrl;
          if (img.lowUrl.isNotEmpty) return img.lowUrl;
          if (img.originalUrl.isNotEmpty) return img.originalUrl;
        }
      }
      final first = productImages.first;
      if (first.midUrl.isNotEmpty) return first.midUrl;
      if (first.lowUrl.isNotEmpty) return first.lowUrl;
      if (first.originalUrl.isNotEmpty) return first.originalUrl;
    }
    if (images.isNotEmpty) {
      for (final img in images) {
        if (!ProductImage.isUrlExpired(img)) return img;
      }
      return images.first;
    }
    return '';
  }

  String get originalImageUrl {
    if (productImages.isNotEmpty) {
      for (final img in productImages) {
        if (!img.isExpired) {
          if (img.originalUrl.isNotEmpty &&
              (img.originalUrl.contains('X-Goog-Signature') ||
                  img.originalUrl.contains('token') ||
                  !img.originalUrl.contains('storage.googleapis.com'))) {
            return img.originalUrl;
          }
          if (img.midUrl.isNotEmpty) return img.midUrl;
          if (img.originalUrl.isNotEmpty) return img.originalUrl;
          if (img.lowUrl.isNotEmpty) return img.lowUrl;
        }
      }
      final first = productImages.first;
      if (first.midUrl.isNotEmpty) return first.midUrl;
      if (first.originalUrl.isNotEmpty) return first.originalUrl;
      if (first.lowUrl.isNotEmpty) return first.lowUrl;
    }
    if (images.isNotEmpty) {
      for (final img in images) {
        if (!ProductImage.isUrlExpired(img)) return img;
      }
      return images.first;
    }
    return '';
  }

  String get highResImageUrl {
    if (productImages.isNotEmpty) {
      for (final img in productImages) {
        if (!img.isExpired) {
          if (img.midUrl.isNotEmpty) return img.midUrl;
          if (img.originalUrl.isNotEmpty) return img.originalUrl;
          if (img.lowUrl.isNotEmpty) return img.lowUrl;
        }
      }
      final first = productImages.first;
      if (first.midUrl.isNotEmpty) return first.midUrl;
      if (first.originalUrl.isNotEmpty) return first.originalUrl;
      if (first.lowUrl.isNotEmpty) return first.lowUrl;
    }
    if (images.isNotEmpty) {
      for (final img in images) {
        if (!ProductImage.isUrlExpired(img)) return img;
      }
      return images.first;
    }
    return '';
  }

  // Convenience Properties mapping all 38 official schema attributes
  String get features => featuresList.join(', ');
  String get benefits => benefitsList.join(', ');
  String get suitableCrop => suitableCropsList.join(', ');
  String get targetPests => targetPestsList.join(', ');
  String get targetDiseases => targetDiseasesList.join(', ');

  String get variant => defaultVariant?.label.isNotEmpty == true ? defaultVariant!.label : _flatVariant;
  String get packSize => defaultVariant != null ? defaultVariant!.packSize.toString() : _flatPackSize;
  String get unit => defaultVariant?.unit.isNotEmpty == true ? defaultVariant!.unit : _flatUnit;
  double get displayRate => defaultVariant != null ? defaultVariant!.displayRate : _flatDisplayRate;
  double get printedMrp => defaultVariant != null ? defaultVariant!.printedMrp : _flatPrintedMrp;
  double get costPrice => defaultVariant != null ? defaultVariant!.costPrice : _flatCostPrice;
  double get discountRs => defaultVariant != null ? defaultVariant!.discountRs : _flatDiscountRs;
  double get gst => defaultVariant != null ? defaultVariant!.gstPercentage : _flatGst;
  double get discountPercentage => defaultVariant != null ? defaultVariant!.discountPercentage : _flatDiscountPercentage;
  int get stock => defaultVariant != null ? defaultVariant!.stock : _flatStock;
  String get shippedBy => defaultVariant?.shippedBy.isNotEmpty == true ? defaultVariant!.shippedBy : _flatShippedBy;
  String get swg => defaultVariant?.swg != null ? defaultVariant!.swg.toString() : _flatSwg;
  String get dimensions => defaultVariant?.dimensions.formatted.isNotEmpty == true
      ? defaultVariant!.dimensions.formatted
      : (productDimensions.formatted != '0 x 0 x 0 cm' ? productDimensions.formatted : _flatDimensions);

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse variants if present
    List<ProductVariant> parsedVariants = [];
    if (json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .whereType<Map>()
          .map((v) => ProductVariant.fromJson(Map<String, dynamic>.from(v)))
          .toList();
      parsedVariants.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }

    final id = _parseString(json['_id'] ?? json['id']);
    final sku = _parseString(json['sku'] ?? json['productCode'] ?? json['Product Code']);
    final productCode = _parseString(json['productCode'] ?? json['Product Code'] ?? json['sku']);
    final hsnCode = _parseString(json['hsnCode'] ?? json['HSN Code']);
    final sellerId = _parseString(json['sellerId'] ?? json['seller_id']);
    final title = _parseString(json['title'] ?? json['Title']);
    final technicalName = _parseString(json['technicalName'] ?? json['Technical Name']);
    final rawSellerName = _parseString(json['sellerName'] ?? json['Seller Name'] ?? json['seller_name']);
    final rawVendor = _parseString(json['vendor'] ?? json['Vendor']);
    final effectiveSellerName = rawSellerName.isNotEmpty ? rawSellerName : rawVendor;
    final effectiveVendor = rawVendor.isNotEmpty ? rawVendor : effectiveSellerName;
    final description = _parseString(json['description'] ?? json['Description']);

    List<ProductImage> parsedProductImages = [];
    final rawImgs = json['productImages'] ?? json['ProductImages'];
    if (rawImgs is List) {
      parsedProductImages = rawImgs
          .whereType<Map>()
          .map((m) => ProductImage.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      parsedProductImages.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }

    var images = _parseListString(json['images'] ?? json['Images']);
    if (images.isEmpty && parsedProductImages.isNotEmpty) {
      images = parsedProductImages
          .map((img) => img.midUrl.isNotEmpty ? img.midUrl : (img.lowUrl.isNotEmpty ? img.lowUrl : img.originalUrl))
          .where((url) => url.isNotEmpty)
          .toList();
    }

    final technicalContent = _parseString(json['technicalContent'] ?? json['Technical Content']);
    final featuresList = _parseListString(json['features'] ?? json['Features']);
    final benefitsList = _parseListString(json['benefits'] ?? json['Benefites']);
    final modeOfAction = _parseString(json['modeOfAction'] ?? json['Mode of Action']);
    final suitableCropsList = _parseListString(json['suitableCrops'] ?? json['Suitable Crop'] ?? json['suitableCrop']);
    final targetPestsList = _parseListString(json['targetPests'] ?? json['Target Pests']);
    final targetDiseasesList = _parseListString(json['targetDiseases'] ?? json['Target Diseases']);

    final dosage = _parseString(json['dosage'] ?? json['Dosage']);
    final applicationMethod = _parseString(json['applicationMethod'] ?? json['Application Method']);

    var categoryId = '';
    var category = '';
    if (json['category'] is Map) {
      final catMap = Map<String, dynamic>.from(json['category'] as Map);
      categoryId = _parseString(catMap['id'] ?? catMap['_id']);
      category = _parseString(catMap['name'] ?? catMap['title']);
    } else {
      category = _parseString(json['category'] ?? json['Category'] ?? json['categoryName']);
      categoryId = _parseString(json['categoryId'] ?? json['category_id']);
    }

    final collections = _parseString(json['collections'] ?? json['Collections']);
    var collectionIds = _parseListString(json['collectionIds'] ?? json['collection_ids']);
    final subCollections = _parseString(json['subCollections'] ?? json['Sub Collections']);
    final subCollectionIds = _parseListString(json['subCollectionIds'] ?? json['sub_collection_ids']);
    final assignedCollections = _parseListString(json['assignedCollections'] ?? json['assigned_collections']);
    if (collectionIds.isEmpty && assignedCollections.isNotEmpty) {
      collectionIds = List<String>.from(assignedCollections);
    }

    final isAvailable = json['isAvailable'] as bool? ?? json['Is_Available'] as bool? ?? true;
    final isFeatured = json['isFeatured'] as bool? ?? json['Is_featured'] as bool? ?? false;

    final ratings = _parseDouble(json['averageRating'] ?? json['ratings'] ?? json['Ratings']);
    final totalReviews = _parseInt(json['totalReviews'] ?? json['Total Reviews'], 0);
    final refundPolicy = _parseString(json['refundPolicy'] ?? json['Refund Policy']);
    final productWeight = _parseDouble(json['productWeight'] ?? json['Product Weight']);
    final productWeightUnit = _parseString(json['productWeightUnit'] ?? json['Product Weight Unit'] ?? 'kg');
    final productDimensions = ProductDimensions.fromJson(json['dimensions'] ?? json['Dimmensions']);
    final status = _parseString(json['status'] ?? 'ACTIVE');
    final isDeleted = json['isDeleted'] as bool? ?? false;
    final version = _parseInt(json['version'], 1);

    DateTime? deletedAt;
    if (json['deletedAt'] != null) {
      deletedAt = DateTime.tryParse(_parseString(json['deletedAt']));
    }
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.tryParse(_parseString(json['createdAt']));
    }
    DateTime? updatedAt;
    if (json['updatedAt'] != null) {
      updatedAt = DateTime.tryParse(_parseString(json['updatedAt']));
    }

    // Flat fallbacks if variants not provided
    var flatVariant = _parseString(json['variant'] ?? json['Varient']);
    var flatPackSize = _parseString(json['packSize'] ?? json['Pack Size']);
    var flatDisplayRate = _parseDouble(json['displayRate'] ?? json['Display Rate']);
    var flatPrintedMrp = _parseDouble(json['printedMrp'] ?? json['Printed MRP']);
    var flatCostPrice = _parseDouble(json['costPrice'] ?? json['Cost Price']);
    var flatDiscountRs = _parseDouble(json['discountRs'] ?? json['DiscountRS']);
    var flatUnit = _parseString(json['unit'] ?? json['Unit']);
    var flatGst = _parseDouble(json['gst'] ?? json['GST'] ?? 5.0, 5.0);
    var flatDiscountPct = _parseDouble(json['discountPercentage'] ?? json['Discount Percentage']);
    var flatShippedBy = _parseString(json['shippedBy'] ?? json['Shipped By'] ?? 'Seller');
    var flatSwg = _parseString(json['swg'] ?? json['SWG']);
    var flatStock = _parseInt(json['stock'] ?? json['Stock']);
    final flatDims = _parseString(json['dimensions'] ?? json['Dimmensions']);

    // If variants were parsed, populate the flat fields from the default variant
    if (parsedVariants.isNotEmpty) {
      final defaultVar = parsedVariants.firstWhere((v) => v.isDefault, orElse: () => parsedVariants.first);
      if (flatVariant.isEmpty) flatVariant = defaultVar.label;
      if (flatPackSize.isEmpty) flatPackSize = defaultVar.packSize.toString();
      if (flatDisplayRate <= 0.0) flatDisplayRate = defaultVar.displayRate;
      if (flatPrintedMrp <= 0.0) flatPrintedMrp = defaultVar.printedMrp;
      if (flatCostPrice <= 0.0) flatCostPrice = defaultVar.costPrice;
      if (flatDiscountRs <= 0.0) flatDiscountRs = defaultVar.discountRs;
      if (flatUnit.isEmpty) flatUnit = defaultVar.unit;
      if (flatGst <= 0.0) flatGst = defaultVar.gstPercentage;
      if (flatDiscountPct <= 0.0) flatDiscountPct = defaultVar.discountPercentage;
      if (flatShippedBy == 'Seller') flatShippedBy = defaultVar.shippedBy;
      if (flatSwg.isEmpty && defaultVar.swg > 0) flatSwg = defaultVar.swg.toString();
      if (flatStock <= 0) flatStock = defaultVar.stock;
    }

    return Product(
      id: id,
      sku: sku,
      productCode: productCode,
      hsnCode: hsnCode,
      sellerId: sellerId,
      title: title,
      technicalName: technicalName,
      vendor: effectiveVendor,
      sellerName: effectiveSellerName,
      description: description,
      images: images,
      productImages: parsedProductImages,
      technicalContent: technicalContent,
      featuresList: featuresList,
      benefitsList: benefitsList,
      modeOfAction: modeOfAction,
      suitableCropsList: suitableCropsList,
      targetPestsList: targetPestsList,
      targetDiseasesList: targetDiseasesList,
      dosage: dosage,
      applicationMethod: applicationMethod,
      category: category,
      categoryId: categoryId,
      collections: collections,
      collectionIds: collectionIds,
      subCollections: subCollections,
      subCollectionIds: subCollectionIds,
      assignedCollections: assignedCollections.isNotEmpty
          ? assignedCollections
          : [...collectionIds, ...subCollectionIds],
      isAvailable: isAvailable,
      isFeatured: isFeatured,
      variants: parsedVariants,
      ratings: ratings,
      totalReviews: totalReviews,
      refundPolicy: refundPolicy,
      productWeight: productWeight,
      productWeightUnit: productWeightUnit,
      productDimensions: productDimensions,
      status: status,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      // Flat values
      variant: flatVariant,
      packSize: flatPackSize,
      displayRate: flatDisplayRate,
      printedMrp: flatPrintedMrp,
      costPrice: flatCostPrice,
      discountRs: flatDiscountRs,
      unit: flatUnit,
      gst: flatGst,
      discountPercentage: flatDiscountPct,
      shippedBy: flatShippedBy,
      swg: flatSwg,
      stock: flatStock,
      dimensions: flatDims,
    );
  }

  /// Exports in exact MongoDB production document structure
  Map<String, dynamic> toMongoJson() => {
    if (id.isNotEmpty) '_id': id,
    'sku': sku.isNotEmpty ? sku : productCode,
    'productCode': productCode,
    'hsnCode': hsnCode,
    'sellerId': sellerId,
    'title': title,
    'technicalName': technicalName,
    'vendor': vendor,
    'sellerName': sellerName,
    'description': description,
    'images': images,
    'productImages': productImages.map((p) => p.toJson()).toList(),
    'technicalContent': technicalContent,
    'features': featuresList,
    'benefits': benefitsList,
    'modeOfAction': modeOfAction,
    'suitableCrops': suitableCropsList,
    'targetPests': targetPestsList,
    'targetDiseases': targetDiseasesList,
    'dosage': dosage,
    'applicationMethod': applicationMethod,
    'categoryId': categoryId,
    'collectionIds': collectionIds,
    'subCollectionIds': subCollectionIds,
    'assignedCollections': assignedCollections,
    'dimensions': productDimensions.toJson(),
    'isAvailable': isAvailable,
    'isFeatured': isFeatured,
    'variants': variants.map((v) => v.toJson()).toList(),
    'ratings': ratings,
    'averageRating': ratings,
    'totalReviews': totalReviews,
    'category': category,
    'refundPolicy': refundPolicy,
    'productWeight': productWeight,
    'productWeightUnit': productWeightUnit,
    'status': status,
    'isDeleted': isDeleted,
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'version': version,
  };

  /// Exports in exact structure expected by POST /api/v1/admin/products
  Map<String, dynamic> toAdminCreatePayload() => {
    'sellerId': sellerId,
    'sku': sku.isNotEmpty ? sku : 'EBS-ADM-SKU-${DateTime.now().millisecondsSinceEpoch}',
    'hsnCode': hsnCode.isNotEmpty ? hsnCode : '3808',
    'title': title,
    if (technicalName.isNotEmpty) 'technicalName': technicalName,
    'description': description.isNotEmpty ? description : title,
    'categoryId': categoryId.isNotEmpty ? categoryId : '6ab4f6f619ec643fd9bf3621',
    'productWeight': productWeight > 0 ? productWeight : 500.0,
    'productWeightUnit': productWeightUnit.isNotEmpty ? productWeightUnit : 'g',
    'dimensions': (productDimensions.length > 0 || productDimensions.width > 0 || productDimensions.height > 0)
        ? {
            'length': productDimensions.length > 0 ? productDimensions.length : 20.0,
            'width': productDimensions.width > 0 ? productDimensions.width : 10.0,
            'height': productDimensions.height > 0 ? productDimensions.height : 10.0,
            'unit': productDimensions.unit.isNotEmpty ? productDimensions.unit : 'cm',
          }
        : const {
            'length': 20.0,
            'width': 10.0,
            'height': 10.0,
            'unit': 'cm',
          },
    'variants': variants.isNotEmpty
        ? variants.map((v) => v.toAdminPayload()).toList()
        : [
            {
              'label': variant.isNotEmpty ? variant : '500 ml Bottle',
              'unit': unit.isNotEmpty ? unit : 'ml',
              'packSize': int.tryParse(packSize) ?? 500,
              'packSizeUnit': unit.isNotEmpty ? unit : 'ml',
              'packQuantity': 1,
              'packUnit': 'bottle',
              'shippedBy': shippedBy.isNotEmpty ? shippedBy : 'EBS Direct',
              'displayRate': displayRate > 0 ? displayRate : 450.0,
              'printedMrp': printedMrp > 0 ? printedMrp : 500.0,
              'costPrice': costPrice > 0 ? costPrice : 250.0,
              'discountRs': discountRs > 0 ? discountRs : 50.0,
              'gstPercentage': gst > 0 ? gst : 5.0,
              'discountPercentage': discountPercentage > 0 ? discountPercentage : 10.0,
              'stock': stock > 0 ? stock : 100,
            }
          ],
  };

  /// Exports in standard 38-field flat JSON with canonical keys for loss-free caching and table exports
  Map<String, dynamic> toJson() => {
    'id': id,
    '_id': id,
    'sku': sku,
    'productCode': productCode,
    'Product Code': productCode,
    'hsnCode': hsnCode,
    'HSN Code': hsnCode,
    'sellerId': sellerId,
    'Title': title,
    'title': title,
    'Technical Name': technicalName,
    'technicalName': technicalName,
    'Vendor': vendor,
    'vendor': vendor,
    'Seller Name': sellerName,
    'sellerName': sellerName,
    'Description': description,
    'description': description,
    'Images': images,
    'images': images,
    'ProductImages': productImages.map((p) => p.toJson()).toList(),
    'productImages': productImages.map((p) => p.toJson()).toList(),
    'Technical Content': technicalContent,
    'Features': features,
    'Benefites': benefits,
    'Mode of Action': modeOfAction,
    'Suitable Crop': suitableCrop,
    'Target Pests': targetPests,
    'Target Diseases': targetDiseases,
    'Dosage': dosage,
    'Application Method': applicationMethod,
    'Category': category,
    'category': category,
    'categoryId': categoryId,
    'category_id': categoryId,
    'Collections': collections,
    'Sub Collections': subCollections,
    'assignedCollections': assignedCollections,
    'variants': variants.map((v) => v.toJson()).toList(),
    'Is_Available': isAvailable,
    'Is_featured': isFeatured,
    'Varient': variant,
    'Pack Size': packSize,
    'Display Rate': displayRate,
    'Printed MRP': printedMrp,
    'Cost Price': costPrice,
    'DiscountRS': discountRs,
    'Unit': unit,
    'GST': gst,
    'Discount Percentage': discountPercentage,
    'Shipped By': shippedBy,
    'SWG': swg,
    'Stock': stock,
    'status': status,
    'isDeleted': isDeleted,
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    'Ratings': ratings,
    'ratings': ratings,
    'averageRating': ratings,
    'totalReviews': totalReviews,
    'Refund Policy': refundPolicy,
    'Product Weight': productWeight,
    'Product Weight Unit': productWeightUnit,
    'Dimmensions': dimensions,
  };

  Product copyWith({
    String? id,
    String? sku,
    String? productCode,
    String? hsnCode,
    String? sellerId,
    String? title,
    String? technicalName,
    String? vendor,
    String? sellerName,
    String? description,
    List<String>? images,
    List<ProductImage>? productImages,
    String? technicalContent,
    String? features,
    List<String>? featuresList,
    String? benefits,
    List<String>? benefitsList,
    String? modeOfAction,
    String? suitableCrop,
    List<String>? suitableCropsList,
    String? targetPests,
    List<String>? targetPestsList,
    String? targetDiseases,
    List<String>? targetDiseasesList,
    String? dosage,
    String? applicationMethod,
    String? category,
    String? categoryId,
    String? collections,
    List<String>? collectionIds,
    String? subCollections,
    List<String>? subCollectionIds,
    List<String>? assignedCollections,
    bool? isAvailable,
    bool? isFeatured,
    List<ProductVariant>? variants,
    String? variant,
    String? packSize,
    double? displayRate,
    double? printedMrp,
    double? costPrice,
    double? discountRs,
    String? unit,
    double? gst,
    double? discountPercentage,
    String? shippedBy,
    String? swg,
    int? stock,
    double? ratings,
    int? totalReviews,
    String? refundPolicy,
    double? productWeight,
    String? productWeightUnit,
    String? dimensions,
    ProductDimensions? productDimensions,
    String? status,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    // If variants exist, update the default variant with any new commercial parameters
    List<ProductVariant> updatedVariants = variants ?? this.variants;
    if (updatedVariants.isNotEmpty &&
        (displayRate != null || printedMrp != null || costPrice != null || stock != null || variant != null)) {
      final defaultIdx = updatedVariants.indexWhere((v) => v.isDefault);
      final targetIdx = defaultIdx != -1 ? defaultIdx : 0;
      final cur = updatedVariants[targetIdx];
      final newDisp = displayRate ?? cur.displayRate;
      final newMrp = printedMrp ?? cur.printedMrp;
      final newDisc = (newMrp > newDisp) ? (newMrp - newDisp) : 0.0;
      final newDiscPct = newMrp > 0 ? (newDisc / newMrp * 100) : 0.0;

      final updatedVariant = cur.copyWith(
        displayRate: newDisp,
        printedMrp: newMrp,
        costPrice: costPrice ?? cur.costPrice,
        discountRs: discountRs ?? newDisc,
        discountPercentage: discountPercentage ?? newDiscPct,
        stock: stock ?? cur.stock,
        label: variant ?? cur.label,
        unit: unit ?? cur.unit,
        shippedBy: shippedBy ?? cur.shippedBy,
        gstPercentage: gst ?? cur.gstPercentage,
      );

      updatedVariants = List.from(updatedVariants);
      updatedVariants[targetIdx] = updatedVariant;
    }

    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      productCode: productCode ?? this.productCode,
      hsnCode: hsnCode ?? this.hsnCode,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      technicalName: technicalName ?? this.technicalName,
      vendor: vendor ?? this.vendor,
      sellerName: sellerName ?? this.sellerName,
      description: description ?? this.description,
      images: images ?? this.images,
      productImages: productImages ?? this.productImages,
      technicalContent: technicalContent ?? this.technicalContent,
      featuresList: featuresList ?? (features != null ? [features] : this.featuresList),
      benefitsList: benefitsList ?? (benefits != null ? [benefits] : this.benefitsList),
      modeOfAction: modeOfAction ?? this.modeOfAction,
      suitableCropsList: suitableCropsList ?? (suitableCrop != null ? [suitableCrop] : this.suitableCropsList),
      targetPestsList: targetPestsList ?? (targetPests != null ? [targetPests] : this.targetPestsList),
      targetDiseasesList: targetDiseasesList ?? (targetDiseases != null ? [targetDiseases] : this.targetDiseasesList),
      dosage: dosage ?? this.dosage,
      applicationMethod: applicationMethod ?? this.applicationMethod,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      collections: collections ?? this.collections,
      collectionIds: collectionIds ?? this.collectionIds,
      subCollections: subCollections ?? this.subCollections,
      subCollectionIds: subCollectionIds ?? this.subCollectionIds,
      assignedCollections: assignedCollections ?? this.assignedCollections,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      variants: updatedVariants,
      ratings: ratings ?? this.ratings,
      totalReviews: totalReviews ?? this.totalReviews,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      productWeight: productWeight ?? this.productWeight,
      productWeightUnit: productWeightUnit ?? this.productWeightUnit,
      dimensions: dimensions ?? this.dimensions,
      productDimensions: productDimensions ?? this.productDimensions,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      variant: variant ?? _flatVariant,
      packSize: packSize ?? _flatPackSize,
      displayRate: displayRate ?? _flatDisplayRate,
      printedMrp: printedMrp ?? _flatPrintedMrp,
      costPrice: costPrice ?? _flatCostPrice,
      discountRs: discountRs ?? _flatDiscountRs,
      unit: unit ?? _flatUnit,
      gst: gst ?? _flatGst,
      discountPercentage: discountPercentage ?? _flatDiscountPercentage,
      shippedBy: shippedBy ?? _flatShippedBy,
      swg: swg ?? _flatSwg,
      stock: stock ?? _flatStock,
    );
  }



  @override
  List<Object?> get props => [
    id,
    sku,
    productCode,
    hsnCode,
    sellerId,
    title,
    technicalName,
    vendor,
    sellerName,
    category,
    packSize,
    unit,
    displayRate,
    printedMrp,
    costPrice,
    stock,
    isAvailable,
    isFeatured,
    status,
    isDeleted,
    version,
    productImages,
    assignedCollections,
    ratings,
    totalReviews,
  ];
}

// Internal BSON and JSON parsing utilities
double _parseDouble(dynamic val, [double defaultVal = 0.0]) {
  if (val == null) return defaultVal;
  if (val is num) return val.toDouble();
  final s = val.toString();
  final clean = s.replaceAll(RegExp(r'[^0-9.-]'), '');
  return double.tryParse(clean) ?? defaultVal;
}

int _parseInt(dynamic val, [int defaultVal = 0]) {
  if (val == null) return defaultVal;
  if (val is num) return val.toInt();
  final s = val.toString();
  final clean = s.replaceAll(RegExp(r'[^0-9-]'), '');
  return int.tryParse(clean) ?? defaultVal;
}

String _parseString(dynamic val, [String defaultVal = '']) {
  if (val == null) return defaultVal;
  final s = val.toString();
  final match = RegExp(r"""(?:ObjectId|ISODate)\(['"]?([^'"]+)['"]?\)""").firstMatch(s);
  if (match != null) return match.group(1) ?? s;
  return s;
}

List<String> _parseListString(dynamic val) {
  if (val == null) return [];
  if (val is List) {
    return val.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
  }
  if (val is String && val.isNotEmpty) {
    return val.split(RegExp(r'[,•;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
  return [];
}

/// Paginated products response data model
class ProductPageData extends Equatable {
  final List<Product> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  final int count;

  const ProductPageData({
    this.content = const [],
    this.page = 0,
    this.size = 20,
    this.totalElements = 0,
    this.totalPages = 0,
    this.first = true,
    this.last = true,
    this.count = 0,
  });

  factory ProductPageData.fromJson(dynamic json) {
    if (json == null) return const ProductPageData();
    if (json is List) {
      final products = json
          .whereType<Map>()
          .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return ProductPageData(
        content: products,
        page: 0,
        size: products.isNotEmpty ? products.length : 20,
        totalElements: products.length,
        totalPages: 1,
        first: true,
        last: true,
        count: products.length,
      );
    }
    if (json is! Map) return const ProductPageData();
    final map = Map<String, dynamic>.from(json);

    List<Product> products = [];
    final rawList = map['content'] ?? map['products'] ?? map['items'];
    if (rawList is List) {
      products = rawList
          .whereType<Map>()
          .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return ProductPageData(
      content: products,
      page: _parseInt(map['page'] ?? map['number'], 0),
      size: _parseInt(map['size'] ?? map['pageSize'], products.isNotEmpty ? products.length : 20),
      totalElements: _parseInt(map['totalElements'] ?? map['total'] ?? map['totalCount'], products.length),
      totalPages: _parseInt(map['totalPages'] ?? map['total_pages'], 1),
      first: map['first'] as bool? ?? true,
      last: map['last'] as bool? ?? true,
      count: _parseInt(map['count'] ?? map['numberOfElements'], products.length),
    );
  }

  /// Whether any product in this page has expired signed images
  bool get hasExpiredImages => content.any((p) => p.hasExpiredImages);

  Map<String, dynamic> toJson() => {
    'content': content.map((p) => p.toJson()).toList(),
    'page': page,
    'size': size,
    'totalElements': totalElements,
    'totalPages': totalPages,
    'first': first,
    'last': last,
    'count': count,
  };

  @override
  List<Object?> get props => [
    content,
    page,
    size,
    totalElements,
    totalPages,
    first,
    last,
    count,
  ];
}
