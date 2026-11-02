import 'package:equatable/equatable.dart';
import '../../core/models/collection.dart';

abstract class CollectionEvent extends Equatable {
  const CollectionEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCollections extends CollectionEvent {
  const InitializeCollections();
}

class FetchCollections extends CollectionEvent {
  final bool isRefresh;
  final bool isBackground;

  const FetchCollections({
    this.isRefresh = false,
    this.isBackground = false,
  });

  @override
  List<Object?> get props => [isRefresh, isBackground];
}

class CreateCollection extends CollectionEvent {
  final String name;
  final String slug;
  final String description;
  final bool isActive;
  final int priority;
  final List<Map<String, dynamic>> subCollections;
  final String? bannerTitle;

  const CreateCollection({
    required this.name,
    required this.slug,
    required this.description,
    this.isActive = true,
    this.priority = 0,
    this.subCollections = const [],
    this.bannerTitle,
  });

  @override
  List<Object?> get props => [
        name,
        slug,
        description,
        isActive,
        priority,
        subCollections,
        bannerTitle,
      ];
}

class ResetCreateCollectionState extends CollectionEvent {
  const ResetCreateCollectionState();
}

class UpdateCollection extends CollectionEvent {
  final CollectionItem collection;

  const UpdateCollection(this.collection);

  @override
  List<Object?> get props => [collection];
}

class ResetUpdateCollectionState extends CollectionEvent {
  const ResetUpdateCollectionState();
}

class DeactivateCollection extends CollectionEvent {
  final String collectionId;

  const DeactivateCollection(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}

class ActivateCollection extends CollectionEvent {
  final String collectionId;

  const ActivateCollection(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}

class DeleteCollectionPermanently extends CollectionEvent {
  final String collectionId;

  const DeleteCollectionPermanently(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}

class BulkDeleteCollections extends CollectionEvent {
  final List<String> collectionIds;

  const BulkDeleteCollections(this.collectionIds);

  @override
  List<Object?> get props => [collectionIds];
}

class DeleteSubCollection extends CollectionEvent {
  final String collectionId;
  final String subCollectionId;

  const DeleteSubCollection({
    required this.collectionId,
    required this.subCollectionId,
  });

  @override
  List<Object?> get props => [collectionId, subCollectionId];
}

class BulkDeleteSubCollections extends CollectionEvent {
  final String collectionId;
  final List<String> subCollectionIds;

  const BulkDeleteSubCollections({
    required this.collectionId,
    required this.subCollectionIds,
  });

  @override
  List<Object?> get props => [collectionId, subCollectionIds];
}

class AddSubCollection extends CollectionEvent {
  final String collectionId;
  final String name;
  final String slug;
  final String? image;
  final bool isActive;

  const AddSubCollection({
    required this.collectionId,
    required this.name,
    required this.slug,
    this.image,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [collectionId, name, slug, image, isActive];
}

class ResetDeactivateCollectionState extends CollectionEvent {
  const ResetDeactivateCollectionState();
}
