import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/product.dart';
import '../../../logic/admin_user/admin_user_event.dart';
import '../../../logic/admin_user/admin_user_state.dart';
import '../../../logic/admin_user/seller_bloc.dart';
import '../../../logic/category/category_bloc.dart';
import '../../../logic/category/category_event.dart';
import '../../../logic/category/category_state.dart';

class AddProductDialog extends StatefulWidget {
  final Function(Product) onProductAdded;
  final String sellerId;

  const AddProductDialog({
    super.key,
    required this.onProductAdded,
    this.sellerId = '6ab4ada822033f1670582bda',
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // 1. General Info Controllers
  final _skuController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _hsnCodeController = TextEditingController(text: '3808');
  final _titleController = TextEditingController();
  final _technicalNameController = TextEditingController();
  final _vendorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _featuresController = TextEditingController();
  final _benefitsController = TextEditingController();

  // 2. Agronomy Controllers
  final _technicalContentController = TextEditingController();
  final _modeOfActionController = TextEditingController();
  final _suitableCropController = TextEditingController();
  final _targetPestsController = TextEditingController();
  final _targetDiseasesController = TextEditingController();
  final _dosageController = TextEditingController();
  final _applicationMethodController = TextEditingController();

  // 3. Classification & Variant Controllers
  String _selectedCategory = 'Bio Organic Nutrients';
  String? _selectedCategoryId = '6ab4f6f619ec643fd9bf3621';
  final _collectionsController = TextEditingController(text: 'Crop Protection');
  final _subCollectionsController = TextEditingController(text: 'Pest Management');
  final _variantController = TextEditingController(text: '500 ml Bottle');
  final _packSizeController = TextEditingController(text: '500');
  String _selectedUnit = 'ml';

  // 4. Pricing & Tax Controllers
  final _displayRateController = TextEditingController(text: '450');
  final _printedMrpController = TextEditingController(text: '500');
  final _costPriceController = TextEditingController(text: '250');
  double _selectedGst = 5.0;

  // 5. Inventory & Shipping Controllers
  final _stockController = TextEditingController(text: '100');
  final _shippedByController = TextEditingController(text: 'EBS Direct');
  final _swgController = TextEditingController(text: 'Standard');
  final _weightController = TextEditingController(text: '500');
  String _selectedWeightUnit = 'g';
  final _dimensionsController = TextEditingController(text: '20 x 10 x 10 cm');
  final _refundPolicyController = TextEditingController(text: '7 Days Returnable if unopened');
  bool _isAvailable = false;
  // bool _isFeatured = false; // isFeatured temporarily commented out
  String? _selectedSellerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedSellerId = widget.sellerId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final sellerBloc = context.read<SellerBloc>();
        if (sellerBloc.state.users.isEmpty) {
          sellerBloc.add(const InitializeAdminUsers());
        }
        final categoryBloc = context.read<CategoryBloc>();
        if (categoryBloc.state.allCategories.isEmpty) {
          categoryBloc.add(const InitializeCategories());
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _skuController.dispose();
    _productCodeController.dispose();
    _hsnCodeController.dispose();
    _titleController.dispose();
    _technicalNameController.dispose();
    _vendorController.dispose();
    _descriptionController.dispose();
    _featuresController.dispose();
    _benefitsController.dispose();
    _technicalContentController.dispose();
    _modeOfActionController.dispose();
    _suitableCropController.dispose();
    _targetPestsController.dispose();
    _targetDiseasesController.dispose();
    _dosageController.dispose();
    _applicationMethodController.dispose();
    _collectionsController.dispose();
    _subCollectionsController.dispose();
    _variantController.dispose();
    _packSizeController.dispose();
    _displayRateController.dispose();
    _printedMrpController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _shippedByController.dispose();
    _swgController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _refundPolicyController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields in the product form.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final mrp = double.tryParse(_printedMrpController.text) ?? 500.0;
    final rate = double.tryParse(_displayRateController.text) ?? 450.0;
    final cost = double.tryParse(_costPriceController.text) ?? 250.0;
    final discountRs = (mrp > rate) ? (mrp - rate) : 0.0;
    final discountPct = (mrp > 0) ? ((discountRs / mrp) * 100) : 0.0;
    final stockVal = int.tryParse(_stockController.text) ?? 100;
    final weightVal = double.tryParse(_weightController.text) ?? 500.0;
    final selectedSellerId = (_selectedSellerId != null && _selectedSellerId!.trim().isNotEmpty)
        ? _selectedSellerId!.trim()
        : widget.sellerId;

    final skuVal = _skuController.text.trim().isNotEmpty
        ? _skuController.text.trim()
        : (_productCodeController.text.trim().isNotEmpty
            ? _productCodeController.text.trim()
            : 'EBS-ADM-SKU-${DateTime.now().millisecondsSinceEpoch}');

    final codeVal = _productCodeController.text.trim().isNotEmpty
        ? _productCodeController.text.trim()
        : skuVal;

    final dimText = _dimensionsController.text.trim().isNotEmpty
        ? _dimensionsController.text.trim()
        : '20 x 10 x 10 cm';

    final newProduct = Product(
      sellerId: selectedSellerId,
      sku: skuVal,
      productCode: codeVal,
      hsnCode: _hsnCodeController.text.trim().isNotEmpty ? _hsnCodeController.text.trim() : '3808',
      title: _titleController.text.trim(),
      technicalName: _technicalNameController.text.trim(),
      vendor: _vendorController.text.trim().isEmpty ? 'EBS Agro Sciences' : _vendorController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : _titleController.text.trim(),
      images: const [],
      technicalContent: _technicalContentController.text.trim(),
      features: _featuresController.text.trim(),
      benefits: _benefitsController.text.trim(),
      modeOfAction: _modeOfActionController.text.trim(),
      suitableCrop: _suitableCropController.text.trim(),
      targetPests: _targetPestsController.text.trim(),
      targetDiseases: _targetDiseasesController.text.trim(),
      dosage: _dosageController.text.trim(),
      applicationMethod: _applicationMethodController.text.trim(),
      categoryId: (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty)
          ? _selectedCategoryId!
          : '6ab4f6f619ec643fd9bf3621',
      category: _selectedCategory,
      collections: _collectionsController.text.trim(),
      subCollections: _subCollectionsController.text.trim(),
      isAvailable: _isAvailable,
      isFeatured: false,
      variant: _variantController.text.trim().isNotEmpty ? _variantController.text.trim() : '500 ml Bottle',
      packSize: _packSizeController.text.trim().isNotEmpty ? _packSizeController.text.trim() : '500',
      displayRate: rate,
      printedMrp: mrp,
      costPrice: cost,
      discountRs: discountRs,
      unit: _selectedUnit,
      gst: _selectedGst,
      discountPercentage: discountPct,
      shippedBy: _shippedByController.text.trim().isNotEmpty ? _shippedByController.text.trim() : 'EBS Direct',
      swg: _swgController.text.trim(),
      stock: stockVal,
      ratings: 0.0,
      refundPolicy: _refundPolicyController.text.trim(),
      productWeight: weightVal,
      productWeightUnit: _selectedWeightUnit,
      dimensions: dimText,
      productDimensions: ProductDimensions.fromJson(dimText),
      variants: [
        ProductVariant(
          label: _variantController.text.trim().isNotEmpty ? _variantController.text.trim() : '500 ml Bottle',
          unit: _selectedUnit,
          packSize: int.tryParse(_packSizeController.text.trim()) ?? 500,
          packSizeUnit: _selectedUnit,
          packQuantity: 1,
          packUnit: 'bottle',
          shippedBy: _shippedByController.text.trim().isNotEmpty ? _shippedByController.text.trim() : 'EBS Direct',
          displayRate: rate,
          printedMrp: mrp,
          costPrice: cost,
          discountRs: discountRs,
          gstPercentage: _selectedGst,
          discountPercentage: discountPct,
          stock: stockVal,
          pricePerBaseUnit: weightVal > 0 ? (rate / weightVal) : 0.0,
          isDefault: true,
        ),
      ],
    );

    widget.onProductAdded(newProduct);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 760),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF059669), size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Agricultural Product',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Provide complete 38-field agricultural and commerce specifications',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: borderColor),
                    bottom: BorderSide(color: borderColor),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF059669),
                  unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF059669),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: '1. Basic Specs'),
                    Tab(text: '2. Agronomy & Crop'),
                    Tab(text: '3. Pricing & Tax'),
                    Tab(text: '4. Inventory & Dispatch'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Basic Specs
                    _buildTab1(isDark, borderColor),

                    // Tab 2: Agronomy & Crop
                    _buildTab2(isDark, borderColor),

                    // Tab 3: Pricing & Tax
                    _buildTab3(isDark, borderColor),

                    // Tab 4: Inventory & Dispatch
                    _buildTab4(isDark, borderColor),
                  ],
                ),
              ),

              // Actions Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All entries strictly validated against Agri-Commerce schema',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _handleSave,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            'Save & Publish Product',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }

  // --- TAB 1: BASIC SPECS ---
  Widget _buildTab1(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFormField('Product Title *', _titleController, 'e.g. AgriShield Pro 20% EC', isDark, isRequired: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Technical Name *', _technicalNameController, 'e.g. Chlorpyrifos 20% EC', isDark, isRequired: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Product Code (SKU)', _productCodeController, 'e.g. PRD-AGRI-005', isDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('HSN Code *', _hsnCodeController, 'e.g. 38089190', isDark, isRequired: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<SellerBloc, AdminUserState>(
                  builder: (context, sellerState) {
                    final sellers = sellerState.users;
                    final isLoading = sellerState.status == AdminUserStatus.loading;

                    final sellerIds = sellers.map((s) => s.id).toSet();
                    String? activeValue = _selectedSellerId;
                    if (activeValue != null && !sellerIds.contains(activeValue) && sellers.isNotEmpty) {
                      activeValue = sellers.first.id;
                      _selectedSellerId = activeValue;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seller (Store Owner) *',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: activeValue,
                              isExpanded: true,
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              hint: Text(
                                isLoading ? 'Loading sellers...' : 'Select Seller',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              ),
                              items: sellers.isEmpty
                                  ? [
                                      DropdownMenuItem(
                                        value: widget.sellerId,
                                        child: Text(
                                          'Default Seller (${widget.sellerId})',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ]
                                  : sellers.map((seller) {
                                      final title = seller.displayName;
                                      final phone = seller.phoneNumber.isNotEmpty ? ' (${seller.phoneNumber})' : '';
                                      return DropdownMenuItem<String>(
                                        value: seller.id,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.storefront_rounded,
                                              size: 16,
                                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '$title$phone',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedSellerId = val;
                                    final match = sellers.firstWhere((s) => s.id == val, orElse: () => sellers.first);
                                    if (_vendorController.text.trim().isEmpty || _vendorController.text.trim() == 'Registered Seller') {
                                      _vendorController.text = match.displayName;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Vendor / Manufacturer', _vendorController, 'e.g. Bharat Agro Chemicals', isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, catState) {
                    final categories = catState.allCategories;
                    final categoryNames = categories.isNotEmpty
                        ? categories.map((c) => c.name).toSet().toList()
                        : const ['Bio Organic Nutrients', 'Insecticides', 'Herbicides', 'Fungicides', 'Seeds', 'Fertilizers', 'PGR & Bio-Nutrients'];

                    final effectiveValue = categoryNames.contains(_selectedCategory)
                        ? _selectedCategory
                        : categoryNames.first;

                    return _buildDropdown(
                      label: 'Category',
                      value: effectiveValue,
                      items: categoryNames,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedCategory = val;
                          final match = categories.where((c) => c.name == val).firstOrNull;
                          if (match != null) {
                            _selectedCategoryId = match.id;
                          }
                        });
                      },
                      isDark: isDark,
                      borderColor: borderColor,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Collections', _collectionsController, 'e.g. Kharif Essentials', isDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Sub Collections', _subCollectionsController, 'e.g. Stem Borer Control', isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFormField('Product Description', _descriptionController, 'Comprehensive product overview...', isDark, maxLines: 3),
        ],
      ),
    );
  }

  // --- TAB 2: AGRONOMY & CROP ---
  Widget _buildTab2(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFormField('Technical Content', _technicalContentController, 'e.g. Chlorpyrifos 20% w/w a.i.', isDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Mode of Action', _modeOfActionController, 'e.g. Systemic & Contact AChE Inhibitor', isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Suitable Crops', _suitableCropController, 'e.g. Paddy, Cotton, Chilli, Tomato', isDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Recommended Dosage', _dosageController, 'e.g. 2.5 ml / Litre water', isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Target Pests', _targetPestsController, 'e.g. Stem Borer, Whitefly, Aphids', isDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Target Diseases', _targetDiseasesController, 'e.g. Sheath Blight, Blast', isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFormField('Application Method', _applicationMethodController, 'e.g. Foliar Spray, Drenching, Seed Treatment', isDark),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Key Features', _featuresController, 'e.g. Fast rainfastness, broad coverage...', isDark, maxLines: 2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Farmer Benefits', _benefitsController, 'e.g. Enhances crop stand and yield by 15%...', isDark, maxLines: 2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 3: PRICING & TAX ---
  Widget _buildTab3(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFormField('Display Rate (Selling Price) *', _displayRateController, 'e.g. 540', isDark, isNumber: true, isRequired: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Printed MRP *', _printedMrpController, 'e.g. 680', isDark, isNumber: true, isRequired: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Cost Price (To Seller)', _costPriceController, 'e.g. 420', isDark, isNumber: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'GST Slab',
                  value: '${_selectedGst.toInt()}%',
                  items: const ['0%', '5%', '12%', '18%', '28%'],
                  onChanged: (val) {
                    setState(() {
                      _selectedGst = double.parse(val!.replaceAll('%', ''));
                    });
                  },
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Variant', _variantController, 'e.g. Liquid EC / Powder / Granules', isDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Pack Size', _packSizeController, 'e.g. 250, 500, 1', isDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Unit',
                  value: _selectedUnit,
                  items: const ['Litre', 'ml', 'kg', 'gm', 'Pouch', 'Bottle', 'Bag'],
                  onChanged: (val) => setState(() => _selectedUnit = val!),
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

  // --- TAB 4: INVENTORY & DISPATCH ---
  Widget _buildTab4(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFormField('Current Stock (Units) *', _stockController, 'e.g. 500', isDark, isNumber: true, isRequired: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Shipped By Partner', _shippedByController, 'e.g. AgriBegri Express / Seller', isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Standard Wire Gauge / SWG', _swgController, 'e.g. Volumetric L-1.2', isDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Shipping Weight', _weightController, 'e.g. 1.15', isDark, isNumber: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Weight Unit',
                  value: _selectedWeightUnit,
                  items: const ['kg', 'gm'],
                  onChanged: (val) => setState(() => _selectedWeightUnit = val!),
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Dimensions (LxWxH)', _dimensionsController, 'e.g. 10 x 10 x 24 cm', isDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField('Refund Policy', _refundPolicyController, 'e.g. 7-day replacement if sealed', isDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Is Available for Purchase',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Toggle whether dealers can view and order this SKU',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  activeThumbColor: const Color(0xFF059669),
                  value: _isAvailable,
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
              ),
              /*
              // Is Featured Product switch temporarily commented out
              const SizedBox(width: 24),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Is Featured Product',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Promote this product on homepage and top search tiers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  activeThumbColor: const Color(0xFFF59E0B),
                  value: _isFeatured,
                  onChanged: (val) => setState(() => _isFeatured = val),
                ),
              ),
              */
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hint,
    bool isDark, {
    bool isRequired = false,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: isRequired
              ? (val) => (val == null || val.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF161E2E) : Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              items: items.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
