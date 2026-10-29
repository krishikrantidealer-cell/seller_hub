import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/admin_user.dart';
import 'package:seller_hub/core/models/seller.dart';

void main() {
  group('AdminUser & SellerProfile Schema Alignment Tests', () {
    final Map<String, dynamic> sellersApiResponse = {
      "success": true,
      "message": "Admin users retrieved",
      "data": {
        "content": [
          {
            "id": "6ae317c20382f44d3654aba8",
            "phoneNumber": "9682675141",
            "email": "self.seller.1793267562006@example.com",
            "firstName": null,
            "lastName": null,
            "shopName": null,
            "role": "ROLE_SELLER",
            "address": null,
            "isVerified": true,
            "isProfileComplete": false,
            "kycStatus": null,
            "isKycComplete": false,
            "gstNumber": null,
            "licenceImage": null,
            "shopImage": null,
            "shippingAddresses": [],
            "isBlocked": false,
            "isDeleted": false,
            "createdAt": "2026-10-29T09:54:10.921",
            "updatedAt": "2026-10-29T09:54:10.921",
            "status": "ACTIVE",
            "notes": null,
            "notesHistory": [],
            "monthlyTarget": null,
            "preferredLanguage": null,
            "productCodeSequence": 0,
            "orderNumberSequence": 0
          },
          {
            "id": "6ae317450382f44d3654aba7",
            "phoneNumber": "9775905908",
            "email": null,
            "firstName": null,
            "lastName": null,
            "shopName": null,
            "role": "ROLE_SELLER",
            "address": null,
            "isVerified": true,
            "isProfileComplete": false,
            "kycStatus": null,
            "isKycComplete": false,
            "gstNumber": null,
            "licenceImage": null,
            "shopImage": null,
            "shippingAddresses": [],
            "isBlocked": false,
            "isDeleted": false,
            "createdAt": "2026-10-29T09:52:05.256",
            "updatedAt": "2026-10-29T09:52:05.256",
            "status": "ACTIVE",
            "notes": null,
            "notesHistory": [],
            "monthlyTarget": null,
            "preferredLanguage": null,
            "productCodeSequence": 0,
            "orderNumberSequence": 0
          },
          {
            "id": "6ae2d682477dabe731e2c1f2",
            "phoneNumber": "9876501234",
            "email": "rahul.agro@example.com",
            "firstName": "Saurabh",
            "lastName": "Patel",
            "shopName": "Patel Agro Traders",
            "role": "ROLE_SELLER",
            "address": {
              "villageArea": "MP Nagar",
              "address2": "Near Jyoti Cinema",
              "cityTehsil": "Bhopal",
              "state": "Madhya Pradesh",
              "pincode": "462011"
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
            "createdAt": "2026-10-29T05:15:46.182",
            "updatedAt": "2026-10-29T09:50:28.708",
            "status": "ACTIVE",
            "notes": null,
            "notesHistory": [],
            "monthlyTarget": null,
            "preferredLanguage": null,
            "productCodeSequence": 33,
            "orderNumberSequence": 17
          },
          {
            "id": "6ae2d682477dabe731e2c1f3",
            "phoneNumber": "9123405678",
            "email": "priya.farms@example.com",
            "firstName": "Amit",
            "lastName": "Verma",
            "shopName": "Verma Organic Farms",
            "role": "ROLE_SELLER",
            "address": {
              "villageArea": "Itarsi Road",
              "address2": "Near Agricultural Market",
              "cityTehsil": "Itarsi",
              "state": "Madhya Pradesh",
              "pincode": "461111"
            },
            "isVerified": false,
            "isProfileComplete": true,
            "kycStatus": null,
            "isKycComplete": false,
            "gstNumber": null,
            "licenceImage": null,
            "shopImage": null,
            "shippingAddresses": [],
            "isBlocked": false,
            "isDeleted": false,
            "createdAt": "2026-10-29T05:15:46.182",
            "updatedAt": "2026-10-29T05:30:15.131",
            "status": "ACTIVE",
            "notes": null,
            "notesHistory": [],
            "monthlyTarget": null,
            "preferredLanguage": null,
            "productCodeSequence": 74,
            "orderNumberSequence": 17
          }
        ],
        "page": 0,
        "size": 20,
        "totalElements": 4,
        "totalPages": 1,
        "first": true,
        "last": true
      },
      "timestamp": "2026-10-29T10:15:13.174549127"
    };

    final Map<String, dynamic> customersApiResponse = {
      "success": true,
      "message": "Admin users retrieved",
      "data": {
        "content": [
          {
            "id": "6ae2d682477dabe731e2c1f1",
            "phoneNumber": "9123456780",
            "email": null,
            "firstName": "Priya",
            "lastName": "roy",
            "shopName": null,
            "role": "ROLE_CUSTOMER",
            "address": {
              "villageArea": "Civil Lines",
              "address2": "Near Main Market",
              "cityTehsil": "Itarsi",
              "state": "Madhya Pradesh",
              "pincode": "461111"
            },
            "isVerified": false,
            "isProfileComplete": true,
            "kycStatus": null,
            "isKycComplete": false,
            "gstNumber": null,
            "licenceImage": null,
            "shopImage": null,
            "shippingAddresses": [],
            "isBlocked": false,
            "isDeleted": false,
            "createdAt": "2026-10-29T05:15:46.182",
            "updatedAt": "2026-10-29T05:15:46.182",
            "status": "ACTIVE",
            "notes": null,
            "notesHistory": [],
            "monthlyTarget": null,
            "preferredLanguage": null,
            "productCodeSequence": null,
            "orderNumberSequence": null
          },
          {
            "id": "6ab2318cbe0b0c21399291f7",
            "phoneNumber": "9876543210",
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
            "createdAt": "2026-09-22T07:43:08.049",
            "updatedAt": "2026-10-29T08:15:11.45",
            "status": "ACTIVE",
            "notes": null,
            "notesHistory": [],
            "monthlyTarget": null,
            "preferredLanguage": null,
            "productCodeSequence": null,
            "orderNumberSequence": null
          }
        ],
        "page": 0,
        "size": 20,
        "totalElements": 2,
        "totalPages": 1,
        "first": true,
        "last": true
      },
      "timestamp": "2026-10-29T10:15:58.312684122"
    };

    test('Parses sellers page data and seller profiles with all backend fields', () {
      final pageData = AdminUserPageData.fromJson(
        sellersApiResponse['data'] as Map<String, dynamic>,
      );

      expect(pageData.totalElements, 4);
      expect(pageData.page, 0);
      expect(pageData.size, 20);
      expect(pageData.content.length, 4);

      // Seller 1: incomplete profile
      final seller1 = pageData.content[0];
      expect(seller1.id, '6ae317c20382f44d3654aba8');
      expect(seller1.phoneNumber, '9682675141');
      expect(seller1.email, 'self.seller.1793267562006@example.com');
      expect(seller1.firstName, '');
      expect(seller1.lastName, '');
      expect(seller1.shopName, isNull);
      expect(seller1.role, 'ROLE_SELLER');
      expect(seller1.address, isNull);
      expect(seller1.isVerified, isTrue);
      expect(seller1.isProfileComplete, isFalse);
      expect(seller1.productCodeSequence, 0);
      expect(seller1.orderNumberSequence, 0);
      expect(seller1.displayName, 'Seller (9682675141)');

      // Seller 3: complete profile with address and sequences
      final seller3 = pageData.content[2];
      expect(seller3.id, '6ae2d682477dabe731e2c1f2');
      expect(seller3.phoneNumber, '9876501234');
      expect(seller3.firstName, 'Saurabh');
      expect(seller3.lastName, 'Patel');
      expect(seller3.shopName, 'Patel Agro Traders');
      expect(seller3.fullName, 'Saurabh Patel');
      expect(seller3.displayName, 'Patel Agro Traders');
      expect(seller3.productCodeSequence, 33);
      expect(seller3.orderNumberSequence, 17);
      expect(seller3.address?.villageArea, 'MP Nagar');
      expect(seller3.address?.cityTehsil, 'Bhopal');
      expect(seller3.address?.state, 'Madhya Pradesh');
      expect(seller3.address?.pincode, '462011');

      // Conversion to SellerProfile
      final profile3 = SellerProfile.fromAdminUser(seller3);
      expect(profile3.id, '6ae2d682477dabe731e2c1f2');
      expect(profile3.tradeName, 'Patel Agro Traders');
      expect(profile3.companyName, 'Patel Agro Traders');
      expect(profile3.contactPerson, 'Saurabh Patel');
      expect(profile3.phone, '9876501234');
      expect(profile3.city, 'Bhopal');
      expect(profile3.state, 'Madhya Pradesh');
      expect(profile3.pincode, '462011');
      expect(profile3.productCodeSequence, 33);
      expect(profile3.orderNumberSequence, 17);
      expect(profile3.isProfileComplete, isTrue);

      // Seller 4: complete profile
      final seller4 = pageData.content[3];
      expect(seller4.shopName, 'Verma Organic Farms');
      expect(seller4.productCodeSequence, 74);
      expect(seller4.orderNumberSequence, 17);
      expect(seller4.displayName, 'Verma Organic Farms');
      final profile4 = SellerProfile.fromAdminUser(seller4);
      expect(profile4.tradeName, 'Verma Organic Farms');
      expect(profile4.productCodeSequence, 74);
    });

    test('Parses customers page data and customer entities with all backend fields', () {
      final pageData = AdminUserPageData.fromJson(
        customersApiResponse['data'] as Map<String, dynamic>,
      );

      expect(pageData.totalElements, 2);
      expect(pageData.content.length, 2);

      // Customer 1: Priya roy
      final customer1 = pageData.content[0];
      expect(customer1.id, '6ae2d682477dabe731e2c1f1');
      expect(customer1.phoneNumber, '9123456780');
      expect(customer1.email, isNull);
      expect(customer1.firstName, 'Priya');
      expect(customer1.lastName, 'roy');
      expect(customer1.fullName, 'Priya roy');
      expect(customer1.displayName, 'Priya roy');
      expect(customer1.role, 'ROLE_CUSTOMER');
      expect(customer1.address?.cityTehsil, 'Itarsi');
      expect(customer1.isVerified, isFalse);
      expect(customer1.isProfileComplete, isTrue);

      // Customer 2: Aashutosh Shrivastava
      final customer2 = pageData.content[1];
      expect(customer2.id, '6ab2318cbe0b0c21399291f7');
      expect(customer2.phoneNumber, '9876543210');
      expect(customer2.firstName, 'Aashutosh');
      expect(customer2.lastName, 'Shrivastava');
      expect(customer2.fullName, 'Aashutosh Shrivastava');
      expect(customer2.displayName, 'Aashutosh Shrivastava');
      expect(customer2.role, 'ROLE_CUSTOMER');
      expect(customer2.address?.cityTehsil, 'Indore');
      expect(customer2.isVerified, isTrue);
      expect(customer2.isProfileComplete, isTrue);
    });
  });
}
