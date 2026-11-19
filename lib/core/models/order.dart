import 'package:equatable/equatable.dart';

/// Reference Bank Detail for Order Payment & Settlement
class OrderBankDetail extends Equatable {
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String utrNumber;
  final String accountHolderName;
  final String branch;

  const OrderBankDetail({
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.utrNumber = '',
    this.accountHolderName = '',
    this.branch = '',
  });

  factory OrderBankDetail.fromJson(Map<String, dynamic> json) {
    return OrderBankDetail(
      bankName: json['bankName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      utrNumber: json['utrNumber']?.toString() ?? '',
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'bankName': bankName,
    'accountNumber': accountNumber,
    'ifscCode': ifscCode,
    'utrNumber': utrNumber,
    'accountHolderName': accountHolderName,
    'branch': branch,
  };

  @override
  List<Object?> get props => [
    bankName,
    accountNumber,
    ifscCode,
    utrNumber,
    accountHolderName,
    branch,
  ];
}

/// Actual Order Product / Line Item
class OrderItem extends Equatable {
  final String id;
  final String productId;
  final String productCode;
  final String title;
  final String technicalName;
  final String category;
  final int packSize;
  final String unit;
  final String packUnit;
  final int quantity;
  final double unitPrice;
  final double mrp;
  final double gstPercentage;
  final double totalPrice;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productCode,
    required this.title,
    this.technicalName = '',
    required this.category,
    required this.packSize,
    required this.unit,
    this.packUnit = 'bottle',
    required this.quantity,
    required this.unitPrice,
    required this.mrp,
    this.gstPercentage = 18.0,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      technicalName: json['technicalName']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      packSize: (json['packSize'] as num?)?.toInt() ?? 1,
      unit: json['unit']?.toString() ?? 'ml',
      packUnit: json['packUnit']?.toString() ?? 'bottle',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
      gstPercentage: (json['gstPercentage'] as num?)?.toDouble() ?? 18.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productCode': productCode,
    'title': title,
    'technicalName': technicalName,
    'category': category,
    'packSize': packSize,
    'unit': unit,
    'packUnit': packUnit,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'mrp': mrp,
    'gstPercentage': gstPercentage,
    'totalPrice': totalPrice,
  };

  @override
  List<Object?> get props => [
    id,
    productId,
    productCode,
    title,
    technicalName,
    category,
    packSize,
    unit,
    packUnit,
    quantity,
    unitPrice,
    mrp,
    gstPercentage,
    totalPrice,
  ];
}

/// Seller Details associated with the Order
class OrderSellerDetail extends Equatable {
  final String sellerId;
  final String tradeName;
  final String legalEntityName;
  final String gstin;
  final String panNumber;
  final String contactPhone;
  final String contactEmail;
  final String warehouseAddress;
  final String city;
  final String state;
  final String pincode;

  const OrderSellerDetail({
    required this.sellerId,
    required this.tradeName,
    this.legalEntityName = '',
    this.gstin = '',
    this.panNumber = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.warehouseAddress = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
  });

