import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/admin_user.dart';
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

class AddProductView extends StatefulWidget {
  final VoidCallback onBack;
  final Function(Product newProduct) onProductAdded;
  final String? initialSellerId;

  const AddProductView({
    super.key,
    required this.onBack,
    required this.onProductAdded,
    this.initialSellerId,
  });

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  int _selectedTabIndex = 0;

  // Seller & Taxonomy - User requirement: nothing in basic info should be pre-selected
  String? _selectedSellerId;
  String? _selectedCategory;
  String? _selectedCategoryId;
  String? _selectedCollectionName;
  String? _selectedSubCollectionName;

  // General Specifications
  final _titleController = TextEditingController();
  final _technicalNameController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _skuController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _featuresController = TextEditingController();
  final _benefitsController = TextEditingController();

  // Agronomy
  final _technicalContentController = TextEditingController();
  final _modeOfActionController = TextEditingController();
  final _suitableCropController = TextEditingController();
  final _targetPestsController = TextEditingController();
  final _targetDiseasesController = TextEditingController();
  final _dosageController = TextEditingController();
  final _applicationMethodController = TextEditingController();

  // Shipping & Logistics
  final _weightController = TextEditingController();
  String _selectedWeightUnit = 'g';
  final _dimensionsLengthController = TextEditingController();
  final _dimensionsWidthController = TextEditingController();
  final _dimensionsHeightController = TextEditingController();
  String _selectedDimensionUnit = 'cm';
  final _refundPolicyController = TextEditingController();
  bool _isAvailable = true;

  // Multi-Variants State
  final List<ProductVariant> _variants = [];
  int _activeVariantIndex = 0;

