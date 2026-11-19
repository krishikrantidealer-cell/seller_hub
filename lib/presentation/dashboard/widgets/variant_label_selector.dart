import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';

const List<String> kVariantUnits = [
  'ml',
  'Ltr',
  'g',
  'kg',
  'pcs',
];

String formatVariantPackLabel({
  required double packSize,
  required String unit,
  required int packQuantity,
}) {
  if (packSize <= 0 || unit.trim().isEmpty || packQuantity <= 0) return '';
  String fmtNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  final sizeStr = fmtNum(packSize);
  final cleanUnit = unit.trim();
  final lowerUnit = cleanUnit.toLowerCase();
  final rawTotal = packSize * packQuantity;

  double displayTotal = rawTotal;
  String displayUnit = cleanUnit;
  if (rawTotal > 999) {
    if (lowerUnit == 'g' || lowerUnit == 'gm' || lowerUnit == 'gram' || lowerUnit == 'grams') {
      displayTotal = rawTotal / 1000.0;
      displayUnit = 'kg';
    } else if (lowerUnit == 'ml') {
      displayTotal = rawTotal / 1000.0;
      displayUnit = 'Ltr';
    }
  }

  final totalStr = fmtNum(displayTotal);
  return '$totalStr $displayUnit ($sizeStr$cleanUnit x $packQuantity Qty)';
}

class VariantLabelItem {
  final String id;
  final String label;
  final double packSize;
  final String unit;
  final int packQuantity;

  const VariantLabelItem({
    required this.id,
    required this.label,
    this.packSize = 0.0,
    this.unit = '',
    this.packQuantity = 1,
  });

  static String normalizeUnit(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    if (lower == 'l' || lower == 'ltr' || lower == 'litre' || lower == 'liter') {
      return 'Ltr';
    }
    if (lower == 'g' || lower == 'gm' || lower == 'gms' || lower == 'gram' || lower == 'grams') {
      return 'g';
    }
    if (lower == 'kg' || lower == 'kgs') return 'kg';
    if (lower == 'ml') return 'ml';
    if (lower == 'pcs' ||
        lower == 'pc' ||
        lower == 'piece' ||
        lower == 'pieces' ||
        lower == 'pouch' ||
        lower == 'pouches' ||
        lower == 'tablet' ||
        lower == 'tablets') {
      return 'pcs';
    }
    return lower;
  }

  factory VariantLabelItem.fromJson(Map<String, dynamic> json) {
    final label = (json['label'] ?? '').toString();
    final rawSize = json['packSize'];
    double size = rawSize is num
        ? rawSize.toDouble()
        : double.tryParse(rawSize?.toString() ?? '') ?? 0.0;
    final rawQty = json['packQuantity'];
    int qty = rawQty is num
        ? rawQty.toInt()
        : int.tryParse(rawQty?.toString() ?? '') ?? 1;
    String unit = normalizeUnit((json['unit'] ?? '').toString());

    if (size <= 0 || unit.isEmpty) {
      final parenMatch = RegExp(
        r'\(\s*(\d+(?:\.\d+)?)\s*([a-zA-Z]+)\s*[xX]\s*(\d+)(?:\s*[qQ]ty)?\s*\)',
      ).firstMatch(label);
      if (parenMatch != null) {
        size = double.tryParse(parenMatch.group(1) ?? '') ?? size;
        unit = normalizeUnit(parenMatch.group(2) ?? '');
        qty = int.tryParse(parenMatch.group(3) ?? '') ?? qty;
      } else {
        final simpleMatch = RegExp(r'(\d+(?:\.\d+)?)\s*([a-zA-Z]+)').firstMatch(label);
        if (simpleMatch != null) {
          size = double.tryParse(simpleMatch.group(1) ?? '') ?? size;
          unit = normalizeUnit(simpleMatch.group(2) ?? '');
        }
      }
    }

    return VariantLabelItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      label: label,
      packSize: size,
      unit: unit,
      packQuantity: qty > 0 ? qty : 1,
    );
  }
}

class VariantLabelService {
  static final VariantLabelService _instance = VariantLabelService._internal();
  factory VariantLabelService() => _instance;
  VariantLabelService._internal();

  List<VariantLabelItem>? _cached;

