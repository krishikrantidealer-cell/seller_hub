import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_endpoints.dart';
import '../models/product.dart';
import '../storage/token_storage.dart';

/// Real-time Enterprise WebSocket Client for Seller Hub
/// Handles instant bidirectional sync, live inventory updates, heartbeat keep-alive,
/// and silent background re-connections with 0ms UI blocking.
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _retryCount = 0;

  final _productUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get productUpdates => _productUpdatesController.stream;
  Stream<bool> get connectionStatus => _connectionStateController.stream;
  bool get isConnected => _isConnected;

  TokenStorage? _tokenStorage;

  /// Global toggle: Disabled until backend developer implements `/ws` on Render.
  static bool enabled = false;

  void setTokenStorage(TokenStorage storage) {
    _tokenStorage = storage;
  }

  /// Connects to the WebSocket server using authentication credentials.
  Future<void> connect({String? customUrl, String? token, String? userId}) async {
    if (!enabled) {
      // WebSocket is paused pending backend developer implementation.
      return;
    }
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;

    try {
      final storage = _tokenStorage ?? TokenStorage();
      final effectiveToken = token ?? await storage.getAccessToken();
      final effectiveUserId = userId ?? await storage.getUserId();

      final wsUri = _resolveWebSocketUri(
        customUrl: customUrl,
        token: effectiveToken,
        userId: effectiveUserId,
      );

      debugPrint('[SellerHub WS] Connecting to $wsUri');

      _channel = WebSocketChannel.connect(wsUri);

      _subscription = _channel!.stream.listen(
        (message) {
          if (!_isConnected) {
            _isConnected = true;
            _isConnecting = false;
            _connectionStateController.add(true);
            _retryCount = 0;
            if (!_isTestEnvironment) {
              _startHeartbeat();
            }
            debugPrint('[SellerHub WS] Connected successfully.');
          }
          _handleMessage(message);
        },
        onDone: () {
          _handleDisconnect();
        },
        onError: (error) {
          _handleDisconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  bool get _isTestEnvironment {
    return WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');
  }

  Uri _resolveWebSocketUri({String? customUrl, String? token, String? userId}) {
    if (customUrl != null && customUrl.isNotEmpty) {
      return Uri.parse(customUrl);
    }

    const envWsUrl = String.fromEnvironment('WS_BASE_URL', defaultValue: '');
    if (envWsUrl.isNotEmpty) {
      return Uri.parse(envWsUrl);
    }

    final baseApi = ApiEndpoints.baseUrl;
    final cleanUrl = baseApi.replaceAll('/api', '').replaceAll(RegExp(r'/+$'), '');
    final wsProtocol = cleanUrl.startsWith('https') ? 'wss' : 'ws';
    final wsHost = cleanUrl.replaceFirst(RegExp(r'https?://'), '');

    final queryParams = <String, String>{};
    if (userId != null && userId.isNotEmpty) queryParams['userId'] = userId;
    if (token != null && token.isNotEmpty) queryParams['token'] = token;

    return Uri(
      scheme: wsProtocol,
      host: wsHost.split(':').first,
      port: wsHost.contains(':') ? int.tryParse(wsHost.split(':').last) : null,
      path: '/ws',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // 15-second heartbeat ping to prevent cloud providers from dropping idle sockets
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_isConnected) {
        _send({
          'type': 'PING',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  void _send(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (e) {
        debugPrint('[SellerHub WS] Send error: $e');
      }
    }
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage.toString());
      if (decoded is! Map<String, dynamic>) return;

      final type = decoded['type'];
      if (type == 'PONG') return;

      if (type == 'CONNECTION_ACK') {
        _isConnected = true;
        _isConnecting = false;
        _connectionStateController.add(true);
        _retryCount = 0;
        return;
      }

      // Check if message is a product or catalog event
      const productEventTypes = [
        'PRODUCT_UPDATE',
        'PRODUCT_UPDATED',
        'PRODUCTS_UPDATE',
        'INVENTORY_UPDATE',
        'INVENTORY_CHANGED',
        'STOCK_UPDATED',
        'PRICE_UPDATED',
      ];

      if (productEventTypes.contains(type) || decoded.containsKey('product') || decoded.containsKey('productCode')) {
        _productUpdatesController.add(decoded);
      }
    } catch (_) {}
  }

  /// Broadcasts an updated product to all connected seller clients and servers
  void broadcastProductChange(Product product) {
    if (!enabled) return;
    final payload = {
      'type': 'PRODUCT_UPDATE',
      'data': product.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 1. Deliver to server socket if connected
    _send(payload);

    // 2. Deliver to local controllers so current UI updates synchronously with 0ms delay
    _productUpdatesController.add(payload);
  }

  /// Broadcasts a live stock count update for instant multi-user table synchronization
  void broadcastStockUpdate(String productId, int newStock) {
    if (!enabled) return;
    final payload = {
      'type': 'STOCK_UPDATED',
      'data': {
        'productId': productId,
        'stock': newStock,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    _send(payload);
    _productUpdatesController.add(payload);
  }

  void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    _connectionStateController.add(false);
    _heartbeatTimer?.cancel();
    _subscription?.cancel();

    // Exponential reconnect with max 30s cap
    _reconnectTimer?.cancel();
    if (!_isTestEnvironment) {
      final delaySeconds = (_retryCount < 5) ? (2 * (_retryCount + 1)) : 30;
      _retryCount++;

      _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
        connect();
      });
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
    _connectionStateController.add(false);
  }

  @visibleForTesting
  void simulateIncomingMessage(Map<String, dynamic> message) {
    _productUpdatesController.add(message);
  }
}
