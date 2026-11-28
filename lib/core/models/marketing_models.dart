import 'package:equatable/equatable.dart';

class MarketingKpis extends Equatable {
  final int totalBlogs;
  final int publishedBlogs;
  final int activeBanners;
  final int activeCollections;
  final int totalReviews;
  final int totalCustomers;
  final int totalCampaigns;
  final int totalWebhookEvents;

  const MarketingKpis({
    this.totalBlogs = 0,
    this.publishedBlogs = 0,
    this.activeBanners = 0,
    this.activeCollections = 0,
    this.totalReviews = 0,
    this.totalCustomers = 0,
    this.totalCampaigns = 0,
    this.totalWebhookEvents = 0,
  });

  factory MarketingKpis.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return MarketingKpis(
      totalBlogs: toInt(json['totalBlogs']),
      publishedBlogs: toInt(json['publishedBlogs']),
      activeBanners: toInt(json['activeBanners']),
      activeCollections: toInt(json['activeCollections']),
      totalReviews: toInt(json['totalReviews']),
      totalCustomers: toInt(json['totalCustomers']),
      totalCampaigns: toInt(json['totalCampaigns']),
      totalWebhookEvents: toInt(json['totalWebhookEvents']),
    );
  }

  @override
  List<Object?> get props => [
        totalBlogs,
        publishedBlogs,
        activeBanners,
        activeCollections,
        totalReviews,
        totalCustomers,
        totalCampaigns,
        totalWebhookEvents,
      ];
}

class MarketingCampaignItem extends Equatable {
  final String id;
  final String title;
  final String channel;
  final String targetAudience;
  final String message;
  final String ctaUrl;
  final String status;
  final int sentCount;
  final int deliveredCount;
  final int openedCount;
  final int clickedCount;
  final int convertedCount;
  final String createdBy;
  final DateTime? createdAt;

  const MarketingCampaignItem({
    required this.id,
    required this.title,
    required this.channel,
    required this.targetAudience,
    required this.message,
    this.ctaUrl = '',
    required this.status,
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.openedCount = 0,
    this.clickedCount = 0,
    this.convertedCount = 0,
    this.createdBy = '',
    this.createdAt,
  });

  factory MarketingCampaignItem.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return MarketingCampaignItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      channel: (json['channel'] ?? 'PUSH').toString(),
      targetAudience: (json['targetAudience'] ?? 'ALL_FARMERS').toString(),
      message: (json['message'] ?? '').toString(),
      ctaUrl: (json['ctaUrl'] ?? '').toString(),
      status: (json['status'] ?? 'ACTIVE').toString(),
      sentCount: toInt(json['sentCount']),
      deliveredCount: toInt(json['deliveredCount']),
      openedCount: toInt(json['openedCount']),
      clickedCount: toInt(json['clickedCount']),
      convertedCount: toInt(json['convertedCount']),
      createdBy: (json['createdBy'] ?? '').toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        channel,
        targetAudience,
        message,
        ctaUrl,
        status,
        sentCount,
        deliveredCount,
        openedCount,
        clickedCount,
        convertedCount,
        createdBy,
        createdAt,
      ];
}

class MarketingWebhookLog extends Equatable {
  final String id;
  final String eventType;
  final String campaignId;
  final String channel;
  final String recipient;
  final String source;
  final DateTime? receivedAt;

  const MarketingWebhookLog({
    required this.id,
    required this.eventType,
    this.campaignId = '',
    this.channel = 'PUSH',
    this.recipient = '',
    this.source = 'webhook',
    this.receivedAt,
  });

  factory MarketingWebhookLog.fromJson(Map<String, dynamic> json) {
    return MarketingWebhookLog(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      eventType: (json['eventType'] ?? 'DELIVERED').toString(),
      campaignId: (json['campaignId'] ?? '').toString(),
      channel: (json['channel'] ?? 'PUSH').toString(),
      recipient: (json['recipient'] ?? '').toString(),
      source: (json['source'] ?? 'webhook').toString(),
      receivedAt: json['receivedAt'] != null ? DateTime.tryParse(json['receivedAt'].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [id, eventType, campaignId, channel, recipient, source, receivedAt];
}
