import 'package:equatable/equatable.dart';
import '../../core/models/collection.dart';

abstract class CollectionEvent extends Equatable {
  const CollectionEvent();

  @override
  List<Object?> get props => [];
}

class FetchCollections extends CollectionEvent {
  final bool isRefresh;

  const FetchCollections({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
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
