import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/admin_user.dart';
import '../../../core/models/category.dart';
import '../../../core/models/order.dart';
import '../../../core/models/product.dart';
import '../../../core/network/api_exception.dart';
import '../../../logic/category/category_bloc.dart';
import '../../../logic/category/category_event.dart';
import '../../../logic/category/category_state.dart';
import '../../../logic/order/order_bloc.dart';
import '../../../logic/order/order_event.dart';
import '../../../logic/product/product_bloc.dart';
import '../../../logic/product/product_event.dart';
import '../../../logic/product/product_state.dart';
import '../widgets/app_product_image.dart';

class _OrderDraftLine {
  final Product product;
  final ProductVariant variant;
  int quantity;

  _OrderDraftLine({
    required this.product,
    required this.variant,
    this.quantity = 1,
  });

  double get lineTotal => variant.displayRate * quantity;
  double get lineSwg => variant.swg * quantity;
  double get lineCodCharge => 0.0;
}

class AdminCreateOrderView extends StatefulWidget {
  final AdminUser customer;
  final VoidCallback onBack;
  final ValueChanged<MarketplaceOrder?> onOrderCreated;

  const AdminCreateOrderView({
    super.key,
    required this.customer,
    required this.onBack,
    required this.onOrderCreated,
  });

  @override
  State<AdminCreateOrderView> createState() => _AdminCreateOrderViewState();
}

class _AdminCreateOrderViewState extends State<AdminCreateOrderView> {
  final TextEditingController _searchController = TextEditingController();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _villageController;
  late final TextEditingController _address2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  final TextEditingController _txRefController = TextEditingController();
  final TextEditingController _paymentNotesController = TextEditingController();
  final TextEditingController _customAdvancePctController = TextEditingController(text: '10');
  final TextEditingController _customAdvanceAmtController = TextEditingController();

  String _searchQuery = '';
  String _selectedSeller = 'ALL';
  String _selectedCategory = 'ALL';
  String _selectedSubCategory = 'ALL';
  String _stockFilter = 'ALL'; // ALL | IN_STOCK | OUT_OF_STOCK | IN_CART
  String _paymentMethod = 'PREPAID'; // PREPAID | PARTIAL
  bool _partialByAmount = false;
  double _advancePercentage = 10.0;
  double _advanceAmountOverride = 0.0;
  String _paymentChannel = 'UPI';
  bool _markAsPaid = true;
  DateTime _paidDate = DateTime.now();
  int _selectedAddressPreset = 0; // -1 for custom
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<_OrderDraftLine> _lines = [];
  late final List<UserAddress> _savedAddresses;

  @override
  void initState() {
    super.initState();
    _savedAddresses = [
      if (widget.customer.address != null &&
          widget.customer.address!.villageArea.trim().isNotEmpty)
        widget.customer.address!,
      ...widget.customer.shippingAddresses.where(
        (a) => a.villageArea.trim().isNotEmpty || a.pincode.trim().isNotEmpty,
      ),
    ];

    final fullName = '${widget.customer.firstName} ${widget.customer.lastName}'.trim();
    _nameController = TextEditingController(
      text: fullName.isNotEmpty ? fullName : (widget.customer.shopName ?? ''),
    );
    _phoneController = TextEditingController(text: widget.customer.phoneNumber);
    _villageController = TextEditingController();
    _address2Controller = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();

    if (_savedAddresses.isNotEmpty) {
      _applyAddressPreset(0);
    } else {
      _selectedAddressPreset = -1;
    }

    final productBloc = context.read<ProductBloc>();
    if (productBloc.state.allCatalogProducts.isEmpty) {
      productBloc.add(const FetchAllCatalogProducts());
    }
    if (!productBloc.state.hasProducts) {
      productBloc.add(const FetchProducts(page: 0, size: 100));
    }
    try {
      final categoryBloc = context.read<CategoryBloc>();
      if (categoryBloc.state.allCategories.isEmpty) {
        categoryBloc.add(const FetchCategories());
      }
    } catch (_) {}
  }

