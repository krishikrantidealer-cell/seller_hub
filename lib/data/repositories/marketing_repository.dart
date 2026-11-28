import '../../core/constants/api_endpoints.dart';
import '../../core/models/marketing_models.dart';
import '../../core/network/api_client.dart';

class MarketingOverviewData {
  final MarketingKpis kpis;
  final List<MarketingCampaignItem> campaigns;
  final List<MarketingWebhookLog> recentWebhooks;

  const MarketingOverviewData({
    required this.kpis,
    required this.campaigns,
    required this.recentWebhooks,
  });
}

class MarketingRepository {
  final ApiClient apiClient;

  MarketingRepository(this.apiClient);

  Future<MarketingOverviewData> fetchOverview() async {
    final res = await apiClient.get(ApiEndpoints.adminMarketingOverview, requiresAuth: true);
    final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : <String, dynamic>{};

    final rawKpis = data['kpis'] is Map ? Map<String, dynamic>.from(data['kpis'] as Map) : <String, dynamic>{};
    final rawCampaigns = data['campaigns'] as List<dynamic>? ?? const [];
    final rawWebhooks = data['recentWebhooks'] as List<dynamic>? ?? const [];

    return MarketingOverviewData(
      kpis: MarketingKpis.fromJson(rawKpis),
      campaigns: rawCampaigns
          .whereType<Map>()
          .map((e) => MarketingCampaignItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      recentWebhooks: rawWebhooks
          .whereType<Map>()
          .map((e) => MarketingWebhookLog.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Future<MarketingCampaignItem> createCampaign({
    required String title,
    required String channel,
    required String targetAudience,
    required String message,
    String ctaUrl = '',
    String status = 'ACTIVE',
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.adminMarketingCampaigns,
      requiresAuth: true,
      body: {
        'title': title,
        'channel': channel,
        'targetAudience': targetAudience,
        'message': message,
        if (ctaUrl.isNotEmpty) 'ctaUrl': ctaUrl,
        'status': status,
      },
    );
    final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : <String, dynamic>{};
    return MarketingCampaignItem.fromJson(data);
  }

  Future<MarketingCampaignItem> updateCampaignStatus({
    required String id,
    required String status,
  }) async {
    final res = await apiClient.patch(
      ApiEndpoints.adminMarketingCampaignStatus(id),
      requiresAuth: true,
      body: {'status': status},
    );
    final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : <String, dynamic>{};
    return MarketingCampaignItem.fromJson(data);
  }
}
