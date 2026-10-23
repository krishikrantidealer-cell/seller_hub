enum WebhookEventType {
  orderCreated,
  orderDispatched,
  orderDelivered,
  orderReturned,
  inventoryLowStock,
  settlementProcessed,
}

class WebhookEvent {
  final String eventId;
  final WebhookEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  const WebhookEvent({
    required this.eventId,
    required this.type,
    required this.timestamp,
    required this.payload,
  });

  factory WebhookEvent.fromJson(Map<String, dynamic> json) {
    return WebhookEvent(
      eventId: json['event_id'] as String? ?? '',
      type: WebhookEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WebhookEventType.orderCreated,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      payload: json['payload'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'payload': payload,
  };
}
