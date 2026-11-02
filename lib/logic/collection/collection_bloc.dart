import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/collection.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/websocket_service.dart';
import '../../domain/repositories/collection_repository.dart';
import 'collection_event.dart';
import 'collection_state.dart';

class CollectionBloc extends Bloc<CollectionEvent, CollectionState> {
  final CollectionRepository collectionRepository;
  final WebSocketService _webSocketService;
  StreamSubscription? _wsSubscription;

  CollectionBloc({
    required this.collectionRepository,
    WebSocketService? webSocketService,
  })  : _webSocketService = webSocketService ?? WebSocketService(),
        super(const CollectionState()) {
    on<InitializeCollections>(_onInitializeCollections);
    on<FetchCollections>(_onFetchCollections);
    on<CreateCollection>(_onCreateCollection);
    on<ResetCreateCollectionState>(_onResetCreateCollectionState);
    on<UpdateCollection>(_onUpdateCollection);
    on<ResetUpdateCollectionState>(_onResetUpdateCollectionState);
    on<DeactivateCollection>(_onDeactivateCollection);
    on<ResetDeactivateCollectionState>(_onResetDeactivateCollectionState);
    on<ActivateCollection>(_onActivateCollection);
    on<DeleteCollectionPermanently>(_onDeleteCollectionPermanently);
    on<BulkDeleteCollections>(_onBulkDeleteCollections);
    on<DeleteSubCollection>(_onDeleteSubCollection);
    on<BulkDeleteSubCollections>(_onBulkDeleteSubCollections);
    on<AddSubCollection>(_onAddSubCollection);

    // Subscribe to real-time collection updates from WebSocket pipeline
    _wsSubscription = _webSocketService.collectionUpdates.listen((_) {
      add(const FetchCollections(isRefresh: true, isBackground: true));
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  void _onResetDeactivateCollectionState(
    ResetDeactivateCollectionState event,
    Emitter<CollectionState> emit,
  ) {
    emit(state.copyWith(
      isDeactivating: false,
      deactivateError: null,
      clearDeactivatedCollection: true,
    ));
  }

  void _onResetCreateCollectionState(
    ResetCreateCollectionState event,
    Emitter<CollectionState> emit,
  ) {
    emit(state.copyWith(
      isCreating: false,
      createError: null,
      clearCreatedCollection: true,
    ));
  }

  void _onResetUpdateCollectionState(
    ResetUpdateCollectionState event,
    Emitter<CollectionState> emit,
  ) {
    emit(state.copyWith(
      isUpdating: false,
      updateError: null,
      clearUpdatedCollection: true,
    ));
  }

  Future<void> _onUpdateCollection(
    UpdateCollection event,
    Emitter<CollectionState> emit,
  ) async {
    emit(state.copyWith(
      isUpdating: true,
      updateError: null,
      clearUpdatedCollection: true,
    ));

    try {
      final updatedItem = await collectionRepository.updateCollection(
        id: event.collection.id,
        collection: event.collection,
      );

      final currentItems = List<CollectionItem>.from(state.data.items);
      final index = currentItems.indexWhere((c) => c.id == updatedItem.id);
      if (index != -1) {
        currentItems[index] = updatedItem;
      } else {
        currentItems.insert(0, updatedItem);
      }

      final updatedData = CollectionsData(
        count: currentItems.length,
        items: currentItems,
      );

      emit(state.copyWith(
        status: CollectionStatus.loaded,
        data: updatedData,
        isUpdating: false,
        updatedCollection: updatedItem,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        updateError: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        updateError: 'Failed to update collection: $e',
      ));
    }
  }

  Future<void> _onDeactivateCollection(
    DeactivateCollection event,
    Emitter<CollectionState> emit,
  ) async {
    emit(state.copyWith(
      isDeactivating: true,
      deactivateError: null,
      clearDeactivatedCollection: true,
    ));

    try {
      final deactivatedItem = await collectionRepository.deactivateCollection(
        event.collectionId,
      );

      final currentItems = List<CollectionItem>.from(state.data.items);
      final index = currentItems.indexWhere((c) => c.id == deactivatedItem.id);
      if (index != -1) {
        currentItems[index] = deactivatedItem;
      } else {
        // In case id matching uses event.collectionId
        final fallbackIdx = currentItems.indexWhere((c) => c.id == event.collectionId);
        if (fallbackIdx != -1) {
          currentItems[fallbackIdx] = currentItems[fallbackIdx].copyWith(isActive: false);
        }
      }

      final updatedData = CollectionsData(
        count: currentItems.length,
        items: currentItems,
      );

      emit(state.copyWith(
        status: CollectionStatus.loaded,
        data: updatedData,
        isDeactivating: false,
        deactivatedCollection: deactivatedItem,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isDeactivating: false,
        deactivateError: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isDeactivating: false,
        deactivateError: 'Failed to deactivate collection: $e',
      ));
    }
  }

  Future<void> _onActivateCollection(
    ActivateCollection event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      final activatedItem = await collectionRepository.activateCollection(
        event.collectionId,
      );

      final currentItems = List<CollectionItem>.from(state.data.items);
      final index = currentItems.indexWhere((c) => c.id == activatedItem.id);
      if (index != -1) {
        currentItems[index] = activatedItem;
      } else {
        final fallbackIdx = currentItems.indexWhere((c) => c.id == event.collectionId);
        if (fallbackIdx != -1) {
          currentItems[fallbackIdx] = currentItems[fallbackIdx].copyWith(isActive: true);
        }
      }

      final updatedData = CollectionsData(
        count: currentItems.length,
        items: currentItems,
      );

      emit(state.copyWith(
        status: CollectionStatus.loaded,
        data: updatedData,
      ));
    } catch (_) {
      // Background retry on error
      add(const FetchCollections(isRefresh: true, isBackground: true));
    }
  }

  Future<void> _onDeleteCollectionPermanently(
    DeleteCollectionPermanently event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      await collectionRepository.deleteCollectionPermanently(
        event.collectionId,
      );

      final currentItems = List<CollectionItem>.from(state.data.items);
      currentItems.removeWhere((c) => c.id == event.collectionId);

      final updatedData = CollectionsData(
        count: currentItems.length,
        items: currentItems,
      );

      emit(state.copyWith(
        status: CollectionStatus.loaded,
        data: updatedData,
      ));
    } catch (_) {
      add(const FetchCollections(isRefresh: true, isBackground: true));
    }
  }

  Future<void> _onBulkDeleteCollections(
    BulkDeleteCollections event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      final deletedIds = await collectionRepository.deleteCollectionsPermanently(
        event.collectionIds,
      );
      final idSet = deletedIds.toSet();

      final currentItems = List<CollectionItem>.from(state.data.items);
      currentItems.removeWhere((c) => idSet.contains(c.id));

      final updatedData = CollectionsData(
        count: currentItems.length,
        items: currentItems,
      );

      emit(state.copyWith(
        status: CollectionStatus.loaded,
        data: updatedData,
      ));
    } catch (_) {
      add(const FetchCollections(isRefresh: true, isBackground: true));
    }
  }

