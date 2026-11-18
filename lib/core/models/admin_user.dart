import 'package:equatable/equatable.dart';

class UserAddress extends Equatable {
  final String villageArea;
  final String address2;
  final String cityTehsil;
  final String state;
  final String pincode;

  const UserAddress({
    this.villageArea = '',
    this.address2 = '',
    this.cityTehsil = '',
    this.state = '',
    this.pincode = '',
  });

  factory UserAddress.fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return const UserAddress();
    }
    final map = Map<String, dynamic>.from(json);
    return UserAddress(
      villageArea: map['villageArea']?.toString() ?? '',
      address2: map['address2']?.toString() ?? '',
      cityTehsil: map['cityTehsil']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      pincode: map['pincode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'villageArea': villageArea,
        'address2': address2,
        'cityTehsil': cityTehsil,
        'state': state,
        'pincode': pincode,
      };

  String get formatted {
    final parts = [villageArea, address2, cityTehsil, state, pincode]
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Address not provided' : parts.join(', ');
  }

  @override
  List<Object?> get props => [villageArea, address2, cityTehsil, state, pincode];
}

class AdminUser extends Equatable {
  final String id;
  final String phoneNumber;
  final String? email;
  final String firstName;
  final String lastName;
  final String? shopName;
  final String? sellerCode;
  final String role;
  final UserAddress? address;
  final bool isVerified;
  final bool isProfileComplete;
  final String? gstNumber;
  final String? panNumber;
  final String? licenceNo;
  final String? licenceImage;
  final List<String> licenceImages;
  final String? gstCertificate;
  final String? panCard;
  final String? aadhaarCard;
  final String? agreement;
  final String? shopImage;
  final List<UserAddress> shippingAddresses;
  final List<UserAddress> warehouseAddresses;
  final bool isBlocked;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String status;
  final String? notes;
  final List<String> notesHistory;
  final int? monthlyTarget;
  final String? preferredLanguage;
  final int? productCodeSequence;
  final int? orderNumberSequence;
  final String pricingModel;
  final double commissionPercentage;
  final Map<String, dynamic>? bankDetails;

  const AdminUser({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.firstName = '',
    this.lastName = '',
    this.shopName,
    this.sellerCode,
    required this.role,
    this.address,
    this.isVerified = false,
    this.isProfileComplete = false,
    this.gstNumber,
    this.panNumber,
    this.licenceNo,
    this.licenceImage,
    this.licenceImages = const [],
    this.gstCertificate,
    this.panCard,
    this.aadhaarCard,
    this.agreement,
    this.shopImage,
    this.shippingAddresses = const [],
    this.warehouseAddresses = const [],
    this.isBlocked = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.status = 'ACTIVE',
    this.notes,
    this.notesHistory = const [],
    this.monthlyTarget,
    this.preferredLanguage,
    this.productCodeSequence,
    this.orderNumberSequence,
    this.pricingModel = 'MARKETPLACE',
    this.commissionPercentage = 0.0,
    this.bankDetails,
  });