  // Active Variant Form Controllers
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _selectedTabIndex != _tabController.index) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    // User requirement: no seller should be selected at first when opening from product screen
    _selectedSellerId = widget.initialSellerId;

    // Initialize with 1 clean empty variant (no dummy data prefilled)
    _variants.add(
      const ProductVariant(
        id: 'var_default_1',
        displayOrder: 1,
        isDefault: true,
        label: 'Pack 1',
        unit: 'ml',
        packSize: 0,
        packSizeUnit: 'ml',
        packQuantity: 1,
        packUnit: 'bottle',
        shippedBy: '',
        displayRate: 0.0,
        printedMrp: 0.0,
        costPrice: 0.0,
        discountRs: 0.0,
        gstPercentage: 5.0,
        discountPercentage: 0.0,
        stock: 0,
        pricePerBaseUnit: 0.0,
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
    _titleController.dispose();
    _technicalNameController.dispose();
    _productCodeController.dispose();
    _skuController.dispose();
    _hsnCodeController.dispose();
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
    _variantPackSizeController.text = v.packSize > 0 ? v.packSize.toString() : '';
    _variantPackQuantityController.text = v.packQuantity > 0 ? v.packQuantity.toString() : '';
    _variantDisplayRateController.text = v.displayRate > 0 ? v.displayRate.toStringAsFixed(0) : '';
    _variantPrintedMrpController.text = v.printedMrp > 0 ? v.printedMrp.toStringAsFixed(0) : '';
    _variantCostPriceController.text = v.costPrice > 0 ? v.costPrice.toStringAsFixed(0) : '';
    _variantStockController.text = v.stock > 0 ? v.stock.toString() : '';
    _variantShippedByController.text = v.shippedBy;
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
        label: 'Pack $newIndex',
        unit: 'ml',
        packSize: 0,
        packSizeUnit: 'ml',
        packQuantity: 1,
        packUnit: 'bottle',
        shippedBy: '',
        displayRate: 0.0,
        printedMrp: 0.0,
        costPrice: 0.0,
        discountRs: 0.0,
        gstPercentage: 5.0,
        discountPercentage: 0.0,
        stock: 0,
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
          content: Text('At least one product variant is required.'),
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

    // 1. Validate Form Fields
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields in the form.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // 2. Validate Seller Selection (Requirement: no seller selected at first, must select one)
    if (_selectedSellerId == null || _selectedSellerId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Please select a Seller from the dropdown before saving.'),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _selectedTabIndex = 0;
        _tabController.index = 0;
      });
      return;
    }

    // 3. Validate Category Selection
    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Please select a Category from the dropdown before saving.'),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _selectedTabIndex = 0;
        _tabController.index = 0;
      });
      return;
    }

    // 4. Validate Variants
    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one product variant must be added.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      setState(() {
        _selectedTabIndex = 1;
        _tabController.index = 1;
      });
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

    // Resolve seller name
    final sellerState = context.read<SellerBloc>().state;
    final matchingSeller = sellerState.users.where((s) => s.id == _selectedSellerId).firstOrNull;
    final resolvedSellerName = matchingSeller?.displayName ?? '';

    final newProduct = Product(
      sellerId: _selectedSellerId!.trim(),
      sellerName: resolvedSellerName,
      vendor: resolvedSellerName, // backward compat
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
      category: _selectedCategory ?? '',
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return Material(
      color: cardBgColor,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            _buildHeader(isDark, borderColor, cardBgColor),

            // Tab Navigation Bar
            _buildTabNavigationBar(isDark, borderColor, cardBgColor),

            // Active Tab Content
            Form(
              key: _formKey,
              child: _buildActiveTabContent(isDark, borderColor, cardBgColor),
            ),

            // Sticky Bottom Action Bar
            _buildBottomActionBar(isDark, borderColor, cardBgColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigationBar(bool isDark, Color borderColor, Color cardBgColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFF059669),
        unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        indicatorColor: const Color(0xFF059669),
        indicatorWeight: 2.5,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        tabs: [
          const Tab(
            height: 38,
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 15),
                SizedBox(width: 6),
                Text('1. Basic Info & Taxonomy'),
              ],
            ),
          ),
          Tab(
            height: 38,
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.layers_rounded, size: 15),
                const SizedBox(width: 6),
                Text('2. Multi-Variants & Pricing (${_variants.length})'),
              ],
            ),
          ),
          const Tab(
            height: 38,
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.agriculture_rounded, size: 15),
                SizedBox(width: 6),
                Text('3. Agronomy & Crop Specs'),
              ],
            ),
          ),
          const Tab(
            height: 38,
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_shipping_outlined, size: 15),
                SizedBox(width: 6),
                Text('4. Shipping & Logistics'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(bool isDark, Color borderColor, Color cardBgColor) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildTab1BasicInfo(isDark, borderColor, cardBgColor);
      case 1:
        return _buildTab2Variants(isDark, borderColor, cardBgColor);
      case 2:
        return _buildTab3Agronomy(isDark, borderColor, cardBgColor);
      case 3:
        return _buildTab4Shipping(isDark, borderColor, cardBgColor);
      default:
        return _buildTab1BasicInfo(isDark, borderColor, cardBgColor);
    }
  }

  // --- HEADER BAR ---
  Widget _buildHeader(bool isDark, Color borderColor, Color cardBgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardBgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(
              'Back to Products',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Add Agricultural Product',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Full Screen Editor',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
            label: Text(
              'Save & Publish Product',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM ACTION BAR ---
  Widget _buildBottomActionBar(bool isDark, Color borderColor, Color cardBgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 15,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Validated against multi-variant agri-commerce backend API schema',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          if (_selectedTabIndex > 0) ...[
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedTabIndex--;
                  _tabController.index = _selectedTabIndex;
                });
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 15),
              label: Text(
                'Previous Step',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (_selectedTabIndex < 3) ...[
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedTabIndex++;
                  _tabController.index = _selectedTabIndex;
                });
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 15),
              label: Text(
                'Next Step',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                side: const BorderSide(color: Color(0xFF059669)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          TextButton(
            onPressed: widget.onBack,
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text(
              'Save & Publish Product',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: BASIC INFO & TAXONOMY ---
  Widget _buildTab1BasicInfo(bool isDark, Color borderColor, Color cardBgColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Store & Seller Ownership + Taxonomy (CATEGORY RIGHT AT THE TOP!)
          _buildCard(
            title: 'Seller & Taxonomy Classification',
            subtitle: 'Assign seller store ownership, category, collection, and sub-collection',
            icon: Icons.storefront_rounded,
            isDark: isDark,
            borderColor: borderColor,
            cardBgColor: cardBgColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Seller (Store Owner) * and Category * side-by-side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seller Dropdown
                    Expanded(
                      child: BlocBuilder<SellerBloc, AdminUserState>(
                        builder: (context, sellerState) {
                          final sellers = sellerState.users;
                          final isLoading = sellerState.status == AdminUserStatus.loading;
                          final selectedSeller = sellers.where((s) => s.id == _selectedSellerId).firstOrNull;
                          final displayText = selectedSeller != null
                              ? '${selectedSeller.displayName}${selectedSeller.phoneNumber.isNotEmpty ? ' • ${selectedSeller.phoneNumber}' : ''}'
                              : '';

                          return _buildSearchableSelectField<AdminUser>(
                            label: 'Seller (Store Owner) *',
                            prefixIcon: Icons.store_rounded,
                            displayText: displayText,
                            placeholder: isLoading
                                ? 'Loading sellers from server...'
                                : '-- Select Seller (Required) --',
                            hasValue: _selectedSellerId != null,
                            helperText: _selectedSellerId == null
                                ? 'No seller selected initially. Please pick a seller to associate with this product.'
                                : null,
                            trailingBadge: selectedSeller != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      selectedSeller.id.length > 8
                                          ? selectedSeller.id.substring(selectedSeller.id.length - 8)
                                          : selectedSeller.id,
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                  )
                                : null,
                            isDark: isDark,
                            borderColor: borderColor,
                            onTap: () async {
                              final picked = await _showSearchablePicker<AdminUser>(
                                context: context,
                                title: 'Select Seller',
                                titleIcon: Icons.store_rounded,
                                searchHint: 'Search sellers by name, shop, or phone...',
                                items: sellers,
                                selectedItem: selectedSeller,
                                labelBuilder: (s) => s.displayName,
                                subtitleBuilder: (s) => '${s.phoneNumber.isNotEmpty ? s.phoneNumber : "No Phone"} • ID: ${s.id}',
                                leadingBuilder: (s) => const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF059669)),
                                trailingBadgeBuilder: (s) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s.id.length > 8 ? s.id.substring(s.id.length - 8) : s.id,
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                                isDark: isDark,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedSellerId = picked.id;
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Category Dropdown - PROMINENT RIGHT AT THE TOP!
                    Expanded(
                      child: BlocBuilder<CategoryBloc, CategoryState>(
                        builder: (context, catState) {
                          final categories = catState.allCategories;
                          final categoryNames = categories.isNotEmpty
                              ? categories.map((c) => c.name).toSet().toList()
                              : const [
                                  'Bio Organic Nutrients',
                                  'Insecticides',
                                  'Herbicides',
                                  'Fungicides',
                                  'Seeds',
                                  'Fertilizers',
                                  'PGR & Bio-Nutrients',
                                ];

                          final displayText = _selectedCategory ?? '';

                          return _buildSearchableSelectField<String>(
                            label: 'Category *',
                            prefixIcon: Icons.category_rounded,
                            displayText: displayText,
                            placeholder: '-- Select Category (Required) --',
                            hasValue: _selectedCategory != null,
                            helperText: _selectedCategory == null
                                ? 'No category selected initially. Please pick a category for this product.'
                                : null,
                            trailingBadge: _selectedCategoryId != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _selectedCategoryId!.length > 8
                                          ? 'ID: ${_selectedCategoryId!.substring(0, 8)}...'
                                          : 'ID: $_selectedCategoryId',
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                  )
                                : null,
                            isDark: isDark,
                            borderColor: borderColor,
                            onTap: () async {
                              final picked = await _showSearchablePicker<String>(
                                context: context,
                                title: 'Select Category',
                                titleIcon: Icons.category_rounded,
                                searchHint: 'Search categories by name, level, or keyword...',
                                items: categoryNames,
                                selectedItem: _selectedCategory,
                                labelBuilder: (cat) => cat,
                                subtitleBuilder: (cat) {
                                  final catItem = categories.where((c) => c.name == cat).firstOrNull;
                                  if (catItem != null) {
                                    return catItem.isRoot ? 'Level 0 • Root Category' : 'Level ${catItem.level} • Sub-Category';
                                  }
                                  return 'Agricultural Category';
                                },
                                leadingBuilder: (cat) {
                                  final catItem = categories.where((c) => c.name == cat).firstOrNull;
                                  return Icon(
                                    catItem?.isRoot == true ? Icons.folder_rounded : Icons.subdirectory_arrow_right_rounded,
                                    size: 16,
                                    color: catItem?.isRoot == true
                                        ? const Color(0xFF059669)
                                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  );
                                },
                                trailingBadgeBuilder: (cat) {
                                  final catItem = categories.where((c) => c.name == cat).firstOrNull;
                                  if (catItem == null) return null;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (catItem.isRoot ? const Color(0xFF059669) : const Color(0xFF3B82F6)).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      catItem.isRoot ? 'Root (L0)' : 'L${catItem.level}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: catItem.isRoot ? const Color(0xFF059669) : const Color(0xFF3B82F6),
                                      ),
                                    ),
                                  );
                                },
                                isDark: isDark,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedCategory = picked;
                                  final match = categories.where((c) => c.name == picked).firstOrNull;
                                  if (match != null) {
                                    _selectedCategoryId = match.id;
                                  }
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Row 2: Collection (Dropdown) * and Sub Collection (Dropdown) *
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Collection Dropdown
                    Expanded(
                      child: BlocBuilder<CollectionBloc, CollectionState>(
                        builder: (context, colState) {
                          final collections = colState.collections;
                          final colNames = collections.isNotEmpty
                              ? collections.map((c) => c.name).toSet().toList()
                              : const [
                                  'Crop Protection',
                                  'Plant Nutrition',
                                  'Organic Bio Products',
                                  'Seeds & Seed Care',
                                  'Kharif Essentials',
                                ];

                          final displayText = _selectedCollectionName ?? '';

                          return _buildSearchableSelectField<String>(
                            label: 'Collection (Dropdown) *',
                            prefixIcon: Icons.collections_bookmark_rounded,
                            displayText: displayText,
                            placeholder: '-- Select Collection (Optional) --',
                            hasValue: _selectedCollectionName != null,
                            isDark: isDark,
                            borderColor: borderColor,
                            onTap: () async {
                              final picked = await _showSearchablePicker<String>(
                                context: context,
                                title: 'Select Collection',
                                titleIcon: Icons.collections_bookmark_rounded,
                                searchHint: 'Search collections by name or keyword...',
                                items: colNames,
                                selectedItem: _selectedCollectionName,
                                labelBuilder: (c) => c,
                                subtitleBuilder: (c) {
                                  final match = collections.where((col) => col.name == c).firstOrNull;
                                  if (match != null && match.subCollections.isNotEmpty) {
                                    return '${match.subCollections.length} sub-collections available';
                                  }
                                  return 'Collection Group';
                                },
                                leadingBuilder: (_) => const Icon(Icons.folder_special_rounded, size: 16, color: Color(0xFF059669)),
                                isDark: isDark,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedCollectionName = picked;
                                  _selectedSubCollectionName = null;
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Sub Collection Dropdown
                    Expanded(
                      child: BlocBuilder<CollectionBloc, CollectionState>(
                        builder: (context, colState) {
                          final collections = colState.collections;
                          final selectedColItem = collections
                              .where((c) => c.name == _selectedCollectionName)
                              .firstOrNull;

                          List<String> subNames = [];
                          if (selectedColItem != null && selectedColItem.subCollections.isNotEmpty) {
                            subNames = selectedColItem.subCollections.map((s) => s.name).toSet().toList();
                          } else {
                            subNames = const [
                              'Pest Management',
                              'Fungus Control',
                              'Foliar Nutrition',
                              'General / Standard',
                            ];
                          }

                          final displayText = _selectedSubCollectionName ?? '';

                          return _buildSearchableSelectField<String>(
                            label: 'Sub Collection (Dropdown) *',
                            prefixIcon: Icons.subdirectory_arrow_right_rounded,
                            displayText: displayText,
                            placeholder: '-- Select Sub Collection (Optional) --',
                            hasValue: _selectedSubCollectionName != null,
                            isDark: isDark,
                            borderColor: borderColor,
                            onTap: () async {
                              final picked = await _showSearchablePicker<String>(
                                context: context,
                                title: 'Select Sub Collection',
                                titleIcon: Icons.subdirectory_arrow_right_rounded,
                                searchHint: 'Search sub-collections...',
                                items: subNames,
                                selectedItem: _selectedSubCollectionName,
                                labelBuilder: (s) => s,
                                subtitleBuilder: (_) => _selectedCollectionName != null ? 'Sub-group under $_selectedCollectionName' : 'Sub-category',
                                leadingBuilder: (_) => const Icon(Icons.label_outline_rounded, size: 16, color: Color(0xFF059669)),
                                isDark: isDark,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedSubCollectionName = picked;
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Section 2: Product Identifiers
          _buildCard(
            title: 'General Specifications',
            subtitle: 'Core product title, technical naming, and commercial tax codes',
            icon: Icons.label_outline_rounded,
            isDark: isDark,
            borderColor: borderColor,
            cardBgColor: cardBgColor,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildFormField(
                        'Product Title *',
                        _titleController,
                        'e.g. Beauveria Bassiana - Bio Pesticide',
                        isDark,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildFormField(
                        'Technical Name *',
                        _technicalNameController,
                        'e.g. Bio Organic Nutrient Formulation',
                        isDark,
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        'Product Code / SKU',
                        _productCodeController,
                        'e.g. EBS-ADM-SKU-001',
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        'HSN Code *',
                        _hsnCodeController,
                        'e.g. 3808',
                        isDark,
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildFormField(
                  'Product Description *',
                  _descriptionController,
                  'High grade bio solution for organic farming...',
                  isDark,
                  maxLines: 2,
                  isRequired: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: MULTI-VARIANTS & PRICING ---
  Widget _buildTab2Variants(bool isDark, Color borderColor, Color cardBgColor) {
    _syncCurrentVariantFromControllers();
    final activeVar = (_activeVariantIndex < _variants.length) ? _variants[_activeVariantIndex] : null;

    final mrp = double.tryParse(_variantPrintedMrpController.text.trim()) ?? 500.0;
    final rate = double.tryParse(_variantDisplayRateController.text.trim()) ?? 450.0;
    final discountRs = (mrp > rate) ? (mrp - rate) : 0.0;
    final discountPct = (mrp > 0 && discountRs > 0) ? ((discountRs / mrp) * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with + Add Variant button and Variant Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.style_rounded, color: Color(0xFF059669), size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Product Variants Manager',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_variants.length} ${_variants.length == 1 ? "Variant" : "Variants"}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Prominent + Add Variant Button
                    ElevatedButton.icon(
                      onPressed: _addNewVariant,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(
                        '+ Add Another Variant',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ..._variants.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final v = entry.value;
                      final isSelected = idx == _activeVariantIndex;

                      return InkWell(
                        onTap: () => _selectVariant(idx),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF059669)
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF059669) : borderColor,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                v.isDefault ? Icons.check_circle_rounded : Icons.label_outline_rounded,
                                size: 14,
                                color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                v.label.isNotEmpty ? v.label : 'Variant ${idx + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ),
                              if (v.isDefault) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF059669).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Active Variant Editing Card
          if (activeVar != null)
            _buildCard(
              title: 'Edit Variant: ${activeVar.label.isNotEmpty ? activeVar.label : "Variant ${_activeVariantIndex + 1}"}',
              subtitle: 'Configure specific pricing, pack sizes, inventory, and tax for this variant',
              icon: Icons.edit_note_rounded,
              isDark: isDark,
              borderColor: borderColor,
              cardBgColor: cardBgColor,
              child: Column(
                children: [
                  // Row 1: Label, Pack Size, Unit, Pack Quantity, Pack Unit
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildFormField(
                          'Variant Label *',
                          _variantLabelController,
                          'e.g. 500 ml Bottle / 1 L Can',
                          isDark,
                          isRequired: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildFormField(
                          'Pack Size *',
                          _variantPackSizeController,
                          'e.g. 500',
                          isDark,
                          isNumber: true,
                          isRequired: true,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Unit *',
                          value: _selectedVariantUnit,
                          items: const ['ml', 'Litre', 'g', 'kg', 'mg', 'gm', 'pouch', 'tablet'],
                          isDark: isDark,
                          borderColor: borderColor,
                          onChanged: (val) => setState(() => _selectedVariantUnit = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 2: Pack Quantity & Shipped By
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFormField(
                          'Pack Quantity',
                          _variantPackQuantityController,
                          'e.g. 1',
                          isDark,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildFormField(
                          'Shipped By Partner',
                          _variantShippedByController,
                          'e.g. EBS Direct',
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 3: Commercial Pricing (Display Rate, MRP, Cost Price, GST)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFormField(
                          'Display Rate (Selling Price ₹) *',
                          _variantDisplayRateController,
                          'e.g. 450',
                          isDark,
                          isNumber: true,
                          isRequired: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildFormField(
                          'Printed MRP (₹) *',
                          _variantPrintedMrpController,
                          'e.g. 500',
                          isDark,
                          isNumber: true,
                          isRequired: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildFormField(
                          'Cost Price (₹)',
                          _variantCostPriceController,
                          'e.g. 250',
                          isDark,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildDropdownField(
                          label: 'GST Slab',
                          value: '${_selectedVariantGst.toInt()}%',
                          items: const ['0%', '5%', '12%', '18%', '28%'],
                          isDark: isDark,
                          borderColor: borderColor,
                          onChanged: (val) => setState(() => _selectedVariantGst = double.parse(val!.replaceAll('%', ''))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 4: Stock & Discount Pill
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildFormField(
                          'Current Stock (Units) *',
                          _variantStockController,
                          'e.g. 100',
                          isDark,
                          isNumber: true,
                          isRequired: true,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          height: 48,
                          margin: const EdgeInsets.only(top: 22),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: discountRs > 0
                                ? const Color(0xFF059669).withValues(alpha: 0.1)
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: discountRs > 0 ? const Color(0xFF059669).withValues(alpha: 0.3) : borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                size: 16,
                                color: discountRs > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                discountRs > 0
                                    ? 'Discount: ₹${discountRs.toStringAsFixed(0)} (${discountPct.toStringAsFixed(1)}% off)'
                                    : 'No discount applied (MRP = Rate)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: discountRs > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Variant Actions (Default, Duplicate, Delete)
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (!activeVar.isDefault)
                            OutlinedButton.icon(
                              onPressed: () => _setDefaultVariant(_activeVariantIndex),
                              icon: const Icon(Icons.star_border_rounded, size: 16),
                              label: Text(
                                'Set as Default Variant',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFF059669)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'This is the Primary Default Variant',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _duplicateVariant(_activeVariantIndex),
                            icon: const Icon(Icons.copy_rounded, size: 15),
                            label: Text(
                              'Duplicate',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (_variants.length > 1)
                            OutlinedButton.icon(
                              onPressed: () => _deleteVariant(_activeVariantIndex),
                              icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                              label: Text(
                                'Remove Variant',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Variants Summary Table - FULL WIDTH RESPONSIVE PREVIEW
          _buildCard(
            title: 'All Configured Variants Preview',
            subtitle: 'Overview of all ${_variants.length} packaging variants to be saved with this product',
            icon: Icons.table_chart_outlined,
            isDark: isDark,
            borderColor: borderColor,
            cardBgColor: cardBgColor,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          horizontalMargin: 16,
                          columnSpacing: 28,
                          headingRowHeight: 40,
                          dataRowMinHeight: 40,
                          dataRowMaxHeight: 46,
                          headingRowColor: WidgetStateProperty.all(
                            isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          ),
                          columns: const [
                            DataColumn(label: Text('#')),
                            DataColumn(label: Text('Label')),
                            DataColumn(label: Text('Pack Size')),
                            DataColumn(label: Text('Display Rate')),
                            DataColumn(label: Text('MRP')),
                            DataColumn(label: Text('Stock')),
                            DataColumn(label: Text('Default')),
                          ],
                          rows: _variants.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final v = entry.value;
                            return DataRow(
                              cells: [
                                DataCell(Text('${idx + 1}')),
                                DataCell(Text(v.label.isNotEmpty ? v.label : 'Pack ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(v.packSize > 0 ? '${v.packSize} ${v.unit}' : '-')),
                                DataCell(Text(v.displayRate > 0 ? '₹${v.displayRate.toStringAsFixed(0)}' : '-', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700))),
                                DataCell(Text(v.printedMrp > 0 ? '₹${v.printedMrp.toStringAsFixed(0)}' : '-')),
                                DataCell(Text(v.stock > 0 ? '${v.stock} units' : '-')),
                                DataCell(
                                  v.isDefault
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF059669).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('YES', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                                        )
                                      : const Text('-'),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: AGRONOMY & CROP SPECS ---
  Widget _buildTab3Agronomy(bool isDark, Color borderColor, Color cardBgColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            title: 'Agronomic Characteristics',
            subtitle: 'Chemical/biological composition, action mechanism, and application',
            icon: Icons.biotech_rounded,
            isDark: isDark,
            borderColor: borderColor,
            cardBgColor: cardBgColor,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        'Technical Content',
                        _technicalContentController,
                        'e.g. Beauveria bassiana 5x10^8 CFU/ml',
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        'Mode of Action',
                        _modeOfActionController,
                        'e.g. Entomopathogenic contact action',
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        'Suitable Crops',
                        _suitableCropController,
                        'e.g. Cotton, Paddy, Chilli, Tomato, Vegetables',
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        'Recommended Dosage',
                        _dosageController,
                        'e.g. 2.5 ml / Litre water',
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        'Target Pests',
                        _targetPestsController,
                        'e.g. Whiteflies, aphids, thrips, mealybugs',
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        'Target Diseases',
                        _targetDiseasesController,
                        'e.g. Sheath Blight, Blast',
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildFormField(
                  'Application Method',
                  _applicationMethodController,
                  'e.g. Foliar spray for plants and garden',
                  isDark,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        'Key Features',
                        _featuresController,
                        'e.g. Fast rainfastness, broad coverage...',
                        isDark,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        'Farmer Benefits',
                        _benefitsController,
                        'e.g. Enhances crop stand and yield by 15%...',
                        isDark,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 4: SHIPPING & LOGISTICS ---
  Widget _buildTab4Shipping(bool isDark, Color borderColor, Color cardBgColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            title: 'Physical Dimensions & Packaging Weight',
            subtitle: 'Volumetric and weight specs utilized by courier logistics partners',
            icon: Icons.local_shipping_outlined,
            isDark: isDark,
            borderColor: borderColor,
            cardBgColor: cardBgColor,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        'Product Weight *',
                        _weightController,
                        'e.g. 500',
                        isDark,
                        isNumber: true,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Weight Unit',
                        value: _selectedWeightUnit,
                        items: const ['g', 'kg', 'mg', 'gm'],
                        isDark: isDark,
                        borderColor: borderColor,
                        onChanged: (val) => setState(() => _selectedWeightUnit = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        'Length (cm)',
                        _dimensionsLengthController,
                        'e.g. 20',
                        isDark,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFormField(
                        'Width (cm)',
                        _dimensionsWidthController,
                        'e.g. 10',
                        isDark,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFormField(
                        'Height (cm)',
                        _dimensionsHeightController,
                        'e.g. 10',
                        isDark,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Unit',
                        value: _selectedDimensionUnit,
                        items: const ['cm', 'inch', 'mm'],
                        isDark: isDark,
                        borderColor: borderColor,
                        onChanged: (val) => setState(() => _selectedDimensionUnit = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildFormField(
                  'Refund Policy',
                  _refundPolicyController,
                  'e.g. 7 Days Returnable if unopened',
                  isDark,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'Is Available for Purchase',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'When enabled, product is active and visible on storefront for ordering',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  value: _isAvailable,
                  activeTrackColor: const Color(0xFF059669),
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE CARD CONTAINER ---
  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required Color borderColor,
    required Color cardBgColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(icon, color: const Color(0xFF059669), size: 15),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '•  $subtitle',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
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
        const SizedBox(height: 4),
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
            fontSize: 12.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE DROPDOWN FIELD ---
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required bool isDark,
    required Color borderColor,
    required Function(String?) onChanged,
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
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
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
                      fontSize: 12.5,
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

  // --- REUSABLE SEARCHABLE SELECT FIELD ---
  Widget _buildSearchableSelectField<T>({
    required String label,
    required String displayText,
    required String placeholder,
    required IconData prefixIcon,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
    bool isRequired = false,
    String? helperText,
    bool hasValue = true,
    Widget? trailingBadge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(prefixIcon, size: 14, color: const Color(0xFF059669)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
            if (trailingBadge != null) ...[
              const SizedBox(width: 8),
              trailingBadge,
            ],
          ],
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: !hasValue
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.6)
                    : borderColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText.isNotEmpty ? displayText : placeholder,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                      color: hasValue
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              helperText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // --- REUSABLE SEARCHABLE PICKER DIALOG ---
  Future<T?> _showSearchablePicker<T>({
    required BuildContext context,
    required String title,
    required IconData titleIcon,
    required String searchHint,
    required List<T> items,
    required T? selectedItem,
    required String Function(T) labelBuilder,
    String Function(T)? subtitleBuilder,
    Widget Function(T)? leadingBuilder,
    Widget? Function(T)? trailingBadgeBuilder,
    bool isDark = false,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return _SearchablePickerDialog<T>(
          title: title,
          titleIcon: titleIcon,
          searchHint: searchHint,
          items: items,
          selectedItem: selectedItem,
          labelBuilder: labelBuilder,
          subtitleBuilder: subtitleBuilder,
          leadingBuilder: leadingBuilder,
          trailingBadgeBuilder: trailingBadgeBuilder,
          isDark: isDark,
        );
      },
    );
  }
}

class _SearchablePickerDialog<T> extends StatefulWidget {
  final String title;
  final IconData titleIcon;
  final String searchHint;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) labelBuilder;
  final String Function(T)? subtitleBuilder;
  final Widget Function(T)? leadingBuilder;
  final Widget? Function(T)? trailingBadgeBuilder;
  final bool isDark;

  const _SearchablePickerDialog({
    required this.title,
    required this.titleIcon,
    required this.searchHint,
    required this.items,
    required this.selectedItem,
    required this.labelBuilder,
    this.subtitleBuilder,
    this.leadingBuilder,
    this.trailingBadgeBuilder,
    this.isDark = false,
  });

  @override
  State<_SearchablePickerDialog<T>> createState() => _SearchablePickerDialogState<T>();
}

class _SearchablePickerDialogState<T> extends State<_SearchablePickerDialog<T>> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBgColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final query = _searchQuery.toLowerCase();

    final filtered = widget.items.where((item) {
      if (query.isEmpty) return true;
      final label = widget.labelBuilder(item).toLowerCase();
      final sub = widget.subtitleBuilder != null ? widget.subtitleBuilder!(item).toLowerCase() : '';
      return label.contains(query) || sub.contains(query);
    }).toList();

    return Dialog(
      backgroundColor: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(widget.titleIcon, color: const Color(0xFF059669), size: 17),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Type to filter in real-time or select from list below',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    splashRadius: 18,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.searchHint,
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 17, color: Color(0xFF059669)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 16),
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                ),
              ),
            ),

            // Subheader
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Text(
                '${filtered.length} ${filtered.length == 1 ? "option available" : "options available"}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Options List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 32,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No matches found for "$_searchQuery"',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 3),
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final isSelected = widget.selectedItem == item;
                        final label = widget.labelBuilder(item);
                        final subtitle = widget.subtitleBuilder?.call(item);
                        final leading = widget.leadingBuilder?.call(item);
                        final badge = widget.trailingBadgeBuilder?.call(item);

                        return Material(
                          color: isSelected
                              ? const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(item),
                            borderRadius: BorderRadius.circular(8),
                            hoverColor: const Color(0xFF059669).withValues(alpha: 0.06),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Row(
                                children: [
                                  if (leading != null) ...[
                                    leading,
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          label,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFF059669)
                                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (subtitle != null && subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitle,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (badge != null) ...[
                                    const SizedBox(width: 8),
                                    badge,
                                  ],
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: Color(0xFF059669),
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
    );
  }
}
