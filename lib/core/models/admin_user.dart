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
  final String role;
  final UserAddress? address;
  final bool isVerified;
  final bool isProfileComplete;
  final String? kycStatus;
  final bool isKycComplete;
  final String? gstNumber;
  final String? licenceImage;
  final String? shopImage;
  final List<UserAddress> shippingAddresses;
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

  const AdminUser({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.firstName = '',
    this.lastName = '',
    this.shopName,
    required this.role,
    this.address,
    this.isVerified = false,
    this.isProfileComplete = false,
    this.kycStatus,
    this.isKycComplete = false,
    this.gstNumber,
    this.licenceImage,
    this.shopImage,
    this.shippingAddresses = const [],
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
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    List<UserAddress> shipping = [];
    final rawShipping = json['shippingAddresses'] ?? json['shipping_addresses'];
    if (rawShipping is List) {
      shipping = rawShipping
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

    return AdminUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      shopName: json['shopName']?.toString(),
      role: json['role']?.toString() ?? 'ROLE_CUSTOMER',
      address: parsedAddress,
      isVerified: json['isVerified'] == true,
      isProfileComplete: json['isProfileComplete'] == true,
      kycStatus: json['kycStatus']?.toString(),
      isKycComplete: json['isKycComplete'] == true,
      gstNumber: json['gstNumber']?.toString(),
      licenceImage: json['licenceImage']?.toString(),
      shopImage: json['shopImage']?.toString(),
      shippingAddresses: shipping,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'shopName': shopName,
        'role': role,
        'address': address?.toJson(),
        'isVerified': isVerified,
        'isProfileComplete': isProfileComplete,
        'kycStatus': kycStatus,
        'isKycComplete': isKycComplete,
        'gstNumber': gstNumber,
        'licenceImage': licenceImage,
        'shopImage': shopImage,
        'shippingAddresses': shippingAddresses.map((a) => a.toJson()).toList(),
        'isBlocked': isBlocked,
        'isDeleted': isDeleted,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'status': status,
        if (notes != null) 'notes': notes,
        'notesHistory': notesHistory,
        if (monthlyTarget != null) 'monthlyTarget': monthlyTarget,
        if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
        if (productCodeSequence != null) 'productCodeSequence': productCodeSequence,
        if (orderNumberSequence != null) 'orderNumberSequence': orderNumberSequence,
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
    if (isVerified || isKycComplete) return 'VERIFIED';
    return status.isNotEmpty ? status : 'ACTIVE';
  }

  AdminUser copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? firstName,
    String? lastName,
    String? shopName,
    String? role,
    UserAddress? address,
    bool? isVerified,
    bool? isProfileComplete,
    String? kycStatus,
    bool? isKycComplete,
    String? gstNumber,
    String? licenceImage,
    String? shopImage,
    List<UserAddress>? shippingAddresses,
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
  }) {
    return AdminUser(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      shopName: shopName ?? this.shopName,
      role: role ?? this.role,
      address: address ?? this.address,
      isVerified: isVerified ?? this.isVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      kycStatus: kycStatus ?? this.kycStatus,
      isKycComplete: isKycComplete ?? this.isKycComplete,
      gstNumber: gstNumber ?? this.gstNumber,
      licenceImage: licenceImage ?? this.licenceImage,
      shopImage: shopImage ?? this.shopImage,
      shippingAddresses: shippingAddresses ?? this.shippingAddresses,
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
        role,
        address,
        isVerified,
        isProfileComplete,
        kycStatus,
        isKycComplete,
        gstNumber,
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