  factory OrderSellerDetail.fromJson(Map<String, dynamic> json) {
    return OrderSellerDetail(
      sellerId: json['sellerId']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? '',
      legalEntityName: json['legalEntityName']?.toString() ?? '',
      gstin: json['gstin']?.toString() ?? '',
      panNumber: json['panNumber']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString() ?? '',
      contactEmail: json['contactEmail']?.toString() ?? '',
      warehouseAddress: json['warehouseAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'sellerId': sellerId,
    'tradeName': tradeName,
    'legalEntityName': legalEntityName,
    'gstin': gstin,
    'panNumber': panNumber,
    'contactPhone': contactPhone,
    'contactEmail': contactEmail,
    'warehouseAddress': warehouseAddress,
    'city': city,
    'state': state,
    'pincode': pincode,
  };

  @override
  List<Object?> get props => [
    sellerId,
    tradeName,
    legalEntityName,
    gstin,
    panNumber,
    contactPhone,
    contactEmail,
    warehouseAddress,
    city,
    state,
    pincode,
  ];
}

/// Shipping and Billing Address
class OrderAddress extends Equatable {
  final String recipientName;
  final String companyName;
  final String phone;
  final String email;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String gstin;
  final String carrier;
  final String trackingNumber;
  final String deliveryStatus;

  const OrderAddress({
    required this.recipientName,
    this.companyName = '',
    required this.phone,
    this.email = '',
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.gstin = '',
    this.carrier = '',
    this.trackingNumber = '',
    this.deliveryStatus = '',
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      recipientName: json['recipientName']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      addressLine: json['addressLine']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      gstin: json['gstin']?.toString() ?? '',
      carrier: json['carrier']?.toString() ?? '',
      trackingNumber: json['trackingNumber']?.toString() ?? '',
      deliveryStatus: json['deliveryStatus']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'recipientName': recipientName,
    'companyName': companyName,
    'phone': phone,
    'email': email,
    'addressLine': addressLine,
    'city': city,
    'state': state,
    'pincode': pincode,
    'gstin': gstin,
    'carrier': carrier,
    'trackingNumber': trackingNumber,
    'deliveryStatus': deliveryStatus,
  };

  @override
  List<Object?> get props => [
    recipientName,
    companyName,
    phone,
    email,
    addressLine,
    city,
    state,
    pincode,
    gstin,
    carrier,
    trackingNumber,
    deliveryStatus,
  ];
}

/// Main Agricultural Marketplace Order
class MarketplaceOrder extends Equatable {
  final String id;
  final String orderNumber;
  final String paymentMethod;
  final String paymentStatus;
  final String company;
  final String sellerName;
  final OrderBankDetail referenceBankDetail;
  final DateTime paidDate;
  final DateTime orderDate;
  final String orderStatus;
  final List<OrderItem> items;
  final OrderSellerDetail sellerDetails;
  final OrderAddress shippingAddress;
  final OrderAddress billingAddress;
  final double subtotal;
  final double gstAmount;
  final double shippingFee;
  final double discountAmount;
  final double grandTotal;
  final String labelReference;
  final String rtoReason;
  final bool rtoRestocked;

  bool get hasLabel => labelReference.trim().isNotEmpty;

  const MarketplaceOrder({
    required this.id,
    required this.orderNumber,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.company,
    required this.sellerName,
    required this.referenceBankDetail,
    required this.paidDate,
    required this.orderDate,
    required this.orderStatus,
    required this.items,
    required this.sellerDetails,
    required this.shippingAddress,
    required this.billingAddress,
    required this.subtotal,
    required this.gstAmount,
    required this.shippingFee,
    required this.discountAmount,
    required this.grandTotal,
    this.labelReference = '',
    this.rtoReason = '',
    this.rtoRestocked = false,
  });

  factory MarketplaceOrder.fromBackendJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    int toInt(dynamic v, [int fallback = 0]) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    DateTime parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      }
      if (v is List && v.length >= 3) {
        return DateTime(
          toInt(v[0], DateTime.now().year),
          toInt(v[1], 1),
          toInt(v[2], 1),
          v.length > 3 ? toInt(v[3]) : 0,
          v.length > 4 ? toInt(v[4]) : 0,
          v.length > 5 ? toInt(v[5]) : 0,
        );
      }
      return DateTime.now();
    }

    final customerSnap = json['customerSnapshot'] is Map
        ? Map<String, dynamic>.from(json['customerSnapshot'] as Map)
        : <String, dynamic>{};
    final shippingMap = json['shippingAddress'] is Map
        ? Map<String, dynamic>.from(json['shippingAddress'] as Map)
        : <String, dynamic>{};
    final billingMap = json['billingAddress'] is Map
        ? Map<String, dynamic>.from(json['billingAddress'] as Map)
        : shippingMap;
    final finMap = json['financialSummary'] is Map
        ? Map<String, dynamic>.from(json['financialSummary'] as Map)
        : <String, dynamic>{};
    final paymentMap = json['payment'] is Map
        ? Map<String, dynamic>.from(json['payment'] as Map)
        : <String, dynamic>{};

    final fulfillmentsRaw = json['sellerFulfillments'] is List
        ? json['sellerFulfillments'] as List
        : const [];
    final firstGroup = fulfillmentsRaw.isNotEmpty && fulfillmentsRaw.first is Map
        ? Map<String, dynamic>.from(fulfillmentsRaw.first as Map)
        : <String, dynamic>{};
    final sellerSnap = firstGroup['sellerSnapshot'] is Map
        ? Map<String, dynamic>.from(firstGroup['sellerSnapshot'] as Map)
        : <String, dynamic>{};
    final shipmentsRaw = firstGroup['shipments'] is List
        ? firstGroup['shipments'] as List
        : const [];
    final firstShipment = shipmentsRaw.isNotEmpty && shipmentsRaw.first is Map
        ? Map<String, dynamic>.from(shipmentsRaw.first as Map)
        : <String, dynamic>{};

    final rawItems = json['items'] is List ? json['items'] as List : const [];
    final parsedItems = <OrderItem>[];
    String? fallbackSellerName;
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final prodSnap = m['productSnapshot'] is Map
          ? Map<String, dynamic>.from(m['productSnapshot'] as Map)
          : <String, dynamic>{};
      final varSnap = m['variantSnapshot'] is Map
          ? Map<String, dynamic>.from(m['variantSnapshot'] as Map)
          : <String, dynamic>{};
      if (fallbackSellerName == null && (m['sellerName']?.toString().trim().isNotEmpty ?? false)) {
        fallbackSellerName = m['sellerName'].toString().trim();
      }
      final qty = toInt(m['quantity'], 1);
      final unitPrice = toDouble(m['unitPrice']);
      final lineTotal = toDouble(m['lineTotal']);
      parsedItems.add(
        OrderItem(
          id: m['itemOrderId']?.toString() ?? m['id']?.toString() ?? '',
          productId: m['productId']?.toString() ?? '',
          productCode: (m['variantSku']?.toString().isNotEmpty ?? false)
              ? m['variantSku'].toString()
              : (m['productCode']?.toString() ?? m['productSku']?.toString() ?? ''),
          title: prodSnap['title']?.toString().isNotEmpty == true
              ? prodSnap['title'].toString()
              : (m['title']?.toString() ?? 'Product'),
          technicalName: prodSnap['variantLabel']?.toString() ?? varSnap['label']?.toString() ?? '',
          category: m['categoryId']?.toString() ?? '',
          packSize: toInt(varSnap['packSize'], 1),
          unit: varSnap['unit']?.toString() ?? varSnap['packSizeUnit']?.toString() ?? '',
          packUnit: varSnap['label']?.toString() ?? 'pack',
          quantity: qty,
          unitPrice: unitPrice,
          mrp: toDouble(m['listPrice']) > 0 ? toDouble(m['listPrice']) : unitPrice,
          gstPercentage: 0.0,
          totalPrice: lineTotal > 0 ? lineTotal : (unitPrice * qty),
        ),
      );
    }

