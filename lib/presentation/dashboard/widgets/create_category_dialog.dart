import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/category.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../logic/category/category_bloc.dart';
import '../../../logic/category/category_event.dart';

class CreateCategoryDialog extends StatefulWidget {
  final CategoryItem? initialParent;
  final void Function(CategoryItem createdCategory)? onCategoryCreated;

  const CreateCategoryDialog({
    super.key,
    this.initialParent,
    this.onCategoryCreated,
  });

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');

  String? _selectedParentId;
  bool _isActive = true;
  bool _manualSlugEdited = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialParent != null) {
      _selectedParentId = widget.initialParent!.id;
    }
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (!_manualSlugEdited) {
      final generated = _nameController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      _slugController.text = generated;
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _slugController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  int _calculateResultingLevel(List<CategoryItem> allCategories) {
    if (_selectedParentId == null || _selectedParentId!.isEmpty) {
      return 0; // Root
    }
    final parent = allCategories.firstWhere(
      (c) => c.id == _selectedParentId,
      orElse: () => const CategoryItem(id: '', name: '', slug: '', level: 0),
    );
    return (parent.level + 1).clamp(0, 2);
  }

  void _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    var slug = _slugController.text.trim();
    if (slug.isEmpty) {
      slug = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      _slugController.text = slug;
    }
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

    try {
      final repo = context.read<CategoryRepository>();
      final newCategory = await repo.createCategory(
        name: name,
        slug: slug,
        parentId: _selectedParentId,
        sortOrder: sortOrder,
        isActive: _isActive,
      );

      if (mounted) {
        // Refresh CategoryBloc to update tree & metrics across app
        context.read<CategoryBloc>().add(const FetchCategories(isRefresh: true));
        widget.onCategoryCreated?.call(newCategory);
        Navigator.of(context).pop(newCategory);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Category "${newCategory.name}" created successfully!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final catState = context.watch<CategoryBloc>().state;
    final allCategories = catState.allCategories;

    // Eligible parents are Level 0 and Level 1 categories (max depth = Level 2)
    final eligibleParents = allCategories.where((c) => c.level < 2).toList()
      ..sort((a, b) {
        if (a.level != b.level) return a.level.compareTo(b.level);
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final resultingLevel = _calculateResultingLevel(allCategories);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.create_new_folder_rounded,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Category',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Add a top-level department or sub-category to taxonomy',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Name Field
                      Text(
                        'Category Name *',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'e.g. Bio Pesticides, Micronutrients, Vegetable Seeds',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary),
                          prefixIcon: Icon(Icons.label_outline_rounded, size: 18, color: textSecondary),
                          filled: true,
                          fillColor: cardBgColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a category name';
                          }
                          if (value.trim().length > 100) {
                            return 'Category name must be at most 100 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Slug Field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'URL Slug *',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _manualSlugEdited ? 'Custom' : 'Auto-generated',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_manualSlugEdited)
                            InkWell(
                              onTap: () {
                                setState(() => _manualSlugEdited = false);
                                _onNameChanged();
                              },
                              child: Text(
                                'Reset to auto-slug',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _slugController,
                        onChanged: (_) {
                          if (!_manualSlugEdited) {
                            setState(() => _manualSlugEdited = true);
                          }
                        },
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'e.g. bio-pesticides',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary),
                          helperText: 'Automatically derived from category name, or customize above',
                          helperStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: textSecondary),
                          prefixIcon: Icon(Icons.link_rounded, size: 18, color: textSecondary),
                          prefixText: '/category/',
                          prefixStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                          filled: true,
                          fillColor: cardBgColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        ),
                        validator: (value) {
                          if ((value == null || value.trim().isEmpty) && _nameController.text.trim().isEmpty) {
                            return 'Please enter a category name or slug';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Hierarchy / Parent Category Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Taxonomy Parent & Depth',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          _buildLevelBadge(resultingLevel),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _selectedParentId,
                            dropdownColor: surfaceColor,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Row(
                                  children: [
                                    const Icon(Icons.folder_special_rounded, size: 16, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 8),
                                    const Text('None (Creates Level 0 Major Root)'),
                                  ],
                                ),
                              ),
                              ...eligibleParents.map((c) {
                                final isRoot = c.level == 0;
                                final prefix = isRoot ? '📁 [Root]' : '   ↳ [Sub]';
                                final nextLabel = isRoot ? 'Creates Level 1' : 'Creates Level 2';
                                final iconColor = isRoot ? const Color(0xFF2563EB) : const Color(0xFF7C3AED);

                                return DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Row(
                                    children: [
                                      Icon(isRoot ? Icons.folder_rounded : Icons.subdirectory_arrow_right_rounded, size: 15, color: iconColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$prefix ${c.name}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        nextLabel,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: iconColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedParentId = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Display Order
                      Text(
                        'Display Order',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _sortOrderController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixIcon: Icon(Icons.sort_rounded, size: 18, color: textSecondary),
                          helperText: 'Lower numbers display first (e.g. 0, 1, 2)',
                          helperStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: textSecondary),
                          filled: true,
                          fillColor: cardBgColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Active Toggle Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Status',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Visible in catalog and available for product assignment',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch(
                              value: _isActive,
                              activeThumbColor: const Color(0xFF059669),
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add_rounded, size: 16),
                    label: Text(_isSubmitting ? 'Creating...' : 'Create Category'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(int level) {
    Color bg;
    Color fg;
    String label;

    switch (level) {
      case 0:
        bg = const Color(0xFF2563EB).withValues(alpha: 0.12);
        fg = const Color(0xFF2563EB);
        label = 'Level 0: Major Root';
        break;
      case 1:
        bg = const Color(0xFF7C3AED).withValues(alpha: 0.12);
        fg = const Color(0xFF7C3AED);
        label = 'Level 1: Sub-Category';
        break;
      case 2:
      default:
        bg = const Color(0xFFD97706).withValues(alpha: 0.12);
        fg = const Color(0xFFD97706);
        label = 'Level 2: Leaf Node';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
