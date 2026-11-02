import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/admin_user.dart';
import '../../../core/models/category.dart';
import '../../../core/models/collection.dart';
import '../../../core/models/product.dart';
import '../../../logic/admin_user/seller_bloc.dart';
import '../../../logic/category/category_bloc.dart';
import '../../../logic/collection/collection_bloc.dart';
import '../../../logic/collection/collection_event.dart';
import '../../../logic/product/product_bloc.dart';
import '../../../logic/product/product_event.dart';
import '../widgets/app_product_image.dart';
import '../widgets/app_html_view.dart';
import '../widgets/app_html_editor.dart';
import '../widgets/assign_collections_dialog.dart';

class ProductImageUploadItem {
  final String name;
  final List<int> bytes;

  const ProductImageUploadItem({required this.name, required this.bytes});
}

class ProductDetailsView extends StatefulWidget {
  final Product product;
  final VoidCallback onBack;
  final Function(Product updatedProduct)? onProductUpdated;
  final void Function(Product newProduct, [List<ProductImageUploadItem>? pendingImages])? onProductCreated;
  final bool startInEditMode;
  final bool isCreateMode;

  const ProductDetailsView({
    super.key,
    required this.product,
    required this.onBack,
    this.onProductUpdated,
    this.onProductCreated,
    this.startInEditMode = false,
    this.isCreateMode = false,
  });

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  late Product _currentProduct;
  late bool _isEditing;

  // Form Controllers for editing
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
  late TextEditingController _variantSkuController;
  late TextEditingController _variantController;
  late TextEditingController _packSizeController;
  late TextEditingController _unitController;
  late TextEditingController _packQuantityController;
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

  String _selectedSellerId = '';
  String _selectedSellerName = '';
  String _selectedCategoryId = '';
  String _selectedCategoryName = '';
  List<String> _selectedCollectionIds = [];
  List<String> _selectedCollectionNames = [];
  String _selectedSubCollectionId = '';
  String _selectedSubCollectionName = '';

  final List<ProductImageUploadItem> _pendingImages = [];
  int _activePreviewImageIndex = 0;

  late bool _editIsAvailable;
  // late bool _editIsFeatured; // isFeatured temporarily commented out

