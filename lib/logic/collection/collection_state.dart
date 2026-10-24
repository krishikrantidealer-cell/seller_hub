import 'package:equatable/equatable.dart';
import '../../core/models/collection.dart';

enum CollectionStatus { initial, loading, loaded, error }

class CollectionState extends Equatable {
  final CollectionStatus status;
  final CollectionsData data;
  final String? errorMessage;
  final bool isCreating;
  final String? createError;
  final CollectionItem? createdCollection;
  final bool isUpdating;
  final String? updateError;
  final CollectionItem? updatedCollection;

  const CollectionState({
    this.status = CollectionStatus.initial,
    this.data = const CollectionsData(),
    this.errorMessage,
    this.isCreating = false,
    this.createError,
    this.createdCollection,
    this.isUpdating = false,
    this.updateError,
    this.updatedCollection,
  });

  List<CollectionItem> get collections => data.items;
  int get totalCollections => data.count;
  int get totalSubCollections =>
      data.items.fold(0, (sum, c) => sum + c.subCollections.length);
  int get activeCollectionsCount =>
      data.items.where((c) => c.isActive).length;
  int get totalMappedProducts =>
      data.items.fold(0, (sum, c) => sum + c.productCount);

  CollectionState copyWith({
    CollectionStatus? status,
    CollectionsData? data,
    String? errorMessage,
    bool? isCreating,
    String? createError,
    CollectionItem? createdCollection,
    bool clearCreatedCollection = false,
    bool? isUpdating,
    String? updateError,
    CollectionItem? updatedCollection,
    bool clearUpdatedCollection = false,
  }) {
    return CollectionState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
      isCreating: isCreating ?? this.isCreating,
      createError: createError,
      createdCollection: clearCreatedCollection
          ? null
          : (createdCollection ?? this.createdCollection),
      isUpdating: isUpdating ?? this.isUpdating,
      updateError: updateError,
      updatedCollection: clearUpdatedCollection
          ? null
          : (updatedCollection ?? this.updatedCollection),
    );
  }

  @override
  List<Object?> get props => [
        status,
        data,
        errorMessage,
        isCreating,
        createError,
        createdCollection,
        isUpdating,
        updateError,
        updatedCollection,
      ];
}
