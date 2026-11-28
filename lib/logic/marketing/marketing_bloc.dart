import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/marketing_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/websocket_service.dart';
import '../../data/repositories/marketing_repository.dart';
import 'marketing_event.dart';
import 'marketing_state.dart';

class MarketingBloc extends Bloc<MarketingEvent, MarketingState> {
  final MarketingRepository repository;
  final WebSocketService _webSocketService;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  MarketingBloc({
    required this.repository,
    WebSocketService? webSocketService,
  })  : _webSocketService = webSocketService ?? WebSocketService(),
        super(const MarketingState()) {
    on<LoadMarketingOverview>(_onLoadOverview);
    on<CreateMarketingCampaign>(_onCreateCampaign);
    on<UpdateCampaignStatus>(_onUpdateCampaignStatus);
    on<WebSocketMarketingEventReceived>(_onWsEventReceived);

    _wsSubscription = _webSocketService.marketingUpdates.listen((payload) {
      add(WebSocketMarketingEventReceived(payload));
    });
  }

  Future<void> _onLoadOverview(
    LoadMarketingOverview event,
    Emitter<MarketingState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: MarketingStatus.loading, errorMessage: null));
    }
    try {
      final data = await repository.fetchOverview();
      emit(state.copyWith(
        status: MarketingStatus.loaded,
        kpis: data.kpis,
        campaigns: data.campaigns,
        recentWebhooks: data.recentWebhooks,
        errorMessage: null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: MarketingStatus.error, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(status: MarketingStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateCampaign(
    CreateMarketingCampaign event,
    Emitter<MarketingState> emit,
  ) async {
    emit(state.copyWith(status: MarketingStatus.submitting, errorMessage: null));
    try {
      final created = await repository.createCampaign(
        title: event.title,
        channel: event.channel,
        targetAudience: event.targetAudience,
        message: event.message,
        ctaUrl: event.ctaUrl,
        status: event.status,
      );
      final updatedList = [
        created,
        ...state.campaigns.where((c) => c.id != created.id),
      ];
      emit(state.copyWith(
        status: MarketingStatus.loaded,
        campaigns: updatedList,
        successMessage: 'Campaign "${created.title}" launched & synced live!',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: MarketingStatus.error, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(status: MarketingStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateCampaignStatus(
    UpdateCampaignStatus event,
    Emitter<MarketingState> emit,
  ) async {
    try {
      final updated = await repository.updateCampaignStatus(
        id: event.id,
        status: event.status,
      );
      final updatedList = state.campaigns.map((c) => c.id == updated.id ? updated : c).toList();
      emit(state.copyWith(
        status: MarketingStatus.loaded,
        campaigns: updatedList,
        successMessage: 'Campaign status updated to ${updated.status}',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: MarketingStatus.error, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(status: MarketingStatus.error, errorMessage: e.toString()));
    }
  }

  void _onWsEventReceived(
    WebSocketMarketingEventReceived event,
    Emitter<MarketingState> emit,
  ) {
    final eventName = event.payload['event']?.toString() ?? '';
    final rawData = event.payload['data'];
    if (rawData is! Map) return;
    final data = Map<String, dynamic>.from(rawData);

    if (eventName == 'marketing:campaign_updated' && data['campaign'] is Map) {
      final updated = MarketingCampaignItem.fromJson(
        Map<String, dynamic>.from(data['campaign'] as Map),
      );
      final exists = state.campaigns.any((c) => c.id == updated.id);
      final updatedList = exists
          ? state.campaigns.map((c) => c.id == updated.id ? updated : c).toList()
          : [updated, ...state.campaigns];
      emit(state.copyWith(
        status: MarketingStatus.loaded,
        campaigns: updatedList,
      ));
    } else if (eventName == 'engagement:webhook_received') {
      final logItem = MarketingWebhookLog.fromJson(data);
      final updatedLogs = [
        logItem,
        ...state.recentWebhooks.where((w) => w.id != logItem.id),
      ].take(30).toList();
      emit(state.copyWith(
        status: MarketingStatus.loaded,
        recentWebhooks: updatedLogs,
      ));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
