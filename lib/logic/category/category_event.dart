import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

/// Instant 0ms cache hydration event
class InitializeCategories extends CategoryEvent {
  const InitializeCategories();
}

/// Fetches categories from the backend
class FetchCategories extends CategoryEvent {
  final bool isRefresh;
  final bool isBackground;

  const FetchCategories({
    this.isRefresh = false,
    this.isBackground = false,
  });

  @override
  List<Object?> get props => [isRefresh, isBackground];
}

/// Real-time search filter
class FilterCategories extends CategoryEvent {
  final String query;

  const FilterCategories(this.query);

  @override
  List<Object?> get props => [query];
}

/// Level filter: 0 = Root, 1 = Sub, 2 = Leaf, null = All
class SelectLevelFilter extends CategoryEvent {
  final int? level;

  const SelectLevelFilter(this.level);

  @override
  List<Object?> get props => [level];
}

/// Toggles expansion of a category node in the tree
class ToggleCategoryExpanded extends CategoryEvent {
  final String categoryId;

  const ToggleCategoryExpanded(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// Expands all nodes in the tree
class ExpandAllCategories extends CategoryEvent {
  const ExpandAllCategories();
}

/// Collapses all nodes in the tree
class CollapseAllCategories extends CategoryEvent {
  const CollapseAllCategories();
}

/// Creates a new category
class CreateCategory extends CategoryEvent {
  final String name;
  final String slug;
  final String? parentId;
  final int? sortOrder;
  final String? iconUrl;
  final bool isActive;

  const CreateCategory({
    required this.name,
    required this.slug,
    this.parentId,
    this.sortOrder,
    this.iconUrl,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [name, slug, parentId, sortOrder, iconUrl, isActive];
}

/// Updates an existing category
class UpdateCategory extends CategoryEvent {
  final String id;
  final String name;
  final String slug;
  final String? parentId;
  final int? sortOrder;
  final String? iconUrl;
  final bool isActive;

  const UpdateCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.sortOrder,
    this.iconUrl,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, slug, parentId, sortOrder, iconUrl, isActive];
}

/// Deactivates a category
class DeactivateCategory extends CategoryEvent {
  final String id;

  const DeactivateCategory(this.id);

  @override
  List<Object?> get props => [id];
}