  void _applyAddressPreset(int index) {
    if (index < 0 || index >= _savedAddresses.length) return;
    final addr = _savedAddresses[index];
    _selectedAddressPreset = index;
    _villageController.text = addr.villageArea;
    _address2Controller.text = addr.address2;
    _cityController.text = addr.cityTehsil;
    _stateController.text = addr.state;
    _pincodeController.text = addr.pincode;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _txRefController.dispose();
    _paymentNotesController.dispose();
    _customAdvancePctController.dispose();
    _customAdvanceAmtController.dispose();
    super.dispose();
  }

  void _addVariant(Product product, ProductVariant variant) {
    if (variant.stock <= 0) {
      setState(() => _errorMessage = '${product.title} (${_variantLabel(variant)}) is out of stock.');
      return;
    }
    setState(() {
      _errorMessage = null;
      final existingIdx = _lines.indexWhere((l) => l.variant.id == variant.id);
      if (existingIdx >= 0) {
        final existing = _lines[existingIdx];
        if (existing.quantity < variant.stock) {
          existing.quantity++;
        } else {
          _errorMessage = 'Maximum available stock (${variant.stock}) reached for ${product.title}.';
        }
      } else {
        _lines.add(_OrderDraftLine(product: product, variant: variant, quantity: 1));
      }
    });
  }

  String _variantLabel(ProductVariant v) {
    if (v.label.trim().isNotEmpty) return v.label.trim();
    final base = '${v.packSize} ${v.unit}'.trim();
    return v.packQuantity > 1 ? '$base × ${v.packQuantity}' : base;
  }

  double get _subtotal => _lines.fold(0.0, (sum, l) => sum + l.lineTotal);
  double get _totalCodCharges =>
      _paymentMethod == 'PREPAID' ? 0.0 : _lines.fold(0.0, (sum, l) => sum + l.lineCodCharge);
  double get _grandTotal => _subtotal + _totalCodCharges;
  double get _advanceDue {
    if (_paymentMethod == 'PREPAID') return _subtotal;
    if (_paymentMethod != 'PARTIAL') return 0.0;
    if (_partialByAmount) return _advanceAmountOverride;
    return _subtotal * (_advancePercentage / 100.0);
  }
  double get _effectiveAdvancePct => _subtotal > 0
      ? ((_advanceDue / _subtotal) * 100.0).clamp(0.0, 100.0)
      : _advancePercentage;
  double get _codDueOnDelivery => _paymentMethod == 'PREPAID'
      ? 0.0
      : (_grandTotal - _advanceDue).clamp(0.0, _grandTotal);
  double get _totalSwg => _lines.fold(0.0, (sum, l) => sum + l.lineSwg);
  int get _totalUnits => _lines.fold(0, (s, l) => s + l.quantity);

