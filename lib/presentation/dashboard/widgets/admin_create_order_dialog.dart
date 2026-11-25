import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/admin_user.dart';
import '../../../core/models/order.dart';
import '../../../core/models/product.dart';
import '../../../core/network/api_exception.dart';
import '../../../logic/order/order_bloc.dart';
import '../../../logic/order/order_event.dart';
import '../../../logic/product/product_bloc.dart';
import '../../../logic/product/product_event.dart';
import '../../../logic/product/product_state.dart';

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
  double get lineCodCharge => variant.codCharge * quantity;
}

class AdminCreateOrderDialog extends StatefulWidget {
  final AdminUser customer;

  const AdminCreateOrderDialog({
    super.key,
    required this.customer,
  });

  static Future<MarketplaceOrder?> show(
    BuildContext context, {
    required AdminUser customer,
  }) {
    return showDialog<MarketplaceOrder>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<ProductBloc>(),
        child: BlocProvider.value(
          value: context.read<OrderBloc>(),
          child: AdminCreateOrderDialog(customer: customer),
        ),
      ),
    );
  }

  @override
  State<AdminCreateOrderDialog> createState() => _AdminCreateOrderDialogState();
}

class _AdminCreateOrderDialogState extends State<AdminCreateOrderDialog> {
  final TextEditingController _searchController = TextEditingController();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _villageController;
  late final TextEditingController _address2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

  String _searchQuery = '';
  String _paymentMethod = 'PREPAID';
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
    if (!productBloc.state.hasProducts) {
      productBloc.add(const FetchProducts(page: 0, size: 100));
    }
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
      _paymentMethod == 'COD' ? _lines.fold(0.0, (sum, l) => sum + l.lineCodCharge) : 0.0;
  double get _grandTotal => _subtotal + _totalCodCharges;
  double get _totalSwg => _lines.fold(0.0, (sum, l) => sum + l.lineSwg);

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
        Navigator.of(context).pop(created);
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
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 960;

    return Dialog(
      backgroundColor: surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1120,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          children: [
            _buildHeader(isDark, border),
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                  ],
                ),
              ),
            Expanded(
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 11, child: _buildCatalogPane(isDark, cardBg, border)),
                        Container(width: 1, color: border),
                        Expanded(flex: 10, child: _buildPlanPane(isDark, cardBg, border)),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 360,
                            child: _buildCatalogPane(isDark, cardBg, border),
                          ),
                          Divider(height: 1, color: border),
                          _buildPlanPane(isDark, cardBg, border, shrinkWrap: true),
                        ],
                      ),
                    ),
            ),
            _buildFooter(isDark, border),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color border) {
    final fullName = '${widget.customer.firstName} ${widget.customer.lastName}'.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF059669), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Order for ${fullName.isNotEmpty ? fullName : widget.customer.phoneNumber}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.customer.phoneNumber}${widget.customer.shopName?.isNotEmpty == true ? ' • ${widget.customer.shopName}' : ''} • Direct Admin Order Plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogPane(bool isDark, Color cardBg, Color border) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. SELECT PRODUCTS & PACK SIZES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search catalog by product title, SKU, or technical name...',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              isDense: true,
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                final source = state.allCatalogProducts.isNotEmpty
                    ? state.allCatalogProducts
                    : state.products;
                final activeProducts = source.where((p) {
                  if (p.isDeleted || !p.isAvailable || p.variants.isEmpty) return false;
                  if (p.status.toUpperCase() != 'ACTIVE') return false;
                  if (_searchQuery.isEmpty) return true;
                  return p.title.toLowerCase().contains(_searchQuery) ||
                      p.sku.toLowerCase().contains(_searchQuery) ||
                      p.technicalName.toLowerCase().contains(_searchQuery) ||
                      p.variants.any((v) => v.sku.toLowerCase().contains(_searchQuery));
                }).toList();

                if (state.status == ProductStatus.loading && source.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (activeProducts.isEmpty) {
                  return Center(
                    child: Text(
                      source.isEmpty
                          ? 'No products loaded yet. Open Catalog once or refresh.'
                          : 'No matching active products found.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: activeProducts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = activeProducts[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (product.sellerName.isNotEmpty)
                                Text(
                                  product.sellerName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: product.variants.map((variant) {
                              final inCartQty = _lines
                                  .where((l) => l.variant.id == variant.id)
                                  .fold(0, (s, l) => s + l.quantity);
                              final outOfStock = variant.stock <= 0;
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
                                      color: inCartQty > 0
                                          ? const Color(0xFF059669)
                                          : border,
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanPane(bool isDark, Color cardBg, Color border, {bool shrinkWrap = false}) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. ORDER PLAN (${_lines.fold(0, (s, l) => s + l.quantity)} ITEMS)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
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
                'Click any variant on the left to add it to this customer\'s order.',
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
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
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
                  'Awaiting payment settlement',
                  Icons.payments_outlined,
                  isDark,
                  border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '4. SHIPPING ADDRESS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
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
        ],
      ),
    );
    return shrinkWrap ? content : SizedBox.expand(child: content);
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
    Color border,
  ) {
    final selected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF059669).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
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

  Widget _buildFooter(bool isDark, Color border) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Total: ₹${_grandTotal.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Items ₹${_subtotal.toStringAsFixed(0)}'
                '${_totalCodCharges > 0 ? ' + COD Fee ₹${_totalCodCharges.toStringAsFixed(0)}' : ''}'
                ' • Seller Will Get ₹${_totalSwg.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
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
                : const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(
              _isSubmitting ? 'Placing Order...' : 'Place Order',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