    final sellerTradeName = (sellerSnap['tradeName']?.toString().trim().isNotEmpty ?? false)
        ? sellerSnap['tradeName'].toString().trim()
        : (fallbackSellerName ?? 'Platform / EBS');

    String stateFromPincode(String pin) {
      final clean = pin.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length < 2) return '';
      final p2 = int.tryParse(clean.substring(0, 2));
      if (p2 == null) return '';
      if (p2 == 11) return 'Delhi';
      if (p2 >= 12 && p2 <= 13) return 'Haryana';
      if (p2 >= 14 && p2 <= 16) return 'Punjab';
      if (p2 == 17) return 'Himachal Pradesh';
      if (p2 >= 18 && p2 <= 19) return 'Jammu and Kashmir';
      if (p2 >= 20 && p2 <= 28) return 'Uttar Pradesh';
      if (p2 >= 30 && p2 <= 34) return 'Rajasthan';
      if (p2 >= 36 && p2 <= 39) return 'Gujarat';
      if (p2 >= 40 && p2 <= 44) return 'Maharashtra';
      if (p2 >= 45 && p2 <= 48) return 'Madhya Pradesh';
      if (p2 == 49) return 'Chhattisgarh';
      if (p2 >= 50 && p2 <= 53) return 'Andhra Pradesh';
      if (p2 >= 56 && p2 <= 59) return 'Karnataka';
      if (p2 >= 60 && p2 <= 64) return 'Tamil Nadu';
      if (p2 >= 67 && p2 <= 69) return 'Kerala';
      if (p2 >= 70 && p2 <= 74) return 'West Bengal';
      if (p2 >= 75 && p2 <= 77) return 'Odisha';
      if (p2 == 78) return 'Assam';
      if (p2 == 79) return 'North East';
      if (p2 >= 80 && p2 <= 85) return 'Bihar';
      return '';
    }

