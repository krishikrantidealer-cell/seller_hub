import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/technical_name.dart';
import '../../../data/datasources/technical_name_service.dart';
import '../../../logic/category/category_bloc.dart';
import '../../../logic/category/category_event.dart';
import '../../../logic/category/category_state.dart';

/// Shared modal dialog to create or edit a Technical Name + Commission (%).
Future<TechnicalNameModel?> showTechnicalNameEditorDialog(
  BuildContext context, {
  TechnicalNameModel? existing,
  String? initialName,
  List<String>? availableCategories,
}) {
  return showDialog<TechnicalNameModel>(
    context: context,
    builder: (ctx) => _TechnicalNameEditorDialog(
      existing: existing,
      initialName: initialName,
      availableCategories: availableCategories,
    ),
  );
}

class _TechnicalNameEditorDialog extends StatefulWidget {
  final TechnicalNameModel? existing;
  final String? initialName;
  final List<String>? availableCategories;

  const _TechnicalNameEditorDialog({
    this.existing,
    this.initialName,
    this.availableCategories,
  });

  @override
  State<_TechnicalNameEditorDialog> createState() =>
      _TechnicalNameEditorDialogState();
}

class _TechnicalNameEditorDialogState
    extends State<_TechnicalNameEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _commissionController;
  String? _selectedCategory;
  bool _isActive = true;
  bool _syncProducts = false;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existing?.name ?? widget.initialName ?? '',
    );
    final existingCat = widget.existing?.category.trim() ?? '';
    _selectedCategory = existingCat.isNotEmpty ? existingCat : null;
    final comm = widget.existing?.commissionPercentage;
    _commissionController = TextEditingController(
      text: comm != null
          ? (comm == comm.roundToDouble()
              ? comm.toInt().toString()
              : comm.toString())
          : '',
    );
    _isActive = widget.existing?.isActive ?? true;
    final categoryBloc = context.read<CategoryBloc>();
    if (categoryBloc.state.allCategories.isEmpty) {
      categoryBloc.add(const InitializeCategories());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final name = _nameController.text.trim();
    final category = (_selectedCategory ?? '').trim();
    final commission =
        double.tryParse(_commissionController.text.trim()) ?? 0.0;

    try {
      final service = TechnicalNameService();
      final TechnicalNameModel saved;
      if (_isEditing) {
        saved = await service.updateTechnicalName(
          widget.existing!.id,
          name: name,
          category: category,
          commissionPercentage: commission,
          isActive: _isActive,
          syncProducts: _syncProducts,
        );
      } else {
        saved = await service.createTechnicalName(
          name: name,
          category: category,
          commissionPercentage: commission,
          isActive: _isActive,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<String?> _showCategorySearchPicker(
    BuildContext context, {
    required List<String> options,
    required String? selected,
    required bool isDark,
    required Color bgColor,
    required Color textPrimary,
    required Color textMuted,
  }) async {
    final searchCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final q = searchCtrl.text.trim().toLowerCase();
            final filtered = q.isEmpty
                ? options
                : options.where((o) => o.toLowerCase().contains(q)).toList();

            return Dialog(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select Category',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            icon: Icon(Icons.close, color: textMuted, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search categories...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    searchCtrl.clear();
                                    setDialogState(() {});
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  q.isEmpty
                                      ? 'No categories available'
                                      : 'No categories match "$q"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: textMuted, fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                ),
                                itemBuilder: (_, index) {
                                  final item = filtered[index];
                                  final isSelected = item == selected;
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      item,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 18)
                                        : null,
                                    onTap: () => Navigator.of(dialogCtx).pop(item),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    searchCtrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'Edit Technical Name'
                            : 'Add Technical Name',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: textMuted, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Technical Name *',
                    hintText: 'e.g. Chlorpyrifos 20% EC',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Technical name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, catState) {
                    final all = catState.allCategories;
                    final optionSet = <String>{
                      ...all
                          .map((c) => c.name.trim())
                          .where((n) => n.isNotEmpty),
                      if (_selectedCategory != null &&
                          _selectedCategory!.trim().isNotEmpty)
                        _selectedCategory!.trim(),
                    };
                    final options = optionSet.toList()..sort();

                    return FormField<String>(
                      initialValue: _selectedCategory,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Category is required';
                        }
                        return null;
                      },
                      builder: (fieldState) {
                        final displayValue = _selectedCategory ?? '';
                        return InkWell(
                          onTap: () async {
                            final picked = await _showCategorySearchPicker(
                              context,
                              options: options,
                              selected: _selectedCategory,
                              isDark: isDark,
                              bgColor: bgColor,
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                            );
                            if (picked != null) {
                              setState(() => _selectedCategory = picked);
                              fieldState.didChange(picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Category *',
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              errorText: fieldState.errorText,
                              suffixIcon: const Icon(Icons.search_rounded, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            isEmpty: false,
                            child: Text(
                              displayValue.isEmpty
                                  ? 'Search & select category...'
                                  : displayValue,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: displayValue.isEmpty ? textMuted : textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _commissionController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Commission (%) *',
                    hintText: 'e.g. 15',
                    suffixText: '%',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Commission is required';
                    }
                    final numVal = double.tryParse(v.trim());
                    if (numVal == null || numVal < 0 || numVal > 100) {
                      return 'Enter a value between 0 and 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                if (_isEditing)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _syncProducts,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) =>
                        setState(() => _syncProducts = val ?? false),
                    title: Text(
                      'Sync commission to existing products',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Updates variants on matching products to use this commission.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing ? 'Save Changes' : 'Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Searchable Technical Name dropdown field that auto-fetches Commission (%).
class TechnicalNameSelector extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<TechnicalNameModel> onSelected;
  final bool isDark;
  final bool isRequired;
  final bool isAdmin;

  const TechnicalNameSelector({
    super.key,
    required this.controller,
    required this.onSelected,
    required this.isDark,
    this.isRequired = true,
    this.isAdmin = false,
  });

  @override
  State<TechnicalNameSelector> createState() => _TechnicalNameSelectorState();
}

class _TechnicalNameSelectorState extends State<TechnicalNameSelector> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _fieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  List<TechnicalNameModel> _items = [];
  bool _isLoading = false;
  String? _loadError;
  TechnicalNameModel? _matchedItem;

  @override
  void initState() {
    super.initState();
    _loadItems();
    widget.controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    widget.controller.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _openDropdown();
    }
  }

  void _onControllerChanged() {
    _syncMatchedFromController();
    _overlayEntry?.markNeedsBuild();
  }

  Future<void> _loadItems({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final list = await TechnicalNameService().fetchSellerTechnicalNames(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _items = list.where((e) => e.isActive).toList();
        _isLoading = false;
      });
      _syncMatchedFromController();
      _overlayEntry?.markNeedsBuild();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _syncMatchedFromController() {
    final current = widget.controller.text.trim().toLowerCase();
    if (current.isEmpty || _items.isEmpty) {
      if (_matchedItem != null && mounted) {
        setState(() => _matchedItem = null);
      }
      return;
    }
    final match = _items
        .where((e) => e.name.trim().toLowerCase() == current)
        .firstOrNull;
    if (match?.id != _matchedItem?.id && mounted) {
      setState(() => _matchedItem = match);
    }
  }

  List<String> get _categories {
    final cats = _items
        .map((e) => e.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...cats];
  }

  List<TechnicalNameModel> get _filteredItems {
    final q = widget.controller.text.trim().toLowerCase();
    // If the field currently matches an exact selected item, show all items so
    // re-opening the dropdown lets the user browse.
    final isExactMatch = _matchedItem != null &&
        _matchedItem!.name.trim().toLowerCase() == q;
    return _items.where((item) {
      if (q.isEmpty || isExactMatch) return true;
      return item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
    }).toList();
  }

  void _openDropdown() {
    if (_overlayEntry != null) return;
    if (_items.isEmpty && !_isLoading) {
      _loadItems(forceRefresh: true);
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final fieldWidth = renderBox?.size.width ?? 360.0;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _buildDropdownOverlay(ctx, fieldWidth),
    );
    overlay.insert(_overlayEntry!);
    setState(() {});
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _closeDropdown() {
    if (_overlayEntry != null) {
      _removeOverlay();
      if (mounted) setState(() {});
    }
  }

  void _selectItem(TechnicalNameModel item) {
    widget.controller.text = item.name;
    widget.controller.selection = TextSelection.collapsed(
      offset: item.name.length,
    );
    setState(() => _matchedItem = item);
    widget.onSelected(item);
    _closeDropdown();
    _focusNode.unfocus();
  }

  Future<void> _handleAddNew() async {
    _closeDropdown();
    final created = await showTechnicalNameEditorDialog(
      context,
      initialName: widget.controller.text.trim(),
      availableCategories: _categories.where((c) => c != 'All').toList(),
    );
    if (created != null && mounted) {
      await _loadItems(forceRefresh: true);
      if (!mounted) return;
      _selectItem(created);
    }
  }

  Future<void> _handleEditItem(TechnicalNameModel item) async {
    _closeDropdown();
    final updated = await showTechnicalNameEditorDialog(
      context,
      existing: item,
      availableCategories: _categories.where((c) => c != 'All').toList(),
    );
    if (updated != null && mounted) {
      await _loadItems(forceRefresh: true);
      if (!mounted) return;
      if (widget.controller.text.trim().toLowerCase() ==
          item.name.trim().toLowerCase()) {
        _selectItem(updated);
      }
    }
  }

  Future<void> _handleDeleteItem(TechnicalNameModel item) async {
    _closeDropdown();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Technical Name?'),
        content: Text('Delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await TechnicalNameService().deleteTechnicalName(item.id);
      if (!mounted) return;
      if (widget.controller.text.trim().toLowerCase() ==
          item.name.trim().toLowerCase()) {
        widget.controller.clear();
        setState(() => _matchedItem = null);
      }
      await _loadItems(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildDropdownOverlay(BuildContext ctx, double fieldWidth) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final filtered = _filteredItems;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _closeDropdown();
              _focusNode.unfocus();
            },
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 54),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: fieldWidth.clamp(280.0, 680.0),
              constraints: const BoxConstraints(maxHeight: 360),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Row(
                      children: [
                        Text(
                          '${filtered.length} technical name${filtered.length == 1 ? '' : 's'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                          ),
                        ),
                        const Spacer(),
                        if (widget.isAdmin)
                          TextButton.icon(
                            onPressed: _handleAddNew,
                            icon: const Icon(Icons.add_rounded, size: 15),
                            label: const Text('Add New'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  Flexible(
                    child: _isLoading && _items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    'No matching technical names found.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: textMuted,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    Divider(height: 1, color: borderColor),
                                itemBuilder: (_, idx) {
                                  final item = filtered[idx];
                                  final isSelected = item.name.toLowerCase() ==
                                      widget.controller.text
                                          .trim()
                                          .toLowerCase();
                                  return ListTile(
                                    dense: true,
                                    selected: isSelected,
                                    selectedTileColor: const Color(0xFF10B981)
                                        .withValues(alpha: 0.08),
                                    onTap: () => _selectItem(item),
                                    title: Text(
                                      item.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    subtitle: item.category.isNotEmpty
                                        ? Text(
                                            item.category,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: textMuted,
                                            ),
                                          )
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            item.formattedCommission,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                        if (widget.isAdmin) ...[
                                          const SizedBox(width: 4),
                                          IconButton(
                                            tooltip: 'Edit',
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              size: 16,
                                              color: textMuted,
                                            ),
                                            onPressed: () =>
                                                _handleEditItem(item),
                                          ),
                                          IconButton(
                                            tooltip: 'Delete',
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () =>
                                                _handleDeleteItem(item),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final fillColor =
        widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textPrimary =
        widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted =
        widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final isOpen = _overlayEntry != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.isRequired ? 'Technical Name *' : 'Technical Name',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textMuted,
              ),
            ),
            const Spacer(),
            if (_matchedItem != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Comm: ${_matchedItem!.formattedCommission}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            key: _fieldKey,
            controller: widget.controller,
            focusNode: _focusNode,
            onTap: () {
              if (!isOpen) _openDropdown();
            },
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: _isLoading
                  ? 'Loading technical names...'
                  : 'Search or select Technical Name (auto-fetches commission)',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: textMuted,
              ),
              filled: true,
              fillColor: fillColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: () {
                        if (isOpen) {
                          _closeDropdown();
                          _focusNode.unfocus();
                        } else {
                          _focusNode.requestFocus();
                          _openDropdown();
                        }
                      },
                      icon: Icon(
                        isOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: textMuted,
                      ),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF10B981), width: 1.5),
              ),
            ),
            validator: widget.isRequired
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Technical Name is required'
                    : null
                : null,
          ),
        ),
        if (_loadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: () => _loadItems(forceRefresh: true),
              child: Text(
                'Could not load technical names. Tap to retry.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