  Future<List<VariantLabelItem>> fetchLabels({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;
    final response = await InjectionContainer.instance.apiClient.get(
      ApiEndpoints.variantLabels,
      requiresAuth: false,
    );
    final raw = response['data'];
    if (raw is! List) return const [];
    final list = raw
        .whereType<Map>()
        .map((e) => VariantLabelItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.label.trim().isNotEmpty)
        .toList();
    _cached = list;
    return list;
  }

  Future<VariantLabelItem> createLabel({
    required String label,
    required double packSize,
    required String unit,
    required int packQuantity,
  }) async {
    final response = await InjectionContainer.instance.apiClient.post(
      ApiEndpoints.variantLabels,
      body: {
        'label': label.trim(),
        'packSize': packSize,
        'unit': unit.trim(),
        'packQuantity': packQuantity,
      },
      requiresAuth: true,
    );
    _cached = null;
    final data = response['data'];
    if (data is Map) {
      return VariantLabelItem.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Invalid response when creating variant label');
  }

  Future<VariantLabelItem> updateLabel(
    String id, {
    required String label,
    required double packSize,
    required String unit,
    required int packQuantity,
  }) async {
    final response = await InjectionContainer.instance.apiClient.put(
      ApiEndpoints.variantLabelById(id),
      body: {
        'label': label.trim(),
        'packSize': packSize,
        'unit': unit.trim(),
        'packQuantity': packQuantity,
      },
      requiresAuth: true,
    );
    _cached = null;
    final data = response['data'];
    if (data is Map) {
      return VariantLabelItem.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Invalid response when updating variant label');
  }

  Future<void> deleteLabel(String id) async {
    await InjectionContainer.instance.apiClient.delete(
      ApiEndpoints.variantLabelById(id),
      requiresAuth: true,
    );
    _cached = null;
  }
}

/// Shared modal dialog to create or edit a Variant Label from Pack Size, Unit, and Pack Quantity.
Future<VariantLabelItem?> showVariantLabelEditorDialog(
  BuildContext context, {
  VariantLabelItem? existing,
}) {
  return showDialog<VariantLabelItem>(
    context: context,
    builder: (ctx) => _VariantLabelEditorDialog(existing: existing),
  );
}

class _VariantLabelEditorDialog extends StatefulWidget {
  final VariantLabelItem? existing;

  const _VariantLabelEditorDialog({this.existing});

  @override
  State<_VariantLabelEditorDialog> createState() =>
      _VariantLabelEditorDialogState();
}

class _VariantLabelEditorDialogState extends State<_VariantLabelEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _packSizeController;
  late final TextEditingController _packQtyController;
  late final TextEditingController _labelController;
  late String _selectedUnit;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _packSizeController = TextEditingController(
      text: (ex != null && ex.packSize > 0)
          ? (ex.packSize == ex.packSize.roundToDouble()
              ? ex.packSize.toInt().toString()
              : ex.packSize.toString())
          : '',
    );
    _packQtyController = TextEditingController(
      text: (ex != null && ex.packQuantity > 0)
          ? ex.packQuantity.toString()
          : '1',
    );
    _selectedUnit = (ex != null && kVariantUnits.contains(ex.unit))
        ? ex.unit
        : kVariantUnits.first;
    _labelController = TextEditingController(text: ex?.label ?? '');
    _packSizeController.addListener(_recomputePreview);
    _packQtyController.addListener(_recomputePreview);
  }

  @override
  void dispose() {
    _packSizeController.removeListener(_recomputePreview);
    _packQtyController.removeListener(_recomputePreview);
    _packSizeController.dispose();
    _packQtyController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _recomputePreview() {
    final size = double.tryParse(_packSizeController.text.trim()) ?? 0.0;
    final qty = int.tryParse(_packQtyController.text.trim()) ?? 1;
    final formatted = formatVariantPackLabel(
      packSize: size,
      unit: _selectedUnit,
      packQuantity: qty > 0 ? qty : 1,
    );
    _labelController.text = formatted;
    setState(() {});
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final size = double.tryParse(_packSizeController.text.trim()) ?? 0.0;
    final qty = int.tryParse(_packQtyController.text.trim()) ?? 1;
    final label = _labelController.text.trim();

    try {
      final service = VariantLabelService();
      final saved = _isEditing
          ? await service.updateLabel(
              widget.existing!.id,
              label: label,
              packSize: size,
              unit: _selectedUnit,
              packQuantity: qty > 0 ? qty : 1,
            )
          : await service.createLabel(
              label: label,
              packSize: size,
              unit: _selectedUnit,
              packQuantity: qty > 0 ? qty : 1,
            );
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
                        Icons.label_outline_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit Variant Label' : 'Add Variant Label',
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _packSizeController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Pack Size *',
                          hintText: 'e.g. 100',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) {
                          final numVal = double.tryParse(v?.trim() ?? '');
                          if (numVal == null || numVal <= 0) {
                            return 'Enter pack size';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: kVariantUnits
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _selectedUnit = val;
                            _recomputePreview();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _packQtyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Pack Qty *',
                          hintText: 'e.g. 2',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) {
                          final qty = int.tryParse(v?.trim() ?? '');
                          if (qty == null || qty <= 0) {
                            return 'Min 1';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _labelController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Generated Variant Label *',
                    hintText: 'e.g. 200(100ml x 2)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter Pack Size, Unit & Pack Qty'
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  'Example: Pack Size 100 + Unit g + Pack Qty 10 = 1 kg (100g x 10 Qty)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: textMuted,
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

/// Dynamic searchable Variant Label dropdown where users can pick, create, or delete labels.
class VariantLabelSelector extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark;
  final bool isRequired;
  final VoidCallback? onChanged;
  final ValueChanged<VariantLabelItem>? onSelected;
  final bool readOnly;

  const VariantLabelSelector({
    super.key,
    required this.controller,
    required this.isDark,
    this.isRequired = true,
    this.onChanged,
    this.onSelected,
    this.readOnly = false,
  });

  @override
  State<VariantLabelSelector> createState() => _VariantLabelSelectorState();
}

class _VariantLabelSelectorState extends State<VariantLabelSelector> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _fieldKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newSizeController = TextEditingController();
  final TextEditingController _newQtyController =
      TextEditingController(text: '0');

  OverlayEntry? _overlayEntry;
  List<VariantLabelItem> _items = [];
  bool _isLoading = false;
  bool _showInlineCreator = false;
  bool _isCreating = false;
  String _newUnit = kVariantUnits.first;
  String? _createError;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(() => _overlayEntry?.markNeedsBuild());
    _newSizeController.addListener(() => _overlayEntry?.markNeedsBuild());
    _newQtyController.addListener(() => _overlayEntry?.markNeedsBuild());
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _newSizeController.dispose();
    _newQtyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadItems({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final list =
          await VariantLabelService().fetchLabels(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
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

  List<VariantLabelItem> get _filteredItems {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items
        .where((item) => item.label.toLowerCase().contains(q))
        .toList();
  }

  void _openDropdown() {
    if (_overlayEntry != null) return;
    if (_items.isEmpty && !_isLoading) {
      _loadItems(forceRefresh: true);
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final fieldWidth = renderBox?.size.width ?? 280.0;

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

  void _selectItem(VariantLabelItem item) {
    widget.controller.text = item.label;
    widget.controller.selection = TextSelection.collapsed(
      offset: item.label.length,
    );
    _searchController.clear();
    widget.onSelected?.call(item);
    widget.onChanged?.call();
    _closeDropdown();
    _focusNode.unfocus();
  }

  String get _inlinePreviewLabel {
    final size = double.tryParse(_newSizeController.text.trim()) ?? 0.0;
    final qty = int.tryParse(_newQtyController.text.trim()) ?? 0;
    return formatVariantPackLabel(
      packSize: size,
      unit: _newUnit,
      packQuantity: qty,
    );
  }

  void _toggleInlineCreator() {
    _showInlineCreator = !_showInlineCreator;
    _createError = null;
    _overlayEntry?.markNeedsBuild();
  }

  Future<void> _saveInlineLabel() async {
    final size = double.tryParse(_newSizeController.text.trim()) ?? 0.0;
    final qty = int.tryParse(_newQtyController.text.trim()) ?? 0;
    if (size <= 0) {
      _createError = 'Enter valid pack size';
      _overlayEntry?.markNeedsBuild();
      return;
    }
    if (qty <= 0) {
      _createError = 'Pack qty must be >= 1';
      _overlayEntry?.markNeedsBuild();
      return;
    }
    final label = formatVariantPackLabel(
      packSize: size,
      unit: _newUnit,
      packQuantity: qty,
    );

    _isCreating = true;
    _createError = null;
    _overlayEntry?.markNeedsBuild();

    try {
      final created = await VariantLabelService().createLabel(
        label: label,
        packSize: size,
        unit: _newUnit,
        packQuantity: qty,
      );
      if (!mounted) return;
      _isCreating = false;
      _showInlineCreator = false;
      _newSizeController.clear();
      _newQtyController.text = '0';
      await _loadItems(forceRefresh: true);
      if (!mounted) return;
      _selectItem(created);
    } catch (e) {
      if (!mounted) return;
      _isCreating = false;
      _createError = e.toString().replaceFirst('Exception: ', '');
      _overlayEntry?.markNeedsBuild();
    }
  }

  Future<void> _handleDelete(VariantLabelItem item) async {
    _closeDropdown();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Variant Label?'),
        content: Text('Delete "${item.label}"?'),
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
      await VariantLabelService().deleteLabel(item.id);
      if (!mounted) return;
      if (widget.controller.text.trim().toLowerCase() ==
          item.label.trim().toLowerCase()) {
        widget.controller.clear();
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
              width: fieldWidth.clamp(240.0, 520.0),
              constraints: const BoxConstraints(maxHeight: 300),
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
                          '${filtered.length} label${filtered.length == 1 ? '' : 's'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _toggleInlineCreator,
                          icon: Icon(
                            _showInlineCreator
                                ? Icons.close_rounded
                                : Icons.add_rounded,
                            size: 15,
                          ),
                          label: Text(_showInlineCreator ? 'Close' : 'Add New'),
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
                  if (_showInlineCreator) ...[
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newSizeController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Pack Size',
                                    hintText: '100',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _newQtyController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Pack Qty',
                                    hintText: '2',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Unit:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted,
                                ),
                              ),
                              ...kVariantUnits.map((u) {
                                final selected = _newUnit == u;
                                return InkWell(
                                  onTap: () {
                                    _newUnit = u;
                                    _overlayEntry?.markNeedsBuild();
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF10B981)
                                          : (isDark
                                              ? const Color(0xFF1E293B)
                                              : Colors.white),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFF10B981)
                                            : borderColor,
                                      ),
                                    ),
                                    child: Text(
                                      u,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selected
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _inlinePreviewLabel.isNotEmpty
                                      ? 'Preview: $_inlinePreviewLabel'
                                      : 'e.g. 100 + ml + 2 = 200(100ml x 2)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: _inlinePreviewLabel.isNotEmpty
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _inlinePreviewLabel.isNotEmpty
                                        ? const Color(0xFF10B981)
                                        : textMuted,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _isCreating ? null : _saveInlineLabel,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: _isCreating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save',
                                        style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          if (_createError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _createError!,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.redAccent),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search variant labels...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 16),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  Flexible(
                    child: _isLoading && _items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'No matching variant labels. Tap "+ Add New" to create.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: textMuted,
                                    ),
                                    textAlign: TextAlign.center,
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
                                  final isSelected = item.label.toLowerCase() ==
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
                                      item.label,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Delete',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => _handleDelete(item),
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
        Text(
          widget.isRequired ? 'Variant Label *' : 'Variant Label',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            key: _fieldKey,
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: !widget.readOnly,
            readOnly: true,
            onTap: widget.readOnly
                ? null
                : () {
                    if (isOpen) {
                      _closeDropdown();
                    } else {
                      _openDropdown();
                    }
                  },
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.readOnly ? textMuted : textPrimary,
            ),
            decoration: InputDecoration(
              hintText: _isLoading
                  ? 'Loading variant labels...'
                  : 'Select or create Variant Label',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: textMuted,
              ),
              filled: true,
              fillColor: widget.readOnly
                  ? (widget.isDark
                      ? const Color(0xFF0B1120)
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.5))
                  : fillColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              suffixIcon: widget.readOnly
                  ? Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: textMuted,
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
                    ? 'Variant Label is required'
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
                'Could not load variant labels. Tap to retry.',
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