  Future<void> _submitOrder() async {
    if (_lines.isEmpty) {
      setState(() => _errorMessage = 'Add at least one product to the order.');
      return;
    }
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final village = _villageController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (name.isEmpty || phone.isEmpty || village.isEmpty || city.isEmpty || state.isEmpty) {
      setState(() => _errorMessage = 'Please complete all required shipping address fields.');
      return;
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(pincode)) {
      setState(() => _errorMessage = 'Enter a valid 6-digit pincode.');
      return;
    }
    if (_paymentMethod == 'PARTIAL') {
      if (_partialByAmount) {
        if (_advanceAmountOverride <= 0 || _advanceAmountOverride >= _subtotal) {
          setState(() => _errorMessage =
              'Advance amount must be greater than ₹0 and less than items subtotal (₹${_subtotal.toStringAsFixed(0)}).');
          return;
        }
      } else if (_advancePercentage <= 0 || _advancePercentage >= 100) {
        setState(() => _errorMessage = 'Advance percentage must be between 1% and 99%.');
        return;
      }
    }
    final isOnlineOrPartial = _paymentMethod == 'PREPAID' || _paymentMethod == 'PARTIAL';
    if (isOnlineOrPartial && _markAsPaid && _txRefController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter the UTR / Transaction Reference for paid advance/prepaid orders.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final orderBloc = context.read<OrderBloc>();
      final idempotencyKey =
          'admin-${widget.customer.id}-${DateTime.now().microsecondsSinceEpoch}';
      final payload = {
        'paymentMethod': _paymentMethod,
        if (_paymentMethod == 'PARTIAL' && _partialByAmount)
          'advanceAmount': double.parse(_advanceAmountOverride.toStringAsFixed(2))
        else if (_paymentMethod == 'PARTIAL')
          'advancePercentage': _advancePercentage,
        if (isOnlineOrPartial)
          'prepaidPayment': {
            'paymentChannel': _paymentChannel,
            if (_txRefController.text.trim().isNotEmpty)
              'transactionReference': _txRefController.text.trim(),
            'markAsPaid': _markAsPaid,
            if (_markAsPaid) 'paidAt': _paidDate.toIso8601String(),
            if (_paymentNotesController.text.trim().isNotEmpty)
              'notes': _paymentNotesController.text.trim(),
          },
        'items': _lines
            .map((l) => {
                  'productId': l.product.id,
                  'variantId': l.variant.id,
                  'quantity': l.quantity,
                })
            .toList(),
        'shippingAddress': {
          'name': name,
          'phoneNumber': phone,
          'villageArea': village,
          if (_address2Controller.text.trim().isNotEmpty)
            'address2': _address2Controller.text.trim(),
          'cityTehsil': city,
          'state': state,
          'country': 'India',
          'pincode': pincode,
        },
      };

      final response = await orderBloc.apiClient.post(
        ApiEndpoints.adminCreateOrderForCustomer(widget.customer.id),
        body: payload,
        requiresAuth: true,
        extraHeaders: {'Idempotency-Key': idempotencyKey},
      );

      orderBloc.add(const LoadAdminOrders(page: 0, size: 50, isRefresh: true));
      final data = response['data'];
      final created = data is Map<String, dynamic>
          ? MarketplaceOrder.fromBackendJson(data)
          : (data is Map
              ? MarketplaceOrder.fromBackendJson(Map<String, dynamic>.from(data))
              : null);
      if (mounted) {
        widget.onOrderCreated(created);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1060;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBar(isDark, surface, border),
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                  onPressed: () => setState(() => _errorMessage = null),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 13,
                child: _buildCatalogSection(isDark, surface, cardBg, border),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 9,
                child: _buildOrderPlanSection(isDark, surface, cardBg, border),
              ),
            ],
          )
        else ...[
          _buildCatalogSection(isDark, surface, cardBg, border),
          const SizedBox(height: 18),
          _buildOrderPlanSection(isDark, surface, cardBg, border),
        ],
      ],
    );
  }

  Widget _buildTopBar(bool isDark, Color surface, Color border) {
    final fullName = '${widget.customer.firstName} ${widget.customer.lastName}'.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(
                  'Back to Customer Profile',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF059669), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Order for ${fullName.isNotEmpty ? fullName : widget.customer.phoneNumber}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Phone: ${widget.customer.phoneNumber}'
                    '${widget.customer.shopName?.isNotEmpty == true ? ' • ${widget.customer.shopName}' : ''}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_totalUnits item${_totalUnits == 1 ? '' : 's'} • ₹${_grandTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitOrder,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 17),
                label: Text(
                  _isSubmitting ? 'Placing Order...' : 'Place Order',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogSection(bool isDark, Color surface, Color cardBg, Color border) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          final source = state.allCatalogProducts.isNotEmpty
              ? state.allCatalogProducts
              : state.products;

          final orderableProducts = source.where((p) {
            if (p.isDeleted || p.variants.isEmpty) return false;
            return p.status.toUpperCase() == 'ACTIVE';
          }).toList();

          CategoryState? catState;
          try {
            catState = context.watch<CategoryBloc>().state;
          } catch (_) {}
          final categoryById = catState?.categoryById ?? const <String, CategoryItem>{};
          final rootCategories = (catState != null && catState.rootCategories.isNotEmpty)
              ? catState.rootCategories
              : (catState?.allCategories.where((c) => c.level == 0).toList() ?? const <CategoryItem>[]);
          final sortedRoots = [...rootCategories]..sort((a, b) => a.name.compareTo(b.name));

          final subCategoryList = _selectedCategory == 'ALL'
              ? (catState?.allCategories.where((c) => c.level > 0).toList() ?? const <CategoryItem>[])
              : (catState?.childrenByParentId[_selectedCategory] ?? const <CategoryItem>[]);
          final sortedSubs = [...subCategoryList]..sort((a, b) => a.name.compareTo(b.name));

          final sellers = <String>{
            for (final p in orderableProducts)
              if (p.sellerName.trim().isNotEmpty) p.sellerName.trim(),
          }.toList()
            ..sort();

          if (_selectedSeller != 'ALL' && !sellers.contains(_selectedSeller)) {
            _selectedSeller = 'ALL';
          }
          if (_selectedCategory != 'ALL' && !sortedRoots.any((c) => c.id == _selectedCategory)) {
            _selectedCategory = 'ALL';
          }
          if (_selectedSubCategory != 'ALL' && !sortedSubs.any((c) => c.id == _selectedSubCategory)) {
            _selectedSubCategory = 'ALL';
          }

          Set<String> productCategoryChain(Product p) {
            final ids = <String>{
              if (p.categoryId.trim().isNotEmpty) p.categoryId.trim(),
              ...p.subCategoryIds.map((e) => e.trim()).where((e) => e.isNotEmpty),
            };
            // Walk up parentId so leaf-only categoryId also matches its root/parent
            final frontier = ids.toList();
            while (frontier.isNotEmpty) {
              final id = frontier.removeLast();
              final parentId = categoryById[id]?.parentId;
              if (parentId != null && parentId.isNotEmpty && ids.add(parentId)) {
                frontier.add(parentId);
              }
            }
            return ids;
          }

          bool isProductInStock(Product p) =>
              p.isAvailable && p.variants.any((v) => v.stock > 0);
          final inStockCount = orderableProducts.where(isProductInStock).length;
          final outOfStockCount = orderableProducts.length - inStockCount;
          final inCartProductIds = _lines.map((l) => l.product.id).toSet();

          final filteredProducts = orderableProducts.where((p) {
            if (_selectedSeller != 'ALL' && p.sellerName.trim() != _selectedSeller) {
              return false;
            }
            if (_selectedCategory != 'ALL' || _selectedSubCategory != 'ALL') {
              final chain = productCategoryChain(p);
              if (_selectedCategory != 'ALL' && !chain.contains(_selectedCategory)) {
                return false;
              }
              if (_selectedSubCategory != 'ALL' && !chain.contains(_selectedSubCategory)) {
                return false;
              }
            }
            if (_stockFilter == 'IN_STOCK' && !isProductInStock(p)) {
              return false;
            }
            if (_stockFilter == 'OUT_OF_STOCK' && isProductInStock(p)) {
              return false;
            }
            if (_stockFilter == 'IN_CART' && !inCartProductIds.contains(p.id)) {
              return false;
            }
            if (_searchQuery.isEmpty) return true;
            return p.title.toLowerCase().contains(_searchQuery) ||
                p.sku.toLowerCase().contains(_searchQuery) ||
                p.productCode.toLowerCase().contains(_searchQuery) ||
                p.brandName.toLowerCase().contains(_searchQuery) ||
                p.technicalName.toLowerCase().contains(_searchQuery) ||
                p.variants.any((v) =>
                    v.sku.toLowerCase().contains(_searchQuery) ||
                    _variantLabel(v).toLowerCase().contains(_searchQuery));
          }).toList();

          final hasActiveFilter = _searchQuery.isNotEmpty ||
              _selectedSeller != 'ALL' ||
              _selectedCategory != 'ALL' ||
              _selectedSubCategory != 'ALL' ||
              _stockFilter != 'ALL';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '1. PRODUCT CATALOG (${filteredProducts.length} / ${orderableProducts.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  if (hasActiveFilter)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedSeller = 'ALL';
                          _selectedCategory = 'ALL';
                          _selectedSubCategory = 'ALL';
                          _stockFilter = 'ALL';
                        });
                      },
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 15),
                      label: Text(
                        'Clear Filters',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Refresh full catalog',
                    onPressed: () =>
                        context.read<ProductBloc>().add(const FetchAllCatalogProducts()),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search + Seller + Category Filter Toolbar (matching OrdersView style)
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 680;
                  final searchBox = SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by title, SKU, product code, brand, or technical name...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  );

                  final sellerDropdown = _buildToolbarDropdown(
                    icon: Icons.storefront_outlined,
                    value: _selectedSeller,
                    allLabel: 'All Sellers',
                    options: sellers,
                    isDark: isDark,
                    cardBg: cardBg,
                    border: border,
                    onChanged: (v) => setState(() => _selectedSeller = v),
                  );

                  final categoryDropdown = _buildIdDropdown(
                    icon: Icons.category_outlined,
                    value: _selectedCategory,
                    allLabel: 'All Categories',
                    items: [
                      for (final c in sortedRoots) MapEntry(c.id, c.name),
                    ],
                    isDark: isDark,
                    cardBg: cardBg,
                    border: border,
                    onChanged: (v) => setState(() {
                      _selectedCategory = v;
                      _selectedSubCategory = 'ALL';
                    }),
                  );

                  final subCategoryDropdown = _buildIdDropdown(
                    icon: Icons.subdirectory_arrow_right_rounded,
                    value: _selectedSubCategory,
                    allLabel: 'All Sub-Categories',
                    items: [
                      for (final c in sortedSubs) MapEntry(c.id, c.name),
                    ],
                    isDark: isDark,
                    cardBg: cardBg,
                    border: border,
                    onChanged: (v) => setState(() => _selectedSubCategory = v),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchBox,
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [sellerDropdown, categoryDropdown, subCategoryDropdown],
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: searchBox),
                          const SizedBox(width: 8),
                          sellerDropdown,
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [categoryDropdown, subCategoryDropdown],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              // Vibrant Stock / Cart Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill(
                      label: 'All Products',
                      count: orderableProducts.length,
                      color: const Color(0xFF059669),
                      selected: _stockFilter == 'ALL',
                      isDark: isDark,
                      surface: surface,
                      border: border,
                      onTap: () => setState(() => _stockFilter = 'ALL'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'In Stock',
                      count: inStockCount,
                      color: const Color(0xFF0D9488),
                      selected: _stockFilter == 'IN_STOCK',
                      isDark: isDark,
                      surface: surface,
                      border: border,
                      onTap: () => setState(() => _stockFilter = 'IN_STOCK'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'Out of Stock',
                      count: outOfStockCount,
                      color: const Color(0xFFE11D48),
                      selected: _stockFilter == 'OUT_OF_STOCK',
                      isDark: isDark,
                      surface: surface,
                      border: border,
                      onTap: () => setState(() => _stockFilter = 'OUT_OF_STOCK'),
                    ),
                    if (_lines.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        label: 'In Order Cart',
                        count: inCartProductIds.length,
                        color: const Color(0xFF4F46E5),
                        selected: _stockFilter == 'IN_CART',
                        isDark: isDark,
                        surface: surface,
                        border: border,
                        onTap: () => setState(() => _stockFilter = 'IN_CART'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (state.status == ProductStatus.loading && source.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredProducts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Center(
                    child: Text(
                      source.isEmpty
                          ? 'Loading products from catalog...'
                          : 'No active products match the selected filters.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: (MediaQuery.of(context).size.height - 320).clamp(420.0, 860.0),
                  child: ListView.separated(
                    itemCount: filteredProducts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(product, isDark, cardBg, border);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isDark, Color cardBg, Color border) {
    final thumbUrl = product.productImages.isNotEmpty
        ? (product.productImages.first.lowUrl.isNotEmpty
            ? product.productImages.first.lowUrl
            : product.productImages.first.midUrl)
        : (product.images.isNotEmpty ? product.images.first : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: thumbUrl.isNotEmpty
                      ? AppProductImage(imageUrl: thumbUrl, fit: BoxFit.cover)
                      : Container(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                          child: const Icon(Icons.inventory_2_outlined, size: 22),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (product.sellerName.isNotEmpty)
                          Text(
                            product.sellerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (product.category.isNotEmpty)
                          Text(
                            '• ${product.category}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        if (product.sku.isNotEmpty)
                          Text(
                            '• SKU: ${product.sku}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.variants.map((variant) {
              final inCartQty = _lines
                  .where((l) => l.variant.id == variant.id)
                  .fold(0, (s, l) => s + l.quantity);
              final outOfStock = !product.isAvailable || variant.stock <= 0;
              return InkWell(
                onTap: outOfStock ? null : () => _addVariant(product, variant),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: inCartQty > 0
                        ? const Color(0xFF059669).withValues(alpha: 0.12)
                        : (isDark ? const Color(0xFF0F172A) : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: inCartQty > 0 ? const Color(0xFF059669) : border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _variantLabel(variant),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: outOfStock
                              ? const Color(0xFF94A3B8)
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${variant.displayRate.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        outOfStock ? '(0 left)' : '(${variant.stock})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: outOfStock
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        inCartQty > 0 ? Icons.add_circle : Icons.add_circle_outline,
                        size: 16,
                        color: outOfStock
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF059669),
                      ),
                      if (inCartQty > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '$inCartQty',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPlanSection(bool isDark, Color surface, Color cardBg, Color border) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. ORDER PLAN ($_totalUnits UNITS)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          if (_lines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Text(
                'Select product pack sizes from the catalog to build this customer\'s order.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _lines.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: border),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lines[i].product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${_variantLabel(_lines[i].variant)} • ₹${_lines[i].variant.displayRate.toStringAsFixed(0)} each',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 18),
                            onPressed: () {
                              setState(() {
                                if (_lines[i].quantity > 1) {
                                  _lines[i].quantity--;
                                } else {
                                  _lines.removeAt(i);
                                }
                              });
                            },
                          ),
                          Text(
                            '${_lines[i].quantity}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            onPressed: () => _addVariant(_lines[i].product, _lines[i].variant),
                          ),
                          SizedBox(
                            width: 64,
                            child: Text(
                              '₹${_lines[i].lineTotal.toStringAsFixed(0)}',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 18),
          Text(
            '3. PAYMENT METHOD',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPaymentOption(
                  'PREPAID',
                  'Prepaid / Online',
                  _markAsPaid ? 'Full online payment' : 'Awaiting settlement',
                  Icons.payments_outlined,
                  isDark,
                  cardBg,
                  border,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPaymentOption(
                  'PARTIAL',
                  'Partial (Adv + COD)',
                  '${_effectiveAdvancePct.toStringAsFixed(0)}% advance + COD',
                  Icons.pie_chart_outline_rounded,
                  isDark,
                  cardBg,
                  border,
                ),
              ),
            ],
          ),
          if (_paymentMethod == 'PARTIAL') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.percent_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Text(
                        'PARTIAL ADVANCE SPLIT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const Spacer(),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(value: false, label: Text('By %')),
                          ButtonSegment<bool>(value: true, label: Text('By ₹')),
                        ],
                        selected: {_partialByAmount},
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStatePropertyAll(
                            GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        onSelectionChanged: (sel) {
                          setState(() {
                            _partialByAmount = sel.first;
                            if (_partialByAmount) {
                              _advanceAmountOverride =
                                  double.parse((_subtotal * (_advancePercentage / 100.0)).toStringAsFixed(0));
                              _customAdvanceAmtController.text = _advanceAmountOverride.toStringAsFixed(0);
                            } else {
                              _advancePercentage = _effectiveAdvancePct > 0 && _effectiveAdvancePct < 100
                                  ? double.parse(_effectiveAdvancePct.toStringAsFixed(2))
                                  : 10.0;
                              _customAdvancePctController.text = _advancePercentage.toStringAsFixed(0);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_partialByAmount) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customAdvanceAmtController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            onChanged: (v) {
                              final parsed = double.tryParse(v) ?? 0.0;
                              setState(() => _advanceAmountOverride = parsed);
                            },
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              labelText: 'Advance Amount Collected (₹)',
                              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                              prefixText: '₹ ',
                              suffixText: _subtotal > 0
                                  ? '${_effectiveAdvancePct.toStringAsFixed(1)}%'
                                  : null,
                              isDense: true,
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: border),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final pct in const [10.0, 20.0, 30.0, 50.0])
                                ChoiceChip(
                                  label: Text(
                                    '${pct.toInt()}% (₹${(_subtotal * (pct / 100.0)).toStringAsFixed(0)})',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
                                  selected: _advancePercentage == pct,
                                  selectedColor: const Color(0xFFD97706).withValues(alpha: 0.16),
                                  onSelected: (_) => setState(() {
                                    _advancePercentage = pct;
                                    _customAdvancePctController.text = pct.toInt().toString();
                                  }),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 86,
                          child: TextField(
                            controller: _customAdvancePctController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}\.?\d{0,2}')),
                            ],
                            onChanged: (v) {
                              final parsed = double.tryParse(v);
                              if (parsed != null && parsed > 0 && parsed < 100) {
                                setState(() => _advancePercentage = parsed);
                              }
                            },
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              suffixText: '%',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: border),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Advance Now: ₹${_advanceDue % 1 == 0 ? _advanceDue.toStringAsFixed(0) : _advanceDue.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                        Text(
                          'COD on Delivery: ₹${_codDueOnDelivery % 1 == 0 ? _codDueOnDelivery.toStringAsFixed(0) : _codDueOnDelivery.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_paymentMethod == 'PREPAID' || _paymentMethod == 'PARTIAL') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Text(
                        _paymentMethod == 'PARTIAL'
                            ? 'ADVANCE PAYMENT DETAILS'
                            : 'PREPAID PAYMENT DETAILS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      const Spacer(),
                      Switch.adaptive(
                        value: _markAsPaid,
                        activeThumbColor: const Color(0xFF059669),
                        onChanged: (v) => setState(() => _markAsPaid = v),
                      ),
                      Text(
                        _markAsPaid ? 'Paid' : 'Pending',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _markAsPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final ch in const [
                        MapEntry('UPI', 'UPI'),
                        MapEntry('BANK_TRANSFER', 'Bank Transfer / NEFT'),
                        MapEntry('RAZORPAY', 'Razorpay Link'),
                        MapEntry('CARD', 'Card'),
                        MapEntry('CASH', 'Cash Collected'),
                      ])
                        ChoiceChip(
                          label: Text(
                            ch.value,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                          selected: _paymentChannel == ch.key,
                          selectedColor: const Color(0xFF059669).withValues(alpha: 0.16),
                          onSelected: (_) => setState(() => _paymentChannel = ch.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _field(
                          _txRefController,
                          _markAsPaid ? 'UTR / Transaction Reference *' : 'Payment Link / Reference (optional)',
                          isDark ? const Color(0xFF0F172A) : Colors.white,
                          border,
                        ),
                      ),
                      if (_markAsPaid) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _paidDate,
                                firstDate: DateTime(2024),
                                lastDate: DateTime.now().add(const Duration(days: 1)),
                              );
                              if (picked != null && mounted) {
                                setState(() => _paidDate = picked);
                              }
                            },
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF059669)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Paid: ${_paidDate.day.toString().padLeft(2, '0')}/${_paidDate.month.toString().padLeft(2, '0')}/${_paidDate.year}',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _paymentNotesController,
                    'Payment Notes / Remarks (optional)',
                    isDark ? const Color(0xFF0F172A) : Colors.white,
                    border,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            '4. SHIPPING ADDRESS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          if (_savedAddresses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < _savedAddresses.length; i++)
                  ChoiceChip(
                    label: Text(
                      i == 0
                          ? 'Primary (${_savedAddresses[i].pincode})'
                          : 'Saved #${i + 1} (${_savedAddresses[i].pincode})',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    selected: _selectedAddressPreset == i,
                    onSelected: (_) => setState(() => _applyAddressPreset(i)),
                  ),
                ChoiceChip(
                  label: Text(
                    'Custom',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  selected: _selectedAddressPreset == -1,
                  onSelected: (_) => setState(() => _selectedAddressPreset = -1),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field(_nameController, 'Recipient Name *', cardBg, border)),
              const SizedBox(width: 10),
              Expanded(child: _field(_phoneController, 'Phone Number *', cardBg, border)),
            ],
          ),
          const SizedBox(height: 8),
          _field(_villageController, 'Village / Street / House No *', cardBg, border),
          const SizedBox(height: 8),
          _field(_address2Controller, 'Landmark / Address Line 2', cardBg, border),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(_cityController, 'City / Tehsil *', cardBg, border)),
              const SizedBox(width: 10),
              Expanded(child: _field(_stateController, 'State *', cardBg, border)),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: _field(
                  _pincodeController,
                  'Pincode *',
                  cardBg,
                  border,
                  digitsOnly: true,
                  maxLength: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                _summaryRow('Items Subtotal', '₹${_subtotal.toStringAsFixed(2)}', isDark),
                if (_totalCodCharges > 0) ...[
                  const SizedBox(height: 6),
                  _summaryRow('COD Fee', '₹${_totalCodCharges.toStringAsFixed(2)}', isDark),
                ],
                if (_paymentMethod == 'PARTIAL') ...[
                  const SizedBox(height: 6),
                  _summaryRow(
                    'Advance Now (${_effectiveAdvancePct.toStringAsFixed(1)}%)',
                    '₹${_advanceDue.toStringAsFixed(2)}',
                    isDark,
                  ),
                  const SizedBox(height: 6),
                  _summaryRow(
                    'Remaining COD on Delivery',
                    '₹${_codDueOnDelivery.toStringAsFixed(2)}',
                    isDark,
                  ),
                ],
                const SizedBox(height: 6),
                _summaryRow('Seller Will Get (SWG)', '₹${_totalSwg.toStringAsFixed(2)}', isDark),
                Divider(height: 18, color: border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '₹${_grandTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'Placing Order...' : 'Place Order',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
    Color cardBg,
    Color border,
  ) {
    final selected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF059669).withValues(alpha: 0.12) : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF059669) : border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? const Color(0xFF059669) : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? const Color(0xFF059669)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
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

  Widget _field(
    TextEditingController controller,
    String label,
    Color fill,
    Color border, {
    bool digitsOnly = false,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      inputFormatters: [
        if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
        isDense: true,
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
      ),
    );
  }

  Widget _buildIdDropdown({
    required IconData icon,
    required String value,
    required String allLabel,
    required List<MapEntry<String, String>> items,
    required bool isDark,
    required Color cardBg,
    required Color border,
    required ValueChanged<String> onChanged,
  }) {
    final isActive = value != 'ALL';
    final selectedLabel = isActive
        ? items.where((e) => e.key == value).map((e) => e.value).firstOrNull ?? allLabel
        : allLabel;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (ctx) => _SearchablePickerDialog(
            title: allLabel.replaceFirst('All ', 'Select '),
            allLabel: allLabel,
            items: items,
            selectedValue: value,
          ),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF059669).withValues(alpha: 0.08) : cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF059669) : border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive
                  ? const Color(0xFF059669)
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                selectedLabel,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
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
    );
  }

  Widget _buildToolbarDropdown({
    required IconData icon,
    required String value,
    required String allLabel,
    required List<String> options,
    required bool isDark,
    required Color cardBg,
    required Color border,
    required ValueChanged<String> onChanged,
  }) {
    final isActive = value != 'ALL';
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF059669).withValues(alpha: 0.08) : cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? const Color(0xFF059669) : border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isActive
                ? const Color(0xFF059669)
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: [
                DropdownMenuItem(value: 'ALL', child: Text(allLabel)),
                for (final opt in options)
                  DropdownMenuItem(
                    value: opt,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(opt, overflow: TextOverflow.ellipsis),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required Color color,
    required bool selected,
    required bool isDark,
    required Color surface,
    required Color border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color
              : (isDark ? const Color(0xFF1E293B) : surface),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: selected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.22)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchablePickerDialog extends StatefulWidget {
  final String title;
  final String allLabel;
  final List<MapEntry<String, String>> items;
  final String selectedValue;

  const _SearchablePickerDialog({
    required this.title,
    required this.allLabel,
    required this.items,
    required this.selectedValue,
  });

  @override
  State<_SearchablePickerDialog> createState() => _SearchablePickerDialogState();
}

class _SearchablePickerDialogState extends State<_SearchablePickerDialog> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
            .where((e) => e.value.toLowerCase().contains(_query))
            .toList();

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 440),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _queryController,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, size: 17),
                  isDense: true,
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      selected: widget.selectedValue == 'ALL',
                      selectedTileColor: const Color(0xFF059669).withValues(alpha: 0.1),
                      title: Text(
                        widget.allLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: widget.selectedValue == 'ALL'
                          ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF059669))
                          : null,
                      onTap: () => Navigator.of(context).pop('ALL'),
                    ),
                    const Divider(height: 8),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No matching options',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      )
                    else
                      for (final entry in filtered)
                        ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          selected: widget.selectedValue == entry.key,
                          selectedTileColor: const Color(0xFF059669).withValues(alpha: 0.1),
                          title: Text(
                            entry.value,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: widget.selectedValue == entry.key
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: widget.selectedValue == entry.key
                              ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF059669))
                              : null,
                          onTap: () => Navigator.of(context).pop(entry.key),
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
}