  Future<void> _onDeleteSubCollection(
    DeleteSubCollection event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      final deletedIds = await collectionRepository.deleteSubCollection(
        collectionId: event.collectionId,
        subCollectionId: event.subCollectionId,
      );

      final currentItems = List<CollectionItem>.from(state.data.items);
      final index = currentItems.indexWhere((c) => c.id == event.collectionId);
      if (index != -1) {
        final col = currentItems[index];
        final updatedSubs = col.subCollections
            .where((s) => !deletedIds.contains(s.id))
            .toList();
        currentItems[index] = col.copyWith(
          subCollections: updatedSubs,
          subCollectionCount: updatedSubs.length,
        );

        final updatedData = CollectionsData(
          count: currentItems.length,
          items: currentItems,
        );

        emit(state.copyWith(
          status: CollectionStatus.loaded,
          data: updatedData,
        ));
      }
    } catch (_) {
      add(const FetchCollections(isRefresh: true, isBackground: true));
    }
  }

  Future<void> _onBulkDeleteSubCollections(
    BulkDeleteSubCollections event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      final deletedIds = await collectionRepository.deleteSubCollectionsBulk(
        collectionId: event.collectionId,
        subCollectionIds: event.subCollectionIds,
      );

      final currentItems = List<CollectionItem>.from(state.data.items);
      final index = currentItems.indexWhere((c) => c.id == event.collectionId);
      if (index != -1) {
        final col = currentItems[index];
        final updatedSubs = col.subCollections
            .where((s) => !deletedIds.contains(s.id))
            .toList();
        currentItems[index] = col.copyWith(
          subCollections: updatedSubs,
          subCollectionCount: updatedSubs.length,
        );

        final updatedData = CollectionsData(
          count: currentItems.length,
          items: currentItems,
        );

        emit(state.copyWith(
          status: CollectionStatus.loaded,
          data: updatedData,
        ));
      }
    } catch (_) {
      add(const FetchCollections(isRefresh: true, isBackground: true));
    }
  }

  Future<void> _onAddSubCollection(
    AddSubCollection event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      final updatedCollection = await collectionRepository.addSubCollection(
        collectionId: event.collectionId,
        name: event.name,
        slug: event.slug,
        image: event.image,
        isActive: event.isActive,
      );

      final currentItems = List<CollectionItem>.from(state.data.items);
      final index = currentItems.indexWhere((c) => c.id == event.collectionId);
      if (index != -1) {
        currentItems[index] = updatedCollection;
      } else {
        currentItems.insert(0, updatedCollection);
      }

      final updatedData = CollectionsData(
        count: currentItems.length,
        items: currentItems,
      );

      emit(state.copyWith(
        status: CollectionStatus.loaded,
        data: updatedData,
      ));
    } catch (_) {
      add(const FetchCollections(isRefresh: true, isBackground: true));
    }
  }

  Future<void> _onCreateCollection(
    CreateCollection event,
    Emitter<CollectionState> emit,
  ) async {
    emit(state.copyWith(
      isCreating: true,
      createError: null,
      clearCreatedCollection: true,
    ));

    try {
      final newItem = await collectionRepository.createCollection(
        name: event.name,
        slug: event.slug,
        description: event.description,
        isActive: event.isActive,
        priority: event.priority,
        subCollections: event.subCollections,
        bannerTitle: event.bannerTitle,
      );

      final currentItems = List<CollectionItem>.from(state.data.items);
      currentItems.insert(0, newItem);
      final updatedData = CollectionsData(
        count: currentItems.length,
        items: currentItems,
      );

      emit(state.copyWith(
        status: CollectionStatus.loaded,
        data: updatedData,
        isCreating: false,
        createdCollection: newItem,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isCreating: false,
        createError: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isCreating: false,
        createError: 'Failed to create collection: $e',
      ));
    }
  }

  Future<void> _onInitializeCollections(
    InitializeCollections event,
    Emitter<CollectionState> emit,
  ) async {
    // 1. Immediately hydrate with locally cached collections (0ms instant render)
    final cached = await collectionRepository.getCachedCollections();
    if (cached != null && cached.items.isNotEmpty) {
      emit(state.copyWith(
        status: CollectionStatus.loaded,
        data: cached,
        errorMessage: null,
      ));
      // 2. Background silent freshness sync
      add(const FetchCollections(isRefresh: true, isBackground: true));
    } else {
      // No local cache yet: standard initial fetch
      add(const FetchCollections(isRefresh: false, isBackground: false));
    }
  }

  Future<void> _onFetchCollections(
    FetchCollections event,
    Emitter<CollectionState> emit,
  ) async {
    final hasExistingData = (state.status == CollectionStatus.loaded && state.collections.isNotEmpty) || event.isBackground;

    if (!hasExistingData || (event.isRefresh && !event.isBackground)) {
      emit(state.copyWith(
        status: CollectionStatus.loading,
        errorMessage: null,
      ));
    }

    try {
      final collectionsData = await collectionRepository.getCollections();
      emit(state.copyWith(
        status: CollectionStatus.loaded,
        data: collectionsData,
        errorMessage: null,
      ));
    } on ApiException catch (e) {
      if (!hasExistingData) {
        emit(state.copyWith(
          status: CollectionStatus.error,
          errorMessage: e.message,
        ));
      }
    } catch (e) {
      if (!hasExistingData) {
        emit(state.copyWith(
          status: CollectionStatus.error,
          errorMessage: 'Failed to load collections: $e',
        ));
      }
    }
  }
}
