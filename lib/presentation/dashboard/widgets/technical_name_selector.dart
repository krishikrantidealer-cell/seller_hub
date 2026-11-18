import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/technical_name.dart';
import '../../../data/datasources/technical_name_service.dart';

/// Shared modal dialog to create or edit a Technical Name + Commission (%).
Future<TechnicalNameModel?> showTechnicalNameEditorDialog(
  BuildContext context, {
  TechnicalNameModel? existing,
  String? initialName,
}) {
  return showDialog<TechnicalNameModel>(
    context: context,
    builder: (ctx) => _TechnicalNameEditorDialog(
      existing: existing,
      initialName: initialName,
    ),
  );
}

class _TechnicalNameEditorDialog extends StatefulWidget {
  final TechnicalNameModel? existing;
  final String? initialName;

  const _TechnicalNameEditorDialog({
    this.existing,
    this.initialName,
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
    final comm = widget.existing?.commissionPercentage;
    _commissionController = TextEditingController(
      text: comm != null
          ? (comm == comm.roundToDouble()
              ? comm.toInt().toString()
              : comm.toString())
          : '',
    );
    _isActive = widget.existing?.isActive ?? true;
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
    final commission =
        double.tryParse(_commissionController.text.trim()) ?? 0.0;

    try {
      final service = TechnicalNameService();
      final TechnicalNameModel saved;
      if (_isEditing) {
        saved = await service.updateTechnicalName(
          widget.existing!.id,
          name: name,
          commissionPercentage: commission,
          isActive: _isActive,
          syncProducts: _syncProducts,
        );
      } else {
        saved = await service.createTechnicalName(
          name: name,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : Colors.white;
    final cardSurface = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const accent = Color(0xFF059669);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.16),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modern Gradient Header
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF064E3B).withValues(alpha: 0.45),
                              const Color(0xFF0F172A),
                            ]
                          : [
                              const Color(0xFFECFDF5),
                              const Color(0xFFF8FAFC),
                            ],
                    ),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF10B981), Color(0xFF047857)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.science_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? 'Edit Technical Name'
                                  : 'New Technical Name',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Standardized formulation & platform commission rule',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.close_rounded,
                                color: textMuted, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'TECHNICAL NAME *',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Chlorpyrifos 20% EC',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: textMuted.withValues(alpha: 0.7),
                          ),
                          prefixIcon: const Icon(
                            Icons.biotech_rounded,
                            size: 19,
                            color: accent,
                          ),
                          filled: true,
                          fillColor: cardSurface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: accent, width: 1.6),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Technical name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'COMMISSION PERCENTAGE *',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _commissionController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d{0,3}(\.\d{0,2})?$'),
                          ),
                        ],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 15',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: textMuted.withValues(alpha: 0.7),
                          ),
                          prefixIcon: const Icon(
                            Icons.percent_rounded,
                            size: 18,
                            color: accent,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Center(
                              widthFactor: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '% Platform',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          filled: true,
                          fillColor: cardSurface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: accent, width: 1.6),
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
                      // Quick Commission Presets
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [5, 10, 12, 15, 18, 20, 25].map((pct) {
                          final current = double.tryParse(
                              _commissionController.text.trim());
                          final isSelected = current == pct.toDouble();
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() {
                              _commissionController.text = pct.toString();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accent.withValues(alpha: 0.16)
                                    : cardSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? accent : borderColor,
                                ),
                              ),
                              child: Text(
                                '$pct%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? accent : textMuted,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (_nameController.text.trim().isNotEmpty ||
                          _commissionController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: isDark ? 0.12 : 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: accent.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 15, color: accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _nameController.text.trim().isNotEmpty
                                      ? _nameController.text.trim()
                                      : 'Technical Name Preview',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${_commissionController.text.trim().isEmpty ? '0' : _commissionController.text.trim()}% Comm',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_isEditing) ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: cardSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            value: _syncProducts,
                            activeColor: accent,
                            onChanged: (val) =>
                                setState(() => _syncProducts = val ?? false),
                            title: Text(
                              'Sync commission to existing products',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
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
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _error!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textMuted,
                                side: BorderSide(color: borderColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                textStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _submit,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 18,
                                    ),
                              label: Text(_isEditing
                                  ? 'Save Changes'
                                  : 'Create Technical Name'),
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                textStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pure multi-token, relevance-ranked search for technical names.
///
/// Ranks matches in four tiers:
/// 0: exact match, 1: prefix match, 2: word-boundary match, 3: substring match.
List<TechnicalNameModel> filterAndRankTechnicalNames(
  List<TechnicalNameModel> items,
  String rawQuery, {
  TechnicalNameModel? matchedItem,
}) {
  final q = rawQuery.trim().toLowerCase();
  final isExactMatchedBrowse = matchedItem != null &&
      matchedItem.name.trim().toLowerCase() == q;
  if (q.isEmpty || isExactMatchedBrowse) {
    return items;
  }
  final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) return items;

  final wordStartRegex = RegExp(r'\b' + RegExp.escape(tokens.first));
  final scored = <({TechnicalNameModel item, int tier})>[];
  for (final item in items) {
    final nameLower = item.name.trim().toLowerCase();
    if (!tokens.every((t) => nameLower.contains(t))) continue;
    final int tier;
    if (nameLower == q) {
      tier = 0;
    } else if (nameLower.startsWith(q)) {
      tier = 1;
    } else if (wordStartRegex.hasMatch(nameLower)) {
      tier = 2;
    } else {
      tier = 3;
    }
    scored.add((item: item, tier: tier));
  }
  scored.sort((a, b) {
    final cmp = a.tier.compareTo(b.tier);
    if (cmp != 0) return cmp;
    return a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
  });
  return scored.map((e) => e.item).toList();
}

/// Searchable Technical Name dropdown field that auto-fetches Commission (%).
class TechnicalNameSelector extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<TechnicalNameModel> onSelected;
  final bool isDark;
  final bool isRequired;
  final bool isAdmin;
  final bool readOnly;
  final List<TechnicalNameModel>? initialItems;

  const TechnicalNameSelector({
    super.key,
    required this.controller,
    required this.onSelected,
    required this.isDark,
    this.isRequired = true,
    this.isAdmin = false,
    this.readOnly = false,
    this.initialItems,
  });

  @override
  State<TechnicalNameSelector> createState() => _TechnicalNameSelectorState();
}

class _TechnicalNameSelectorState extends State<TechnicalNameSelector> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _fieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  List<TechnicalNameModel> _items = [];
  bool _isLoading = false;
  String? _loadError;
  TechnicalNameModel? _matchedItem;
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null) {
      _items = widget.initialItems!.where((e) => e.isActive).toList();
      _syncMatchedFromController();
    } else {
      _loadItems();
    }
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
    if (_focusNode.hasFocus && !widget.readOnly) {
      _openDropdown();
    }
  }

  void _onControllerChanged() {
    _syncMatchedFromController();
    _highlightedIndex = -1;
    if (!mounted) return;
    if (_focusNode.hasFocus && _overlayEntry == null && !widget.readOnly) {
      _openDropdown();
      return;
    }
    if (_overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _overlayEntry?.markNeedsBuild();
      });
    }
    setState(() {});
  }

  Future<void> _loadItems({bool forceRefresh = false}) async {
    if (widget.initialItems != null && !forceRefresh) return;
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

  List<TechnicalNameModel> get _filteredItems {
    return filterAndRankTechnicalNames(
      _items,
      widget.controller.text,
      matchedItem: _matchedItem,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.readOnly) {
      return KeyEventResult.ignored;
    }
    final filtered = _filteredItems;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_overlayEntry == null) {
        _openDropdown();
      }
      if (filtered.isNotEmpty) {
        _highlightedIndex = (_highlightedIndex + 1) % filtered.length;
        _overlayEntry?.markNeedsBuild();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (filtered.isNotEmpty) {
        _highlightedIndex = _highlightedIndex <= 0
            ? filtered.length - 1
            : _highlightedIndex - 1;
        _overlayEntry?.markNeedsBuild();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_overlayEntry != null && filtered.isNotEmpty) {
        final idx = (_highlightedIndex >= 0 && _highlightedIndex < filtered.length)
            ? _highlightedIndex
            : 0;
        _selectItem(filtered[idx]);
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_overlayEntry != null) {
        _closeDropdown();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _openDropdown() {
    if (_overlayEntry != null) return;
    if (_items.isEmpty && !_isLoading) {
      _loadItems(forceRefresh: true);
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final fieldBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final fieldSize = fieldBox?.size ?? const Size(360.0, 48.0);
    final fieldOffset = (fieldBox != null && overlayBox != null)
        ? fieldBox.localToGlobal(Offset.zero, ancestor: overlayBox)
        : (fieldBox?.localToGlobal(Offset.zero) ?? Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _buildDropdownOverlay(ctx, fieldOffset, fieldSize),
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

  Widget _buildHighlightedTitle(
    String text,
    String query,
    bool isSelected,
    Color textPrimary,
  ) {
    final baseStyle = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
      color: textPrimary,
    );
    final q = query.trim().toLowerCase();
    final isExactMatchedBrowse =
        _matchedItem != null && _matchedItem!.name.trim().toLowerCase() == q;
    if (q.isEmpty || isExactMatchedBrowse) {
      return Text(text, style: baseStyle, overflow: TextOverflow.ellipsis);
    }
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) {
      return Text(text, style: baseStyle, overflow: TextOverflow.ellipsis);
    }
    final pattern = RegExp(
      tokens.map(RegExp.escape).join('|'),
      caseSensitive: false,
    );
    final spans = <TextSpan>[];
    int start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: baseStyle.copyWith(
          color: const Color(0xFF059669),
          fontWeight: FontWeight.w800,
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.14),
        ),
      ));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  Widget _buildDropdownOverlay(
      BuildContext ctx, Offset fieldOffset, Size fieldSize) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final filtered = _filteredItems;
    final mediaSize = MediaQuery.of(ctx).size;
    final dropdownWidth = fieldSize.width.clamp(280.0, 680.0);
    final clampedLeft = fieldOffset.dx
        .clamp(12.0, (mediaSize.width - dropdownWidth - 12.0).clamp(12.0, mediaSize.width));
    final spaceBelow = (mediaSize.height - (fieldOffset.dy + fieldSize.height) - 16.0)
        .clamp(0.0, 360.0);
    final spaceAbove = (fieldOffset.dy - 16.0).clamp(0.0, 360.0);
    final openAbove = spaceBelow < 210.0 && spaceAbove > spaceBelow;
    final maxDropdownHeight = (openAbove ? spaceAbove : spaceBelow).clamp(160.0, 360.0);

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
        Positioned(
          left: clampedLeft,
          top: openAbove ? null : fieldOffset.dy + fieldSize.height + 6,
          bottom: openAbove ? mediaSize.height - fieldOffset.dy + 6 : null,
          width: dropdownWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDropdownHeight),
            child: Material(
                color: bgColor,
                elevation: isDark ? 12 : 8,
                shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} technical name${filtered.length == 1 ? '' : 's'}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
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
                                foregroundColor: const Color(0xFF059669),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
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
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'No matching technical names found.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: textMuted,
                                        ),
                                      ),
                                      if (widget.isAdmin &&
                                          widget.controller.text
                                              .trim()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        TextButton.icon(
                                          onPressed: _handleAddNew,
                                          icon: const Icon(Icons.add_rounded,
                                              size: 16),
                                          label: Text(
                                            'Add "${widget.controller.text.trim()}"',
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF059669),
                                          ),
                                        ),
                                      ],
                                    ],
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
                                    final isHighlighted = idx == _highlightedIndex;
                                    return Material(
                                      color: isSelected
                                          ? const Color(0xFF10B981)
                                              .withValues(alpha: 0.08)
                                          : (isHighlighted
                                              ? const Color(0xFF10B981)
                                                  .withValues(alpha: 0.05)
                                              : Colors.transparent),
                                      child: InkWell(
                                        onTap: () => _selectItem(item),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 9),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _buildHighlightedTitle(
                                                  item.name,
                                                  widget.controller.text,
                                                  isSelected,
                                                  textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981)
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Text(
                                                  item.formattedCommission,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFF10B981),
                                                  ),
                                                ),
                                              ),
                                              if (widget.isAdmin) ...[
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  tooltip: 'Edit',
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.all(4),
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
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.all(4),
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
                                        ),
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
                fontSize: 11.5,
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
        const SizedBox(height: 5),
        Focus(
          onKeyEvent: _handleKeyEvent,
          child: TextFormField(
            key: _fieldKey,
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: !widget.readOnly,
            readOnly: widget.readOnly,
            onTap: widget.readOnly
                ? null
                : () {
                    if (!isOpen) _openDropdown();
                  },
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.readOnly ? textMuted : textPrimary,
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
              fillColor: widget.readOnly
                  ? (widget.isDark
                      ? const Color(0xFF0B1120)
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.5))
                  : fillColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: widget.readOnly
                  ? Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: textMuted,
                    )
                  : (_isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.controller.text.isNotEmpty)
                              IconButton(
                                tooltip: 'Clear',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                onPressed: () {
                                  widget.controller.clear();
                                  setState(() => _matchedItem = null);
                                  _focusNode.requestFocus();
                                  _openDropdown();
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: textMuted,
                                ),
                              ),
                            IconButton(
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
                          ],
                        )),
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