    OrderAddress parseAddress(Map<String, dynamic> m) {
      final line1 = m['villageArea']?.toString() ??
          m['addressLine1']?.toString() ??
          m['line1']?.toString() ??
          m['street']?.toString() ??
          '';
      final line2 = m['address2']?.toString() ??
          m['addressLine2']?.toString() ??
          m['line2']?.toString() ??
          '';
      final combinedLine = [line1, line2].where((s) => s.trim().isNotEmpty).join(', ');
      final fullName = [
        customerSnap['firstName']?.toString() ?? '',
        customerSnap['lastName']?.toString() ?? '',
      ].where((s) => s.trim().isNotEmpty).join(' ');
      final recipient = (m['recipientName']?.toString().trim().isNotEmpty ?? false)
          ? m['recipientName'].toString().trim()
          : ((m['name']?.toString().trim().isNotEmpty ?? false)
              ? m['name'].toString().trim()
              : (customerSnap['name']?.toString().trim().isNotEmpty == true
                  ? customerSnap['name'].toString().trim()
                  : (fullName.isNotEmpty ? fullName : 'Customer')));
      final pin = m['pincode']?.toString() ?? m['postalCode']?.toString() ?? m['zip']?.toString() ?? '';
      final city = (m['cityTehsil']?.toString().trim().isNotEmpty ?? false)
          ? m['cityTehsil'].toString().trim()
          : ((m['city']?.toString().trim().isNotEmpty ?? false)
              ? m['city'].toString().trim()
              : (m['district']?.toString().trim() ?? ''));
      final rawState = m['state']?.toString().trim() ?? '';
      final state = rawState.isNotEmpty ? rawState : stateFromPincode(pin);
      return OrderAddress(
        recipientName: recipient,
        phone: (m['phoneNumber']?.toString().trim().isNotEmpty ?? false)
            ? m['phoneNumber'].toString().trim()
            : (m['phone']?.toString().trim().isNotEmpty == true
                ? m['phone'].toString().trim()
                : (customerSnap['phoneNumber']?.toString() ?? '')),
        email: customerSnap['email']?.toString() ?? m['email']?.toString() ?? '',
        addressLine: combinedLine,
        city: city,
        state: state,
        pincode: pin,
        carrier: firstShipment['courierName']?.toString() ?? firstShipment['carrier']?.toString() ?? '',
        trackingNumber: firstShipment['awbNumber']?.toString() ?? firstShipment['trackingNumber']?.toString() ?? '',
        deliveryStatus: firstGroup['status']?.toString() ?? json['overallStatus']?.toString() ?? 'CONFIRMED',
      );
    }

    final rawPayType = paymentMap['paymentType']?.toString().toUpperCase() ?? 'PREPAID';
    final rawPayStatus = paymentMap['status']?.toString().toUpperCase() ?? 'CREATED';
    final normalizedPayStatus = rawPayStatus == 'CAPTURED' || rawPayStatus == 'PAID'
        ? 'PAID'
        : (rawPayStatus == 'REFUNDED'
            ? 'REFUNDED'
            : (rawPayStatus == 'FAILED' ? 'FAILED' : 'PENDING'));
    final paymentLabel = paymentMap['provider']?.toString().isNotEmpty == true
        ? '${paymentMap['provider']} ($rawPayType)'
        : rawPayType;

    final gmv = toDouble(finMap['grossMerchandiseValue']);
    final discount = toDouble(finMap['discountTotal']);
    final grandTotal = toDouble(finMap['currentOrderTotal']) > 0
        ? toDouble(finMap['currentOrderTotal'])
        : (toDouble(finMap['originalOrderTotal']) > 0
            ? toDouble(finMap['originalOrderTotal'])
            : parsedItems.fold<double>(0.0, (sum, it) => sum + it.totalPrice));
    final placedAt = parseDate(json['placedAt'] ?? json['createdAt']);

