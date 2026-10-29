import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/product.dart';
import '../../../core/models/seller.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../logic/product/product_bloc.dart';

class BulkAddProductsDialog extends StatefulWidget {
  final SellerProfile seller;
  final List<Product> catalogProducts;
  final Function(List<Product> products) onProductsAdded;

  const BulkAddProductsDialog({
    super.key,
    required this.seller,
    required this.catalogProducts,
    required this.onProductsAdded,
  });

  @override
  State<BulkAddProductsDialog> createState() => _BulkAddProductsDialogState();
}

class _BulkAddProductsDialogState extends State<BulkAddProductsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Catalog Tab State
  String _catalogSearchQuery = '';
  final Set<String> _selectedProductCodes = {};
  bool _hideAlreadyAssigned = false;
  List<Product> _allProducts = [];
  bool _isLoadingAllProducts = false;

  bool _isAlreadyAssigned(Product p) {
    if (p.sellerId.isNotEmpty && p.sellerId == widget.seller.id) return true;
    if (p.sellerName.isNotEmpty &&
        p.sellerName.trim().toLowerCase() == widget.seller.tradeName.trim().toLowerCase()) {
      return true;
    }
    if (p.vendor.isNotEmpty &&
        p.vendor.trim().toLowerCase() == widget.seller.tradeName.trim().toLowerCase()) {
      return true;
    }

    final targetTitle = p.title.trim().toLowerCase();
    final targetCode = p.productCode.toLowerCase();
    final targetSku = p.sku.toLowerCase();

    for (final ep in _allProducts) {
      final isSellerProduct = ep.sellerId == widget.seller.id ||
          (ep.sellerName.isNotEmpty &&
              ep.sellerName.trim().toLowerCase() == widget.seller.tradeName.trim().toLowerCase()) ||
          (ep.vendor.isNotEmpty &&
              ep.vendor.trim().toLowerCase() == widget.seller.tradeName.trim().toLowerCase());

      if (isSellerProduct) {
        if (targetTitle.isNotEmpty && ep.title.trim().toLowerCase() == targetTitle) {
          return true;
        }
        if (targetCode.isNotEmpty && ep.productCode.toLowerCase() == targetCode) {
          return true;
        }
        if (targetSku.isNotEmpty && ep.sku.toLowerCase() == targetSku) {
          return true;
        }
      }
    }
    return false;
  }

  // CSV Tab State
  final TextEditingController _csvTextController = TextEditingController();
  List<Product> _parsedCsvProducts = [];
  String? _csvParseError;

  static const String _sampleCsv = '''Title,Category,Price,MRP,Stock,Unit,HSN,TechnicalName
Bio-Neem 10000 PPM 1L,Bio-Pesticides,650,799,100,Litre,380891,Azadirachtin 1% EC
Krishi Organic Potash Granules 50kg,Organic Fertilizers,1250,1450,40,Bag,310520,Bio Potash 14.5%
Rhizobium Bio-Fertilizer 1L,Bio-Fertilizers,350,450,150,Litre,310100,Rhizobium Spp
Trichoderma Viride Bio-Fungicide 1kg,Bio-Fungicides,280,350,200,Kg,380892,Trichoderma Viride 1.5% WP
Humic Acid 98% Potassium Humate 1kg,Plant Growth Regulators,420,550,80,Kg,380893,Potassium Humate 98%''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _csvTextController.addListener(_onCsvTextChanged);
    _allProducts = List.from(widget.catalogProducts);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFullCatalog();
    });
  }

  Future<void> _loadFullCatalog() async {
    if (!mounted) return;
    try {
      final productBloc = context.read<ProductBloc>();
      if (productBloc.state.allCatalogProducts.isNotEmpty) {
        setState(() {
          _allProducts = productBloc.state.allCatalogProducts;
        });
        return;
      }
    } catch (_) {}

    setState(() => _isLoadingAllProducts = true);
    try {
      final repo = context.read<ProductRepository>();
      final fetched = await repo.getAllProducts();
      if (mounted && fetched.isNotEmpty) {
        setState(() {
          _allProducts = fetched;
          _isLoadingAllProducts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAllProducts = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _csvTextController.removeListener(_onCsvTextChanged);
    _csvTextController.dispose();
    super.dispose();
  }

  void _onCsvTextChanged() {
    final text = _csvTextController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _parsedCsvProducts = [];
        _csvParseError = null;
      });
      return;
    }
    _parseCsv(text);
  }

  void _parseCsv(String csvContent) {
    try {
      final lines = const LineSplitter().convert(csvContent).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.length <= 1) {
        setState(() {
          _parsedCsvProducts = [];
          _csvParseError = 'Please provide CSV headers and at least one data row.';
        });
        return;
      }

      final header = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
      final titleIdx = header.indexOf('title');
      final catIdx = header.indexOf('category');
      final priceIdx = header.indexOf('price');
      final mrpIdx = header.indexOf('mrp');
      final stockIdx = header.indexOf('stock');
      final unitIdx = header.indexOf('unit');
      final hsnIdx = header.indexOf('hsn');
      final techIdx = header.indexOf('technicalname');

      if (titleIdx == -1 || priceIdx == -1) {
        setState(() {
          _parsedCsvProducts = [];
          _csvParseError = 'CSV header must include at least "Title" and "Price" columns.';
        });
        return;
      }

      final List<Product> result = [];
      final now = DateTime.now();

      for (int i = 1; i < lines.length; i++) {
        final cols = lines[i].split(',').map((c) => c.trim()).toList();
        if (cols.length <= titleIdx || cols.length <= priceIdx) continue;

        final title = cols[titleIdx];
        if (title.isEmpty) continue;

        final price = double.tryParse(cols[priceIdx]) ?? 0.0;
        final mrp = (mrpIdx != -1 && cols.length > mrpIdx) ? (double.tryParse(cols[mrpIdx]) ?? price) : price;
        final cat = (catIdx != -1 && cols.length > catIdx && cols[catIdx].isNotEmpty) ? cols[catIdx] : 'Bio-Crop Solutions';
        final stock = (stockIdx != -1 && cols.length > stockIdx) ? (int.tryParse(cols[stockIdx]) ?? 50) : 50;
        final unit = (unitIdx != -1 && cols.length > unitIdx && cols[unitIdx].isNotEmpty) ? cols[unitIdx] : 'Unit';
        final hsn = (hsnIdx != -1 && cols.length > hsnIdx) ? cols[hsnIdx] : '380899';
        final tech = (techIdx != -1 && cols.length > techIdx) ? cols[techIdx] : title;

        final code = 'PRD-${widget.seller.id.substring(widget.seller.id.length > 4 ? widget.seller.id.length - 4 : 0).toUpperCase()}-${(1000 + i)}-${now.millisecondsSinceEpoch.toString().substring(10)}';

        result.add(Product(
          id: 'temp_${now.millisecondsSinceEpoch}_$i',
          sku: 'EBS-ADM-SKU-${now.millisecondsSinceEpoch + i}',
          productCode: code,
          hsnCode: hsn,
          sellerId: widget.seller.id,
          title: title,
          technicalName: tech,
          vendor: widget.seller.tradeName,
          sellerName: widget.seller.tradeName,
          description: '$title sourced and distributed by ${widget.seller.tradeName}. High purity agronomy standard.',
          images: const ['https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=600'],
          technicalContent: tech,
          modeOfAction: 'Broad spectrum contact and systemic action.',
          dosage: '2-3 ml per litre of water or as per crop advisory.',
          applicationMethod: 'Foliar spray / Soil application',
          category: cat,
          isAvailable: true,
          isFeatured: false,
          ratings: 4.8,
          refundPolicy: '7 Days Replacement',
          productWeight: 1.0,
          productWeightUnit: 'kg',
          displayRate: price,
          printedMrp: mrp,
          costPrice: price * 0.75,
          discountRs: (mrp > price) ? (mrp - price) : 0.0,
          unit: unit,
          stock: stock,
          status: 'ACTIVE',
        ));
      }

      setState(() {
        _parsedCsvProducts = result;
        _csvParseError = result.isEmpty ? 'No valid product rows parsed from CSV.' : null;
      });
    } catch (e) {
      setState(() {
        _parsedCsvProducts = [];
        _csvParseError = 'Error parsing CSV: $e';
      });
    }
  }

  Future<void> _pickCsvFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          final content = utf8.decode(bytes);
          _csvTextController.text = content;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load file: $e')),
        );
      }
    }
  }

  void _submitCatalogAssignment() {
    if (_selectedProductCodes.isEmpty) return;

    // Filter out already assigned products defensively
    final selected = _allProducts
        .where((p) => _selectedProductCodes.contains(p.productCode) && !_isAlreadyAssigned(p))
        .toList();
    if (selected.isEmpty) return;

    final List<Product> updatedProducts = [];
    final now = DateTime.now();
    final sellerCode = widget.seller.sellerCode.isNotEmpty
        ? widget.seller.sellerCode
        : (widget.seller.id.length > 6
            ? widget.seller.id.substring(widget.seller.id.length - 6).toUpperCase()
            : widget.seller.id.toUpperCase());

    for (int i = 0; i < selected.length; i++) {
      final base = selected[i];
      // Generate unique SKU and product code conforming to backend contract
      final uniqueSku = 'EBS-ADM-SKU-${now.millisecondsSinceEpoch + i}';
      final newProductCode = 'PRD-$sellerCode-${(1000 + i)}-${now.millisecondsSinceEpoch.toString().substring(10)}';

      updatedProducts.add(base.copyWith(
        id: 'assigned_${now.millisecondsSinceEpoch}_$i',
        sku: uniqueSku,
        productCode: newProductCode,
        sellerId: widget.seller.id,
        vendor: widget.seller.tradeName,
        sellerName: widget.seller.tradeName,
        status: 'INACTIVE',
        isAvailable: false,
      ));
    }

    widget.onProductsAdded(updatedProducts);
    Navigator.of(context).pop();
  }

  void _submitCsvBatch() {
    if (_parsedCsvProducts.isEmpty) return;
    widget.onProductsAdded(_parsedCsvProducts);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final dialogBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 920,
          maxHeight: screenSize.height * 0.88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.playlist_add_rounded, color: Color(0xFF059669), size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk Add Products for Seller',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Assigning to: ${widget.seller.tradeName} (ID: ${widget.seller.id})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF059669),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Navigation
            Container(
              color: surfaceColor,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF059669),
                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                indicatorColor: const Color(0xFF059669),
                indicatorWeight: 2.5,
                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.library_add_check_rounded, size: 18),
                    text: _allProducts.isNotEmpty
                        ? 'Assign from Master Catalog (${_allProducts.length})'
                        : 'Assign from Master Catalog',
                  ),
                  const Tab(icon: Icon(Icons.upload_file_rounded, size: 18), text: 'CSV / Batch Ingestion'),
                ],
              ),
            ),

            Divider(height: 1, color: borderColor),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCatalogTab(isDark, surfaceColor, borderColor),
                  _buildCsvTab(isDark, surfaceColor, borderColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 1: CATALOG MULTI-SELECT =================
  Widget _buildCatalogTab(bool isDark, Color surfaceColor, Color borderColor) {
    final filteredCatalog = _allProducts.where((p) {
      if (_hideAlreadyAssigned && _isAlreadyAssigned(p)) return false;
      if (_catalogSearchQuery.isEmpty) return true;
      final query = _catalogSearchQuery.toLowerCase();
      return p.title.toLowerCase().contains(query) ||
          p.productCode.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.sellerName.toLowerCase().contains(query) ||
          p.vendor.toLowerCase().contains(query);
    }).toList();

    final assignableProducts = filteredCatalog.where((p) => !_isAlreadyAssigned(p)).toList();
    final allAssignableSelected = assignableProducts.isNotEmpty &&
        assignableProducts.every((p) => _selectedProductCodes.contains(p.productCode));

    return Column(
      children: [
        // Controls Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: surfaceColor,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        onChanged: (val) => setState(() => _catalogSearchQuery = val.trim()),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search products by title, SKU, or category...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 16),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Select All / Deselect All (Restricted to assignable products only)
                  TextButton.icon(
                    onPressed: assignableProducts.isEmpty
                        ? null
                        : () {
                            setState(() {
                              if (allAssignableSelected) {
                                final codes = assignableProducts.map((p) => p.productCode).toSet();
                                _selectedProductCodes.removeWhere((c) => codes.contains(c));
                              } else {
                                _selectedProductCodes.addAll(assignableProducts.map((p) => p.productCode));
                              }
                            });
                          },
                    icon: Icon(
                      allAssignableSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                      size: 16,
                      color: assignableProducts.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF059669),
                    ),
                    label: Text(
                      allAssignableSelected
                          ? 'Deselect All'
                          : 'Select All (${assignableProducts.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: assignableProducts.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Filter and assignment stats
              Row(
                children: [
                  Checkbox(
                    value: _hideAlreadyAssigned,
                    activeColor: const Color(0xFF059669),
                    onChanged: (val) => setState(() => _hideAlreadyAssigned = val ?? false),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _hideAlreadyAssigned = !_hideAlreadyAssigned),
                    child: Text(
                      'Hide already assigned products',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoadingAllProducts) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFF059669)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Fetching complete catalog...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${assignableProducts.length} assignable • ${filteredCatalog.length - assignableProducts.length} assigned',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF059669),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        Divider(height: 1, color: borderColor),

        // Products List
        Expanded(
          child: filteredCatalog.isEmpty
              ? Center(
                  child: Text(
                    'No products found matching "$_catalogSearchQuery"',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredCatalog.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final p = filteredCatalog[index];
                    final isAssigned = _isAlreadyAssigned(p);
                    final isSelected = !isAssigned && _selectedProductCodes.contains(p.productCode);

                    return InkWell(
                      onTap: isAssigned
                          ? null
                          : () {
                              setState(() {
                                if (isSelected) {
                                  _selectedProductCodes.remove(p.productCode);
                                } else {
                                  _selectedProductCodes.add(p.productCode);
                                }
                              });
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isAssigned
                              ? (isDark
                                  ? const Color(0xFF059669).withValues(alpha: 0.05)
                                  : const Color(0xFFECFDF5).withValues(alpha: 0.45))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            if (isAssigned)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Tooltip(
                                  message: 'This product is already assigned to this seller and cannot be selected.',
                                  child: Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF059669)),
                                ),
                              )
                            else
                              Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFF059669),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedProductCodes.add(p.productCode);
                                    } else {
                                      _selectedProductCodes.remove(p.productCode);
                                    }
                                  });
                                },
                              ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (isAssigned ? const Color(0xFF059669) : const Color(0xFF2563EB)).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Icon(
                                  isAssigned ? Icons.verified_rounded : Icons.inventory_2_outlined,
                                  size: 18,
                                  color: isAssigned ? const Color(0xFF059669) : const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          p.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isAssigned
                                                ? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155))
                                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isAssigned) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF059669).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.verified_rounded, size: 11, color: Color(0xFF059669)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Already Assigned',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF059669),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isAssigned
                                        ? '${p.productCode} • ${p.category} • Already assigned to ${widget.seller.tradeName}'
                                        : '${p.productCode} • ${p.category} • Current Vendor: ${p.sellerName.isNotEmpty ? p.sellerName : (p.vendor.isNotEmpty ? p.vendor : "None")}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isAssigned
                                          ? const Color(0xFF059669)
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      fontWeight: isAssigned ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '₹${p.displayRate.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isAssigned
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Catalog Bottom Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Text(
                '${_selectedProductCodes.length} product${_selectedProductCodes.length == 1 ? '' : 's'} selected',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _selectedProductCodes.isEmpty ? null : _submitCatalogAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  'Assign ${_selectedProductCodes.length} Products to ${widget.seller.tradeName}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TAB 2: CSV / BATCH INGESTION =================
  Widget _buildCsvTab(bool isDark, Color surfaceColor, Color borderColor) {
    return Column(
      children: [
        // CSV Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: surfaceColor,
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _csvTextController.text = _sampleCsv,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF059669)),
                label: Text(
                  'Load Sample CSV',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF059669)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF059669)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickCsvFile,
                icon: Icon(Icons.attach_file_rounded, size: 16, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                label: Text(
                  'Upload .CSV File',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const Spacer(),
              if (_csvTextController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _csvTextController.clear(),
                  icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFFEF4444)),
                  label: Text(
                    'Clear',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444)),
                  ),
                ),
            ],
          ),
        ),

        Divider(height: 1, color: borderColor),

        // Text Field & Parser Preview
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Raw CSV Input Area
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CSV Raw Input (Header: Title,Category,Price,MRP,Stock,Unit,HSN,TechnicalName)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _csvTextController,
                            maxLines: null,
                            expands: true,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Paste CSV rows here or click "Load Sample CSV" above...',
                              hintStyle: GoogleFonts.jetBrainsMono(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Live Preview Panel
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _parsedCsvProducts.isNotEmpty ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            size: 16,
                            color: _parsedCsvProducts.isNotEmpty ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Parsed Preview (${_parsedCsvProducts.length} items)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_csvParseError != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _csvParseError!,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFFEF4444)),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _parsedCsvProducts.isEmpty
                            ? Center(
                                child: Text(
                                  'No parsed rows to display.\nPaste data or click "Load Sample CSV".',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _parsedCsvProducts.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final p = _parsedCsvProducts[index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              '${p.category} • ₹${p.displayRate.toStringAsFixed(0)}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF059669),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              'Stock: ${p.variants.isNotEmpty ? p.variants.first.stock : 50}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10.5,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // CSV Bottom Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Text(
                '${_parsedCsvProducts.length} valid product row${_parsedCsvProducts.length == 1 ? '' : 's'} ready',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _parsedCsvProducts.isEmpty ? null : _submitCsvBatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                ),
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(
                  'Import & Create ${_parsedCsvProducts.length} Products for ${widget.seller.tradeName}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
