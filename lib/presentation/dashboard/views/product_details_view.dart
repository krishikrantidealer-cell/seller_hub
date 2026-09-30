import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/product.dart';

class ProductDetailsView extends StatefulWidget {
  final Product product;
  final VoidCallback onBack;
  final Function(Product updatedProduct)? onProductUpdated;
  final bool startInEditMode;

  const ProductDetailsView({
    super.key,
    required this.product,
    required this.onBack,
    this.onProductUpdated,
    this.startInEditMode = false,
  });

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  late Product _currentProduct;
  late bool _isEditing;

  // Form Controllers for 38-field editing
  late TextEditingController _titleController;
  late TextEditingController _techNameController;
  late TextEditingController _productCodeController;
  late TextEditingController _hsnCodeController;
  late TextEditingController _vendorController;
  late TextEditingController _categoryController;
  late TextEditingController _collectionsController;
  late TextEditingController _subCollectionsController;
  late TextEditingController _descriptionController;
  late TextEditingController _techContentController;
  late TextEditingController _featuresController;
  late TextEditingController _benefitsController;
  late TextEditingController _modeOfActionController;
  late TextEditingController _suitableCropController;
  late TextEditingController _targetPestsController;
  late TextEditingController _targetDiseasesController;
  late TextEditingController _dosageController;
  late TextEditingController _appMethodController;
  late TextEditingController _variantController;
  late TextEditingController _packSizeController;
  late TextEditingController _unitController;
  late TextEditingController _displayRateController;
  late TextEditingController _printedMrpController;
  late TextEditingController _costPriceController;
  late TextEditingController _gstController;
  late TextEditingController _shippedByController;
  late TextEditingController _swgController;
  late TextEditingController _stockController;
  late TextEditingController _ratingsController;
  late TextEditingController _refundPolicyController;
  late TextEditingController _weightController;
  late TextEditingController _weightUnitController;
  late TextEditingController _dimensionsController;
  late TextEditingController _imageUrlController;

