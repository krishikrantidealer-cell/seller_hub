import 'package:equatable/equatable.dart';

abstract class MarketingEvent extends Equatable {
  const MarketingEvent();

  @override
  List<Object?> get props => [];
}

class LoadMarketingOverview extends MarketingEvent {
  final bool isRefresh;

  const LoadMarketingOverview({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class CreateMarketingCampaign extends MarketingEvent {
  final String title;
  final String channel;
  final String targetAudience;
  final String message;
  final String ctaUrl;
  final String status;

  const CreateMarketingCampaign({
    required this.title,
    required this.channel,
    required this.targetAudience,
    required this.message,
    this.ctaUrl = '',
    this.status = 'ACTIVE',
  });

  @override
  List<Object?> get props => [title, channel, targetAudience, message, ctaUrl, status];
}

class UpdateCampaignStatus extends MarketingEvent {
  final String id;
  final String status;

  const UpdateCampaignStatus({
    required this.id,
    required this.status,
  });

  @override
  List<Object?> get props => [id, status];
}

class WebSocketMarketingEventReceived extends MarketingEvent {
  final Map<String, dynamic> payload;

  const WebSocketMarketingEventReceived(this.payload);

  @override
  List<Object?> get props => [payload];
}
