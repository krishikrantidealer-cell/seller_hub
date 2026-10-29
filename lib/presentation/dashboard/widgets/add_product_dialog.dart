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
import '../../../logic/collection/collection_bloc.dart';
import '../../../logic/collection/collection_event.dart';
import '../../../logic/collection/collection_state.dart';

class AddProductDialog extends StatefulWidget {
  final Function(Product) onProductAdded;
  final String? sellerId;

  const AddProductDialog({
    super.key,
    required this.onProductAdded,
    this.sellerId,
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

  // 3. Classification & Collections (Dropdowns)
  String _selectedCategory = 'Bio Organic Nutrients';
  String? _selectedCategoryId = '6ab4f6f619ec643fd9bf3621';
  String? _selectedCollectionName;
  String? _selectedSubCollectionName;

  // 4. Multi-Variants Manager
  final List<ProductVariant> _variants = [];
  int _activeVariantIndex = 0;

  final _variantLabelController = TextEditingController();
  final _variantPackSizeController = TextEditingController();
  final _variantPackQuantityController = TextEditingController();
  final _variantDisplayRateController = TextEditingController();
  final _variantPrintedMrpController = TextEditingController();
  final _variantCostPriceController = TextEditingController();
  final _variantStockController = TextEditingController();
  final _variantShippedByController = TextEditingController();
  String _selectedVariantUnit = 'ml';
  String _selectedPackUnit = 'bottle';
  double _selectedVariantGst = 5.0;

  // 5. Inventory & Shipping Controllers
  final _swgController = TextEditingController(text: 'Standard');
  final _weightController = TextEditingController(text: '500');
  String _selectedWeightUnit = 'g';
  final _dimensionsLengthController = TextEditingController(text: '20');
  final _dimensionsWidthController = TextEditingController(text: '10');
  final _dimensionsHeightController = TextEditingController(text: '10');
  final String _selectedDimensionUnit = 'cm';
  final _refundPolicyController = TextEditingController(text: '7 Days Returnable if unopened');
  bool _isAvailable = false;
  String? _selectedSellerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // User requirement: no seller should be selected at first
    _selectedSellerId = widget.sellerId;

    // Start with 1 default variant
    _variants.add(
      const ProductVariant(
        id: 'var_default_1',
        displayOrder: 1,
        isDefault: true,
        label: '500 ml Bottle',
        unit: 'ml',
        packSize: 500,
        packSizeUnit: 'ml',
        packQuantity: 1,
        packUnit: 'bottle',
        shippedBy: 'EBS Direct',
        displayRate: 450.0,
        printedMrp: 500.0,
        costPrice: 250.0,
        discountRs: 50.0,
        gstPercentage: 5.0,
        discountPercentage: 10.0,
        stock: 100,
        pricePerBaseUnit: 0.9,
      ),
    );
    _populateVariantControllers(_variants[0]);

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
        final collectionBloc = context.read<CollectionBloc>();
        if (collectionBloc.state.collections.isEmpty) {
          collectionBloc.add(const FetchCollections());
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
    _swgController.dispose();
    _weightController.dispose();
    _dimensionsLengthController.dispose();
    _dimensionsWidthController.dispose();
    _dimensionsHeightController.dispose();
    _refundPolicyController.dispose();
    _variantLabelController.dispose();
    _variantPackSizeController.dispose();
    _variantPackQuantityController.dispose();
    _variantDisplayRateController.dispose();
    _variantPrintedMrpController.dispose();
    _variantCostPriceController.dispose();
    _variantStockController.dispose();
    _variantShippedByController.dispose();
    super.dispose();
  }

  void _populateVariantControllers(ProductVariant v) {
    _variantLabelController.text = v.label;
    _variantPackSizeController.text = v.packSize.toString();
    _variantPackQuantityController.text = v.packQuantity.toString();
    _variantDisplayRateController.text = v.displayRate.toStringAsFixed(0);
    _variantPrintedMrpController.text = v.printedMrp.toStringAsFixed(0);
    _variantCostPriceController.text = v.costPrice.toStringAsFixed(0);
    _variantStockController.text = v.stock.toString();
    _variantShippedByController.text = v.shippedBy.isNotEmpty ? v.shippedBy : 'EBS Direct';
    _selectedVariantUnit = v.unit.isNotEmpty ? v.unit : 'ml';
    _selectedPackUnit = v.packUnit.isNotEmpty ? v.packUnit : 'bottle';
    _selectedVariantGst = v.gstPercentage > 0 ? v.gstPercentage : 5.0;
  }

  void _syncCurrentVariantFromControllers() {
    if (_variants.isEmpty || _activeVariantIndex >= _variants.length) return;
    final cur = _variants[_activeVariantIndex];

    final disp = double.tryParse(_variantDisplayRateController.text.trim()) ?? cur.displayRate;
    final mrp = double.tryParse(_variantPrintedMrpController.text.trim()) ?? cur.printedMrp;
    final cp = double.tryParse(_variantCostPriceController.text.trim()) ?? cur.costPrice;
    final st = int.tryParse(_variantStockController.text.trim()) ?? cur.stock;
    final ps = int.tryParse(_variantPackSizeController.text.trim()) ?? cur.packSize;
    final pq = int.tryParse(_variantPackQuantityController.text.trim()) ?? cur.packQuantity;
    final disc = (mrp > disp) ? (mrp - disp) : 0.0;
    final discPct = (mrp > 0 && disc > 0) ? ((disc / mrp) * 100) : 0.0;

    _variants[_activeVariantIndex] = cur.copyWith(
      label: _variantLabelController.text.trim().isNotEmpty
          ? _variantLabelController.text.trim()
          : cur.label,
      packSize: ps,
      unit: _selectedVariantUnit,
      packSizeUnit: _selectedVariantUnit,
      packQuantity: pq,
      packUnit: _selectedPackUnit,
      shippedBy: _variantShippedByController.text.trim().isNotEmpty
          ? _variantShippedByController.text.trim()
          : 'EBS Direct',
      displayRate: disp,
      printedMrp: mrp,
      costPrice: cp,
      discountRs: disc,
      discountPercentage: discPct,
      gstPercentage: _selectedVariantGst,
      stock: st,
    );
  }

  void _selectVariant(int index) {
    if (index < 0 || index >= _variants.length) return;
    _syncCurrentVariantFromControllers();
    setState(() {
      _activeVariantIndex = index;
      _populateVariantControllers(_variants[index]);
    });
  }

  void _addNewVariant() {
    _syncCurrentVariantFromControllers();
    setState(() {
      final newIndex = _variants.length + 1;
      final newVariant = ProductVariant(
        id: 'var_${DateTime.now().millisecondsSinceEpoch}_$newIndex',
        displayOrder: newIndex,
        isDefault: _variants.isEmpty,
        label: 'Pack $newIndex (1 L Can)',
        unit: 'ml',
        packSize: 1000,
        packSizeUnit: 'ml',
        packQuantity: 1,
        packUnit: 'can',
        shippedBy: 'EBS Direct',
        displayRate: 850.0,
        printedMrp: 1000.0,
        costPrice: 480.0,
        discountRs: 150.0,
        gstPercentage: 5.0,
        discountPercentage: 15.0,
        stock: 50,
      );
      _variants.add(newVariant);
      _activeVariantIndex = _variants.length - 1;
      _populateVariantControllers(newVariant);
    });
  }

  void _duplicateVariant(int index) {
    if (index < 0 || index >= _variants.length) return;
    _syncCurrentVariantFromControllers();
    setState(() {
      final source = _variants[index];
      final newIndex = _variants.length + 1;
      final duplicate = source.copyWith(
        id: 'var_${DateTime.now().millisecondsSinceEpoch}_$newIndex',
        displayOrder: newIndex,
        isDefault: false,
        label: '${source.label} (Copy)',
      );
      _variants.add(duplicate);
      _activeVariantIndex = _variants.length - 1;
      _populateVariantControllers(duplicate);
    });
  }

  void _deleteVariant(int index) {
    if (_variants.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one variant is required.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    setState(() {
      final wasDefault = _variants[index].isDefault;
      _variants.removeAt(index);
      if (wasDefault && _variants.isNotEmpty) {
        _variants[0] = _variants[0].copyWith(isDefault: true);
      }
      final nextIdx = index >= _variants.length ? _variants.length - 1 : index;
      _activeVariantIndex = nextIdx;
      _populateVariantControllers(_variants[nextIdx]);
    });
  }

  void _setDefaultVariant(int index) {
    if (index < 0 || index >= _variants.length) return;
    _syncCurrentVariantFromControllers();
    setState(() {
      for (int i = 0; i < _variants.length; i++) {
        _variants[i] = _variants[i].copyWith(isDefault: i == index);
      }
    });
  }

  void _handleSave() {
    _syncCurrentVariantFromControllers();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields in the product form.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_selectedSellerId == null || _selectedSellerId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Please select a Seller before saving.'),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _tabController.animateTo(0);
      return;
    }

    final defaultVariant = _variants.firstWhere(
      (v) => v.isDefault,
      orElse: () => _variants.first,
    );

    final weightVal = double.tryParse(_weightController.text.trim()) ?? 500.0;
    final lenVal = double.tryParse(_dimensionsLengthController.text.trim()) ?? 20.0;
    final widthVal = double.tryParse(_dimensionsWidthController.text.trim()) ?? 10.0;
    final heightVal = double.tryParse(_dimensionsHeightController.text.trim()) ?? 10.0;

    final dimensionsObj = ProductDimensions(
      length: lenVal,
      width: widthVal,
      height: heightVal,
      unit: _selectedDimensionUnit,
    );

    final skuVal = _skuController.text.trim().isNotEmpty
        ? _skuController.text.trim()
        : (_productCodeController.text.trim().isNotEmpty
            ? _productCodeController.text.trim()
            : 'EBS-ADM-SKU-${DateTime.now().millisecondsSinceEpoch}');

    final codeVal = _productCodeController.text.trim().isNotEmpty
        ? _productCodeController.text.trim()
        : skuVal;

    final sellerState = context.read<SellerBloc>().state;
    final matchingSeller = sellerState.users.where((s) => s.id == _selectedSellerId).firstOrNull;
    final resolvedSellerName = matchingSeller?.displayName ?? '';

    final newProduct = Product(
      sellerId: _selectedSellerId!.trim(),
      sellerName: resolvedSellerName,
      vendor: resolvedSellerName,
      sku: skuVal,
      productCode: codeVal,
      hsnCode: _hsnCodeController.text.trim().isNotEmpty ? _hsnCodeController.text.trim() : '3808',
      title: _titleController.text.trim(),
      technicalName: _technicalNameController.text.trim(),
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
      collections: _selectedCollectionName ?? '',
      subCollections: _selectedSubCollectionName ?? '',
      isAvailable: _isAvailable,
      isFeatured: false,
      variant: defaultVariant.label,
      packSize: defaultVariant.packSize.toString(),
      displayRate: defaultVariant.displayRate,
      printedMrp: defaultVariant.printedMrp,
      costPrice: defaultVariant.costPrice,
      discountRs: defaultVariant.discountRs,
      unit: defaultVariant.unit,
      gst: defaultVariant.gstPercentage,
      discountPercentage: defaultVariant.discountPercentage,
      shippedBy: defaultVariant.shippedBy,
      swg: _swgController.text.trim(),
      stock: defaultVariant.stock,
      ratings: 0.0,
      refundPolicy: _refundPolicyController.text.trim(),
      productWeight: weightVal,
      productWeightUnit: _selectedWeightUnit,
      dimensions: '${lenVal.toInt()} x ${widthVal.toInt()} x ${heightVal.toInt()} $_selectedDimensionUnit',
      productDimensions: dimensionsObj,
      variants: List.from(_variants),
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
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 800),
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
                            'Select seller, configure collection dropdowns, and manage multiple variants',
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
                  tabs: [
                    const Tab(text: '1. Basic Specs'),
                    Tab(text: '2. Variants (${_variants.length})'),
                    const Tab(text: '3. Agronomy & Crop'),
                    const Tab(text: '4. Inventory & Dispatch'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTab1(isDark, borderColor),
                    _buildTab2Variants(isDark, borderColor),
                    _buildTab3(isDark, borderColor),
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
                      'Validated against multi-variant Agri-Commerce schema',
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
          // Seller Dropdown (NO VENDOR FIELD)
          BlocBuilder<SellerBloc, AdminUserState>(
            builder: (context, sellerState) {
              final sellers = sellerState.users;
              final isLoading = sellerState.status == AdminUserStatus.loading;

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
                      border: Border.all(
                        color: _selectedSellerId == null
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                            : borderColor,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSellerId,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        hint: Text(
                          isLoading ? 'Loading sellers...' : '-- Select Seller (Required) --',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                        items: sellers.map((seller) {
                          final title = seller.displayName;
                          final phone = seller.phoneNumber.isNotEmpty ? ' (${seller.phoneNumber})' : '';
                          return DropdownMenuItem<String>(
                            value: seller.id,
                            child: Row(
                              children: [
                                const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF059669)),
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
                          setState(() {
                            _selectedSellerId = val;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

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
                child: _buildFormField('HSN Code *', _hsnCodeController, 'e.g. 3808', isDark, isRequired: true),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Taxonomy Dropdowns (Category, Collection, Sub Collection)
          Row(
            children: [
              // Category Dropdown
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

              // Collection Dropdown
              Expanded(
                child: BlocBuilder<CollectionBloc, CollectionState>(
                  builder: (context, colState) {
                    final collections = colState.collections;
                    final colNames = collections.isNotEmpty
                        ? collections.map((c) => c.name).toSet().toList()
                        : const ['Crop Protection', 'Plant Nutrition', 'Organic Bio Products', 'Seeds & Seed Care'];

                    if (_selectedCollectionName == null && colNames.isNotEmpty) {
                      _selectedCollectionName = colNames.first;
                    }

                    final effectiveCol = colNames.contains(_selectedCollectionName)
                        ? _selectedCollectionName!
                        : colNames.first;

                    return _buildDropdown(
                      label: 'Collection',
                      value: effectiveCol,
                      items: colNames,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedCollectionName = val;
                          _selectedSubCollectionName = null;
                        });
                      },
                      isDark: isDark,
                      borderColor: borderColor,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Sub Collection Dropdown
              Expanded(
                child: BlocBuilder<CollectionBloc, CollectionState>(
                  builder: (context, colState) {
                    final collections = colState.collections;
                    final selectedCol = collections.where((c) => c.name == _selectedCollectionName).firstOrNull;
                    List<String> subNames = [];
                    if (selectedCol != null && selectedCol.subCollections.isNotEmpty) {
                      subNames = selectedCol.subCollections.map((s) => s.name).toSet().toList();
                    } else {
                      subNames = const ['Pest Management', 'Fungus Control', 'Foliar Nutrition', 'General / Standard'];
                    }

                    if (_selectedSubCollectionName == null && subNames.isNotEmpty) {
                      _selectedSubCollectionName = subNames.first;
                    }

                    final effectiveSub = subNames.contains(_selectedSubCollectionName)
                        ? _selectedSubCollectionName!
                        : subNames.first;

                    return _buildDropdown(
                      label: 'Sub Collection',
                      value: effectiveSub,
                      items: subNames,
                      onChanged: (val) {
                        setState(() {
                          _selectedSubCollectionName = val;
                        });
                      },
                      isDark: isDark,
                      borderColor: borderColor,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFormField('Product Description', _descriptionController, 'Comprehensive product overview...', isDark, maxLines: 3),
        ],
      ),
    );
  }

  // --- TAB 2: MULTI-VARIANTS & PRICING ---
  Widget _buildTab2Variants(bool isDark, Color borderColor) {
    _syncCurrentVariantFromControllers();
    final activeVar = (_activeVariantIndex < _variants.length) ? _variants[_activeVariantIndex] : null;

    final mrp = double.tryParse(_variantPrintedMrpController.text.trim()) ?? 500.0;
    final rate = double.tryParse(_variantDisplayRateController.text.trim()) ?? 450.0;
    final discountRs = (mrp > rate) ? (mrp - rate) : 0.0;
    final discountPct = (mrp > 0 && discountRs > 0) ? ((discountRs / mrp) * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Variants (${_variants.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addNewVariant,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  '+ Add Variant',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Variant Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _variants.asMap().entries.map((entry) {
              final idx = entry.key;
              final v = entry.value;
              final isSelected = idx == _activeVariantIndex;
              return ChoiceChip(
                label: Text('${v.label} ${v.isDefault ? "(Default)" : ""}'),
                selected: isSelected,
                selectedColor: const Color(0xFF059669),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                onSelected: (_) => _selectVariant(idx),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          if (activeVar != null) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFormField('Variant Label *', _variantLabelController, 'e.g. 500 ml Bottle', isDark, isRequired: true),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildFormField('Pack Size *', _variantPackSizeController, 'e.g. 500', isDark, isNumber: true, isRequired: true),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDropdown(
                    label: 'Unit',
                    value: _selectedVariantUnit,
                    items: const ['ml', 'Litre', 'g', 'kg', 'mg', 'gm', 'pouch', 'tablet'],
                    onChanged: (val) => setState(() => _selectedVariantUnit = val!),
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
                  child: _buildFormField('Pack Quantity', _variantPackQuantityController, 'e.g. 1', isDark, isNumber: true),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDropdown(
                    label: 'Pack Unit',
                    value: _selectedPackUnit,
                    items: const ['bottle', 'can', 'pouch', 'bag', 'drum', 'box', 'pack', 'piece'],
                    onChanged: (val) => setState(() => _selectedPackUnit = val!),
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildFormField('Shipped By', _variantShippedByController, 'e.g. EBS Direct', isDark),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildFormField('Display Rate (₹) *', _variantDisplayRateController, 'e.g. 450', isDark, isNumber: true, isRequired: true, onChanged: (_) => setState(() {})),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildFormField('Printed MRP (₹) *', _variantPrintedMrpController, 'e.g. 500', isDark, isNumber: true, isRequired: true, onChanged: (_) => setState(() {})),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildFormField('Cost Price (₹)', _variantCostPriceController, 'e.g. 250', isDark, isNumber: true),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDropdown(
                    label: 'GST Slab',
                    value: '${_selectedVariantGst.toInt()}%',
                    items: const ['0%', '5%', '12%', '18%', '28%'],
                    onChanged: (val) => setState(() => _selectedVariantGst = double.parse(val!.replaceAll('%', ''))),
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
                  child: _buildFormField('Stock (Units) *', _variantStockController, 'e.g. 100', isDark, isNumber: true, isRequired: true),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.only(top: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: discountRs > 0 ? const Color(0xFF059669).withValues(alpha: 0.1) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(
                        discountRs > 0
                            ? 'Discount: ₹${discountRs.toStringAsFixed(0)} (${discountPct.toStringAsFixed(1)}% off)'
                            : 'No Discount (MRP = Rate)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: discountRs > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!activeVar.isDefault)
                  OutlinedButton.icon(
                    onPressed: () => _setDefaultVariant(_activeVariantIndex),
                    icon: const Icon(Icons.star_border_rounded, size: 16),
                    label: const Text('Set as Default'),
                  )
                else
                  const Text('⭐ Primary Default Variant', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12)),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _duplicateVariant(_activeVariantIndex),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Duplicate'),
                    ),
                    const SizedBox(width: 8),
                    if (_variants.length > 1)
                      OutlinedButton.icon(
                        onPressed: () => _deleteVariant(_activeVariantIndex),
                        icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                        label: const Text('Remove', style: TextStyle(color: Color(0xFFEF4444))),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 3: AGRONOMY & CROP ---
  Widget _buildTab3(bool isDark, Color borderColor) {
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

  // --- TAB 4: INVENTORY & DISPATCH ---
  Widget _buildTab4(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFormField('Shipping Weight', _weightController, 'e.g. 500', isDark, isNumber: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Weight Unit',
                  value: _selectedWeightUnit,
                  items: const ['g', 'kg', 'mg', 'gm'],
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
                child: _buildFormField('Length (cm)', _dimensionsLengthController, 'e.g. 20', isDark, isNumber: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField('Width (cm)', _dimensionsWidthController, 'e.g. 10', isDark, isNumber: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField('Height (cm)', _dimensionsHeightController, 'e.g. 10', isDark, isNumber: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFormField('Refund Policy', _refundPolicyController, 'e.g. 7-day replacement if sealed', isDark),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Is Available for Purchase',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            value: _isAvailable,
            onChanged: (val) => setState(() => _isAvailable = val),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE DROPDOWN ---
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
    required Color borderColor,
  }) {
    final effectiveItems = items.toSet().toList();
    final effectiveValue = effectiveItems.contains(value)
        ? value
        : (effectiveItems.isNotEmpty ? effectiveItems.first : value);

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
              value: effectiveValue,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: effectiveItems.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
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

  // --- REUSABLE FORM FIELD ---
  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hint,
    bool isDark, {
    bool isRequired = false,
    bool isNumber = false,
    int maxLines = 1,
    Function(String)? onChanged,
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
          onChanged: onChanged,
          validator: isRequired
              ? (val) {
                  if (val == null || val.trim().isEmpty) {
                    return '$label is required';
                  }
                  return null;
                }
              : null,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