    return MarketplaceOrder(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      paymentMethod: paymentLabel,
      paymentStatus: normalizedPayStatus,
      company: json['checkoutGroupId']?.toString().isNotEmpty == true
          ? json['checkoutGroupId'].toString()
          : 'EBS Krishi Dukaan',
      sellerName: sellerTradeName,
      referenceBankDetail: OrderBankDetail(
        bankName: paymentMap['provider']?.toString() ?? 'FASTRR',
        utrNumber: paymentMap['providerOrderId']?.toString() ?? '',
      ),
      paidDate: placedAt,
      orderDate: placedAt,
      orderStatus: json['overallStatus']?.toString() ?? 'CONFIRMED',
      items: parsedItems,
      sellerDetails: OrderSellerDetail(
        sellerId: firstGroup['sellerId']?.toString() ?? '',
        tradeName: sellerTradeName,
        gstin: sellerSnap['gstNumber']?.toString() ?? '',
        contactPhone: sellerSnap['contactPhone']?.toString() ?? '',
        pincode: sellerSnap['dispatchPincode']?.toString() ?? '',
      ),
      shippingAddress: parseAddress(shippingMap),
      billingAddress: parseAddress(billingMap),
      subtotal: gmv > 0 ? gmv : grandTotal,
      gstAmount: 0.0,
      shippingFee: 0.0,
      discountAmount: discount,
      grandTotal: grandTotal,
      labelReference: firstShipment['labelReference']?.toString() ?? '',
      rtoReason: firstShipment['rtoReason']?.toString() ?? '',
      rtoRestocked: firstShipment['rtoRestocked'] == true,
    );
  }

  MarketplaceOrder copyWith({
    String? id,
    String? orderNumber,
    String? paymentMethod,
    String? paymentStatus,
    String? company,
    String? sellerName,
    OrderBankDetail? referenceBankDetail,
    DateTime? paidDate,
    DateTime? orderDate,
    String? orderStatus,
    List<OrderItem>? items,
    OrderSellerDetail? sellerDetails,
    OrderAddress? shippingAddress,
    OrderAddress? billingAddress,
    double? subtotal,
    double? gstAmount,
    double? shippingFee,
    double? discountAmount,
    double? grandTotal,
    String? labelReference,
    String? rtoReason,
    bool? rtoRestocked,
  }) {
    return MarketplaceOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      company: company ?? this.company,
      sellerName: sellerName ?? this.sellerName,
      referenceBankDetail: referenceBankDetail ?? this.referenceBankDetail,
      paidDate: paidDate ?? this.paidDate,
      orderDate: orderDate ?? this.orderDate,
      orderStatus: orderStatus ?? this.orderStatus,
      items: items ?? this.items,
      sellerDetails: sellerDetails ?? this.sellerDetails,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      billingAddress: billingAddress ?? this.billingAddress,
      subtotal: subtotal ?? this.subtotal,
      gstAmount: gstAmount ?? this.gstAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      discountAmount: discountAmount ?? this.discountAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      labelReference: labelReference ?? this.labelReference,
      rtoReason: rtoReason ?? this.rtoReason,
      rtoRestocked: rtoRestocked ?? this.rtoRestocked,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    paymentMethod,
    paymentStatus,
    company,
    sellerName,
    referenceBankDetail,
    paidDate,
    orderDate,
    orderStatus,
    items,
    sellerDetails,
    shippingAddress,
    billingAddress,
    subtotal,
    gstAmount,
    shippingFee,
    discountAmount,
    grandTotal,
  ];
}

