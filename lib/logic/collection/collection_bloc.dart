import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/collection.dart';
import '../../core/network/api_exception.dart';
import '../../domain/repositories/collection_repository.dart';
import 'collection_event.dart';
import 'collection_state.dart';

class CollectionBloc extends Bloc<CollectionEvent, CollectionState> {
  final CollectionRepository collectionRepository;

  CollectionBloc({required this.collectionRepository}) : super(const CollectionState()) {
    on<FetchCollections>(_onFetchCollections);
    on<CreateCollection>(_onCreateCollection);
    on<ResetCreateCollectionState>(_onResetCreateCollectionState);
    on<UpdateCollection>(_onUpdateCollection);
    on<ResetUpdateCollectionState>(_onResetUpdateCollectionState);
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

  Future<void> _onFetchCollections(
    FetchCollections event,
    Emitter<CollectionState> emit,
  ) async {
    final hasExistingData = state.status == CollectionStatus.loaded && state.collections.isNotEmpty;

    if (!hasExistingData || event.isRefresh) {
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
