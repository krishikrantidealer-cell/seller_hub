import 'package:equatable/equatable.dart';

/// Bank Details for Seller Payouts & Settlement
class SellerBankDetails extends Equatable {
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String branch;
  final String upiId;

  const SellerBankDetails({
    this.accountHolderName = '',
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.branch = '',
    this.upiId = '',
  });

  factory SellerBankDetails.fromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) {
      return const SellerBankDetails();
    }
    return SellerBankDetails(
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      upiId: json['upiId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'accountHolderName': accountHolderName,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'ifscCode': ifscCode,
    'branch': branch,
    'upiId': upiId,
  };

  SellerBankDetails copyWith({
    String? accountHolderName,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? branch,
    String? upiId,
  }) {
    return SellerBankDetails(
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      branch: branch ?? this.branch,
      upiId: upiId ?? this.upiId,
    );
  }

  @override
  List<Object?> get props => [accountHolderName, bankName, accountNumber, ifscCode, branch, upiId];
}

/// Comprehensive Multi-Tenant Seller Profile Model
class SellerProfile extends Equatable {
  final String id;
  final String sellerCode;
  final String companyName;
  final String tradeName;
  final String contactPerson;
  final String email;
  final String phone;
  final String gstin;
  final String panNumber;
  final String licenseNumber;
  final String businessType;
  final String registeredAddress;
  final String city;
  final String state;
  final String pincode;
  final String warehouseAddress;
  final SellerBankDetails bankDetails;
  final double commissionPercentage;
  final String settlementCycle;
  final double rating;
  final int totalProducts;
  final int totalOrders;
  final double grossSalesValue;
  final String status; // ACTIVE, VERIFIED, KYC_PENDING, SUSPENDED
  final bool isVerified;
  final DateTime? joinedAt;
  final DateTime? updatedAt;
  final List<String> kycDocuments;