/// Realistic Mock Agricultural Orders
class MockOrders {
  static List<MarketplaceOrder> get sampleOrders => [
    MarketplaceOrder(
      id: 'ord_001',
      orderNumber: 'ORD-AGRI-9921',
      paymentMethod: 'Razorpay UPI / QR Transfer',
      paymentStatus: 'PAID',
      company: 'AgriBegri Marketplace Pvt Ltd',
      sellerName: 'Krishi Kranti Organics',
      referenceBankDetail: const OrderBankDetail(
        bankName: 'HDFC Bank Ltd',
        accountNumber: '50200084920194',
        ifscCode: 'HDFC0000240',
        utrNumber: 'HDFC984210984124',
        accountHolderName: 'Krishi Kranti Organics Private Limited',
        branch: 'APMC Market Yard Branch, Pune',
      ),
      orderDate: DateTime(2026, 9, 29, 13, 10),
      paidDate: DateTime(2026, 9, 29, 13, 15),
      orderStatus: 'READY TO DISPATCH',
      items: const [
        OrderItem(
          id: 'item_001',
          productId: '6abbb7a337a9025b8c51a7e5',
          productCode: 'TEMP-CODE-001',
          title: 'Crop Protection Insecticide Sample (Chlorpyrifos 20% EC)',
          technicalName: 'Synthetic test compound A',
          category: 'Insecticides',
          packSize: 250,
          unit: 'ml',
          packUnit: 'bottle',
          quantity: 20,
          unitPrice: 399.0,
          mrp: 499.0,
          gstPercentage: 18.0,
          totalPrice: 7980.0,
        ),
        OrderItem(
          id: 'item_002',
          productId: 'prod_004',
          productCode: 'AGRI-BIO-101',
          title: 'Bio-NPK Consortium Bio Stimulant 1L',
          technicalName: 'Azotobacter, PSB & KMB Liquid Bacterial Culture',
          category: 'Bio Stimulants',
          packSize: 1,
          unit: 'L',
          packUnit: 'can',
          quantity: 15,
          unitPrice: 549.0,
          mrp: 750.0,
          gstPercentage: 5.0,
          totalPrice: 8235.0,
        ),
      ],
      sellerDetails: const OrderSellerDetail(
        sellerId: '6ab4ada822033f1670582bda',
        tradeName: 'Krishi Kranti Organics',
        legalEntityName: 'Krishi Kranti Organics Private Limited',
        gstin: '27AABCK9821P1Z4',
        panNumber: 'AABCK9821P',
        contactPhone: '+91 98220 11928',
        contactEmail: 'dispatch@krishikrantiorganics.com',
        warehouseAddress: 'Plot 42, Agro Industrial Estate, Hadapsar',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411028',
      ),
      shippingAddress: const OrderAddress(
        recipientName: 'Rameshwar Patel (Dealer)',
        companyName: 'Kisan Seva Kendra Agency',
        phone: '+91 98251 44321',
        email: 'rameshwar.patel@kisanmail.com',
        addressLine: 'Plot 14-B, Near APMC Krishi Mandi, Station Road',
        city: 'Nashik',
        state: 'Maharashtra',
        pincode: '422003',
        carrier: 'Delhivery Surface Express',
        trackingNumber: 'DEL9842109824',
        deliveryStatus: 'Warehouse Packed - Ready for Courier Pickup',
      ),
      billingAddress: const OrderAddress(
        recipientName: 'Kisan Seva Kendra Agency',
        companyName: 'Kisan Seva Kendra Agro Agency',
        phone: '+91 98251 44321',
        email: 'accounts@kisansevakendra.in',
        addressLine: 'Shop 12-14, APMC Market Yard, Station Road',
        city: 'Nashik',
        state: 'Maharashtra',
        pincode: '422003',
        gstin: '27AABCK9821P1Z4',
      ),
      subtotal: 16215.0,
      gstAmount: 1848.0,
      shippingFee: 450.0,
      discountAmount: 500.0,
      grandTotal: 18013.0,
    ),
    MarketplaceOrder(
      id: 'ord_002',
      orderNumber: 'ORD-AGRI-9918',
      paymentMethod: 'Direct Bank Transfer (NEFT/RTGS)',
      paymentStatus: 'PAID',
      company: 'AgriBegri Marketplace Pvt Ltd',
      sellerName: 'Bharat Agro Chemicals Ltd',
      referenceBankDetail: const OrderBankDetail(
        bankName: 'State Bank of India',
        accountNumber: '38192049182',
        ifscCode: 'SBIN0004128',
        utrNumber: 'SBIN99281741094',
        accountHolderName: 'Bharat Agro Chemicals Ltd Current Account',
        branch: 'GIDC Industrial Area Branch, Ankleshwar',
      ),
      orderDate: DateTime(2026, 9, 28, 11, 20),
      paidDate: DateTime(2026, 9, 28, 12, 05),
      orderStatus: 'IN TRANSIT',
      items: const [
        OrderItem(
          id: 'item_003',
          productId: 'prod_002',
          productCode: 'AGRI-COT-990',
          title: 'Hybrid Bt-Cotton BG-II Seeds 450g',
          technicalName: 'Bollgard-II Transgenic Cotton Seed Hybrid',
          category: 'Seeds',
          packSize: 450,
          unit: 'g',
          packUnit: 'pouch',
          quantity: 80,
          unitPrice: 857.0,
          mrp: 930.0,
          gstPercentage: 0.0,
          totalPrice: 68560.0,
        ),
      ],
      sellerDetails: const OrderSellerDetail(
        sellerId: '6ab4ada822033f1670582bdb',
        tradeName: 'Bharat Agro Chemicals Ltd',
        legalEntityName: 'Bharat Agro Chemicals Public Limited',
        gstin: '24AAACB9012M1Z2',
        panNumber: 'AAACB9012M',
        contactPhone: '+91 94280 33411',
        contactEmail: 'logistics@bharatagrochem.com',
        warehouseAddress: 'Phase II, Plot 89-91, GIDC Estate',
        city: 'Ankleshwar',
        state: 'Gujarat',
        pincode: '393002',
      ),
      shippingAddress: const OrderAddress(
        recipientName: 'Govindbhai Patel',
        companyName: 'Shree Agro Traders',
        phone: '+91 98980 22345',
        email: 'govind.patel@shreeagro.com',
        addressLine: 'Shop 8-10, Grain Market Road, Dhoraji',
        city: 'Rajkot',
        state: 'Gujarat',
        pincode: '360410',
        carrier: 'V-Trans Logistics Cargo',
        trackingNumber: 'VTR88291049',
        deliveryStatus: 'Departed Transit Hub Ahmedabad - In Transit',
      ),
      billingAddress: const OrderAddress(
        recipientName: 'Shree Agro Traders',
        companyName: 'Shree Agro Traders Proprietary Firm',
        phone: '+91 98980 22345',
        email: 'govind.patel@shreeagro.com',
        addressLine: 'Shop 8-10, Grain Market Road, Dhoraji',
        city: 'Rajkot',
        state: 'Gujarat',
        pincode: '360410',
        gstin: '24AADCS8821M1Z1',
      ),
      subtotal: 68560.0,
      gstAmount: 0.0,
      shippingFee: 1200.0,
      discountAmount: 1000.0,
      grandTotal: 68760.0,
    ),
    MarketplaceOrder(
      id: 'ord_003',
      orderNumber: 'ORD-AGRI-9904',
      paymentMethod: 'Razorpay NetBanking (ICICI)',
      paymentStatus: 'PAID',
      company: 'AgriBegri Marketplace Pvt Ltd',
      sellerName: 'Mahyco Seeds India Ltd',
      referenceBankDetail: const OrderBankDetail(
        bankName: 'ICICI Bank Ltd',
        accountNumber: '001905008491',
        ifscCode: 'ICIC0000019',
        utrNumber: 'ICIC29104928172',
        accountHolderName: 'Mahyco Seeds Commercial Payouts',
        branch: 'Nariman Point Branch, Mumbai',
      ),
      orderDate: DateTime(2026, 9, 27, 16, 45),
      paidDate: DateTime(2026, 9, 27, 16, 50),
      orderStatus: 'DELIVERED',
      items: const [
        OrderItem(
          id: 'item_004',
          productId: 'prod_003',
          productCode: 'AGRI-WSF-1919',
          title: 'Water Soluble 19-19-19 NPK Foliar Fertilizer 1kg',
          technicalName: 'Fully Water Soluble Nitrogen, Phosphate & Potash',
          category: 'Fertilizers',
          packSize: 1,
          unit: 'kg',
          packUnit: 'bag',
          quantity: 60,
          unitPrice: 175.0,
          mrp: 230.0,
          gstPercentage: 5.0,
          totalPrice: 10500.0,
        ),
      ],
      sellerDetails: const OrderSellerDetail(
        sellerId: '6ab4ada822033f1670582bdc',
        tradeName: 'Mahyco Seeds India Ltd',
        legalEntityName: 'Maharashtra Hybrid Seeds Company Private Limited',
        gstin: '27AAACM1234N1Z8',
        panNumber: 'AAACM1234N',
        contactPhone: '+91 22 2288 4400',
        contactEmail: 'sales@mahyco.com',
        warehouseAddress: 'Sardar Patel Road, Jalna Industrial Hub',
        city: 'Jalna',
        state: 'Maharashtra',
        pincode: '431203',
      ),
      shippingAddress: const OrderAddress(
        recipientName: 'Mukesh Choudhary',
        companyName: 'Annadata Krishi Kendra',
        phone: '+91 97550 88910',
        email: 'mukesh@annadatapradesh.org',
        addressLine: 'Agro Commercial Complex, Dewas Naka',
        city: 'Indore',
        state: 'Madhya Pradesh',
        pincode: '452010',
        carrier: 'BlueDart Surface Express',
        trackingNumber: 'BLU773820194',
        deliveryStatus: 'Delivered and Signed by Mukesh Choudhary',
      ),
      billingAddress: const OrderAddress(
        recipientName: 'Annadata Krishi Kendra',
        companyName: 'Annadata Krishi Kendra Agro Traders',
        phone: '+91 97550 88910',
        email: 'billing@annadatapradesh.org',
        addressLine: 'Agro Commercial Complex, Dewas Naka',
        city: 'Indore',
        state: 'Madhya Pradesh',
        pincode: '452010',
        gstin: '23AACCA9918P1Z5',
      ),
      subtotal: 10500.0,
      gstAmount: 525.0,
      shippingFee: 350.0,
      discountAmount: 200.0,
      grandTotal: 11175.0,
    ),
    MarketplaceOrder(
      id: 'ord_004',
      orderNumber: 'ORD-AGRI-9882',
      paymentMethod: 'Cash on Delivery (COD Verified)',
      paymentStatus: 'PENDING',
      company: 'AgriBegri Marketplace Pvt Ltd',
      sellerName: 'Godrej Agrovet Ltd',
      referenceBankDetail: const OrderBankDetail(
        bankName: 'Axis Bank Ltd',
        accountNumber: '91802008491829',
        ifscCode: 'UTIB0000084',
        utrNumber: 'COD-SETTLEMENT-PENDING',
        accountHolderName: 'Godrej Agrovet Agri Marketplace Escrow',
        branch: 'Pirojshanagar Branch, Vikhroli, Mumbai',
      ),
      orderDate: DateTime(2026, 9, 30, 09, 15),
      paidDate: DateTime(2026, 9, 30, 09, 15),
      orderStatus: 'PROCESSING',
      items: const [
        OrderItem(
          id: 'item_005',
          productId: 'prod_005',
          productCode: 'AGRI-FUNG-M45',
          title: 'Systemic & Contact Broad Spectrum Fungicide 500g',
          technicalName: 'Mancozeb 75% WP Preventive Agricultural Formulation',
          category: 'Fungicides',
          packSize: 500,
          unit: 'g',
          packUnit: 'pack',
          quantity: 25,
          unitPrice: 320.0,
          mrp: 410.0,
          gstPercentage: 18.0,
          totalPrice: 8000.0,
        ),
      ],
      sellerDetails: const OrderSellerDetail(
        sellerId: '6ab4ada822033f1670582bdd',
        tradeName: 'Godrej Agrovet Ltd',
        legalEntityName: 'Godrej Agrovet Limited Crop Protection Division',
        gstin: '27AAACG0023K1Z1',
        panNumber: 'AAACG0023K',
        contactPhone: '+91 22 2518 8010',
        contactEmail: 'cropprotection@godrejagrovet.com',
        warehouseAddress: 'Godrej One, Eastern Express Highway',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400079',
      ),
      shippingAddress: const OrderAddress(
        recipientName: 'Harishankar Verma (Farmer)',
        companyName: 'Verma Integrated Farms',
        phone: '+91 94150 99882',
        email: 'harishankar.verma@agrokrishi.com',
        addressLine: 'Village Koirajpur, Post Harhua, Babatpur Road',
        city: 'Varanasi',
        state: 'Uttar Pradesh',
        pincode: '221105',
        carrier: 'India Post Speed Post Cargo',
        trackingNumber: 'EK992810481IN',
        deliveryStatus: 'Processing in Origin Warehouse - Awaiting Dispatch',
      ),
      billingAddress: const OrderAddress(
        recipientName: 'Harishankar Verma',
        companyName: 'Individual Farmer',
        phone: '+91 94150 99882',
        email: 'harishankar.verma@agrokrishi.com',
        addressLine: 'Village Koirajpur, Post Harhua, Babatpur Road',
        city: 'Varanasi',
        state: 'Uttar Pradesh',
        pincode: '221105',
        gstin: '',
      ),
      subtotal: 8000.0,
      gstAmount: 1440.0,
      shippingFee: 250.0,
      discountAmount: 0.0,
      grandTotal: 9690.0,
    ),
  ];
}
