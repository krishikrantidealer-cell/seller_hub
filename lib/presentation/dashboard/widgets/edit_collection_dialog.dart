import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/collection.dart';
import '../../../domain/repositories/collection_repository.dart';
import '../../../logic/collection/collection_bloc.dart';
import '../../../logic/collection/collection_event.dart';
import '../../../logic/collection/collection_state.dart';
import '../widgets/app_product_image.dart';

class EditCollectionDialog extends StatefulWidget {
  final CollectionItem collection;
  final void Function(CollectionItem updatedItem)? onCollectionUpdated;
  final VoidCallback? onClose;

  const EditCollectionDialog({
    super.key,
    required this.collection,
    this.onCollectionUpdated,
    this.onClose,
  });

  @override
  State<EditCollectionDialog> createState() => _EditCollectionDialogState();
}

class _EditCollectionDialogState extends State<EditCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priorityController;
  late final TextEditingController _bannerTitleController;

  late bool _isActive;
  late List<SubCollectionItem> _subCollections;

  // Collection Image state
  String? _imageUrl;
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isUploadingImage = false;

  // Inline Sub-Collection adder controllers
  bool _isAddingSub = false;
  final _newSubNameController = TextEditingController();
  final _newSubSlugController = TextEditingController();
  String? _newSubImageUrl;
  Uint8List? _newSubImageBytes;
  String? _newSubImageFileName;
  bool _isUploadingSubImage = false;

  @override
  void initState() {
    super.initState();
    context.read<CollectionBloc>().add(const ResetUpdateCollectionState());
    _nameController = TextEditingController(text: widget.collection.name);
    _slugController = TextEditingController(text: widget.collection.slug);
    _descriptionController = TextEditingController(text: widget.collection.description);
    _priorityController = TextEditingController(text: widget.collection.priority.toString());
    _bannerTitleController = TextEditingController(text: widget.collection.bannerTitle ?? '');
    _isActive = widget.collection.isActive;
    _imageUrl = widget.collection.image;
    _subCollections = List.from(widget.collection.subCollections);

    _newSubNameController.addListener(_onSubNameChanged);
  }

  void _onSubNameChanged() {
    final generated = _newSubNameController.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    _newSubSlugController.text = generated;
    setState(() {});
  }

  Future<void> _pickCollectionImage() async {
    final repo = context.read<CollectionRepository>();
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );
      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty && mounted) {
          setState(() {
            _imageBytes = bytes;
            _imageFileName = file.name;
            _isUploadingImage = true;
          });
          try {
            final uploadedUrl = await repo.uploadCollectionImageDirect(
                  fileBytes: bytes,
                  fileName: file.name,
                );
            if (mounted) {
              setState(() {
                _imageUrl = uploadedUrl;
                _isUploadingImage = false;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isUploadingImage = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to upload collection image: $e'),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking collection image: $e');
    }
  }

  Future<void> _pickSubCollectionImage() async {
    final repo = context.read<CollectionRepository>();
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );
      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty && mounted) {
          setState(() {
            _newSubImageBytes = bytes;
            _newSubImageFileName = file.name;
            _isUploadingSubImage = true;
          });
          try {
            final uploadedUrl = await repo.uploadCollectionImageDirect(
                  fileBytes: bytes,
                  fileName: file.name,
                );
            if (mounted) {
              setState(() {
                _newSubImageUrl = uploadedUrl;
                _isUploadingSubImage = false;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isUploadingSubImage = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to upload sub-collection image: $e'),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking sub-collection image: $e');
    }
  }

  @override
  void dispose() {
    _newSubNameController.removeListener(_onSubNameChanged);
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _priorityController.dispose();
    _bannerTitleController.dispose();
    _newSubNameController.dispose();
    _newSubSlugController.dispose();
    super.dispose();
  }

  void _handleAddSubCollection() {
    final name = _newSubNameController.text.trim();
    final slug = _newSubSlugController.text.trim();

    if (name.isEmpty || slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter sub-collection name.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final newSub = SubCollectionItem(
      id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      slug: slug,
      isActive: true,
      image: _newSubImageUrl,
      productCount: 0,
    );

    setState(() {
      _subCollections.add(newSub);
      _isAddingSub = false;
      _newSubNameController.clear();
      _newSubSlugController.clear();
      _newSubImageUrl = null;
      _newSubImageBytes = null;
      _newSubImageFileName = null;
    });
  }

  void _handleRemoveSubCollection(int index) {
    setState(() {
      _subCollections.removeAt(index);
    });
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final priorityVal = int.tryParse(_priorityController.text.trim()) ?? widget.collection.priority;
    final bannerVal = _bannerTitleController.text.trim();

    final updatedItem = widget.collection.copyWith(
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      description: _descriptionController.text.trim(),
      isActive: _isActive,
      priority: priorityVal,
      bannerTitle: bannerVal.isNotEmpty ? bannerVal : null,
      image: _imageUrl,
      subCollections: _subCollections,
      subCollectionCount: _subCollections.length,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );

    context.read<CollectionBloc>().add(UpdateCollection(updatedItem));
  }

  void _closeView([CollectionItem? updated]) {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardBgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

    return BlocListener<CollectionBloc, CollectionState>(
      listenWhen: (previous, current) =>
          previous.updatedCollection != current.updatedCollection &&
          current.updatedCollection != null,
      listener: (context, state) {
        final updated = state.updatedCollection!;
        widget.onCollectionUpdated?.call(updated);
        _closeView(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Collection "${updated.name}" updated successfully.',
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
          final isUpdating = state.isUpdating;
          final errorMessage = state.updateError;

          final pageBgColor =
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

          final content = Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Workspace Header (Pinned)
                Container(
                  color: surfaceColor,
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: isUpdating ? null : () => _closeView(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 17),
                        label: Text(
                          'Back to Collections',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155),
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Collection',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'PUT /api/v1/admin/collections/${widget.collection.id}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: borderColor),

                // Scrollable Full-Width Form Workspace
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            if (errorMessage != null) ...[
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
                              const SizedBox(height: 16),
                            ],

                            // Collection Name
                      _buildLabel('Collection Name *', isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        enabled: !isUpdating,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: _inputDecoration(
                          hintText: 'e.g. Shop By Crops',
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

                      // Description
                      _buildLabel('Description', isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !isUpdating,
                        maxLines: 2,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: _inputDecoration(
                          hintText: 'Shop accordingly to crop',
                          isDark: isDark,
                          surfaceColor: cardBgColor,
                          borderColor: borderColor,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Collection Image Upload Section
                      _buildLabel('Collection Image (Optional)', isDark),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 50,
                                height: 50,
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                child: _imageBytes != null
                                    ? Image.memory(_imageBytes!, width: 50, height: 50, fit: BoxFit.cover)
                                    : (_imageUrl != null && _imageUrl!.isNotEmpty
                                        ? AppProductImage(imageUrl: _imageUrl!, width: 50, height: 50, borderRadius: 8, fit: BoxFit.cover)
                                        : const Icon(Icons.photo_outlined, size: 22, color: Color(0xFF94A3B8))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _imageFileName ?? (_imageUrl != null ? 'Image attached' : 'Upload banner / thumbnail'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'PNG, JPG, WEBP from device',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isUploadingImage)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                                ),
                              )
                            else ...[
                              OutlinedButton.icon(
                                onPressed: isUpdating ? null : _pickCollectionImage,
                                icon: const Icon(Icons.upload_file_rounded, size: 15),
                                label: Text(
                                  _imageUrl != null || _imageBytes != null ? 'Change' : 'Upload Image',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF059669),
                                  side: const BorderSide(color: Color(0xFF059669)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                              if (_imageUrl != null || _imageBytes != null) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                  tooltip: 'Remove',
                                  onPressed: () {
                                    setState(() {
                                      _imageUrl = null;
                                      _imageBytes = null;
                                      _imageFileName = null;
                                    });
                                  },
                                ),
                              ],
                            ],
                          ],
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
                                  enabled: !isUpdating,
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
                                  enabled: !isUpdating,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  decoration: _inputDecoration(
                                    hintText: 'e.g. Shop By Crop',
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
                                        ? 'Collection is visible on live buyer store routes'
                                        : 'Collection is hidden from storefront navigation',
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
                              onChanged: isUpdating ? null : (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Sub-Collections Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_tree_outlined, size: 16, color: Color(0xFF7C3AED)),
                              const SizedBox(width: 6),
                              Text(
                                'Sub-Collections (${_subCollections.length})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          if (!_isAddingSub)
                            TextButton.icon(
                              onPressed: isUpdating ? null : () => setState(() => _isAddingSub = true),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                'Add Sub-Collection',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Inline Add Sub-Collection Form
                      if (_isAddingSub) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Sub-Collection Node',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _newSubNameController,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                decoration: _inputDecoration(
                                  hintText: 'Sub-Collection Name (e.g. Rice, Maize)',
                                  isDark: isDark,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.link_rounded, size: 13, color: Color(0xFF7C3AED)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Slug (auto): ',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    _newSubSlugController.text.isNotEmpty ? '/${_newSubSlugController.text}' : '/auto-generated',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF7C3AED),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Sub-Collection Image Upload
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                        child: _newSubImageBytes != null
                                            ? Image.memory(_newSubImageBytes!, width: 40, height: 40, fit: BoxFit.cover)
                                            : (_newSubImageUrl != null && _newSubImageUrl!.isNotEmpty
                                                ? AppProductImage(imageUrl: _newSubImageUrl!, width: 40, height: 40, borderRadius: 6, fit: BoxFit.cover)
                                                : const Icon(Icons.image_outlined, size: 20, color: Color(0xFF94A3B8))),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _newSubImageFileName ?? (_newSubImageUrl != null ? 'Image uploaded' : 'Sub-collection image (optional)'),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Upload image from device',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_isUploadingSubImage)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                                        ),
                                      )
                                    else ...[
                                      OutlinedButton.icon(
                                        onPressed: _pickSubCollectionImage,
                                        icon: const Icon(Icons.upload_rounded, size: 14),
                                        label: Text(
                                          _newSubImageUrl != null || _newSubImageBytes != null ? 'Change' : 'Upload',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF7C3AED),
                                          side: const BorderSide(color: Color(0xFF7C3AED)),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                      if (_newSubImageUrl != null || _newSubImageBytes != null) ...[
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                          tooltip: 'Remove',
                                          onPressed: () {
                                            setState(() {
                                              _newSubImageUrl = null;
                                              _newSubImageBytes = null;
                                              _newSubImageFileName = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => setState(() => _isAddingSub = false),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _isUploadingSubImage ? null : _handleAddSubCollection,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7C3AED),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: Text(
                                      _isUploadingSubImage ? 'Uploading...' : 'Add Node',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Sub-Collections List
                      if (_subCollections.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No sub-collections attached.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(10),
                            color: cardBgColor,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 260),
                            child: GridView.builder(
                              shrinkWrap: true,
                              itemCount: _subCollections.length,
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                mainAxisExtent: 48,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemBuilder: (context, idx) {
                                final sub = _subCollections[idx];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: SizedBox(
                                          width: 26,
                                          height: 26,
                                          child: sub.image != null && sub.image!.isNotEmpty
                                              ? AppProductImage(
                                                  imageUrl: sub.image!,
                                                  width: 26,
                                                  height: 26,
                                                  borderRadius: 6,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                                                  child: const Icon(
                                                    Icons.subdirectory_arrow_right_rounded,
                                                    size: 14,
                                                    color: Color(0xFF7C3AED),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              sub.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              '/${sub.slug} • ${sub.productCount}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 10,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                        onTap: isUpdating ? null : () => _handleRemoveSubCollection(idx),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 16,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ),

                Divider(height: 1, color: borderColor),

                // Action Buttons (Pinned Footer)
                Container(
                  color: surfaceColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    children: [
                      const Spacer(),
                      OutlinedButton(
                        onPressed: isUpdating ? null : () => _closeView(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: isUpdating ? null : _handleSubmit,
                        icon: isUpdating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 16),
                        label: Text(
                          isUpdating ? 'Saving...' : 'Save Collection',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (widget.onClose != null) {
            return Container(color: pageBgColor, child: content);
          }
          return Scaffold(
            backgroundColor: pageBgColor,
            body: SafeArea(child: content),
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
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
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
