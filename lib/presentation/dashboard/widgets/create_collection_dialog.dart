import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/collection.dart';
import '../../../logic/collection/collection_bloc.dart';
import '../../../logic/collection/collection_event.dart';
import '../../../logic/collection/collection_state.dart';

class CreateCollectionDialog extends StatefulWidget {
  final void Function(CollectionItem createdItem)? onCollectionCreated;

  const CreateCollectionDialog({
    super.key,
    this.onCollectionCreated,
  });

  @override
  State<CreateCollectionDialog> createState() => _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<CreateCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');
  final _bannerTitleController = TextEditingController();

  bool _isActive = true;
  bool _manualSlugEdited = false;

  @override
  void initState() {
    super.initState();
    context.read<CollectionBloc>().add(const ResetCreateCollectionState());
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
    _descriptionController.dispose();
    _priorityController.dispose();
    _bannerTitleController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final priorityVal = int.tryParse(_priorityController.text.trim()) ?? 0;
    final bannerVal = _bannerTitleController.text.trim();

    context.read<CollectionBloc>().add(
          CreateCollection(
            name: _nameController.text.trim(),
            slug: _slugController.text.trim(),
            description: _descriptionController.text.trim(),
            isActive: _isActive,
            priority: priorityVal,
            bannerTitle: bannerVal.isNotEmpty ? bannerVal : null,
            subCollections: const [],
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardBgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

    return BlocListener<CollectionBloc, CollectionState>(
      listenWhen: (previous, current) =>
          previous.createdCollection != current.createdCollection &&
          current.createdCollection != null,
      listener: (context, state) {
        final created = state.createdCollection!;
        widget.onCollectionCreated?.call(created);
        Navigator.of(context).pop(created);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Collection "${created.name}" created successfully.',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(20),
          ),
        );
      },
      child: BlocBuilder<CollectionBloc, CollectionState>(
        builder: (context, state) {
          final isCreating = state.isCreating;
          final errorMessage = state.createError;

          return Dialog(
            backgroundColor: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_rounded,
                              color: Color(0xFF059669),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create New Collection',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'POST /api/v1/admin/collections',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: isCreating ? null : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ],
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Collection Name
                      _buildLabel('Collection Name *', isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        enabled: !isCreating,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: _inputDecoration(
                          hintText: 'e.g. New Arrivals',
                          isDark: isDark,
                          surfaceColor: cardBgColor,
                          borderColor: borderColor,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Collection name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Slug
                      _buildLabel('Slug * (URL Identifier)', isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _slugController,
                        enabled: !isCreating,
                        onChanged: (_) => _manualSlugEdited = true,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          color: const Color(0xFF059669),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          hintText: 'e.g. new-arrivals',
                          isDark: isDark,
                          surfaceColor: cardBgColor,
                          borderColor: borderColor,
                          prefixIcon: const Icon(Icons.link_rounded, size: 18),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Slug is required';
                          }
                          if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value.trim())) {
                            return 'Slug must only contain lowercase letters, numbers, and hyphens';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Description
                      _buildLabel('Description', isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !isCreating,
                        maxLines: 2,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: _inputDecoration(
                          hintText: 'Recently added products selected for display.',
                          isDark: isDark,
                          surfaceColor: cardBgColor,
                          borderColor: borderColor,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Priority and Banner Title in Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Priority', isDark),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _priorityController,
                                  enabled: !isCreating,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  decoration: _inputDecoration(
                                    hintText: '0',
                                    isDark: isDark,
                                    surfaceColor: cardBgColor,
                                    borderColor: borderColor,
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Banner Title (Optional)', isDark),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _bannerTitleController,
                                  enabled: !isCreating,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  decoration: _inputDecoration(
                                    hintText: 'e.g. Featured Highlights',
                                    isDark: isDark,
                                    surfaceColor: cardBgColor,
                                    borderColor: borderColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Is Active Switch Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              size: 20,
                              color: _isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active on Storefront',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    _isActive
                                        ? 'Collection will be immediately visible to buyers'
                                        : 'Collection will remain hidden as a draft',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isActive,
                              activeTrackColor: const Color(0xFF059669),
                              onChanged: isCreating ? null : (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: isCreating ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isCreating ? null : _handleSubmit,
                            icon: isCreating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: Text(
                              isCreating ? 'Creating Collection...' : 'Create Collection',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: surfaceColor,
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
      prefixIcon: prefixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
