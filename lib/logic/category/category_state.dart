import 'package:equatable/equatable.dart';
import '../../core/models/category.dart';

enum CategoryStatus { initial, loading, loaded, error }

class CategoryState extends Equatable {
  final CategoryStatus status;
  final List<CategoryItem> allCategories;
  final List<CategoryItem> rootCategories;
  final Map<String, List<CategoryItem>> childrenByParentId;
  final Map<String, CategoryItem> categoryById;
  final Set<String> expandedCategoryIds;
  final String searchQuery;
  final int? selectedLevelFilter;
  final String? errorMessage;

  const CategoryState({
    this.status = CategoryStatus.initial,
    this.allCategories = const [],
    this.rootCategories = const [],
    this.childrenByParentId = const {},
    this.categoryById = const {},
    this.expandedCategoryIds = const {},
    this.searchQuery = '',
    this.selectedLevelFilter,
    this.errorMessage,
  });

  int get totalCount => allCategories.length;
  int get rootCount => allCategories.where((c) => c.level == 0).length;
  int get subCount => allCategories.where((c) => c.level == 1).length;
  int get leafCount => allCategories.where((c) => c.level == 2).length;
  int get activeCount => allCategories.where((c) => c.isActive).length;
  int get inactiveCount => allCategories.where((c) => !c.isActive).length;

  /// Returns the tree filtered by search query and level filter
  List<CategoryItem> get filteredTree {
    final query = searchQuery.trim().toLowerCase();

    // Helper to check if item matches query
    bool itemMatches(CategoryItem item) {
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          item.slug.toLowerCase().contains(query);
    }

    if (query.isEmpty && selectedLevelFilter == null) {
      return rootCategories;
    }

    // If level filter is selected and NOT level 0:
    if (selectedLevelFilter != null && selectedLevelFilter != 0) {
      // Return flat filtered list of categories for that specific level
      final matchingLevel = allCategories.where((c) {
        if (c.level != selectedLevelFilter) return false;
        if (query.isNotEmpty && !itemMatches(c)) return false;
        return true;
      }).toList();
      return matchingLevel;
    }

    // Filter tree preserving hierarchy:
    List<CategoryItem> filterSubtree(List<CategoryItem> nodes) {
      final result = <CategoryItem>[];
      for (final node in nodes) {
        final filteredChildren = filterSubtree(node.children);
        final matchesSelf = itemMatches(node) && (selectedLevelFilter == null || node.level == selectedLevelFilter);
        final hasMatchingDescendants = filteredChildren.isNotEmpty;

        if (matchesSelf || hasMatchingDescendants) {
          result.add(node.copyWith(children: filteredChildren));
        }
      }
      return result;
    }

    return filterSubtree(rootCategories);
  }

  CategoryState copyWith({
    CategoryStatus? status,
    List<CategoryItem>? allCategories,
    List<CategoryItem>? rootCategories,
    Map<String, List<CategoryItem>>? childrenByParentId,
    Map<String, CategoryItem>? categoryById,
    Set<String>? expandedCategoryIds,
    String? searchQuery,
    int? selectedLevelFilter,
    bool clearLevelFilter = false,
    String? errorMessage,
  }) {
    return CategoryState(
      status: status ?? this.status,
      allCategories: allCategories ?? this.allCategories,
      rootCategories: rootCategories ?? this.rootCategories,
      childrenByParentId: childrenByParentId ?? this.childrenByParentId,
      categoryById: categoryById ?? this.categoryById,
      expandedCategoryIds: expandedCategoryIds ?? this.expandedCategoryIds,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLevelFilter: clearLevelFilter ? null : (selectedLevelFilter ?? this.selectedLevelFilter),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allCategories,
        rootCategories,
        childrenByParentId,
        categoryById,
        expandedCategoryIds,
        searchQuery,
        selectedLevelFilter,
        errorMessage,
      ];
}
