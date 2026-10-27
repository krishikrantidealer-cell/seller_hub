import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository categoryRepository;

  CategoryBloc({required this.categoryRepository}) : super(const CategoryState()) {
    on<InitializeCategories>(_onInitializeCategories);
    on<FetchCategories>(_onFetchCategories);
    on<FilterCategories>(_onFilterCategories);
    on<SelectLevelFilter>(_onSelectLevelFilter);
    on<ToggleCategoryExpanded>(_onToggleCategoryExpanded);
    on<ExpandAllCategories>(_onExpandAllCategories);
    on<CollapseAllCategories>(_onCollapseAllCategories);
    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeactivateCategory>(_onDeactivateCategory);
  }

  Future<void> _onInitializeCategories(
    InitializeCategories event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final cached = await categoryRepository.getCachedCategories();
      if (cached != null && cached.isNotEmpty) {
        final treeData = _buildTreeAndLookups(cached);
        emit(state.copyWith(
          status: CategoryStatus.loaded,
          allCategories: cached,
          rootCategories: treeData.roots,
          childrenByParentId: treeData.childrenByParentId,
          categoryById: treeData.categoryById,
          expandedCategoryIds: treeData.initialExpandedIds,
        ));
        add(const FetchCategories(isBackground: true));
        return;
      }
    } catch (_) {}

    add(const FetchCategories());
  }

  Future<void> _onFetchCategories(
    FetchCategories event,
    Emitter<CategoryState> emit,
  ) async {
    if (!event.isBackground && state.status != CategoryStatus.loaded) {
      emit(state.copyWith(status: CategoryStatus.loading));
    }

    try {
      final categories = await categoryRepository.getCategories(forceRefresh: true);
      final treeData = _buildTreeAndLookups(categories);

      // Preserve existing expanded IDs or initialize with roots
      final currentExpanded = Set<String>.from(state.expandedCategoryIds);
      if (currentExpanded.isEmpty) {
        currentExpanded.addAll(treeData.initialExpandedIds);
      }

      emit(state.copyWith(
        status: CategoryStatus.loaded,
        allCategories: categories,
        rootCategories: treeData.roots,
        childrenByParentId: treeData.childrenByParentId,
        categoryById: treeData.categoryById,
        expandedCategoryIds: currentExpanded,
      ));
    } catch (e) {
      if (!event.isBackground || state.status != CategoryStatus.loaded) {
        emit(state.copyWith(
          status: CategoryStatus.error,
          errorMessage: e.toString().replaceAll('ApiException: ', ''),
        ));
      }
    }
  }

  void _onFilterCategories(
    FilterCategories event,
    Emitter<CategoryState> emit,
  ) {
    final query = event.query.trim().toLowerCase();
    final newExpanded = Set<String>.from(state.expandedCategoryIds);

    if (query.isNotEmpty) {
      // Auto-expand parents of matching nodes so search results are instantly visible
      for (final cat in state.allCategories) {
        if (cat.name.toLowerCase().contains(query) || cat.slug.toLowerCase().contains(query)) {
          String? currentParentId = cat.parentId;
          while (currentParentId != null && currentParentId.isNotEmpty) {
            newExpanded.add(currentParentId);
            final parent = state.categoryById[currentParentId];
            currentParentId = parent?.parentId;
          }
        }
      }
    }

    emit(state.copyWith(
      searchQuery: event.query,
      expandedCategoryIds: newExpanded,
    ));
  }

  void _onSelectLevelFilter(
    SelectLevelFilter event,
    Emitter<CategoryState> emit,
  ) {
    if (event.level == null) {
      emit(state.copyWith(clearLevelFilter: true));
    } else {
      emit(state.copyWith(selectedLevelFilter: event.level));
    }
  }

  void _onToggleCategoryExpanded(
    ToggleCategoryExpanded event,
    Emitter<CategoryState> emit,
  ) {
    final newExpanded = Set<String>.from(state.expandedCategoryIds);
    if (newExpanded.contains(event.categoryId)) {
      newExpanded.remove(event.categoryId);
    } else {
      newExpanded.add(event.categoryId);
    }
    emit(state.copyWith(expandedCategoryIds: newExpanded));
  }

  void _onExpandAllCategories(
    ExpandAllCategories event,
    Emitter<CategoryState> emit,
  ) {
    final allParentIds = <String>{};
    for (final cat in state.allCategories) {
      if (state.childrenByParentId[cat.id]?.isNotEmpty ?? false) {
        allParentIds.add(cat.id);
      }
    }
    emit(state.copyWith(expandedCategoryIds: allParentIds));
  }

  void _onCollapseAllCategories(
    CollapseAllCategories event,
    Emitter<CategoryState> emit,
  ) {
    emit(state.copyWith(expandedCategoryIds: const {}));
  }

  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await categoryRepository.createCategory(
        name: event.name,
        slug: event.slug,
        parentId: event.parentId,
        sortOrder: event.sortOrder,
        isActive: event.isActive,
      );
      add(const FetchCategories(isRefresh: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString().replaceAll('ApiException: ', '')));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await categoryRepository.updateCategory(
        id: event.id,
        name: event.name,
        slug: event.slug,
        parentId: event.parentId,
        sortOrder: event.sortOrder,
        isActive: event.isActive,
      );
      add(const FetchCategories(isRefresh: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString().replaceAll('ApiException: ', '')));
    }
  }

  Future<void> _onDeactivateCategory(
    DeactivateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await categoryRepository.deactivateCategory(event.id);
      add(const FetchCategories(isRefresh: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString().replaceAll('ApiException: ', '')));
    }
  }

  /// Builds a tree structure from flat categories list and returns root items with nested children
  _TreeBuildResult _buildTreeAndLookups(List<CategoryItem> categories) {
    final categoryById = <String, CategoryItem>{};
    final childrenByParentId = <String, List<CategoryItem>>{};

    for (final c in categories) {
      categoryById[c.id] = c;
      if (c.parentId != null && c.parentId!.isNotEmpty) {
        childrenByParentId.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    // Sort children by sortOrder ASC, then name ASC
    for (final children in childrenByParentId.values) {
      children.sort((a, b) {
        final cmp = a.sortOrder.compareTo(b.sortOrder);
        if (cmp != 0) return cmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    // Assemble 3 levels:
    // Level 0: roots (parentId == null || parentId is empty || level == 0)
    final rootItems = categories.where((c) => c.level == 0 || c.parentId == null || c.parentId!.isEmpty).toList();
    rootItems.sort((a, b) {
      final cmp = a.sortOrder.compareTo(b.sortOrder);
      if (cmp != 0) return cmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    final initialExpandedIds = <String>{};

    final fullRoots = rootItems.map((root) {
      initialExpandedIds.add(root.id);

      final l1Children = childrenByParentId[root.id] ?? [];
      final fullL1Children = l1Children.map((l1) {
        final l2Children = childrenByParentId[l1.id] ?? [];
        return l1.copyWith(children: l2Children);
      }).toList();

      return root.copyWith(children: fullL1Children);
    }).toList();

    return _TreeBuildResult(
      roots: fullRoots,
      categoryById: categoryById,
      childrenByParentId: childrenByParentId,
      initialExpandedIds: initialExpandedIds,
    );
  }
}

class _TreeBuildResult {
  final List<CategoryItem> roots;
  final Map<String, CategoryItem> categoryById;
  final Map<String, List<CategoryItem>> childrenByParentId;
  final Set<String> initialExpandedIds;

  _TreeBuildResult({
    required this.roots,
    required this.categoryById,
    required this.childrenByParentId,
    required this.initialExpandedIds,
  });
}
