import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/collection.dart';
import '../../../logic/collection/collection_bloc.dart';
import '../../../logic/collection/collection_event.dart';

class AddSubCollectionDialog extends StatefulWidget {
  final CollectionItem collection;

  const AddSubCollectionDialog({
    super.key,
    required this.collection,
  });

  @override
  State<AddSubCollectionDialog> createState() => _AddSubCollectionDialogState();
}

class _AddSubCollectionDialogState extends State<AddSubCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _imageController = TextEditingController();

  bool _isActive = true;
  bool _manualSlugEdited = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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
    _imageController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final slug = _slugController.text.trim();
    final image = _imageController.text.trim();

    try {
      context.read<CollectionBloc>().add(
            AddSubCollection(
              collectionId: widget.collection.id,
              name: name,
              slug: slug,
              image: image.isNotEmpty ? image : null,
              isActive: _isActive,
            ),
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sub-collection "$name" added to "${widget.collection.name}".',
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException: ', '')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: surfaceColor,
      prefixIcon: prefixIcon,
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
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardBgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_tree_outlined,
                        color: Color(0xFF7C3AED),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Sub-Collection',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'To "${widget.collection.name}" • POST /api/v1/admin/collections/${widget.collection.id}/subcollections',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Sub-Collection Name
                _buildLabel('Sub-Collection Name *', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: _inputDecoration(
                    hintText: 'e.g. Paddy & Rice',
                    isDark: isDark,
                    surfaceColor: cardBgColor,
                    borderColor: borderColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Sub-collection name is required';
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
                  enabled: !_isSubmitting,
                  onChanged: (_) => _manualSlugEdited = true,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _inputDecoration(
                    hintText: 'e.g. paddy-rice',
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

                // Image URL
                _buildLabel('Image URL (Optional)', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _imageController,
                  enabled: !_isSubmitting,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: _inputDecoration(
                    hintText: 'https://example.com/banner.webp',
                    isDark: isDark,
                    surfaceColor: cardBgColor,
                    borderColor: borderColor,
                    prefixIcon: const Icon(Icons.image_outlined, size: 18),
                  ),
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
                                  ? 'Sub-collection will be immediately visible under ${widget.collection.name}'
                                  : 'Sub-collection will remain hidden',
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
                        activeTrackColor: const Color(0xFF7C3AED),
                        onChanged: _isSubmitting ? null : (val) => setState(() => _isActive = val),
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
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        _isSubmitting ? 'Adding...' : 'Add Sub-Collection',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
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
  }
}
