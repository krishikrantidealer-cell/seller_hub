import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/order.dart';
import 'package:seller_hub/presentation/dashboard/views/order_detail_view.dart';

Map<String, dynamic> _backendOrderJson({
  required String overallStatus,
  String? trackingNumber,
  String? labelReference,
  String? state,
  String pincode = '452001',
  bool rtoRestocked = false,
  String? rtoReason,
}) {
  return {
    'id': 'ord-ui-1',
    'orderNumber': 'FASTRR-UI-1001-S1',
    'overallStatus': overallStatus,
    'placedAt': '2026-11-19T10:00:00',
    'customerSnapshot': {
      'name': 'Ramesh Farmer',
      'phone': '9876543210',
      'email': 'ramesh@example.com',
    },
    'shippingAddress': {
      'name': 'Ramesh Farmer',
      'phoneNumber': '9876543210',
      'villageArea': 'Near Krishi Mandi',
      'cityTehsil': 'Indore',
      'state': ?state,
      'pincode': pincode,
    },
    'payment': {
      'paymentType': 'PREPAID',
      'status': 'CAPTURED',
    },
    'financialSummary': {
      'currentOrderTotal': 1250.0,
      'shippingCharge': 0.0,
    },
    'items': [
      {
        'itemOrderId': 'item-1',
        'productId': 'prod-1',
        'quantity': 2,
        'unitPrice': 625.0,
        'lineTotal': 1250.0,
        'productSnapshot': {
          'title': 'Neem Oil Organic',
          'variantLabel': '1 kg (100g x 10 Qty)',
        },
      }
    ],
    'sellerFulfillments': [
      {
        'id': 'ful-1',
        'sellerId': 'seller-A',
        'status': overallStatus,
        'shipments': (trackingNumber != null || labelReference != null || rtoReason != null)
            ? [
                {
                  'carrier': 'DELHIVERY',
                  'trackingNumber': ?trackingNumber,
                  'labelReference': ?labelReference,
                  'rtoRestocked': rtoRestocked,
                  'rtoReason': ?rtoReason,
                }
              ]
            : [],
      }
    ],
  };
}

Widget _wrapInDesktopViewport(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(width: 1400, child: child),
      ),
    ),
  );
}

void main() {
  group('MarketplaceOrder.fromBackendJson', () {
    test('derives Indian state from pincode when backend state is omitted', () {
      final order = MarketplaceOrder.fromBackendJson(
        _backendOrderJson(overallStatus: 'PENDING', state: null, pincode: '452001'),
      );
      expect(order.shippingAddress.city, 'Indore');
      expect(order.shippingAddress.state, 'Madhya Pradesh');
      expect(order.orderStatus, 'PENDING');
      expect(order.hasLabel, isFalse);
    });

    test('maps all Delhivery forward and RTO statuses accurately', () {
      const statuses = [
        'PENDING',
        'CONFIRMED',
        'PACKED',
        'SHIPPED',
        'IN_TRANSIT',
        'OUT_FOR_DELIVERY',
        'DELIVERED',
        'RTO_INITIATED',
        'RTO_IN_TRANSIT',
        'RTO_DELIVERED',
      ];
      for (final status in statuses) {
        final order = MarketplaceOrder.fromBackendJson(
          _backendOrderJson(overallStatus: status),
        );
        expect(order.orderStatus, status, reason: 'Failed mapping $status');
      }
    });
  });

  group('OrderDetailView progressive Delhivery One UI gating', () {
    testWidgets('PENDING order shows Confirm Order and strictly hides Print/Download Label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final order = MarketplaceOrder.fromBackendJson(_backendOrderJson(overallStatus: 'PENDING'));
      await tester.pumpWidget(_wrapInDesktopViewport(OrderDetailView(order: order, onBack: () {})));

      expect(find.text('Confirm Order'), findsOneWidget);
      expect(find.text('Check Delhivery Label'), findsNothing);
      expect(find.text('Download Label & Mark Packed'), findsNothing);
      expect(find.text('Print Shipping Label'), findsNothing);
    });

    testWidgets('CONFIRMED order WITHOUT backend label shows Check Delhivery Label and hides Print/Download', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final order = MarketplaceOrder.fromBackendJson(_backendOrderJson(overallStatus: 'CONFIRMED'));
      expect(order.hasLabel, isFalse);

      await tester.pumpWidget(_wrapInDesktopViewport(OrderDetailView(order: order, onBack: () {})));

      expect(find.text('Check Delhivery Label'), findsOneWidget);
      expect(find.text('Download Label & Mark Packed'), findsNothing);
      expect(find.text('Print Shipping Label'), findsNothing);
    });

    testWidgets('CONFIRMED order WITH backend label reveals Download Label & Mark Packed', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final order = MarketplaceOrder.fromBackendJson(_backendOrderJson(
        overallStatus: 'CONFIRMED',
        trackingNumber: 'DLV9988776655',
        labelReference: 'https://staging-express.delhivery.com/labels/DLV9988776655.pdf',
      ));
      expect(order.hasLabel, isTrue);

      await tester.pumpWidget(_wrapInDesktopViewport(OrderDetailView(order: order, onBack: () {})));

      expect(find.text('Download Label & Mark Packed'), findsOneWidget);
      expect(find.text('Check Delhivery Label'), findsNothing);
    });

    testWidgets('PACKED order WITH label shows Print Shipping Label and Sync Delhivery Tracking', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final order = MarketplaceOrder.fromBackendJson(_backendOrderJson(
        overallStatus: 'PACKED',
        trackingNumber: 'DLV9988776655',
        labelReference: 'https://staging-express.delhivery.com/labels/DLV9988776655.pdf',
      ));

      await tester.pumpWidget(_wrapInDesktopViewport(OrderDetailView(order: order, onBack: () {})));

      expect(find.text('Print Shipping Label'), findsOneWidget);
      expect(find.text('Sync Delhivery Tracking'), findsOneWidget);
    });

    testWidgets('RTO_DELIVERED order shows Verify RTO & Restock until restocked', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final unverified = MarketplaceOrder.fromBackendJson(_backendOrderJson(
        overallStatus: 'RTO_DELIVERED',
        trackingNumber: 'DLV9988776655',
        labelReference: 'https://staging-express.delhivery.com/labels/DLV9988776655.pdf',
        rtoRestocked: false,
        rtoReason: 'Customer refused delivery',
      ));

      await tester.pumpWidget(_wrapInDesktopViewport(OrderDetailView(order: unverified, onBack: () {})));
      expect(find.text('Verify RTO & Restock'), findsOneWidget);

      final restocked = MarketplaceOrder.fromBackendJson(_backendOrderJson(
        overallStatus: 'RTO_DELIVERED',
        trackingNumber: 'DLV9988776655',
        labelReference: 'https://staging-express.delhivery.com/labels/DLV9988776655.pdf',
        rtoRestocked: true,
        rtoReason: 'Customer refused delivery',
      ));

      await tester.pumpWidget(_wrapInDesktopViewport(OrderDetailView(order: restocked, onBack: () {})));
      await tester.pumpAndSettle();
      expect(find.text('Verify RTO & Restock'), findsNothing);
    });
  });
}