  int _selectedVariantIndex = 0;
  List<ProductVariant> _workingVariants = [];
  final ScrollController _variantScrollController = ScrollController();
  bool _isSaving = false;
  DateTime? _lastSaveClickTime;
  bool _pointerDownOnSave = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _isEditing = widget.startInEditMode || widget.isCreateMode;
    _initControllers(_currentProduct);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final colState = context.read<CollectionBloc>().state;
          if (colState.collections.isEmpty) {
            context.read<CollectionBloc>().add(const FetchCollections());
          }
        } catch (_) {}
      }
    });
  }

  void _initControllers(Product p) {
    if (widget.isCreateMode) {
      _workingVariants = [
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
      ];
      _selectedVariantIndex = 0;

      _titleController = TextEditingController();
      _techNameController = TextEditingController();
      _productCodeController = TextEditingController();
      _hsnCodeController = TextEditingController();
      _vendorController = TextEditingController();
      _categoryController = TextEditingController();
      _collectionsController = TextEditingController();
      _subCollectionsController = TextEditingController();
      _descriptionController = TextEditingController();
      _techContentController = TextEditingController();
      _featuresController = TextEditingController();
      _benefitsController = TextEditingController();
      _modeOfActionController = TextEditingController();
      _suitableCropController = TextEditingController();
      _targetPestsController = TextEditingController();
      _targetDiseasesController = TextEditingController();
      _dosageController = TextEditingController();
      _appMethodController = TextEditingController();
      _variantSkuController = TextEditingController();
      _variantController = TextEditingController(text: 'Pack 1');
      _packSizeController = TextEditingController();
      _unitController = TextEditingController(text: 'ml');
      _packQuantityController = TextEditingController(text: '1');
      _displayRateController = TextEditingController();
      _printedMrpController = TextEditingController();
      _costPriceController = TextEditingController();
      _gstController = TextEditingController(text: '5');
      _shippedByController = TextEditingController(text: 'essentialbiocropscience');
      _swgController = TextEditingController();
      _stockController = TextEditingController();
      _ratingsController = TextEditingController(text: '4.8');
      _refundPolicyController = TextEditingController();
      _weightController = TextEditingController();
      _weightUnitController = TextEditingController(text: 'g');
      _dimensionsController = TextEditingController();

      _selectedSellerId = p.sellerId;
      _selectedSellerName = p.sellerName.isNotEmpty ? p.sellerName : p.vendor;
      _selectedCategoryId = p.categoryId;
      _selectedCategoryName = p.category;
      _selectedCollectionIds = List<String>.from(p.collectionIds);
      if (p.collections.isNotEmpty) {
        _selectedCollectionNames = p.collections
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        _selectedCollectionNames = [];
      }
      if (_selectedCollectionIds.isEmpty && p.assignedCollections.isNotEmpty) {
        _selectedCollectionIds = List<String>.from(p.assignedCollections);
      }
      _selectedSubCollectionId = p.subCollectionIds.isNotEmpty ? p.subCollectionIds.first : '';
      _selectedSubCollectionName = p.subCollections;

      _editIsAvailable = true;
      return;
    }

    _workingVariants = List.from(p.variants);
    final defIdx = _workingVariants.indexWhere((v) => v.isDefault);
    _selectedVariantIndex = defIdx != -1 ? defIdx : 0;
    final initialVar = _workingVariants.isNotEmpty ? _workingVariants[_selectedVariantIndex] : null;

    _titleController = TextEditingController(text: p.title);
    _techNameController = TextEditingController(text: p.technicalName);
    _productCodeController = TextEditingController(text: p.productCode);
    _hsnCodeController = TextEditingController(text: p.hsnCode);
    _vendorController = TextEditingController(text: p.sellerName.isNotEmpty ? p.sellerName : p.vendor);
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
    _variantSkuController = TextEditingController(text: initialVar?.sku ?? '');
    _variantController = TextEditingController(text: initialVar?.label ?? p.variant);
    _packSizeController = TextEditingController(text: (initialVar != null ? initialVar.packSize : (int.tryParse(p.packSize) ?? 1)).toString());
    _unitController = TextEditingController(text: initialVar?.unit ?? p.unit);
    _packQuantityController = TextEditingController(text: (initialVar?.packQuantity ?? 1).toString());
    _displayRateController = TextEditingController(text: (initialVar?.displayRate ?? p.displayRate).toStringAsFixed(2));
    _printedMrpController = TextEditingController(text: (initialVar?.printedMrp ?? p.printedMrp).toStringAsFixed(2));
    _costPriceController = TextEditingController(text: (initialVar?.costPrice ?? p.costPrice).toStringAsFixed(2));
    _gstController = TextEditingController(text: (initialVar?.gstPercentage ?? p.gst).toStringAsFixed(0));
    _shippedByController = TextEditingController(
      text: (initialVar?.shippedBy == 'essentialbiocropscience')
          ? initialVar!.shippedBy
          : 'essentialbiocropscience',
    );
    _swgController = TextEditingController(text: p.swg);
    _stockController = TextEditingController(text: (initialVar?.stock ?? p.stock).toString());
    _ratingsController = TextEditingController(text: (p.ratings > 0 ? p.ratings : 4.8).toStringAsFixed(1));
    _refundPolicyController = TextEditingController(text: p.refundPolicy);
    _weightController = TextEditingController(text: p.productWeight.toStringAsFixed(2));
    _weightUnitController = TextEditingController(text: p.productWeightUnit);
    _dimensionsController = TextEditingController(text: p.dimensions);

    _selectedSellerId = p.sellerId;
    _selectedSellerName = p.sellerName.isNotEmpty ? p.sellerName : p.vendor;
    _selectedCategoryId = p.categoryId;
    _selectedCategoryName = p.category;
    _selectedCollectionIds = List<String>.from(p.collectionIds);
    if (p.collections.isNotEmpty) {
      _selectedCollectionNames = p.collections
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      _selectedCollectionNames = [];
    }
    if (_selectedCollectionIds.isEmpty && p.assignedCollections.isNotEmpty) {
      _selectedCollectionIds = List<String>.from(p.assignedCollections);
    }
    _selectedSubCollectionId = p.subCollectionIds.isNotEmpty ? p.subCollectionIds.first : '';
    _selectedSubCollectionName = p.subCollections;

    _editIsAvailable = p.isAvailable;
    // _editIsFeatured = p.isFeatured;
  }

  void _resetControllers() {
    _initControllers(_currentProduct);
  }

  void _syncCurrentVariantFromControllers() {
    if (_workingVariants.isEmpty || _selectedVariantIndex >= _workingVariants.length) return;
    final cur = _workingVariants[_selectedVariantIndex];
    final disp = double.tryParse(_displayRateController.text.trim()) ?? cur.displayRate;
    final mrp = double.tryParse(_printedMrpController.text.trim()) ?? cur.printedMrp;
    final cp = double.tryParse(_costPriceController.text.trim()) ?? cur.costPrice;
    final st = int.tryParse(_stockController.text.trim()) ?? cur.stock;
    final ps = int.tryParse(_packSizeController.text.trim()) ?? cur.packSize;
    final pq = int.tryParse(_packQuantityController.text.trim()) ?? cur.packQuantity;
    final unit = _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : cur.unit;
    final disc = (mrp > disp) ? (mrp - disp) : 0.0;
    final discPct = mrp > 0 ? (disc / mrp * 100) : 0.0;
    final totalBase = (ps > 0 && pq > 0) ? (ps * pq) : cur.totalBaseQuantity;
    final pricePerBase = totalBase > 0 ? (disp / totalBase) : 0.0;

    _workingVariants[_selectedVariantIndex] = cur.copyWith(
      sku: _variantSkuController.text.trim().isNotEmpty ? _variantSkuController.text.trim() : cur.sku,
      label: _variantController.text.trim(),
      packSize: ps,
      unit: unit,
      packSizeUnit: unit,
      packQuantity: pq,
      totalBaseQuantity: totalBase,
      totalBaseUnit: unit,
      pricePerBaseUnit: pricePerBase,
      displayRate: disp,
      printedMrp: mrp,
      costPrice: cp,
      discountRs: disc,
      discountPercentage: discPct,
      stock: st,
      gstPercentage: double.tryParse(_gstController.text.trim()) ?? cur.gstPercentage,
      swg: double.tryParse(_swgController.text.trim()) ?? cur.swg,
      dimensions: _dimensionsController.text.trim().isNotEmpty
          ? ProductDimensions.fromJson(_dimensionsController.text.trim())
          : cur.dimensions,
      shippedBy: _shippedByController.text.trim(),
    );
  }

  void _onVariantFieldChanged() {
    _syncCurrentVariantFromControllers();
    setState(() {});
  }

  void _selectVariant(int index, {bool syncCurrent = true}) {
    if (index < 0 || index >= _workingVariants.length) return;
    if (_isEditing && syncCurrent) {
      _syncCurrentVariantFromControllers();
    }
    setState(() {
      _selectedVariantIndex = index;
      final v = _workingVariants[index];
      _variantSkuController.text = v.sku;
      _variantController.text = v.label;
      _packSizeController.text = v.packSize > 0 ? v.packSize.toString() : '';
      _unitController.text = v.unit;
      _packQuantityController.text = v.packQuantity > 0 ? v.packQuantity.toString() : '1';
      _displayRateController.text = v.displayRate > 0 ? v.displayRate.toStringAsFixed(2) : '';
      _printedMrpController.text = v.printedMrp > 0 ? v.printedMrp.toStringAsFixed(2) : '';
      _costPriceController.text = v.costPrice > 0 ? v.costPrice.toStringAsFixed(2) : '';
      _stockController.text = v.stock.toString();
      _shippedByController.text = (v.shippedBy.isNotEmpty)
          ? v.shippedBy
          : 'essentialbiocropscience';
      _gstController.text = v.gstPercentage.toStringAsFixed(0);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_variantScrollController.hasClients) {
        final target = (index * 140.0 - 60.0).clamp(0.0, _variantScrollController.position.maxScrollExtent);
        _variantScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _addVariant() {
    if (_isEditing) {
      _syncCurrentVariantFromControllers();
    }
    setState(() {
      final newIndex = _workingVariants.length + 1;
      final unit = _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'ml';
      final baseSku = (_currentProduct.sku.isNotEmpty ? _currentProduct.sku : 'PROD')
          .replaceAll(RegExp(r'\s*-\s*'), '-')
          .trim();
      final autoSku = '$baseSku-${newIndex.toString().padLeft(2, '0')}';
      final newVariant = ProductVariant(
        id: 'var_${DateTime.now().millisecondsSinceEpoch}',
        sku: autoSku,
        displayOrder: newIndex,
        isDefault: _workingVariants.isEmpty,
        label: 'Pack $newIndex (${_packSizeController.text.trim()}$unit x 1)',
        unit: unit,
        packSize: int.tryParse(_packSizeController.text.trim()) ?? 1,
        packSizeUnit: unit,
        packQuantity: 1,
        packUnit: 'pack',
        shippedBy: _shippedByController.text.trim().isNotEmpty
            ? _shippedByController.text.trim()
            : 'essentialbiocropscience',
        totalBaseQuantity: int.tryParse(_packSizeController.text.trim()) ?? 1,
        totalBaseUnit: unit,
        displayRate: double.tryParse(_displayRateController.text.trim()) ?? 500.0,
        printedMrp: double.tryParse(_printedMrpController.text.trim()) ?? 999.0,
        costPrice: double.tryParse(_costPriceController.text.trim()) ?? 350.0,
        stock: 50,
        gstPercentage: double.tryParse(_gstController.text.trim()) ?? 18.0,
      );
      _workingVariants.add(newVariant);
      _selectVariant(_workingVariants.length - 1);
    });
  }

  void _duplicateVariant(int index) {
    if (index < 0 || index >= _workingVariants.length) return;
    if (_isEditing) {
      _syncCurrentVariantFromControllers();
    }
    setState(() {
      final source = _workingVariants[index];
      final newIndex = _workingVariants.length + 1;
      final baseSku = (_currentProduct.sku.isNotEmpty ? _currentProduct.sku : 'PROD')
          .replaceAll(RegExp(r'\s*-\s*'), '-')
          .trim();
      final autoSku = '$baseSku-${newIndex.toString().padLeft(2, '0')}';
      final duplicate = source.copyWith(
        id: 'var_${DateTime.now().millisecondsSinceEpoch}',
        sku: autoSku,
        displayOrder: newIndex,
        isDefault: false,
        label: '${source.label} (Copy)',
      );
      _workingVariants.add(duplicate);
      _selectVariant(_workingVariants.length - 1);
    });
  }

  void _deleteVariant(int index) {
    if (_workingVariants.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete the only remaining variant',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      final wasDefault = _workingVariants[index].isDefault;
      _workingVariants.removeAt(index);
      if (wasDefault && _workingVariants.isNotEmpty) {
        _workingVariants[0] = _workingVariants[0].copyWith(isDefault: true);
      }
      final newIdx = (index >= _workingVariants.length) ? _workingVariants.length - 1 : index;
      _selectedVariantIndex = newIdx;
      _selectVariant(newIdx, syncCurrent: false);
    });
  }

  void _setVariantAsDefault(int index) {
    if (index < 0 || index >= _workingVariants.length) return;
    setState(() {
      for (int i = 0; i < _workingVariants.length; i++) {
        _workingVariants[i] = _workingVariants[i].copyWith(isDefault: i == index);
      }
    });
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
    _variantSkuController.dispose();
    _variantController.dispose();
    _packSizeController.dispose();
    _unitController.dispose();
    _packQuantityController.dispose();
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
    _variantScrollController.dispose();
    super.dispose();
  }

  void _toggleAvailability() {
    final newAvailability = !_currentProduct.isAvailable;
    setState(() {
      _currentProduct = _currentProduct.copyWith(isAvailable: newAvailability);
      _editIsAvailable = newAvailability;
    });
    widget.onProductUpdated?.call(_currentProduct);

    if (!widget.isCreateMode && _currentProduct.id.isNotEmpty) {
      try {
        context.read<ProductBloc>().add(
              ToggleProductAvailability(
                productId: _currentProduct.id,
                isAvailable: newAvailability,
              ),
            );
      } catch (_) {}
    }
  }

  void _openAssignCollectionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AssignCollectionsDialog(
        product: _currentProduct,
        onProductUpdated: (updatedProduct) {
          setState(() {
            _currentProduct = updatedProduct;
          });
          widget.onProductUpdated?.call(updatedProduct);
        },
      ),
    );
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
    final now = DateTime.now();
    if (_lastSaveClickTime != null && now.difference(_lastSaveClickTime!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastSaveClickTime = now;

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

    if (widget.isCreateMode && _selectedSellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a Seller (Store Owner) for this product',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.isCreateMode && _selectedCategoryId.isEmpty && _categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a Category for this product',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    if (_isEditing) {
      _syncCurrentVariantFromControllers();
    }

    final displayRate = double.tryParse(_displayRateController.text) ?? _currentProduct.displayRate;
    final printedMrp = double.tryParse(_printedMrpController.text) ?? _currentProduct.printedMrp;
    final costPrice = double.tryParse(_costPriceController.text) ?? _currentProduct.costPrice;
    final discountRs = (printedMrp > displayRate) ? (printedMrp - displayRate) : 0.0;
    final discountPct = printedMrp > 0 ? (discountRs / printedMrp * 100) : 0.0;
    final stock = int.tryParse(_stockController.text) ?? _currentProduct.stock;
    final gst = double.tryParse(_gstController.text) ?? _currentProduct.gst;
    final rawRating = double.tryParse(_ratingsController.text.trim()) ?? 4.8;
    final ratings = rawRating.clamp(0.0, 5.0);
    final weight = double.tryParse(_weightController.text) ?? _currentProduct.productWeight;

    final assignedCols = <String>[
      ..._selectedCollectionIds,
      if (_selectedSubCollectionId.isNotEmpty && !_selectedCollectionIds.contains(_selectedSubCollectionId))
        _selectedSubCollectionId,
    ];

    final updatedProduct = _currentProduct.copyWith(
      title: title,
      technicalName: _techNameController.text.trim(),
      productCode: _productCodeController.text.trim(),
      hsnCode: _hsnCodeController.text.trim(),
      sellerId: _selectedSellerId.isNotEmpty ? _selectedSellerId : _currentProduct.sellerId,
      vendor: _selectedSellerName.isNotEmpty ? _selectedSellerName : _vendorController.text.trim(),
      sellerName: _selectedSellerName.isNotEmpty ? _selectedSellerName : _vendorController.text.trim(),
      categoryId: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : _currentProduct.categoryId,
      category: _selectedCategoryName.isNotEmpty ? _selectedCategoryName : _categoryController.text.trim(),
      collections: _selectedCollectionNames.isNotEmpty ? _selectedCollectionNames.join(', ') : _collectionsController.text.trim(),
      collectionIds: _selectedCollectionIds,
      subCollections: _selectedSubCollectionName.isNotEmpty ? _selectedSubCollectionName : _subCollectionsController.text.trim(),
      subCollectionIds: _selectedSubCollectionId.isNotEmpty ? [_selectedSubCollectionId] : [],
      assignedCollections: assignedCols.isNotEmpty ? assignedCols : _currentProduct.assignedCollections,
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
      images: _currentProduct.images,
      isAvailable: _editIsAvailable,
      isFeatured: _currentProduct.isFeatured,
      variants: _workingVariants,
    );

    if (widget.isCreateMode) {
      widget.onProductCreated?.call(updatedProduct, _pendingImages);
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _isSaving) {
          setState(() => _isSaving = false);
        }
      });
      return;
    }

    if (_pendingImages.isNotEmpty && _currentProduct.id.isNotEmpty) {
      try {
        context.read<ProductBloc>().add(
              UploadProductImages(
                productId: _currentProduct.id,
                filesBytes: _pendingImages.map((e) => e.bytes).toList(),
                fileNames: _pendingImages.map((e) => e.name).toList(),
              ),
            );
        _pendingImages.clear();
      } catch (_) {}
    }

    setState(() {
      _currentProduct = updatedProduct;
      _isEditing = false;
      _isSaving = false;
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
    if (widget.isCreateMode) {
      widget.onBack();
      return;
    }
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
                          widget.isCreateMode
                              ? (_titleController.text.trim().isNotEmpty
                                  ? _titleController.text.trim()
                                  : 'Add Agricultural Product')
                              : p.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isCreateMode) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            'NEW PRODUCT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ] else if (_isEditing) ...[
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
                  Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {
                      _pointerDownOnSave = true;
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    onPointerCancel: (_) => _pointerDownOnSave = false,
                    onPointerUp: (_) {
                      if (_pointerDownOnSave && !_isSaving) {
                        _pointerDownOnSave = false;
                        _saveChanges();
                      }
                    },
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveChanges,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 16),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : (widget.isCreateMode ? 'Save & Publish Product' : 'Save Changes'),
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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

          // Main Responsive Grid Layout (Industry Standard E-Commerce Structure)
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Identity, Narrative/Documentation & Multi-Variants (Main Workspace)
                Expanded(
                  flex: 65,
                  child: Column(
                    children: [
                      _buildIdentityHeaderCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                      const SizedBox(height: 18),
                      _buildDescriptionAndBenefitsCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                      const SizedBox(height: 18),
                      _buildVariantsCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Right Column: Media Gallery, Commercial Pricing & Logistics Sidebar (380px)
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
              ],
            )
          else
            // Narrow Screen Layout
            Column(
              children: [
                _buildIdentityHeaderCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                const SizedBox(height: 16),
                _buildDescriptionAndBenefitsCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                const SizedBox(height: 16),
                _buildImageAndMediaCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                const SizedBox(height: 16),
                _buildVariantsCard(p, isDark, surfaceColor, borderColor, cardBgColor),
                const SizedBox(height: 16),
                _buildPricingCard(p, isDark, surfaceColor, borderColor, cardBgColor, grossProfit, marginPct),
                const SizedBox(height: 16),
                _buildLogisticsAndPackagingCard(p, isDark, surfaceColor, borderColor, cardBgColor),
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
            _buildField(
              controller: _techContentController,
              label: 'Chemical Composition & Technical Content',
              hint: 'e.g. Chlorpyrifos 50% + Cypermethrin 5% EC',
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _productCodeController,
                    label: 'Product Code *',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _isEditing
                      ? Builder(builder: (ctx) {
                          SellerBloc? sellerBloc;
                          try {
                            sellerBloc = ctx.watch<SellerBloc>();
                          } catch (_) {}
                          final sellers = sellerBloc?.state.users ?? <AdminUser>[];
                          final currentSelected = sellers.where((s) => s.id == _selectedSellerId).firstOrNull;
                          final displayText = currentSelected != null
                              ? '${currentSelected.displayName}${currentSelected.phoneNumber.isNotEmpty ? ' • ${currentSelected.phoneNumber}' : ''}'
                              : (_selectedSellerName.isNotEmpty ? _selectedSellerName : _vendorController.text);

                          return _buildSearchableSelectField<AdminUser>(
                            label: 'Seller (Store Owner) *',
                            displayText: displayText,
                            placeholder: '-- Select Seller (Required) --',
                            prefixIcon: Icons.storefront_rounded,
                            hasValue: _selectedSellerId.isNotEmpty || _vendorController.text.isNotEmpty,
                            isDark: isDark,
                            borderColor: borderColor,
                            onTap: () async {
                              final picked = await _showSearchablePicker<AdminUser>(
                                context: context,
                                title: 'Select Seller (Store Owner)',
                                titleIcon: Icons.storefront_rounded,
                                searchHint: 'Search seller by name or phone...',
                                items: sellers,
                                selectedItem: currentSelected,
                                labelBuilder: (s) => s.displayName,
                                subtitleBuilder: (s) => '${s.phoneNumber.isNotEmpty ? '${s.phoneNumber} • ' : ''}ID: ${s.id}',
                                isDark: isDark,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedSellerId = picked.id;
                                  _selectedSellerName = picked.displayName;
                                  _vendorController.text = picked.displayName;
                                });
                              }
                            },
                          );
                        })
                      : _buildField(
                          controller: _vendorController,
                          label: 'Seller Name',
                          hint: 'e.g. Krishi Kranti Organics',
                          isDark: isDark,
                          borderColor: borderColor,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isEditing
                      ? Builder(builder: (ctx) {
                          CategoryBloc? catBloc;
                          try {
                            catBloc = ctx.watch<CategoryBloc>();
                          } catch (_) {}
                          final flatCategories = catBloc?.state.allCategories ?? <CategoryItem>[];
                          final currentSelected = flatCategories.where((c) => c.id == _selectedCategoryId || c.name == _selectedCategoryName).firstOrNull;
                          final displayText = currentSelected != null
                              ? currentSelected.name
                              : (_selectedCategoryName.isNotEmpty ? _selectedCategoryName : _categoryController.text);

                          return _buildSearchableSelectField<CategoryItem>(
                            label: 'Category *',
                            displayText: displayText,
                            placeholder: '-- Select Category (Required) --',
                            prefixIcon: Icons.category_rounded,
                            hasValue: _selectedCategoryId.isNotEmpty || _categoryController.text.isNotEmpty,
                            isDark: isDark,
                            borderColor: borderColor,
                            onTap: () async {
                              final picked = await _showSearchablePicker<CategoryItem>(
                                context: context,
                                title: 'Select Category',
                                titleIcon: Icons.category_rounded,
                                searchHint: 'Search categories by name...',
                                items: flatCategories,
                                selectedItem: currentSelected,
                                labelBuilder: (c) => c.name,
                                subtitleBuilder: (c) => 'Level ${c.level + 1} Category',
                                isDark: isDark,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedCategoryId = picked.id;
                                  _selectedCategoryName = picked.name;
                                  _categoryController.text = picked.name;
                                });
                              }
                            },
                          );
                        })
                      : _buildField(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _isEditing
                      ? Builder(builder: (ctx) {
                          CollectionBloc? colBloc;
                          try {
                            colBloc = ctx.watch<CollectionBloc>();
                          } catch (_) {}
                          final collections = colBloc?.state.collections ?? <CollectionItem>[];
                          final currentSelectedList = collections.where((c) =>
                              _selectedCollectionIds.contains(c.id) ||
                              _selectedCollectionNames.contains(c.name)).toList();
                          final displayText = currentSelectedList.isNotEmpty
                              ? currentSelectedList.map((c) => c.name).join(', ')
                              : (_selectedCollectionNames.isNotEmpty
                                  ? _selectedCollectionNames.join(', ')
                                  : _collectionsController.text);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSearchableSelectField<CollectionItem>(
                                label: 'Collections (Multiple)',
                                displayText: displayText,
                                placeholder: '-- Select Collections (Optional) --',
                                prefixIcon: Icons.collections_bookmark_rounded,
                                hasValue: _selectedCollectionIds.isNotEmpty || _selectedCollectionNames.isNotEmpty || _collectionsController.text.isNotEmpty,
                                isDark: isDark,
                                borderColor: borderColor,
                                onTap: () async {
                                  final pickedList = await _showMultiSearchablePicker<CollectionItem>(
                                    context: context,
                                    title: 'Select Collections',
                                    titleIcon: Icons.collections_bookmark_rounded,
                                    searchHint: 'Search collections by name...',
                                    items: collections,
                                    selectedItems: currentSelectedList,
                                    labelBuilder: (c) => c.name,
                                    subtitleBuilder: (c) => '${c.subCollections.length} sub-collections',
                                    isDark: isDark,
                                  );
                                  if (pickedList != null) {
                                    setState(() {
                                      _selectedCollectionIds = pickedList.map((c) => c.id).toList();
                                      _selectedCollectionNames = pickedList.map((c) => c.name).toList();
                                      _collectionsController.text = _selectedCollectionNames.join(', ');
                                      // If previously selected subcollection no longer belongs to any selected collection, clear it
                                      final allSubIds = pickedList.expand((c) => c.subCollections.map((s) => s.id)).toSet();
                                      if (_selectedSubCollectionId.isNotEmpty && !allSubIds.contains(_selectedSubCollectionId)) {
                                        _selectedSubCollectionId = '';
                                        _selectedSubCollectionName = '';
                                        _subCollectionsController.text = '';
                                      }
                                    });
                                  }
                                },
                              ),
                              if (_selectedCollectionNames.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _selectedCollectionNames.map((colName) {
                                    final colItem = collections.where((c) => c.name == colName).firstOrNull;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            colName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF059669),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _selectedCollectionNames.remove(colName);
                                                if (colItem != null) {
                                                  _selectedCollectionIds.remove(colItem.id);
                                                }
                                                _collectionsController.text = _selectedCollectionNames.join(', ');
                                              });
                                            },
                                            child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFF059669)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          );
                        })
                      : _buildField(
                          controller: _collectionsController,
                          label: 'Collections',
                          hint: 'e.g. Crop Protection, Seeds',
                          isDark: isDark,
                          borderColor: borderColor,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isEditing
                      ? Builder(builder: (ctx) {
                          CollectionBloc? colBloc;
                          try {
                            colBloc = ctx.watch<CollectionBloc>();
                          } catch (_) {}
                          final collections = colBloc?.state.collections ?? <CollectionItem>[];
                          final selectedCols = collections.where((c) =>
                              _selectedCollectionIds.contains(c.id) ||
                              _selectedCollectionNames.contains(c.name)).toList();
                          final subItems = <SubCollectionItem>[];
                          for (final col in selectedCols) {
                            subItems.addAll(col.subCollections);
                          }
                          final currentSelected = subItems.where((s) => s.id == _selectedSubCollectionId || s.name == _selectedSubCollectionName).firstOrNull;
                          final displayText = currentSelected != null
                              ? currentSelected.name
                              : (_selectedSubCollectionName.isNotEmpty ? _selectedSubCollectionName : _subCollectionsController.text);

                          return _buildSearchableSelectField<SubCollectionItem>(
                            label: 'Sub Collection',
                            displayText: displayText,
                            placeholder: selectedCols.isEmpty ? '-- Select Collection First --' : '-- Select Sub Collection (Optional) --',
                            prefixIcon: Icons.subdirectory_arrow_right_rounded,
                            hasValue: _selectedSubCollectionId.isNotEmpty || _subCollectionsController.text.isNotEmpty,
                            isDark: isDark,
                            borderColor: borderColor,
                            onTap: () async {
                              if (subItems.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select at least one collection with sub-collections first')),
                                );
                                return;
                              }
                              final picked = await _showSearchablePicker<SubCollectionItem>(
                                context: context,
                                title: 'Select Sub Collection',
                                titleIcon: Icons.subdirectory_arrow_right_rounded,
                                searchHint: 'Search sub-collections...',
                                items: subItems,
                                selectedItem: currentSelected,
                                labelBuilder: (s) => s.name,
                                subtitleBuilder: (s) {
                                  final parent = selectedCols.where((c) => c.subCollections.any((sub) => sub.id == s.id)).firstOrNull;
                                  return parent != null ? 'Collection: ${parent.name}' : '';
                                },
                                isDark: isDark,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedSubCollectionId = picked.id;
                                  _selectedSubCollectionName = picked.name;
                                  _subCollectionsController.text = picked.name;
                                });
                              }
                            },
                          );
                        })
                      : _buildField(
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
                    label: 'Rating (0.0 - 5.0)',
                    hint: '4.8',
                    height: 40,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    prefixIcon: const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    isDark: isDark,
                    borderColor: borderColor,
                    onChanged: (val) {
                      final parsed = double.tryParse(val.trim());
                      if (parsed != null && parsed > 5.0) {
                        _ratingsController.text = '5.0';
                        _ratingsController.selection = TextSelection.fromPosition(
                          const TextPosition(offset: 3),
                        );
                      }
                    },
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
          if (p.technicalContent.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Composition: ${p.technicalContent}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
          ],
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
              _buildBadgePill('Seller', p.sellerName.isNotEmpty ? p.sellerName : p.vendor, isDark, borderColor),
              if (p.subCollections.isNotEmpty)
                _buildBadgePill('Sub Collection', p.subCollections, isDark, borderColor),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          // Storefront Collections Assignment Card (in Read-Only View)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.collections_bookmark_rounded, size: 18, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Text(
                          'Storefront Collections Assignment',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openAssignCollectionsDialog(context),
                      icon: const Icon(Icons.tune_rounded, size: 15),
                      label: Text(
                        'Assign / Manage Collections',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (ctx) {
                    final displayItems = p.assignedCollections.isNotEmpty
                        ? p.assignedCollections
                        : [
                            if (p.collections.isNotEmpty)
                              ...p.collections.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
                            if (p.subCollections.isNotEmpty)
                              ...p.subCollections.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
                          ];

                    if (displayItems.isEmpty) {
                      return Text(
                        'No storefront collections assigned yet. Click "Assign / Manage Collections" to link this product to crop, pest, or offer collections.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      );
                    }

                    List<CollectionItem> collections = [];
                    try {
                      collections = ctx.watch<CollectionBloc>().state.collections;
                    } catch (_) {}

                    String resolveName(String id) {
                      for (final c in collections) {
                        if (c.id == id || c.slug == id || c.name.toLowerCase() == id.toLowerCase()) {
                          return c.name;
                        }
                        for (final s in c.subCollections) {
                          if (s.id == id || s.slug == id || s.name.toLowerCase() == id.toLowerCase()) {
                            return '${c.name} > ${s.name}';
                          }
                        }
                      }
                      final colIdx = p.collectionIds.indexOf(id);
                      if (colIdx != -1 && p.collections.isNotEmpty) {
                        final names = p.collections.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                        if (colIdx < names.length) return names[colIdx];
                      }
                      final subColIdx = p.subCollectionIds.indexOf(id);
                      if (subColIdx != -1 && p.subCollections.isNotEmpty) {
                        final names = p.subCollections.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                        if (subColIdx < names.length) return names[subColIdx];
                      }
                      final assignedIdx = p.assignedCollections.indexOf(id);
                      final allNames = [
                        if (p.collections.isNotEmpty) ...p.collections.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
                        if (p.subCollections.isNotEmpty) ...p.subCollections.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
                      ];
                      if (assignedIdx != -1 && assignedIdx < allNames.length) {
                        return allNames[assignedIdx];
                      }
                      return id;
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: displayItems.map((colId) {
                        final displayName = resolveName(colId);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bookmark_added_rounded,
                                size: 13,
                                color: Color(0xFF059669),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD: PACKAGING & COMMERCIAL VARIANTS (MongoDB BSON)
  // ==========================================
  Widget _buildVariantsCard(
    Product p,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color cardBgColor,
  ) {
    final variantsList = _isEditing ? _workingVariants : p.variants;
    if (variantsList.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeIdx = (_selectedVariantIndex < variantsList.length) ? _selectedVariantIndex : 0;
    final activeVariant = variantsList[safeIdx];

    return Container(
      clipBehavior: Clip.antiAlias,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.layers_rounded, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Packaging & Commercial Variants (${variantsList.length} SKUs)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isEditing
                          ? 'Edit variant pricing, pack size, units, and inventory live'
                          : 'MongoDB multi-variant architecture with pack quantity, unit pricing & stock',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (_isEditing) ...[
                FilledButton.icon(
                  onPressed: _addVariant,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add SKU'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Edit Variants'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFF059669)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Variant Pill Selector strictly clipped inside this card
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent && _variantScrollController.hasClients) {
                  final delta = pointerSignal.scrollDelta.dy != 0
                      ? pointerSignal.scrollDelta.dy
                      : pointerSignal.scrollDelta.dx;
                  final target = (_variantScrollController.offset + delta)
                      .clamp(0.0, _variantScrollController.position.maxScrollExtent);
                  _variantScrollController.jumpTo(target);
                }
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: SingleChildScrollView(
                  controller: _variantScrollController,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.hardEdge,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  child: Row(
                    children: [
                      ...List.generate(variantsList.length, (idx) {
                        final v = variantsList[idx];
                        final isSelected = idx == safeIdx;

                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _VariantPillChip(
                            variant: v,
                            index: idx,
                            isSelected: isSelected,
                            isDark: isDark,
                            isEditing: _isEditing,
                            canDelete: _isEditing && variantsList.length > 1,
                            onTap: () => _selectVariant(idx),
                            onDelete: () => _deleteVariant(idx),
                          ),
                        );
                      }),
                      if (_isEditing) ...[
                        _AddSkuPillButton(
                          isDark: isDark,
                          onTap: _addVariant,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Active Variant Section: Interactive Form only when in edit mode
          if (_isEditing) ...[
            _buildActiveVariantEditor(activeVariant, safeIdx, isDark, borderColor, cardBgColor),
            const SizedBox(height: 18),
          ],

          // Variants Table Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'All Packaging SKUs Matrix',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Click row to edit SKU',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Full-Width Packaging SKUs Matrix Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth > 700 ? constraints.maxWidth : 700.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table Header Row (Full Width)
                        Container(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'VARIANT / PACK',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'PACK SIZE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'QTY',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'SELLING RATE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'PRINTED MRP',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'STOCK',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'BASE RATE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  'DEFAULT',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: borderColor),

                        // Table Rows (Full Width)
                        ...variantsList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final v = entry.value;
                          final isCur = idx == safeIdx;

                          return Material(
                            color: isCur
                                ? (isDark
                                    ? const Color(0xFF059669).withValues(alpha: 0.12)
                                    : const Color(0xFF059669).withValues(alpha: 0.06))
                                : Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectVariant(idx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: idx < variantsList.length - 1
                                        ? BorderSide(color: borderColor.withValues(alpha: 0.6))
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              if (_isEditing && isCur) ...[
                                                const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF059669)),
                                                const SizedBox(width: 4),
                                              ],
                                              Flexible(
                                                child: Text(
                                                  v.label,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: isCur ? FontWeight.w800 : FontWeight.w600,
                                                    color: isCur
                                                        ? const Color(0xFF059669)
                                                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (v.sku.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF334155).withValues(alpha: 0.5)
                                                    : const Color(0xFFE2E8F0),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                v.sku,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${v.packSize} ${v.packSizeUnit}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${v.packQuantity}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${v.displayRate.toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF059669),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${v.printedMrp.toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          decoration: v.printedMrp > v.displayRate ? TextDecoration.lineThrough : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: v.stock > 50 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              '${v.stock} Units',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: v.stock > 50 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        v.pricePerBaseUnit > 0 ? '₹${v.pricePerBaseUnit.toStringAsFixed(3)}' : '-',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 70,
                                      child: Center(
                                        child: v.isDefault
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Default',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(0xFF10B981),
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                '-',
                                                style: TextStyle(
                                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
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

  Widget _buildActiveVariantEditor(
    ProductVariant v,
    int index,
    bool isDark,
    Color borderColor,
    Color cardBgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with variant status & quick actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF059669)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editing SKU #${index + 1}${v.sku.isNotEmpty ? " (${v.sku})" : ""}: ${v.label.isNotEmpty ? v.label : "Unnamed Variant"}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      v.isDefault ? 'Primary Default SKU' : 'Secondary Packaging Variant',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: v.isDefault ? const Color(0xFFD97706) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        fontWeight: v.isDefault ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!v.isDefault)
                IconButton(
                  tooltip: 'Set as Default SKU',
                  icon: const Icon(Icons.star_outline_rounded, size: 18, color: Color(0xFFD97706)),
                  onPressed: () => _setVariantAsDefault(index),
                  visualDensity: VisualDensity.compact,
                ),
              IconButton(
                tooltip: 'Duplicate Variant',
                icon: const Icon(Icons.copy_rounded, size: 16),
                onPressed: () => _duplicateVariant(index),
                visualDensity: VisualDensity.compact,
              ),
              if (_workingVariants.length > 1)
                IconButton(
                  tooltip: 'Delete Variant',
                  icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFEF4444)),
                  onPressed: () => _deleteVariant(index),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 1: Label, Pack Size, Unit, Pack Quantity
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideVariant = constraints.maxWidth > 650;
              if (isWideVariant) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildField(
                            controller: _variantController,
                            label: 'Variant Label / Name *',
                            hint: 'e.g. 1 ltr (250ml x 4)',
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            controller: _variantSkuController,
                            label: 'Variant SKU',
                            hint: 'e.g. KKR-01-01',
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            controller: _packSizeController,
                            label: 'Pack Size *',
                            hint: '250',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildField(
                            controller: _unitController,
                            label: 'Unit *',
                            hint: 'ml / L / kg',
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildField(
                            controller: _packQuantityController,
                            label: 'Pack Quantity *',
                            hint: '4',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _displayRateController,
                            label: 'Selling Rate (₹) *',
                            hint: '1060.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _printedMrpController,
                            label: 'Printed MRP (₹) *',
                            hint: '1900.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _costPriceController,
                            label: 'Cost Price (₹)',
                            hint: '850.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _stockController,
                            label: 'Stock Quantity *',
                            hint: '100',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
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
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Fulfilled / Shipped By',
                            value: _shippedByController.text.trim().isNotEmpty
                                ? _shippedByController.text.trim()
                                : 'essentialbiocropscience',
                            items: _shippedByOptions,
                            prefixIcon: Icons.local_shipping_outlined,
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _shippedByController.text = val;
                                });
                                _onVariantFieldChanged();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Responsive stacked layout for smaller screen widths
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildField(
                            controller: _variantController,
                            label: 'Variant Label / Name *',
                            hint: 'e.g. 1 ltr (250ml x 4)',
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            controller: _variantSkuController,
                            label: 'Variant SKU',
                            hint: 'e.g. KKR-01-01',
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _packSizeController,
                            label: 'Pack Size *',
                            hint: '250',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildField(
                            controller: _unitController,
                            label: 'Unit *',
                            hint: 'ml / L / kg',
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildField(
                            controller: _packQuantityController,
                            label: 'Pack Quantity *',
                            hint: '4',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _displayRateController,
                            label: 'Selling Rate (₹) *',
                            hint: '1060.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildField(
                            controller: _printedMrpController,
                            label: 'Printed MRP (₹) *',
                            hint: '1900.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _costPriceController,
                            label: 'Cost Price (₹)',
                            hint: '850.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildField(
                            controller: _stockController,
                            label: 'Stock Quantity *',
                            hint: '100',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _gstController,
                            label: 'GST Slab (%)',
                            hint: '18',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (_) => _onVariantFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Shipped By',
                            value: _shippedByController.text.trim().isNotEmpty
                                ? _shippedByController.text.trim()
                                : 'essentialbiocropscience',
                            items: _shippedByOptions,
                            prefixIcon: Icons.local_shipping_outlined,
                            isDark: isDark,
                            borderColor: borderColor,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _shippedByController.text = val;
                                });
                                _onVariantFieldChanged();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 14),

          // Live Metrics Calculations Badge Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLiveCalcBadge(
                  icon: Icons.scale_rounded,
                  label: 'Base Volume:',
                  value: '${v.totalBaseQuantity} ${v.totalBaseUnit}',
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
                _buildLiveCalcBadge(
                  icon: Icons.savings_rounded,
                  label: 'Customer Savings:',
                  value: '₹${v.discountRs.toStringAsFixed(0)} (${v.discountPercentage.toStringAsFixed(1)}% off)',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
                _buildLiveCalcBadge(
                  icon: Icons.pie_chart_rounded,
                  label: 'Per Base Unit:',
                  value: v.pricePerBaseUnit > 0 ? '₹${v.pricePerBaseUnit.toStringAsFixed(3)} / ${v.totalBaseUnit}' : 'N/A',
                  color: const Color(0xFF0EA5E9),
                  isDark: isDark,
                ),
                _buildLiveCalcBadge(
                  icon: Icons.trending_up_rounded,
                  label: 'Gross Profit:',
                  value: '₹${(v.displayRate - v.costPrice).toStringAsFixed(2)}',
                  color: const Color(0xFF059669),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCalcBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARD 2: IMAGE & VISUAL ASSETS
  // ==========================================
  Future<void> _pickProductImages() async {
    const maxImages = 5;
    if (_pendingImages.length >= maxImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum of 5 product images allowed. Please remove an image before adding more.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
      return;
    }

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );
      if (files.isNotEmpty) {
        final remainingSlots = maxImages - _pendingImages.length;
        final filesToAdd = files.take(remainingSlots).toList();

        for (final f in filesToAdd) {
          final bytes = await f.readAsBytes();
          if (bytes.isNotEmpty) {
            _pendingImages.add(ProductImageUploadItem(name: f.name, bytes: bytes));
          }
        }

        if (files.length > remainingSlots && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $remainingSlots image(s). Maximum limit of 5 product images reached.'),
              backgroundColor: const Color(0xFFF59E0B),
            ),
          );
        }

        if (_pendingImages.isNotEmpty) {
          setState(() {
            _activePreviewImageIndex = 0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Widget _buildImageAndMediaCard(
    Product p,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color cardBgColor,
  ) {
    const double heroHeight = 190.0;
    Widget heroWidget;

    if (_pendingImages.isNotEmpty && _activePreviewImageIndex < _pendingImages.length) {
      heroWidget = Image.memory(
        Uint8List.fromList(_pendingImages[_activePreviewImageIndex].bytes),
        fit: BoxFit.cover,
        width: double.infinity,
        height: heroHeight,
      );
    } else if (p.originalImageUrl.isNotEmpty) {
      heroWidget = AppProductImage(
        imageUrl: p.originalImageUrl,
        fallbackUrls: p.candidateImageUrls,
        width: double.infinity,
        height: heroHeight,
        borderRadius: 10,
        borderColor: borderColor,
        categoryColor: const Color(0xFF64748B),
        fit: BoxFit.cover,
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        padding: EdgeInsets.zero,
      );
    } else {
      heroWidget = InkWell(
        onTap: _isEditing && _pendingImages.length < 5 ? _pickProductImages : null,
        child: Container(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 38,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 6),
              Text(
                'No product images uploaded',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 2),
                Text(
                  'Click or tap button below to browse (max 5)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
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
            child: SizedBox(
              height: heroHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  heroWidget,

                  // Original Asset Badge (Top Left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _pendingImages.isNotEmpty ? Icons.fiber_new_rounded : Icons.image_outlined,
                            size: 11,
                            color: _pendingImages.isNotEmpty ? const Color(0xFF10B981) : Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _pendingImages.isNotEmpty
                                ? 'Upload Queued (${_pendingImages.length}/5)'
                                : 'Original Image',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pendingImages.length >= 5 ? null : _pickProductImages,
              icon: Icon(
                _pendingImages.length >= 5 ? Icons.check_circle_outline_rounded : Icons.cloud_upload_outlined,
                size: 15,
              ),
              label: Text(
                _pendingImages.isEmpty
                    ? 'Upload Images (Max 5: PNG, JPG, WEBP)'
                    : _pendingImages.length >= 5
                        ? 'Max 5 Images Selected (5/5)'
                        : 'Add More Images (${_pendingImages.length}/5 selected)',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _pendingImages.length >= 5 ? const Color(0xFF64748B) : const Color(0xFF059669),
                side: BorderSide(
                  color: _pendingImages.length >= 5 ? borderColor : const Color(0xFF059669),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (_pendingImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pendingImages.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 6),
                  itemBuilder: (context, idx) {
                    final item = _pendingImages[idx];
                    final isSel = idx == _activePreviewImageIndex;
                    return InkWell(
                      onTap: () => setState(() => _activePreviewImageIndex = idx),
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSel ? const Color(0xFF059669) : borderColor,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.memory(
                                Uint8List.fromList(item.bytes),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -3,
                            right: -3,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _pendingImages.removeAt(idx);
                                  if (_activePreviewImageIndex >= _pendingImages.length) {
                                    _activePreviewImageIndex = (_pendingImages.length - 1).clamp(0, 999);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDC2626),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, size: 10, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
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
            _buildDropdownField(
              label: 'Shipped By Partner',
              value: _shippedByController.text.trim().isNotEmpty
                  ? _shippedByController.text.trim()
                  : 'essentialbiocropscience',
              items: _shippedByOptions,
              prefixIcon: Icons.local_shipping_outlined,
              isDark: isDark,
              borderColor: borderColor,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _shippedByController.text = val;
                  });
                  _onVariantFieldChanged();
                }
              },
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
          _buildGridValueRow('Shipped By Partner', p.shippedBy.isNotEmpty ? p.shippedBy : 'essentialbiocropscience', isDark),
          _buildGridValueRow('Refund / Return Policy', p.refundPolicy, isDark),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 6: PRODUCT NARRATIVE & DOCUMENTATION
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
                    'Product Narrative & Commercial Documentation',
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
            AppHtmlEditor(
              controller: _descriptionController,
              label: 'Full Commercial Description',
              hintText: 'Comprehensive product description with agronomy tables, per-acre dosage, application guide, and guidelines...',
              isRequired: true,
              minHeight: 320,
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
              const Icon(Icons.description_outlined, color: Color(0xFF059669), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Product Narrative & Commercial Documentation',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Description (Parsed HTML with rich typography, list support & collapsible view)
          AppHtmlView(
            htmlData: p.description,
            fontSize: 13.5,
            lineHeight: 1.55,
            collapsible: true,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  static const List<String> _shippedByOptions = [
    'essentialbiocropscience',
  ];

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
    required Color borderColor,
    IconData? prefixIcon,
  }) {
    final effectiveItems = items.isNotEmpty ? items : const ['essentialbiocropscience'];
    final effectiveValue = effectiveItems.contains(value) ? value : effectiveItems.first;

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
        InputDecorator(
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: const Color(0xFF059669))
                : null,
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              isExpanded: true,
              isDense: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              items: effectiveItems.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(
                    opt,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required Color borderColor,
    int maxLines = 1,
    double? height,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefixIcon,
    Widget? suffix,
    void Function(String)? onChanged,
  }) {
    final inputWidget = TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        prefixIconConstraints: height != null
            ? const BoxConstraints(minWidth: 36, minHeight: 36)
            : null,
        suffix: suffix,
        isDense: height != null,
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
        contentPadding: height != null
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: height != null ? 12 : 11.5,
            fontWeight: height != null ? FontWeight.w600 : FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        SizedBox(height: height != null ? 6 : 5),
        height != null ? SizedBox(height: height, child: inputWidget) : inputWidget,
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

  Widget _buildSearchableSelectField<T>({
    required String label,
    required String displayText,
    required String placeholder,
    required IconData prefixIcon,
    required VoidCallback onTap,
    required bool hasValue,
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
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _isEditing ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasValue ? const Color(0xFF059669).withValues(alpha: 0.5) : borderColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  prefixIcon,
                  size: 16,
                  color: hasValue ? const Color(0xFF059669) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasValue ? displayText : placeholder,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (_isEditing)
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<T?> _showSearchablePicker<T>({
    required BuildContext context,
    required String title,
    required IconData titleIcon,
    required String searchHint,
    required List<T> items,
    required T? selectedItem,
    required String Function(T) labelBuilder,
    String Function(T)? subtitleBuilder,
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
          isDark: isDark,
        );
      },
    );
  }

  Future<List<T>?> _showMultiSearchablePicker<T>({
    required BuildContext context,
    required String title,
    required IconData titleIcon,
    required String searchHint,
    required List<T> items,
    required List<T> selectedItems,
    required String Function(T) labelBuilder,
    String Function(T)? subtitleBuilder,
    bool isDark = false,
  }) async {
    return showDialog<List<T>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return _MultiSearchablePickerDialog<T>(
          title: title,
          titleIcon: titleIcon,
          searchHint: searchHint,
          items: items,
          initialSelectedItems: selectedItems,
          labelBuilder: labelBuilder,
          subtitleBuilder: subtitleBuilder,
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
  final bool isDark;

  const _SearchablePickerDialog({
    required this.title,
    required this.titleIcon,
    required this.searchHint,
    required this.items,
    required this.selectedItem,
    required this.labelBuilder,
    this.subtitleBuilder,
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                children: [
                  Icon(widget.titleIcon, size: 20, color: const Color(0xFF059669)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    borderSide: const BorderSide(color: Color(0xFF059669)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: borderColor),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No matching items found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final isSelected = widget.selectedItem == item;
                        final label = widget.labelBuilder(item);
                        final subtitle = widget.subtitleBuilder != null ? widget.subtitleBuilder!(item) : null;

                        return InkWell(
                          onTap: () => Navigator.of(context).pop(item),
                          child: Container(
                            color: isSelected
                                ? (isDark ? const Color(0xFF059669).withValues(alpha: 0.15) : const Color(0xFF059669).withValues(alpha: 0.08))
                                : null,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        label,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF059669)
                                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                        ),
                                      ),
                                      if (subtitle != null && subtitle.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF059669)),
                              ],
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

class _MultiSearchablePickerDialog<T> extends StatefulWidget {
  final String title;
  final IconData titleIcon;
  final String searchHint;
  final List<T> items;
  final List<T> initialSelectedItems;
  final String Function(T) labelBuilder;
  final String Function(T)? subtitleBuilder;
  final bool isDark;

  const _MultiSearchablePickerDialog({
    required this.title,
    required this.titleIcon,
    required this.searchHint,
    required this.items,
    required this.initialSelectedItems,
    required this.labelBuilder,
    this.subtitleBuilder,
    this.isDark = false,
  });

  @override
  State<_MultiSearchablePickerDialog<T>> createState() => _MultiSearchablePickerDialogState<T>();
}

class _MultiSearchablePickerDialogState<T> extends State<_MultiSearchablePickerDialog<T>> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.from(widget.initialSelectedItems);
  }

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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Row(
                children: [
                  Icon(widget.titleIcon, size: 20, color: const Color(0xFF059669)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    borderSide: const BorderSide(color: Color(0xFF059669)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selected.length} of ${widget.items.length} selected',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selected.addAll(filtered);
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Select All',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  _selected.clear();
                                });
                              },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Clear',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: borderColor),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No matching items found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final isSelected = _selected.contains(item);
                        final label = widget.labelBuilder(item);
                        final subtitle = widget.subtitleBuilder != null ? widget.subtitleBuilder!(item) : null;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selected.remove(item);
                              } else {
                                _selected.add(item);
                              }
                            });
                          },
                          child: Container(
                            color: isSelected
                                ? (isDark ? const Color(0xFF059669).withValues(alpha: 0.15) : const Color(0xFF059669).withValues(alpha: 0.08))
                                : null,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: const Color(0xFF059669),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (_) {
                                    setState(() {
                                      if (isSelected) {
                                        _selected.remove(item);
                                      } else {
                                        _selected.add(item);
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        label,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF059669)
                                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                        ),
                                      ),
                                      if (subtitle != null && subtitle.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selected.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Done (${_selected.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
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
}

class _VariantPillChip extends StatefulWidget {
  final ProductVariant variant;
  final int index;
  final bool isSelected;
  final bool isDark;
  final bool isEditing;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VariantPillChip({
    required this.variant,
    required this.index,
    required this.isSelected,
    required this.isDark,
    required this.isEditing,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_VariantPillChip> createState() => _VariantPillChipState();
}

class _VariantPillChipState extends State<_VariantPillChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.variant;
    final isSelected = widget.isSelected;
    final isDark = widget.isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF059669)
                : (_isHovered
                    ? (isDark ? const Color(0xFF243044) : const Color(0xFFE2E8F0))
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF059669)
                  : (_isHovered
                      ? const Color(0xFF059669).withValues(alpha: 0.65)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF059669).withValues(alpha: 0.38)
                          : (isDark
                              ? Colors.black.withValues(alpha: 0.5)
                              : const Color(0xFF0F172A).withValues(alpha: 0.14)),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : (isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.22),
                          blurRadius: 5,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (v.isDefault) ...[
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: isSelected ? Colors.amberAccent : const Color(0xFFD97706),
                ),
                const SizedBox(width: 4),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  v.label.isNotEmpty ? v.label : 'Variant ${widget.index + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : (isDark ? Colors.black26 : Colors.white),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₹${v.displayRate.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF059669),
                  ),
                ),
              ),
              if (widget.canDelete) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: widget.onDelete,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: isSelected ? Colors.white70 : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSkuPillButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AddSkuPillButton({
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AddSkuPillButton> createState() => _AddSkuPillButtonState();
}

class _AddSkuPillButtonState extends State<_AddSkuPillButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF059669).withValues(alpha: 0.18)
                : const Color(0xFF059669).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF059669)
                  : const Color(0xFF059669).withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 15, color: Color(0xFF059669)),
              const SizedBox(width: 4),
              Text(
                'Add SKU',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