  factory AdminUser.emptyCustomer() {
    return const AdminUser(
      id: '',
      phoneNumber: '',
      firstName: '',
      lastName: '',
      role: 'ROLE_CUSTOMER',
      status: 'ACTIVE',
      address: UserAddress(
        state: 'Madhya Pradesh',
      ),
    );
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    List<UserAddress> shipping = [];
    final rawShipping = json['shippingAddresses'] ?? json['shipping_addresses'];
    if (rawShipping is List) {
      shipping = rawShipping
          .whereType<Map>()
          .map((a) => UserAddress.fromJson(a))
          .toList();
    }

    List<UserAddress> warehouses = [];
    final rawWarehouses = json['warehouseAddresses'] ?? json['warehouse_addresses'];
    if (rawWarehouses is List) {
      warehouses = rawWarehouses
          .whereType<Map>()
          .map((a) => UserAddress.fromJson(a))
          .toList();
    }

    final rawHistory = json['notesHistory'] ?? json['notes_history'];
    List<String> parsedHistory = [];
    if (rawHistory is List) {
      parsedHistory = rawHistory.map((e) => e.toString()).toList();
    }

    final rawAddress = json['address'];
    UserAddress? parsedAddress;
    if (rawAddress != null && rawAddress is Map) {
      parsedAddress = UserAddress.fromJson(rawAddress);
    }

    final rawLicences = json['licenceImage'];
    List<String> parsedLicences = [];
    String? singleLicence;
    if (rawLicences is List) {
      parsedLicences = rawLicences.map((e) => e.toString()).toList();
      singleLicence = parsedLicences.isNotEmpty ? parsedLicences.first : null;
    } else if (rawLicences != null && rawLicences.toString().trim().isNotEmpty) {
      singleLicence = rawLicences.toString().trim();
      if (singleLicence != '[]') {
        parsedLicences = [singleLicence];
      } else {
        singleLicence = null;
      }
    }

    return AdminUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      shopName: json['shopName']?.toString(),
      sellerCode: json['sellerCode']?.toString(),
      role: json['role']?.toString() ?? 'ROLE_CUSTOMER',
      address: parsedAddress,
      isVerified: json['isVerified'] == true,
      isProfileComplete: json['isProfileComplete'] == true,
      gstNumber: json['gstNumber']?.toString(),
      panNumber: json['panNumber']?.toString(),
      licenceNo: json['licenceNo']?.toString() ?? json['licenseNumber']?.toString(),
      licenceImage: singleLicence,
      licenceImages: parsedLicences,
      gstCertificate: json['gstCertificate']?.toString(),
      panCard: json['panCard']?.toString(),
      aadhaarCard: json['aadhaarCard']?.toString(),
      agreement: json['agreement']?.toString(),
      shopImage: json['shopImage']?.toString(),
      shippingAddresses: shipping,
      warehouseAddresses: warehouses,
      isBlocked: json['isBlocked'] == true,
      isDeleted: json['isDeleted'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      status: json['status']?.toString() ?? 'ACTIVE',
      notes: json['notes']?.toString(),
      notesHistory: parsedHistory,
      monthlyTarget: (json['monthlyTarget'] as num?)?.toInt(),
      preferredLanguage: json['preferredLanguage']?.toString(),
      productCodeSequence: (json['productCodeSequence'] as num?)?.toInt(),
      orderNumberSequence: (json['orderNumberSequence'] as num?)?.toInt(),
      pricingModel: json['pricingModel']?.toString() ?? 'MARKETPLACE',
      commissionPercentage: (json['commissionPercentage'] as num?)?.toDouble() ??
          (json['settlementTerms'] is Map
              ? (json['settlementTerms']['commissionPercentage'] as num?)?.toDouble()
              : null) ??
          0.0,
      bankDetails: json['bankDetails'] is Map
          ? Map<String, dynamic>.from(json['bankDetails'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'shopName': shopName,
        if (sellerCode != null) 'sellerCode': sellerCode,
        'role': role,
        'address': address?.toJson(),
        'isVerified': isVerified,
        'isProfileComplete': isProfileComplete,
        'gstNumber': gstNumber,
        'panNumber': panNumber,
        'licenceNo': licenceNo,
        'licenceImage': licenceImages.isNotEmpty ? licenceImages : licenceImage,
        'licenceImages': licenceImages,
        'gstCertificate': gstCertificate,
        'panCard': panCard,
        'aadhaarCard': aadhaarCard,
        'agreement': agreement,
        'shopImage': shopImage,
        if (role != 'ROLE_SELLER')
          'shippingAddresses': shippingAddresses.map((a) => a.toJson()).toList(),
        if (role == 'ROLE_SELLER')
          'warehouseAddresses': warehouseAddresses.map((a) => a.toJson()).toList(),
        'isBlocked': isBlocked,
        'isDeleted': isDeleted,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'status': status,
        if (notes != null) 'notes': notes,
        if (role != 'ROLE_SELLER') 'notesHistory': notesHistory,
        if (monthlyTarget != null) 'monthlyTarget': monthlyTarget,
        if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
        if (productCodeSequence != null) 'productCodeSequence': productCodeSequence,
        if (orderNumberSequence != null) 'orderNumberSequence': orderNumberSequence,
        'pricingModel': pricingModel,
        'commissionPercentage': commissionPercentage,
        if (bankDetails != null) 'bankDetails': bankDetails,
      };

  String get fullName {
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) return name;
    if (shopName != null && shopName!.trim().isNotEmpty) return shopName!.trim();
    if (phoneNumber.isNotEmpty) return phoneNumber;
    final snippet = id.length > 8 ? id.substring(0, 8) : id;
    return 'User #$snippet';
  }

  String get displayName {
    if (shopName != null && shopName!.trim().isNotEmpty) {
      return shopName!.trim();
    }
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) {
      return name;
    }
    if (phoneNumber.isNotEmpty) {
      return role == 'ROLE_SELLER' ? 'Seller ($phoneNumber)' : 'Customer ($phoneNumber)';
    }
    final snippet = id.length > 8 ? id.substring(0, 8) : id;
    return 'User #$snippet';
  }

  String get fullAddress {
    return address?.formatted ?? 'Address not provided';
  }

  String get statusBadge {
    if (isDeleted) return 'DELETED';
    if (isBlocked) return 'BLOCKED';
    if (status.isNotEmpty && status != 'ACTIVE') return status;
    if (isVerified) return 'VERIFIED';
    return status.isNotEmpty ? status : 'ACTIVE';
  }

  AdminUser copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? firstName,
    String? lastName,
    String? shopName,
    String? sellerCode,
    String? role,
    UserAddress? address,
    bool? isVerified,
    bool? isProfileComplete,
    String? gstNumber,
    String? panNumber,
    String? licenceNo,
    String? licenceImage,
    List<String>? licenceImages,
    String? gstCertificate,
    String? panCard,
    String? aadhaarCard,
    String? agreement,
    String? shopImage,
    List<UserAddress>? shippingAddresses,
    List<UserAddress>? warehouseAddresses,
    bool? isBlocked,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? notes,
    List<String>? notesHistory,
    int? monthlyTarget,
    String? preferredLanguage,
    int? productCodeSequence,
    int? orderNumberSequence,
    Map<String, dynamic>? bankDetails,
  }) {
    return AdminUser(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      shopName: shopName ?? this.shopName,
      sellerCode: sellerCode ?? this.sellerCode,
      role: role ?? this.role,
      address: address ?? this.address,
      isVerified: isVerified ?? this.isVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      licenceNo: licenceNo ?? this.licenceNo,
      licenceImage: licenceImage ?? this.licenceImage,
      licenceImages: licenceImages ?? this.licenceImages,
      gstCertificate: gstCertificate ?? this.gstCertificate,
      panCard: panCard ?? this.panCard,
      aadhaarCard: aadhaarCard ?? this.aadhaarCard,
      agreement: agreement ?? this.agreement,
      shopImage: shopImage ?? this.shopImage,
      shippingAddresses: shippingAddresses ?? this.shippingAddresses,
      warehouseAddresses: warehouseAddresses ?? this.warehouseAddresses,
      isBlocked: isBlocked ?? this.isBlocked,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      notesHistory: notesHistory ?? this.notesHistory,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      productCodeSequence: productCodeSequence ?? this.productCodeSequence,
      orderNumberSequence: orderNumberSequence ?? this.orderNumberSequence,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        email,
        firstName,
        lastName,
        shopName,
        sellerCode,
        role,
        address,
        isVerified,
        isProfileComplete,
        gstNumber,
        panNumber,
        licenceNo,
        warehouseAddresses,
        isBlocked,
        isDeleted,
        createdAt,
        updatedAt,
        status,
        notes,
        notesHistory,
        monthlyTarget,
        preferredLanguage,
        productCodeSequence,
        orderNumberSequence,
      ];
}

class AdminUserPageData extends Equatable {
  final List<AdminUser> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  const AdminUserPageData({
    this.content = const [],
    this.page = 0,
    this.size = 20,
    this.totalElements = 0,
    this.totalPages = 1,
    this.first = true,
    this.last = true,
  });

  factory AdminUserPageData.fromJson(Map<String, dynamic> json) {
    final list = (json['content'] as List?)
            ?.map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AdminUserPageData(
      content: list,
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? list.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      first: json['first'] == true,
      last: json['last'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'content': content.map((u) => u.toJson()).toList(),
        'page': page,
        'size': size,
        'totalElements': totalElements,
        'totalPages': totalPages,
        'first': first,
        'last': last,
      };

  @override
  List<Object?> get props => [content, page, size, totalElements, totalPages, first, last];
}
