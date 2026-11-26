import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/constants/api_endpoints.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/logic/auth/auth_bloc.dart';
import 'package:seller_hub/logic/category/category_bloc.dart';
import 'package:seller_hub/logic/order/order_bloc.dart';
import 'package:seller_hub/logic/product/product_bloc.dart';
import 'package:seller_hub/logic/product/product_event.dart';

enum _ArrangeScope { global, category, collection }

class ArrangeProductsView extends StatefulWidget {
  final bool isWide;
  final bool embedded;
  final List<Product>? initialProducts;

  const ArrangeProductsView({
    super.key,
    this.isWide = true,
    this.embedded = false,
    this.initialProducts,
  });

  @override
  State<ArrangeProductsView> createState() => _ArrangeProductsViewState();
}

class _ArrangeProductsViewState extends State<ArrangeProductsView> {
  _ArrangeScope _scope = _ArrangeScope.global;
  String? _selectedCategoryId;
  String? _selectedCollectionKey;
  String _highlightQuery = '';

  List<Map<String, dynamic>> _collections = const [];
  List<Product> _workingList = [];
  List<Product> _originalList = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialProducts != null && widget.initialProducts!.isNotEmpty) {
      _isLoading = false;
      _rebuildScopedList(widget.initialProducts!);
    }
    _loadScopeData();
  }

  Future<void> _loadScopeData() async {
    if (widget.initialProducts == null || widget.initialProducts!.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final api = context.read<OrderBloc>().apiClient;
      final futures = await Future.wait([
        api.get('${ApiEndpoints.adminProducts}?page=0&size=200&deleted=false', requiresAuth: true),
        api.get(ApiEndpoints.adminCollections, requiresAuth: true),
      ]);

      final prodData = futures[0]['data'];
      final rawItems = prodData is Map ? (prodData['content'] ?? prodData['items'] ?? prodData['products']) : null;
      final loadedProducts = rawItems is List
          ? rawItems.whereType<Map>().map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList()
          : (widget.initialProducts ?? <Product>[]);

      final colData = futures[1]['data'];
      final loadedCols = colData is List
          ? colData.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _collections = loadedCols;
        _isLoading = false;
      });
      _rebuildScopedList(loadedProducts);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _rebuildScopedList(List<Product> allProducts) {
    final active = allProducts.where((p) => !p.isDeleted && p.status.toUpperCase() == 'ACTIVE').toList();
    List<Product> filtered;
    if (_scope == _ArrangeScope.category && (_selectedCategoryId?.isNotEmpty ?? false)) {
      filtered = active.where((p) => p.categoryId == _selectedCategoryId || p.subCategoryIds.contains(_selectedCategoryId)).toList();
      filtered.sort((a, b) {
        final ao = a.categorySortOrders[_selectedCategoryId!] ?? a.displayOrder;
        final bo = b.categorySortOrders[_selectedCategoryId!] ?? b.displayOrder;
        final cmp = ao.compareTo(bo);
        return cmp != 0 ? cmp : a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    } else if (_scope == _ArrangeScope.collection && (_selectedCollectionKey?.isNotEmpty ?? false)) {
      filtered = active.where((p) =>
          p.assignedCollections.contains(_selectedCollectionKey) ||
          p.collectionIds.contains(_selectedCollectionKey) ||
          p.subCollectionIds.contains(_selectedCollectionKey)).toList();
      filtered.sort((a, b) {
        final ao = a.collectionSortOrders[_selectedCollectionKey!] ?? a.displayOrder;
        final bo = b.collectionSortOrders[_selectedCollectionKey!] ?? b.displayOrder;
        final cmp = ao.compareTo(bo);
        return cmp != 0 ? cmp : a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    } else {
      filtered = active;
      filtered.sort((a, b) {
        final cmp = a.displayOrder.compareTo(b.displayOrder);
        if (cmp != 0) return cmp;
        final feat = (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
        return feat != 0 ? feat : a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    }

    setState(() {
      _originalList = List<Product>.from(filtered);
      _workingList = List<Product>.from(filtered);
      _hasUnsavedChanges = false;
    });
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    if (_isSaving) return;
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= _workingList.length ||
        newIndex < 0 ||
        newIndex >= _workingList.length) {
      return;
    }
    setState(() {
      final item = _workingList.removeAt(oldIndex);
      _workingList.insert(newIndex, item);
      _hasUnsavedChanges = true;
    });
  }

  void _pushOutOfStockToBottom() {
    if (_isSaving || _workingList.length < 2) return;
    final inStock = _workingList.where((p) => p.isAvailable && p.stock > 0).toList();
    final outOfStock = _workingList.where((p) => !p.isAvailable || p.stock <= 0).toList();
    setState(() {
      _workingList = [...inStock, ...outOfStock];
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _openMoveToPositionDialog(int currentIndex) async {
    final ctrl = TextEditingController(text: '${currentIndex + 1}');
    final target = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Move "${_workingList[currentIndex].title}"', maxLines: 1, overflow: TextOverflow.ellipsis),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'New Position (1 to ${_workingList.length})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val >= 1 && val <= _workingList.length) {
                Navigator.pop(ctx, val - 1);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            child: const Text('Move'),
          ),
        ],
      ),
    );
    if (target != null && target != currentIndex) {
      _onReorderItem(currentIndex, target);
    }
  }

  Future<void> _publishOrder() async {
    if (_isSaving || !_hasUnsavedChanges || _workingList.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final api = context.read<OrderBloc>().apiClient;
      final orderedIds = _workingList.map((p) => p.id).toList();
      final body = <String, dynamic>{'orderedIds': orderedIds};
      if (_scope == _ArrangeScope.category && (_selectedCategoryId?.isNotEmpty ?? false)) {
        body['categoryId'] = _selectedCategoryId;
      } else if (_scope == _ArrangeScope.collection && (_selectedCollectionKey?.isNotEmpty ?? false)) {
        body['collectionKey'] = _selectedCollectionKey;
      }

      await api.put(ApiEndpoints.adminProductsReorder, body: body, requiresAuth: true);
      if (!mounted) return;
      context.read<ProductBloc>().add(const FetchProducts());
      setState(() {
        _originalList = List<Product>.from(_workingList);
        _hasUnsavedChanges = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('Storefront product order published live to ebskrishidukaan.com!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish order: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  void _discardChanges() {
    setState(() {
      _workingList = List<Product>.from(_originalList);
      _hasUnsavedChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF161E2E) : Colors.white;
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final session = context.watch<AuthBloc>().state.session;
    final canManage = session == null || session.isAdmin || session.hasPermission('CATALOG_MANAGE');
    final catState = context.watch<CategoryBloc>().state;
    final categories = catState.rootCategories;

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.embedded ? 0 : (widget.isWide ? 20 : 12),
        vertical: widget.embedded ? 4 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arrange Storefront Products',
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Drag & drop, pin to #1, or jump any product to an exact position. Publish to sync live.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
              if (canManage && _workingList.length > 1)
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pushOutOfStockToBottom,
                  icon: const Icon(Icons.low_priority_rounded, size: 17),
                  label: const Text('Push Out-of-Stock to Bottom'),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Reload Products',
                onPressed: _isLoading ? null : _loadScopeData,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Scope Selector + Quick Highlight Search
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Home / All Products'),
                  selected: _scope == _ArrangeScope.global,
                  onSelected: (_) {
                    setState(() => _scope = _ArrangeScope.global);
                    _loadScopeData();
                  },
                ),
                ChoiceChip(
                  label: const Text('By Category'),
                  selected: _scope == _ArrangeScope.category,
                  onSelected: (_) {
                    setState(() {
                      _scope = _ArrangeScope.category;
                      if (_selectedCategoryId == null && categories.isNotEmpty) {
                        _selectedCategoryId = categories.first.id;
                      }
                    });
                    _loadScopeData();
                  },
                ),
                ChoiceChip(
                  label: const Text('By Collection'),
                  selected: _scope == _ArrangeScope.collection,
                  onSelected: (_) {
                    setState(() {
                      _scope = _ArrangeScope.collection;
                      if (_selectedCollectionKey == null && _collections.isNotEmpty) {
                        _selectedCollectionKey = _collections.first['id']?.toString();
                      }
                    });
                    _loadScopeData();
                  },
                ),
                if (_scope == _ArrangeScope.category && categories.isNotEmpty)
                  DropdownButton<String>(
                    value: categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : categories.first.id,
                    items: categories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategoryId = val);
                      _loadScopeData();
                    },
                  ),
                if (_scope == _ArrangeScope.collection && _collections.isNotEmpty)
                  DropdownButton<String>(
                    value: _collections.any((c) => c['id']?.toString() == _selectedCollectionKey)
                        ? _selectedCollectionKey
                        : _collections.first['id']?.toString(),
                    items: _collections
                        .map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']?.toString() ?? 'Collection')))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedCollectionKey = val);
                      _loadScopeData();
                    },
                  ),
                SizedBox(
                  width: 240,
                  child: TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Highlight product by name/SKU...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _highlightQuery = v.trim().toLowerCase()),
                  ),
                ),
              ],
            ),
          ),

          if (_hasUnsavedChanges) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.publish_rounded, color: Color(0xFF059669)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have unsaved storefront arrangement changes.',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                  ),
                  TextButton(onPressed: _isSaving ? null : _discardChanges, child: const Text('Discard')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _publishOrder,
                    icon: _isSaving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.rocket_launch_rounded, size: 16),
                    label: Text(_isSaving ? 'Publishing...' : 'Publish Order Live'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
              child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFF991B1B))),
            )
          else if (_workingList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
              child: Center(child: Text('No active products in this scope.', style: TextStyle(color: textSecondary))),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _workingList.length,
              onReorderItem: (oldIdx, newIdx) {
                if (canManage) _onReorderItem(oldIdx, newIdx);
              },
              itemBuilder: (context, index) {
                final p = _workingList[index];
                final isHighlighted = _highlightQuery.isNotEmpty &&
                    (p.title.toLowerCase().contains(_highlightQuery) || p.sku.toLowerCase().contains(_highlightQuery));
                final inStock = p.isAvailable && p.stock > 0;
                final imgUrl = p.thumbnailUrl;

                return Container(
                  key: ValueKey(p.id),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isHighlighted ? const Color(0xFFFEF3C7).withValues(alpha: isDark ? 0.18 : 0.7) : surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isHighlighted ? const Color(0xFFD97706) : border, width: isHighlighted ? 1.6 : 1),
                  ),
                  child: Row(
                    children: [
                      if (canManage)
                        ReorderableDragStartListener(
                          index: index,
                          enabled: !_isSaving,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(Icons.drag_indicator_rounded, color: textSecondary),
                            ),
                          ),
                        ),
                      Container(
                        width: 38,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF059669)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imgUrl.isNotEmpty
                            ? Image.network(imgUrl, width: 46, height: 46, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.inventory_2_outlined))
                            : Container(width: 46, height: 46, color: const Color(0xFFF1F5F9), child: const Icon(Icons.inventory_2_outlined)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                            Text(
                              'SKU: ${p.sku} • ₹${p.price.toStringAsFixed(0)} • ${inStock ? "In Stock (${p.stock})" : "Out of Stock"}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: inStock ? textSecondary : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canManage) ...[
                        IconButton(
                          tooltip: 'Pin to #1',
                          onPressed: (_isSaving || index == 0) ? null : () => _onReorderItem(index, 0),
                          icon: const Icon(Icons.vertical_align_top_rounded, size: 18),
                        ),
                        IconButton(
                          tooltip: 'Move Up',
                          onPressed: (_isSaving || index == 0) ? null : () => _onReorderItem(index, index - 1),
                          icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                        ),
                        IconButton(
                          tooltip: 'Move Down',
                          onPressed: (_isSaving || index == _workingList.length - 1) ? null : () => _onReorderItem(index, index + 1),
                          icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                        ),
                        OutlinedButton(
                          onPressed: _isSaving ? null : () => _openMoveToPositionDialog(index),
                          child: const Text('Move to #'),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
    return widget.embedded ? content : SingleChildScrollView(child: content);
  }
}