  const SellerProfile({
    required this.id,
    this.sellerCode = '',
    required this.companyName,
    required this.tradeName,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.gstin,
    this.panNumber = '',
    this.licenseNumber = '',
    this.businessType = 'Private Limited',
    this.registeredAddress = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.warehouseAddress = '',
    this.bankDetails = const SellerBankDetails(),
    this.commissionPercentage = 8.5,
    this.settlementCycle = 'Weekly (T+3)',
    this.rating = 4.8,
    this.totalProducts = 0,
    this.totalOrders = 0,
    this.grossSalesValue = 0.0,
    this.status = 'ACTIVE',
    this.isVerified = true,
    this.joinedAt,
    this.updatedAt,
    this.kycDocuments = const [],
  });

  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      sellerCode: json['sellerCode']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? json['vendor']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? json['vendor']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gstin: json['gstin']?.toString() ?? '',
      panNumber: json['panNumber']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      businessType: json['businessType']?.toString() ?? 'Private Limited',
      registeredAddress: json['registeredAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      warehouseAddress: json['warehouseAddress']?.toString() ?? '',
      bankDetails: SellerBankDetails.fromJson(json['bankDetails']),
      commissionPercentage: (json['commissionPercentage'] as num?)?.toDouble() ?? 8.5,
      settlementCycle: json['settlementCycle']?.toString() ?? 'Weekly (T+3)',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      grossSalesValue: (json['grossSalesValue'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'ACTIVE',
      isVerified: json['isVerified'] as bool? ?? true,
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      kycDocuments: (json['kycDocuments'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'sellerCode': sellerCode,
    'companyName': companyName,
    'tradeName': tradeName,
    'contactPerson': contactPerson,
    'email': email,
    'phone': phone,
    'gstin': gstin,
    'panNumber': panNumber,
    'licenseNumber': licenseNumber,
    'businessType': businessType,
    'registeredAddress': registeredAddress,
    'city': city,
    'state': state,
    'pincode': pincode,
    'warehouseAddress': warehouseAddress,
    'bankDetails': bankDetails.toJson(),
    'commissionPercentage': commissionPercentage,
    'settlementCycle': settlementCycle,
    'rating': rating,
    'totalProducts': totalProducts,
    'totalOrders': totalOrders,
    'grossSalesValue': grossSalesValue,
    'status': status,
    'isVerified': isVerified,
    if (joinedAt != null) 'joinedAt': joinedAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'kycDocuments': kycDocuments,
  };

  SellerProfile copyWith({
    String? id,
    String? sellerCode,
    String? companyName,
    String? tradeName,
    String? contactPerson,
    String? email,
    String? phone,
    String? gstin,
    String? panNumber,
    String? licenseNumber,
    String? businessType,
    String? registeredAddress,
    String? city,
    String? state,
    String? pincode,
    String? warehouseAddress,
    SellerBankDetails? bankDetails,
    double? commissionPercentage,
    String? settlementCycle,
    double? rating,
    int? totalProducts,
    int? totalOrders,
    double? grossSalesValue,
    String? status,
    bool? isVerified,
    DateTime? joinedAt,
    DateTime? updatedAt,
    List<String>? kycDocuments,
  }) {
    return SellerProfile(
      id: id ?? this.id,
      sellerCode: sellerCode ?? this.sellerCode,
      companyName: companyName ?? this.companyName,
      tradeName: tradeName ?? this.tradeName,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      panNumber: panNumber ?? this.panNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      businessType: businessType ?? this.businessType,
      registeredAddress: registeredAddress ?? this.registeredAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      warehouseAddress: warehouseAddress ?? this.warehouseAddress,
      bankDetails: bankDetails ?? this.bankDetails,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      settlementCycle: settlementCycle ?? this.settlementCycle,
      rating: rating ?? this.rating,
      totalProducts: totalProducts ?? this.totalProducts,
      totalOrders: totalOrders ?? this.totalOrders,
      grossSalesValue: grossSalesValue ?? this.grossSalesValue,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      kycDocuments: kycDocuments ?? this.kycDocuments,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sellerCode,
    companyName,
    tradeName,
    contactPerson,
    email,
    phone,
    gstin,
    status,
    isVerified,
    rating,
  ];

  /// Standard authentic sample sellers representing the enterprise multi-tenant ecosystem
  static final List<SellerProfile> sampleSellers = [
    // 1. Primary Test & Production Seller
    SellerProfile(
      id: '6ab4ada822033f1670582bda',
      sellerCode: 'SLR-KKO-001',
      companyName: 'Krishi Kranti Organics Private Limited',
      tradeName: 'Krishi Kranti Organics',
      contactPerson: 'Suresh Bhai Patel',
      email: 'seller@krishikrantiorganics.com',
      phone: '+91 98251 77201',
      gstin: '24AABCK1234F1Z5',
      panNumber: 'AABCK1234F',
      licenseNumber: 'AGRI-BIO-GJ-8401',
      businessType: 'Private Limited',
      registeredAddress: 'Plot No. 42, GIDC Agro Industrial Park, Naroda',
      city: 'Ahmedabad',
      state: 'Gujarat',
      pincode: '382330',
      warehouseAddress: 'Krishi Kranti Fulfillment Hub, National Highway 8, Aslali, Ahmedabad',
      bankDetails: const SellerBankDetails(
        accountHolderName: 'Krishi Kranti Organics Pvt Ltd',
        bankName: 'HDFC Bank Ltd',
        accountNumber: '50200049281048',
        ifscCode: 'HDFC0000281',
        branch: 'Naroda Industrial Estate Branch',
        upiId: 'krishikranti@hdfcbank',
      ),
      commissionPercentage: 7.5,
      settlementCycle: 'Weekly (T+3)',
      rating: 4.9,
      totalProducts: 24,
      totalOrders: 1842,
      grossSalesValue: 4892400.0,
      status: 'VERIFIED',
      isVerified: true,
      joinedAt: DateTime(2025, 4, 15),
      kycDocuments: const ['GST Certificate (Active)', 'Agri Directorate Pesticide License', 'Company PAN Card', 'Cancelled Cheque Verification'],
    ),

    // 2. Bharat Agro Chemicals Ltd
    SellerProfile(
      id: '6ab5c71982bfa034298101ab',
      sellerCode: 'SLR-BAC-002',
      companyName: 'Bharat Agro Chemicals Limited',
      tradeName: 'Bharat Agro Chemicals Ltd',
      contactPerson: 'Vikramaditya Sharma',
      email: 'partnerships@bharatagro.com',
      phone: '+91 99881 22345',
      gstin: '27AABCB9823M1Z8',
      panNumber: 'AABCB9823M',
      licenseNumber: 'CIB-RC-INS-2023-9912',
      businessType: 'Public Limited',
      registeredAddress: 'Corporate Tower 3, MIDC Industrial Area, Andheri East',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400093',
      warehouseAddress: 'Bharat Agro Logistics Hub, Bhiwandi Warehousing Zone, Thane',
      bankDetails: const SellerBankDetails(
        accountHolderName: 'Bharat Agro Chemicals Limited',
        bankName: 'State Bank of India',
        accountNumber: '381920491823',
        ifscCode: 'SBIN0001824',
        branch: 'Commercial Branch, Fort, Mumbai',
        upiId: 'bharatagro@sbi',
      ),
      commissionPercentage: 9.0,
      settlementCycle: 'Bi-Weekly (T+5)',
      rating: 4.8,
      totalProducts: 48,
      totalOrders: 3410,
      grossSalesValue: 9812500.0,
      status: 'VERIFIED',
      isVerified: true,
      joinedAt: DateTime(2025, 6, 1),
      kycDocuments: const ['CIBRC Registration Copy', 'Manufacturing License', 'GST Verification', 'Bank Mandate Form'],
    ),

    // 3. Kisan Care Biotech
    SellerProfile(
      id: '6ab7e90141fca928374162ec',
      sellerCode: 'SLR-KCB-003',
      companyName: 'Kisan Care Biotechnology LLP',
      tradeName: 'Kisan Care Biotech',
      contactPerson: 'Anil Kumar Choudhary',
      email: 'sales@kisancarebiotech.in',
      phone: '+91 94140 88219',
      gstin: '08AAPFK8819Q1ZP',
      panNumber: 'AAPFK8819Q',
      licenseNumber: 'RAJ-BIO-AGRI-1092',
      businessType: 'LLP',
      registeredAddress: 'Bio Park Phase II, Sitapura Industrial Area',
      city: 'Jaipur',
      state: 'Rajasthan',
      pincode: '302022',
      warehouseAddress: 'Sitapura Central Dispatch Yard, Tonk Road, Jaipur',
      bankDetails: const SellerBankDetails(
        accountHolderName: 'Kisan Care Biotechnology LLP',
        bankName: 'ICICI Bank Ltd',
        accountNumber: '184905001928',
        ifscCode: 'ICIC0001849',
        branch: 'Sitapura Branch, Jaipur',
        upiId: 'kisancare@icici',
      ),
      commissionPercentage: 8.0,
      settlementCycle: 'Weekly (T+3)',
      rating: 4.7,
      totalProducts: 16,
      totalOrders: 920,
      grossSalesValue: 2450800.0,
      status: 'VERIFIED',
      isVerified: true,
      joinedAt: DateTime(2025, 8, 10),
      kycDocuments: const ['Organic NPOP Certificate', 'GST Return Proof', 'LLP Deed', 'Bank Account Verification'],
    ),

    // 4. Syngenta Crop Protection
    SellerProfile(
      id: '6ab8f21950dca827164928fe',
      sellerCode: 'SLR-SYN-004',
      companyName: 'Syngenta India Private Limited',
      tradeName: 'Syngenta Crop Protection',
      contactPerson: 'Deepak Deshmukh',
      email: 'agri.channels@syngenta.com',
      phone: '+91 20 6603 2000',
      gstin: '27AAACS1849E1ZS',
      panNumber: 'AAACS1849E',
      licenseNumber: 'MH-PUN-PEST-88192',
      businessType: 'Private Limited',
      registeredAddress: 'Amar Paradigm, S.No. 110/11/3, Baner Road',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411045',
      warehouseAddress: 'Syngenta National Distribution Center, Chakan Phase 2, Pune',
      bankDetails: const SellerBankDetails(
        accountHolderName: 'Syngenta India Private Limited',
        bankName: 'Citibank N.A.',
        accountNumber: '003928174628',
        ifscCode: 'CITI0000004',
        branch: 'Corporate Banking, Mumbai',
        upiId: 'syngenta@citibank',
      ),
      commissionPercentage: 6.5,
      settlementCycle: 'Monthly (T+15)',
      rating: 4.9,
      totalProducts: 65,
      totalOrders: 6890,
      grossSalesValue: 28450000.0,
      status: 'VERIFIED',
      isVerified: true,
      joinedAt: DateTime(2025, 2, 20),
      kycDocuments: const ['CIB & RC Master Approval', 'National Distribution License', 'Corporate Tax Certificate'],
    ),

    // 5. GreenLeaf Bio-Solutions (KYC Pending)
    SellerProfile(
      id: '6ab9c018274a1928472619ab',
      sellerCode: 'SLR-GLB-005',
      companyName: 'GreenLeaf Bio-Solutions Enterprise',
      tradeName: 'GreenLeaf Organics',
      contactPerson: 'Mahesh Verma',
      email: 'mahesh@greenleafbio.com',
      phone: '+91 97110 33419',
      gstin: '07AAAFG8829R1Z3',
      panNumber: 'AAAFG8829R',
      licenseNumber: 'DL-AGRI-PENDING',
      businessType: 'Proprietorship',
      registeredAddress: 'Kh. No. 48, Alipur Industrial Area',
      city: 'Delhi',
      state: 'Delhi',
      pincode: '110036',
      warehouseAddress: 'Alipur Godown No. 4, GT Karnal Road, Delhi',
      bankDetails: const SellerBankDetails(
        accountHolderName: 'GreenLeaf Bio-Solutions',
        bankName: 'Axis Bank Ltd',
        accountNumber: '91802004819284',
        ifscCode: 'UTIB0000412',
        branch: 'Model Town Branch, Delhi',
        upiId: 'greenleaf@axisbank',
      ),
      commissionPercentage: 10.0,
      settlementCycle: 'Weekly (T+3)',
      rating: 4.2,
      totalProducts: 4,
      totalOrders: 45,
      grossSalesValue: 125000.0,
      status: 'KYC_PENDING',
      isVerified: false,
      joinedAt: DateTime(2026, 1, 14),
      kycDocuments: const ['Aadhaar / PAN Card (Verified)', 'Pesticide License (Under Review)'],
    ),
  ];
}
