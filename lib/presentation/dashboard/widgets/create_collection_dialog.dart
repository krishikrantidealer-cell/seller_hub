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

  // Collection Image state
  String? _imageUrl;
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isUploadingImage = false;

  final List<SubCollectionItem> _subCollections = [];
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
    context.read<CollectionBloc>().add(const ResetCreateCollectionState());
    _nameController.addListener(_onNameChanged);
    _newSubNameController.addListener(_onSubNameChanged);
  }

  void _onNameChanged() {
    final generated = _nameController.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    _slugController.text = generated;
    setState(() {});
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
    _nameController.removeListener(_onNameChanged);
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
      id: '',
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
            image: _imageUrl,
            subCollections: _subCollections.map((s) => s.toJson()).toList(),
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
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: MediaQuery.sizeOf(context).height * 0.92,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Row(
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
                    ),
                    Divider(height: 1, color: borderColor),

                    // Scrollable form fields
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                              enabled: !isCreating && !_isUploadingImage,
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

                            const SizedBox(height: 6),

                            // Auto-generated slug indicator (User does not write slug)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.link_rounded, size: 14, color: Color(0xFF059669)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Auto URL Slug: ',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    _slugController.text.isNotEmpty ? _slugController.text : 'auto-generated',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ],
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
                                          _imageFileName ?? (_imageUrl != null ? 'Image uploaded' : 'Upload banner / thumbnail'),
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
                                      onPressed: isCreating ? null : _pickCollectionImage,
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

                      const SizedBox(height: 18),

                      // Sub-Collections Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.account_tree_outlined, size: 16, color: Color(0xFF7C3AED)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Sub-Collections (${_subCollections.length})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isAddingSub)
                            TextButton.icon(
                              onPressed: isCreating ? null : () => setState(() => _isAddingSub = true),
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
                                      fontWeight: FontWeight.w600,
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
                                    onPressed: _handleAddSubCollection,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7C3AED),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: Text(
                                      'Add Node',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
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
                            'No sub-collections attached yet. You can add them now or later.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _subCollections.length,
                            separatorBuilder: (_, index) => Divider(height: 1, color: borderColor),
                            itemBuilder: (context, idx) {
                              final sub = _subCollections[idx];
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: sub.image != null && sub.image!.isNotEmpty
                                        ? AppProductImage(
                                            imageUrl: sub.image!,
                                            width: 28,
                                            height: 28,
                                            borderRadius: 6,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                            child: const Center(
                                              child: Icon(Icons.grain_rounded, size: 16, color: Color(0xFF7C3AED)),
                                            ),
                                          ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      sub.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '/${sub.slug}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10.5,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  tooltip: 'Remove',
                                  color: const Color(0xFFEF4444),
                                  onPressed: isCreating ? null : () => _handleRemoveSubCollection(idx),
                                ),
                              );
                            },
                          ),
                        ),

                          ],
                        ),
                      ),
                    ),

                    Divider(height: 1, color: borderColor),

                    // Pinned Actions Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                      child: Row(
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
                    ),
                  ],
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
