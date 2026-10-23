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
    if (json is Map<String, dynamic>) {
      return ProductDimensions(
        length: _parseDouble(json['length']),
        width: _parseDouble(json['width']),
        height: _parseDouble(json['height']),
        unit: json['unit']?.toString() ?? 'cm',
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

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    final id = _parseString(json['id'] ?? json['_id']);
    final displayOrder = _parseInt(json['displayOrder'], 0);

    final originalObj = _parseString(json['originalObjectName']);
    final midObj = _parseString(json['midObjectName']);
    final lowObj = _parseString(json['lowObjectName']);

    String mid = _parseString(json['midUrl']);
    String low = _parseString(json['lowUrl']);
    String original = _parseString(json['originalUrl']);

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
    final disc = json['discountRs'] != null
        ? _parseDouble(json['discountRs'])
        : ((mrp > disp) ? (mrp - disp) : 0.0);
    final discPct = json['discountPercentage'] != null
        ? _parseDouble(json['discountPercentage'])
        : (mrp > 0 ? (disc / mrp * 100) : 0.0);

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
      totalBaseQuantity: _parseInt(json['totalBaseQuantity'], 1000),
      totalBaseUnit: _parseString(json['totalBaseUnit'] ?? 'ml'),
      dimensions: ProductDimensions.fromJson(json['dimensions'] ?? json['Dimmensions']),
      displayRate: disp,
      printedMrp: mrp,
      costPrice: _parseDouble(json['costPrice'] ?? json['Cost Price']),
      discountRs: disc,
      gstPercentage: _parseDouble(json['gstPercentage'] ?? json['GST'] ?? 18.0),
      discountPercentage: discPct,
      stock: _parseInt(json['stock'] ?? json['Stock']),
      pricePerBaseUnit: _parseDouble(json['pricePerBaseUnit']),
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
  final bool isAvailable;
  final bool isFeatured;
  final List<ProductVariant> variants;
  final double ratings;
  final String refundPolicy;
  final double productWeight;
  final String productWeightUnit;
  final ProductDimensions productDimensions;
  final String status;
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
    required this.productCode,
    required this.hsnCode,
    this.sellerId = '',
    required this.title,
    required this.technicalName,
    required this.vendor,
    required this.description,
    required this.images,
    this.productImages = const [],
    required this.technicalContent,
    String features = '',
    List<String>? featuresList,
    String benefits = '',
    List<String>? benefitsList,
    required this.modeOfAction,
    String suitableCrop = '',
    List<String>? suitableCropsList,
    String targetPests = '',
    List<String>? targetPestsList,
    String targetDiseases = '',
    List<String>? targetDiseasesList,
    required this.dosage,
    required this.applicationMethod,
    required this.category,
    this.categoryId = '',
    this.collections = '',
    this.collectionIds = const [],
    this.subCollections = '',
    this.subCollectionIds = const [],
    required this.isAvailable,
    required this.isFeatured,
    this.variants = const [],
    required this.ratings,
    required this.refundPolicy,
    required this.productWeight,
    required this.productWeightUnit,
    this.productDimensions = const ProductDimensions(),
    this.status = 'ACTIVE',
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
  })  : featuresList = featuresList ?? (features.isNotEmpty ? [features] : const []),
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

  String get thumbnailUrl {
    if (productImages.isNotEmpty) {
      final first = productImages.first;
      if (first.lowUrl.isNotEmpty) return first.lowUrl;
      if (first.midUrl.isNotEmpty) return first.midUrl;
    }
    if (images.isNotEmpty) return images.first;
    return '';
  }

  String get primaryImageUrl {
    if (productImages.isNotEmpty) {
      final first = productImages.first;
      if (first.midUrl.isNotEmpty) return first.midUrl;
      if (first.lowUrl.isNotEmpty) return first.lowUrl;
    }
    if (images.isNotEmpty) return images.first;
    return '';
  }

  String get originalImageUrl {
    if (productImages.isNotEmpty) {
      final first = productImages.first;
      // If originalUrl has active pre-signed credentials or is an external CDN, prioritize it
      if (first.originalUrl.isNotEmpty &&
          (first.originalUrl.contains('X-Goog-Signature') ||
              first.originalUrl.contains('token') ||
              !first.originalUrl.contains('storage.googleapis.com'))) {
        return first.originalUrl;
      }
      // midUrl from backend is the 1200x1200px signed high-resolution asset
      if (first.midUrl.isNotEmpty) return first.midUrl;
      if (first.originalUrl.isNotEmpty) return first.originalUrl;
      if (first.lowUrl.isNotEmpty) return first.lowUrl;
    }
    if (images.isNotEmpty) return images.first;
    return '';
  }

  String get highResImageUrl {
    if (productImages.isNotEmpty) {
      final first = productImages.first;
      if (first.midUrl.isNotEmpty) return first.midUrl;
      if (first.originalUrl.isNotEmpty) return first.originalUrl;
      if (first.lowUrl.isNotEmpty) return first.lowUrl;
    }
    if (images.isNotEmpty) return images.first;
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
          .whereType<Map<String, dynamic>>()
          .map((v) => ProductVariant.fromJson(v))
          .toList();
    }

    final id = _parseString(json['_id'] ?? json['id']);
    final sku = _parseString(json['sku'] ?? json['productCode'] ?? json['Product Code']);
    final productCode = _parseString(json['productCode'] ?? json['Product Code'] ?? json['sku']);
    final hsnCode = _parseString(json['hsnCode'] ?? json['HSN Code']);
    final sellerId = _parseString(json['sellerId'] ?? json['seller_id']);
    final title = _parseString(json['title'] ?? json['Title']);
    final technicalName = _parseString(json['technicalName'] ?? json['Technical Name']);
    final vendor = _parseString(json['vendor'] ?? json['Vendor']);
    final description = _parseString(json['description'] ?? json['Description']);

    List<ProductImage> parsedProductImages = [];
    if (json['productImages'] is List) {
      parsedProductImages = (json['productImages'] as List)
          .whereType<Map<String, dynamic>>()
          .map((m) => ProductImage.fromJson(m))
          .toList();
    }

    var images = _parseListString(json['images'] ?? json['Images']);
    if (images.isEmpty && parsedProductImages.isNotEmpty) {
      images = parsedProductImages
          .map((img) => img.midUrl.isNotEmpty ? img.midUrl : img.lowUrl)
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
    final category = _parseString(json['category'] ?? json['Category']);
    final categoryId = _parseString(json['categoryId'] ?? json['category_id']);
    final collections = _parseString(json['collections'] ?? json['Collections']);
    final collectionIds = _parseListString(json['collectionIds'] ?? json['collection_ids']);
    final subCollections = _parseString(json['subCollections'] ?? json['Sub Collections']);
    final subCollectionIds = _parseListString(json['subCollectionIds'] ?? json['sub_collection_ids']);

    final isAvailable = json['isAvailable'] as bool? ?? json['Is_Available'] as bool? ?? true;
    final isFeatured = json['isFeatured'] as bool? ?? json['Is_featured'] as bool? ?? false;

    final ratings = _parseDouble(json['ratings'] ?? json['Ratings']);
    final refundPolicy = _parseString(json['refundPolicy'] ?? json['Refund Policy']);
    final productWeight = _parseDouble(json['productWeight'] ?? json['Product Weight']);
    final productWeightUnit = _parseString(json['productWeightUnit'] ?? json['Product Weight Unit'] ?? 'kg');
    final productDimensions = ProductDimensions.fromJson(json['dimensions'] ?? json['Dimmensions']);
    final status = _parseString(json['status'] ?? 'ACTIVE');
    final version = _parseInt(json['version'], 1);

    DateTime? createdAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.tryParse(_parseString(json['createdAt']));
    }
    DateTime? updatedAt;
    if (json['updatedAt'] != null) {
      updatedAt = DateTime.tryParse(_parseString(json['updatedAt']));
    }

    // Flat fallbacks if variants not provided
    final flatVariant = _parseString(json['variant'] ?? json['Varient']);
    final flatPackSize = _parseString(json['packSize'] ?? json['Pack Size']);
    final flatDisplayRate = _parseDouble(json['displayRate'] ?? json['Display Rate']);
    final flatPrintedMrp = _parseDouble(json['printedMrp'] ?? json['Printed MRP']);
    final flatCostPrice = _parseDouble(json['costPrice'] ?? json['Cost Price']);
    final flatDiscountRs = _parseDouble(json['discountRs'] ?? json['DiscountRS']);
    final flatUnit = _parseString(json['unit'] ?? json['Unit']);
    final flatGst = _parseDouble(json['gst'] ?? json['GST'] ?? 18.0);
    final flatDiscountPct = _parseDouble(json['discountPercentage'] ?? json['Discount Percentage']);
    final flatShippedBy = _parseString(json['shippedBy'] ?? json['Shipped By'] ?? 'Seller');
    final flatSwg = _parseString(json['swg'] ?? json['SWG']);
    final flatStock = _parseInt(json['stock'] ?? json['Stock']);
    final flatDims = _parseString(json['dimensions'] ?? json['Dimmensions']);

    return Product(
      id: id,
      sku: sku,
      productCode: productCode,
      hsnCode: hsnCode,
      sellerId: sellerId,
      title: title,
      technicalName: technicalName,
      vendor: vendor,
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
      isAvailable: isAvailable,
      isFeatured: isFeatured,
      variants: parsedVariants,
      ratings: ratings,
      refundPolicy: refundPolicy,
      productWeight: productWeight,
      productWeightUnit: productWeightUnit,
      productDimensions: productDimensions,
      status: status,
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
    'dimensions': productDimensions.toJson(),
    'isAvailable': isAvailable,
    'isFeatured': isFeatured,
    'variants': variants.map((v) => v.toJson()).toList(),
    'ratings': ratings,
    'refundPolicy': refundPolicy,
    'productWeight': productWeight,
    'productWeightUnit': productWeightUnit,
    'status': status,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'version': version,
  };

  /// Exports in standard 38-field flat JSON for table exports and CSV/Excel interchange
  Map<String, dynamic> toJson() => {
    'Product Code': productCode,
    'HSN Code': hsnCode,
    'Title': title,
    'Technical Name': technicalName,
    'Vendor': vendor,
    'Description': description,
    'Images': images,
    'ProductImages': productImages.map((p) => p.toJson()).toList(),
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
    'Collections': collections,
    'Sub Collections': subCollections,
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
    'Ratings': ratings,
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
    String? refundPolicy,
    double? productWeight,
    String? productWeightUnit,
    String? dimensions,
    ProductDimensions? productDimensions,
    String? status,
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
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      variants: updatedVariants,
      ratings: ratings ?? this.ratings,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      productWeight: productWeight ?? this.productWeight,
      productWeightUnit: productWeightUnit ?? this.productWeightUnit,
      dimensions: dimensions ?? this.dimensions,
      productDimensions: productDimensions ?? this.productDimensions,
      status: status ?? this.status,
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
    version,
    productImages,
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

  factory ProductPageData.fromJson(Map<String, dynamic> json) {
    List<Product> products = [];
    if (json['content'] is List) {
      products = (json['content'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => Product.fromJson(item))
          .toList();
    }

    return ProductPageData(
      content: products,
      page: _parseInt(json['page'], 0),
      size: _parseInt(json['size'], 20),
      totalElements: _parseInt(json['totalElements'], products.length),
      totalPages: _parseInt(json['totalPages'], 1),
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
      count: _parseInt(json['count'], products.length),
    );
  }

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