  late bool _editIsAvailable;
  // late bool _editIsFeatured; // isFeatured temporarily commented out

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _isEditing = widget.startInEditMode;
    _initControllers(_currentProduct);
  }

  void _initControllers(Product p) {
    _titleController = TextEditingController(text: p.title);
    _techNameController = TextEditingController(text: p.technicalName);
    _productCodeController = TextEditingController(text: p.productCode);
    _hsnCodeController = TextEditingController(text: p.hsnCode);
    _vendorController = TextEditingController(text: p.vendor);
    _categoryController = TextEditingController(text: p.category);
    _collectionsController = TextEditingController(text: p.collections);
    _subCollectionsController = TextEditingController(text: p.subCollections);
    _descriptionController = TextEditingController(text: p.description);
    _techContentController = TextEditingController(text: p.technicalContent);
    _featuresController = TextEditingController(text: p.features);
    _benefitsController = TextEditingController(text: p.benefits);
    _modeOfActionController = TextEditingController(text: p.modeOfAction);
    _suitableCropController = TextEditingController(text: p.suitableCrop);
    _targetPestsController = TextEditingController(text: p.targetPests);
    _targetDiseasesController = TextEditingController(text: p.targetDiseases);
    _dosageController = TextEditingController(text: p.dosage);
    _appMethodController = TextEditingController(text: p.applicationMethod);
    _variantController = TextEditingController(text: p.variant);
    _packSizeController = TextEditingController(text: p.packSize);
    _unitController = TextEditingController(text: p.unit);
    _displayRateController = TextEditingController(text: p.displayRate.toStringAsFixed(2));
    _printedMrpController = TextEditingController(text: p.printedMrp.toStringAsFixed(2));
    _costPriceController = TextEditingController(text: p.costPrice.toStringAsFixed(2));
    _gstController = TextEditingController(text: p.gst.toStringAsFixed(0));
    _shippedByController = TextEditingController(text: p.shippedBy);
    _swgController = TextEditingController(text: p.swg);
    _stockController = TextEditingController(text: p.stock.toString());
    _ratingsController = TextEditingController(text: p.ratings.toStringAsFixed(1));
    _refundPolicyController = TextEditingController(text: p.refundPolicy);
    _weightController = TextEditingController(text: p.productWeight.toStringAsFixed(2));
    _weightUnitController = TextEditingController(text: p.productWeightUnit);
    _dimensionsController = TextEditingController(text: p.dimensions);
    _imageUrlController = TextEditingController(text: p.images.isNotEmpty ? p.images.first : '');

    _editIsAvailable = p.isAvailable;
    // _editIsFeatured = p.isFeatured;
  }

  void _resetControllers() {
    _initControllers(_currentProduct);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _techNameController.dispose();
    _productCodeController.dispose();
    _hsnCodeController.dispose();
    _vendorController.dispose();
    _categoryController.dispose();
    _collectionsController.dispose();
    _subCollectionsController.dispose();
    _descriptionController.dispose();
    _techContentController.dispose();
    _featuresController.dispose();
    _benefitsController.dispose();
    _modeOfActionController.dispose();
    _suitableCropController.dispose();
    _targetPestsController.dispose();
    _targetDiseasesController.dispose();
    _dosageController.dispose();
    _appMethodController.dispose();
    _variantController.dispose();
    _packSizeController.dispose();
    _unitController.dispose();
    _displayRateController.dispose();
    _printedMrpController.dispose();
    _costPriceController.dispose();
    _gstController.dispose();
    _shippedByController.dispose();
    _swgController.dispose();
    _stockController.dispose();
    _ratingsController.dispose();
    _refundPolicyController.dispose();
    _weightController.dispose();
    _weightUnitController.dispose();
    _dimensionsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _toggleAvailability() {
    setState(() {
      _currentProduct = _currentProduct.copyWith(isAvailable: !_currentProduct.isAvailable);
      _editIsAvailable = _currentProduct.isAvailable;
    });
    widget.onProductUpdated?.call(_currentProduct);
  }

  /*
  void _toggleFeatured() {
    setState(() {
      _currentProduct = _currentProduct.copyWith(isFeatured: !_currentProduct.isFeatured);
      _editIsFeatured = _currentProduct.isFeatured;
    });
    widget.onProductUpdated?.call(_currentProduct);
  }
  */

  void _saveChanges() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Product Title cannot be empty',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final displayRate = double.tryParse(_displayRateController.text) ?? _currentProduct.displayRate;
    final printedMrp = double.tryParse(_printedMrpController.text) ?? _currentProduct.printedMrp;
    final costPrice = double.tryParse(_costPriceController.text) ?? _currentProduct.costPrice;
    final discountRs = (printedMrp > displayRate) ? (printedMrp - displayRate) : 0.0;
    final discountPct = printedMrp > 0 ? (discountRs / printedMrp * 100) : 0.0;
    final stock = int.tryParse(_stockController.text) ?? _currentProduct.stock;
    final gst = double.tryParse(_gstController.text) ?? _currentProduct.gst;
    final ratings = double.tryParse(_ratingsController.text) ?? _currentProduct.ratings;
    final weight = double.tryParse(_weightController.text) ?? _currentProduct.productWeight;

    final imgUrl = _imageUrlController.text.trim();
    final updatedImages = imgUrl.isNotEmpty
        ? [imgUrl, ..._currentProduct.images.where((img) => img != imgUrl)]
        : _currentProduct.images;

    final updatedProduct = _currentProduct.copyWith(
      title: title,
      technicalName: _techNameController.text.trim(),
      productCode: _productCodeController.text.trim(),
      hsnCode: _hsnCodeController.text.trim(),
      vendor: _vendorController.text.trim(),
      category: _categoryController.text.trim(),
      collections: _collectionsController.text.trim(),
      subCollections: _subCollectionsController.text.trim(),
      description: _descriptionController.text.trim(),
      technicalContent: _techContentController.text.trim(),
      features: _featuresController.text.trim(),
      benefits: _benefitsController.text.trim(),
      modeOfAction: _modeOfActionController.text.trim(),
      suitableCrop: _suitableCropController.text.trim(),
      targetPests: _targetPestsController.text.trim(),
      targetDiseases: _targetDiseasesController.text.trim(),
      dosage: _dosageController.text.trim(),
      applicationMethod: _appMethodController.text.trim(),
      variant: _variantController.text.trim(),
      packSize: _packSizeController.text.trim(),
      unit: _unitController.text.trim(),
      displayRate: displayRate,
      printedMrp: printedMrp,
      costPrice: costPrice,
      discountRs: discountRs,
      gst: gst,
      discountPercentage: discountPct,
      shippedBy: _shippedByController.text.trim(),
      swg: _swgController.text.trim(),
      stock: stock,
      ratings: ratings,
      refundPolicy: _refundPolicyController.text.trim(),
      productWeight: weight,
      productWeightUnit: _weightUnitController.text.trim(),
      dimensions: _dimensionsController.text.trim(),
      images: updatedImages,
      isAvailable: _editIsAvailable,
      isFeatured: _currentProduct.isFeatured,
    );

    setState(() {
      _currentProduct = updatedProduct;
      _isEditing = false;
    });

    widget.onProductUpdated?.call(updatedProduct);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Successfully updated "${updatedProduct.title}" (All 38 Fields Synchronized)',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      _resetControllers();
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 1040;
    final p = _currentProduct;

    // Derived Financials for live calculation
    double curDisplayRate = p.displayRate;
    double curCostPrice = p.costPrice;
    if (_isEditing) {
      curDisplayRate = double.tryParse(_displayRateController.text) ?? p.displayRate;
      curCostPrice = double.tryParse(_costPriceController.text) ?? p.costPrice;
    }
    final grossProfit = curDisplayRate - curCostPrice;
    final marginPct = curDisplayRate > 0 ? (grossProfit / curDisplayRate * 100) : 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Action & Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                // Back to catalog button
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _isEditing ? _cancelEdit : widget.onBack,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Text(
                          'Products Catalog',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            'EDIT MODE ACTIVE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Edit Mode Actions or Standard Quick Actions
                if (_isEditing) ...[
                  OutlinedButton.icon(
                    onPressed: _cancelEdit,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text(
                      'Save Changes',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ] else ...[
                  /*
                  // Star / Featured Quick Toggle temporarily commented out
                  IconButton(
                    tooltip: p.isFeatured ? 'Featured Product' : 'Mark as Featured',
                    icon: Icon(
                      p.isFeatured ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 22,
                    ),
                    onPressed: _toggleFeatured,
                  ),
                  */

                  // Availability Quick Pill
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _toggleAvailability,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (p.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (p.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.isAvailable ? 'In Stock / Live' : 'Unavailable',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: p.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Prominent "Edit Product" Button
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _initControllers(_currentProduct);
                        _isEditing = true;
                      });
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: Text(
                      'Edit Product',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Main Responsive Grid Layout
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Media, Commercials & Logistics (380px)
                SizedBox(
                  width: 380,
                  child: Column(
                    children: [
                      _buildImageAndMediaCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                      const SizedBox(height: 18),
                      _buildPricingCard(p, isDark, surfaceColor, borderColor, cardBgColor, grossProfit, marginPct),
                      const SizedBox(height: 18),
                      _buildLogisticsAndPackagingCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Right Column: Identity, Agronomy & Narrative (Flexible)
                Expanded(
                  child: Column(
                    children: [
                      _buildIdentityHeaderCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                      const SizedBox(height: 18),
                      _buildAgronomyCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                      const SizedBox(height: 18),
                      _buildDescriptionAndBenefitsCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                    ],
                  ),
                ),
              ],
            )
          else
            // Narrow Screen Layout
            Column(
              children: [
                _buildIdentityHeaderCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                const SizedBox(height: 16),
                _buildImageAndMediaCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                const SizedBox(height: 16),
                _buildPricingCard(p, isDark, surfaceColor, borderColor, cardBgColor, grossProfit, marginPct),
                const SizedBox(height: 16),
                _buildAgronomyCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                const SizedBox(height: 16),
                _buildLogisticsAndPackagingCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                const SizedBox(height: 16),
                _buildDescriptionAndBenefitsCard(p, isDark, surfaceColor, borderColor, cardBgColor),
              ],
            ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 1: PRODUCT IDENTITY HEADER
  // ==========================================
  Widget _buildIdentityHeaderCard(
    Product p,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color cardBgColor,
  ) {
    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.badge_outlined, color: Color(0xFF059669), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Product Identity & Catalog Codes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _titleController,
              label: 'Product Title *',
              hint: 'e.g. Chlorpyrifos 50% + Cypermethrin 5% EC',
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _techNameController,
              label: 'Technical / Scientific Name',
              hint: 'e.g. Chlorpyrifos + Cypermethrin',
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _productCodeController,
                    label: 'Product Code (SKU) *',
                    hint: 'e.g. AGRI-INS-001',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _hsnCodeController,
                    label: 'HSN Code *',
                    hint: 'e.g. 38089190',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _vendorController,
                    label: 'Vendor / Manufacturer',
                    hint: 'e.g. Krishi Kranti Organics',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _categoryController,
                    label: 'Category',
                    hint: 'e.g. Agro Chemicals',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _collectionsController,
                    label: 'Collection',
                    hint: 'e.g. Crop Protection',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _subCollectionsController,
                    label: 'Sub Collection',
                    hint: 'e.g. Insecticides',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _ratingsController,
                    label: 'Ratings (1.0 - 5.0)',
                    hint: '4.8',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: Text(
                        'Live / Available for Orders',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      value: _editIsAvailable,
                      activeThumbColor: const Color(0xFF059669),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _editIsAvailable = val),
                    ),
                  ),
                ),
                /*
                // Featured Product Banner temporarily commented out
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: Text(
                        'Featured Product Banner',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      value: _editIsFeatured,
                      activeThumbColor: const Color(0xFFF59E0B),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _editIsFeatured = val),
                    ),
                  ),
                ),
                */
              ],
            ),
          ],
        ),
      );
    }

    // Read-only view
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.category.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (p.collections.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.collections,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(
                    p.ratings.toStringAsFixed(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    ' (Ratings)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            p.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.science_rounded, size: 16, color: Color(0xFF059669)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Technical Name: ${p.technicalName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (p.sellerId.isNotEmpty)
                _buildBadgePill('Seller ID', p.sellerId, isDark, borderColor),
              if (p.sku.isNotEmpty && p.sku != p.productCode)
                _buildBadgePill('SKU', p.sku, isDark, borderColor),
              _buildBadgePill('Product Code', p.productCode, isDark, borderColor),
              _buildBadgePill('HSN Code', p.hsnCode, isDark, borderColor),
              _buildBadgePill('Vendor', p.vendor, isDark, borderColor),
              if (p.subCollections.isNotEmpty)
                _buildBadgePill('Sub Collection', p.subCollections, isDark, borderColor),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 2: IMAGE & VISUAL ASSETS
  // ==========================================
  Widget _buildImageAndMediaCard(
    Product p,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color cardBgColor,
  ) {
    final previewUrl = _isEditing ? _imageUrlController.text.trim() : (p.images.isNotEmpty ? p.images.first : '');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 200,
              color: cardBgColor,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (previewUrl.isNotEmpty && previewUrl.startsWith('http'))
                    Image.network(
                      previewUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildImageFallback(p),
                    )
                  else
                    _buildImageFallback(p),

                  // Pack Tag on Image
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pack: ${_isEditing ? _packSizeController.text : p.packSize} ${_isEditing ? _unitController.text : p.unit} • ${_isEditing ? _variantController.text : p.variant}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isEditing) ...[
            _buildField(
              controller: _imageUrlController,
              label: 'Primary Image URL',
              hint: 'https://images.unsplash.com/...',
              isDark: isDark,
              borderColor: borderColor,
              onChanged: (_) => setState(() {}),
            ),
          ] else ...[
            Text(
              'Product Media Gallery (${p.images.length} Image)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageFallback(Product p) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: const Color(0xFF059669).withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _isEditing ? _titleController.text : p.title,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 3: PRICING & COMMERCIAL MATRIX
  // ==========================================
  Widget _buildPricingCard(
    Product p,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color cardBgColor,
    double grossProfit,
    double marginPct,
  ) {
    if (_isEditing) {
      final disp = double.tryParse(_displayRateController.text) ?? 0.0;
      final mrp = double.tryParse(_printedMrpController.text) ?? 0.0;
      final disc = (mrp > disp) ? (mrp - disp) : 0.0;
      final discPct = mrp > 0 ? (disc / mrp * 100) : 0.0;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.currency_rupee_rounded, color: Color(0xFF059669), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Pricing & Commercials',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _displayRateController,
                    label: 'Display Rate (₹) *',
                    hint: '540.00',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    borderColor: borderColor,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _printedMrpController,
                    label: 'Printed MRP (₹) *',
                    hint: '650.00',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    borderColor: borderColor,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _costPriceController,
                    label: 'Cost Price (₹)',
                    hint: '410.00',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    borderColor: borderColor,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _gstController,
                    label: 'GST Slab (%)',
                    hint: '18',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Live financial calculation summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _buildMiniSummaryRow('Auto-Calculated Discount:', '₹${disc.toStringAsFixed(2)} (${discPct.toStringAsFixed(1)}%)', isDark),
                  const SizedBox(height: 4),
                  _buildMiniSummaryRow('Projected Gross Margin:', '₹${grossProfit.toStringAsFixed(2)} (${marginPct.toStringAsFixed(1)}%)', isDark, valueColor: const Color(0xFF10B981)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Read-only view
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing & Commercial Matrix',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Main Price Row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISPLAY RATE (SELLER OFFER)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${p.displayRate.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PRINTED MRP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '₹${p.printedMrp.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.lineThrough,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _buildGridValueRow('Cost Price (To Seller)', '₹${p.costPrice.toStringAsFixed(2)}', isDark),
          _buildGridValueRow(
            'Discount in Rupees',
            '₹${p.discountRs.toStringAsFixed(2)} (${p.discountPercentage.toStringAsFixed(1)}% off)',
            isDark,
            valueColor: const Color(0xFF059669),
          ),
          _buildGridValueRow('GST Tax Slab', '${p.gst.toStringAsFixed(0)}% Applicable', isDark),
          _buildGridValueRow(
            'Estimated Gross Margin',
            '₹${grossProfit.toStringAsFixed(2)} (${marginPct.toStringAsFixed(1)}%)',
            isDark,
            valueColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 4: LOGISTICS & INVENTORY
  // ==========================================
  Widget _buildLogisticsAndPackagingCard(
    Product p,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color cardBgColor,
  ) {
    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: Color(0xFF059669), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Logistics & Packaging Specs',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _stockController,
                    label: 'Stock on Hand *',
                    hint: '240',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _packSizeController,
                    label: 'Pack Size *',
                    hint: '500',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _unitController,
                    label: 'Unit *',
                    hint: 'ml / L / kg',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _variantController,
                    label: 'Variant *',
                    hint: 'Liquid Formulation',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _weightController,
                    label: 'Product Weight',
                    hint: '0.62',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _weightUnitController,
                    label: 'Weight Unit',
                    hint: 'kg',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _swgController,
                    label: 'SWG Code',
                    hint: 'SWG-22',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _dimensionsController,
                    label: 'Dimensions (LxWxH)',
                    hint: '8 x 8 x 20 cm',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _shippedByController,
              label: 'Shipped By Partner',
              hint: 'Krishi Kranti Logistics / Seller',
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _refundPolicyController,
              label: 'Refund & Return Policy',
              hint: '7-day replacement for sealed bottle',
              isDark: isDark,
              borderColor: borderColor,
            ),
          ],
        ),
      );
    }

    // Read-only view
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory & Fulfillment Specs',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          _buildGridValueRow('Stock on Hand', '${p.stock} Units', isDark, valueColor: p.stock > 50 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
          _buildGridValueRow('Pack Size & Unit', '${p.packSize} ${p.unit}', isDark),
          _buildGridValueRow('Variant Type', p.variant, isDark),
          _buildGridValueRow('Shipping Weight', '${p.productWeight} ${p.productWeightUnit}', isDark),
          _buildGridValueRow('Volumetric SWG', p.swg, isDark),
          _buildGridValueRow('Dimensions (LxWxH)', p.dimensions, isDark),
          _buildGridValueRow('Shipped By Partner', p.shippedBy, isDark),
          _buildGridValueRow('Refund / Return Policy', p.refundPolicy, isDark),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 5: AGRONOMY, CROPS & CHEMICAL SPECS
  // ==========================================
  Widget _buildAgronomyCard(
    Product p,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color cardBgColor,
  ) {
    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.eco_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Agronomic Specifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _techContentController,
              label: 'Chemical Composition & Technical Content',
              hint: 'e.g. Chlorpyrifos 50% + Cypermethrin 5% EC',
              maxLines: 2,
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _modeOfActionController,
              label: 'Biochemical Mode of Action',
              hint: 'e.g. Dual-action contact and stomach poison with rapid knockdown',
              maxLines: 2,
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _dosageController,
                    label: 'Dosage Recommendation',
                    hint: 'e.g. 2 - 2.5 ml per liter of water',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _appMethodController,
                    label: 'Application Method',
                    hint: 'e.g. Foliar Spray with knapsack sprayer',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _suitableCropController,
              label: 'Suitable Crops (Comma-separated)',
              hint: 'Cotton, Paddy, Sugarcane, Vegetables, Pulses',
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _targetPestsController,
                    label: 'Target Pests (Comma-separated)',
                    hint: 'Bollworms, Aphids, Whiteflies, Thrips',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _targetDiseasesController,
                    label: 'Target Diseases (Comma-separated)',
                    hint: 'None / Fungal Blight, Rust',
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Read-only view
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, size: 20, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Agronomic Specifications & Field Efficacy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Technical Content
          _buildSectionHeader('Chemical Composition & Technical Content', isDark),
          Text(
            p.technicalContent.isNotEmpty ? p.technicalContent : 'Standard formulated technical concentration.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 14),

          // Mode of Action
          _buildSectionHeader('Biochemical Mode of Action', isDark),
          Text(
            p.modeOfAction.isNotEmpty ? p.modeOfAction : 'Standard action mechanism.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Recommended Dosage & Application Callout Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B241C) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.water_drop_rounded, color: Color(0xFF059669), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECOMMENDED DOSAGE & APPLICATION METHOD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.dosage} • ${p.applicationMethod}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF064E3B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Suitable Crops Chips
          _buildSectionHeader('Suitable Crops / Target Field Crops', isDark),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.suitableCrop.split(RegExp(r'[,•;]')).map((crop) {
              final trimmed = crop.trim();
              if (trimmed.isEmpty) return const SizedBox.shrink();
              return Chip(
                avatar: const Icon(Icons.grass_rounded, size: 14, color: Color(0xFF059669)),
                label: Text(trimmed),
                backgroundColor: const Color(0xFF059669).withValues(alpha: 0.1),
                side: BorderSide(color: const Color(0xFF059669).withValues(alpha: 0.2)),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Target Pests & Diseases Chips
          _buildSectionHeader('Target Pests & Controlled Diseases', isDark),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...p.targetPests.split(RegExp(r'[,•;]')).map((pest) {
                final trimmed = pest.trim();
                if (trimmed.isEmpty) return const SizedBox.shrink();
                return Chip(
                  avatar: const Icon(Icons.bug_report_rounded, size: 14, color: Color(0xFFF59E0B)),
                  label: Text('Pest: $trimmed'),
                  backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }),
              ...p.targetDiseases.split(RegExp(r'[,•;]')).map((disease) {
                final trimmed = disease.trim();
                if (trimmed.isEmpty || trimmed.toLowerCase().contains('none')) return const SizedBox.shrink();
                return Chip(
                  avatar: const Icon(Icons.coronavirus_rounded, size: 14, color: Color(0xFFEF4444)),
                  label: Text('Disease: $trimmed'),
                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 6: DESCRIPTION, FEATURES & BENEFITS
  // ==========================================
  Widget _buildDescriptionAndBenefitsCard(
    Product p,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color cardBgColor,
  ) {
    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined, color: Color(0xFF059669), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Product Narrative & Documentation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _descriptionController,
              label: 'Full Commercial Description',
              hint: 'Comprehensive product description for farmers and dealers...',
              maxLines: 4,
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _featuresController,
              label: 'Key Features (Comma-separated or bullet lines)',
              hint: 'Quick knockdown, Broad spectrum, Translaminar action',
              maxLines: 3,
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _benefitsController,
              label: 'Farmer & Yield Benefits (Comma-separated or bullet lines)',
              hint: 'Protects critical crop growth phase, Enhances greening',
              maxLines: 3,
              isDark: isDark,
              borderColor: borderColor,
            ),
          ],
        ),
      );
    }

    // Read-only view
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commercial Description & Agronomic Documentation',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Description
          Text(
            p.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              height: 1.55,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 18),

          // Features
          _buildSectionHeader('Key Product Features', isDark),
          const SizedBox(height: 6),
          ...p.features.split(RegExp(r'[,•;]')).map((feat) {
            final trimmed = feat.trim();
            if (trimmed.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trimmed,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Benefits
          _buildSectionHeader('Farmer & Yield Benefits', isDark),
          const SizedBox(height: 6),
          ...p.benefits.split(RegExp(r'[,•;]')).map((ben) {
            final trimmed = ben.trim();
            if (trimmed.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trimmed,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required Color borderColor,
    int maxLines = 1,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniSummaryRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          textAlign: TextAlign.end,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildBadgePill(String label, String value, bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridValueRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 5,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
