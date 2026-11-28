import 'package:equatable/equatable.dart';
import '../../core/models/marketing_models.dart';

enum MarketingStatus { initial, loading, loaded, submitting, error }

class MarketingState extends Equatable {
  final MarketingStatus status;
  final MarketingKpis kpis;
  final List<MarketingCampaignItem> campaigns;
  final List<MarketingWebhookLog> recentWebhooks;
  final String? errorMessage;
  final String? successMessage;

  const MarketingState({
    this.status = MarketingStatus.initial,
    this.kpis = const MarketingKpis(),
    this.campaigns = const [],
    this.recentWebhooks = const [],
    this.errorMessage,
    this.successMessage,
  });

  MarketingState copyWith({
    MarketingStatus? status,
    MarketingKpis? kpis,
    List<MarketingCampaignItem>? campaigns,
    List<MarketingWebhookLog>? recentWebhooks,
    String? errorMessage,
    String? successMessage,
  }) {
    return MarketingState(
      status: status ?? this.status,
      kpis: kpis ?? this.kpis,
      campaigns: campaigns ?? this.campaigns,
      recentWebhooks: recentWebhooks ?? this.recentWebhooks,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        kpis,
        campaigns,
        recentWebhooks,
        errorMessage,
        successMessage,
      ];
}
