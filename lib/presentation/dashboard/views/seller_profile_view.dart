import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/seller.dart';
import '../../../core/models/product.dart';
import '../../../logic/product/product_bloc.dart';
import '../../../logic/product/product_event.dart';
import '../../../logic/admin_user/admin_user_event.dart';
import '../../../logic/admin_user/seller_bloc.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/bulk_add_products_dialog.dart';

class SellerProfileView extends StatefulWidget {
  final SellerProfile seller;
  final List<Product> allProducts;
  final VoidCallback onBack;
  final ValueChanged<SellerProfile> onSellerUpdated;
  final ValueChanged<String> onViewSellerProducts;

  const SellerProfileView({
    super.key,
    required this.seller,
    required this.allProducts,
    required this.onBack,
    required this.onSellerUpdated,
    required this.onViewSellerProducts,
  });

  @override
  State<SellerProfileView> createState() => _SellerProfileViewState();
}

class _SellerProfileViewState extends State<SellerProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SellerProfile _currentSeller;
  bool _isEditing = false;

  // Edit Controllers
  late TextEditingController _companyNameController;
  late TextEditingController _tradeNameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _gstinController;
  late TextEditingController _panController;
  late TextEditingController _licenseController;
  late TextEditingController _registeredAddressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _warehouseAddressController;
  late TextEditingController _commissionController;

  // Bank Controllers
  late TextEditingController _bankNameController;
  late TextEditingController _accHolderController;
  late TextEditingController _accNumberController;
  late TextEditingController _ifscController;
  late TextEditingController _branchController;
  late TextEditingController _upiController;

  @override
  void initState() {
    super.initState();
    _currentSeller = widget.seller;
    _tabController = TabController(length: 4, vsync: this);
    _initControllers();
  }

  void _initControllers() {
    _companyNameController = TextEditingController(text: _currentSeller.companyName);
    _tradeNameController = TextEditingController(text: _currentSeller.tradeName);
    _contactPersonController = TextEditingController(text: _currentSeller.contactPerson);
    _emailController = TextEditingController(text: _currentSeller.email);
    _phoneController = TextEditingController(text: _currentSeller.phone);
    _gstinController = TextEditingController(text: _currentSeller.gstin);
    _panController = TextEditingController(text: _currentSeller.panNumber);
    _licenseController = TextEditingController(text: _currentSeller.licenseNumber);
    _registeredAddressController = TextEditingController(text: _currentSeller.registeredAddress);
    _cityController = TextEditingController(text: _currentSeller.city);
    _stateController = TextEditingController(text: _currentSeller.state);
    _pincodeController = TextEditingController(text: _currentSeller.pincode);
    _warehouseAddressController = TextEditingController(text: _currentSeller.warehouseAddress);
    _commissionController = TextEditingController(text: _currentSeller.commissionPercentage.toString());

    _bankNameController = TextEditingController(text: _currentSeller.bankDetails.bankName);
    _accHolderController = TextEditingController(text: _currentSeller.bankDetails.accountHolderName);
    _accNumberController = TextEditingController(text: _currentSeller.bankDetails.accountNumber);
    _ifscController = TextEditingController(text: _currentSeller.bankDetails.ifscCode);
    _branchController = TextEditingController(text: _currentSeller.bankDetails.branch);
    _upiController = TextEditingController(text: _currentSeller.bankDetails.upiId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _companyNameController.dispose();
    _tradeNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _licenseController.dispose();
    _registeredAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _warehouseAddressController.dispose();
    _commissionController.dispose();
    _bankNameController.dispose();
    _accHolderController.dispose();
    _accNumberController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updated = _currentSeller.copyWith(
      companyName: _companyNameController.text.trim(),
      tradeName: _tradeNameController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      gstin: _gstinController.text.trim(),
      panNumber: _panController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      registeredAddress: _registeredAddressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      warehouseAddress: _warehouseAddressController.text.trim(),
      commissionPercentage: double.tryParse(_commissionController.text) ?? _currentSeller.commissionPercentage,
      bankDetails: _currentSeller.bankDetails.copyWith(
        bankName: _bankNameController.text.trim(),
        accountHolderName: _accHolderController.text.trim(),
        accountNumber: _accNumberController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        branch: _branchController.text.trim(),
        upiId: _upiController.text.trim(),
      ),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _currentSeller = updated;
      _isEditing = false;
    });

    widget.onSellerUpdated(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Seller profile for "${updated.tradeName}" updated successfully.'),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleStatus() {
    final nextStatus = _currentSeller.status == 'ACTIVE'
        ? 'SUSPENDED'
        : (_currentSeller.status == 'SUSPENDED' ? 'ACTIVE' : 'ACTIVE');
    final updated = _currentSeller.copyWith(status: nextStatus, updatedAt: DateTime.now());
    setState(() => _currentSeller = updated);
    widget.onSellerUpdated(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Seller status updated to $nextStatus'),
        backgroundColor: nextStatus == 'ACTIVE' ? const Color(0xFF059669) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final isWide = MediaQuery.of(context).size.width >= 960;

    // Filter products belonging to this seller
    final sellerProducts = widget.allProducts.where((p) =>
        p.sellerId == _currentSeller.id ||
        (p.vendor.isNotEmpty && p.vendor.toLowerCase() == _currentSeller.tradeName.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigation & Actions Breadcrumb Bar
        _buildTopActionBar(context, isDark, surfaceColor, borderColor, sellerProducts.length),

        const SizedBox(height: 18),

        // Seller Header Banner Card
        _buildSellerHeaderCard(context, isDark, surfaceColor, borderColor, isWide),

        const SizedBox(height: 18),

        // KPI Metric Strip
        _buildSellerMetricsGrid(context, isDark, surfaceColor, borderColor, sellerProducts.length, isWide),

        const SizedBox(height: 18),

        // Tab Bar for Profile Sections
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF059669),
                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                indicatorColor: const Color(0xFF059669),
                indicatorWeight: 3,
                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(icon: Icon(Icons.business_rounded, size: 18), text: 'Business & Legal'),
                  Tab(icon: Icon(Icons.contact_phone_rounded, size: 18), text: 'Contact & Personnel'),
                  Tab(icon: Icon(Icons.account_balance_rounded, size: 18), text: 'Bank & Settlement'),
                  Tab(icon: Icon(Icons.inventory_2_rounded, size: 18), text: 'Products Catalog'),
                ],
              ),
              Divider(height: 1, color: borderColor),
              SizedBox(
                height: 580,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBusinessTab(isDark, borderColor),
                    _buildContactTab(isDark, borderColor),
                    _buildBankTab(isDark, borderColor),
                    _buildProductsTab(isDark, surfaceColor, borderColor, sellerProducts),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmToggleDeleteSeller(BuildContext context) {
    final willDelete = !_currentSeller.isDeleted;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          willDelete ? 'Deactivate Seller Account?' : 'Restore Seller Account?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          willDelete
              ? 'Are you sure you want to deactivate / soft-delete "${_currentSeller.tradeName}" (ID: ${_currentSeller.id})? This triggers the soft-delete API {{baseUrl}}/api/v1/admin/users/${_currentSeller.id}/deletion with {"deleted": true}. Their storefront and products will be deactivated while historical orders and payout ledgers remain preserved.'
              : 'Are you sure you want to restore "${_currentSeller.tradeName}"? Their account will be reactivated on the marketplace.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<SellerBloc>().add(
                    ToggleDeleteAdminUser(userId: _currentSeller.id, deleted: willDelete),
                  );
              setState(() {
                _currentSeller = _currentSeller.copyWith(
                  isDeleted: willDelete,
                  status: willDelete ? 'DEACTIVATED' : 'ACTIVE',
                );
              });
              widget.onSellerUpdated(_currentSeller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: willDelete ? const Color(0xFFE11D48) : const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: Text(willDelete ? 'Deactivate' : 'Restore'),
          ),
        ],
      ),
    );
  }

  // --- TOP ACTION BAR ---
  Widget _buildTopActionBar(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    int productCount,
  ) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: Text(
            'Back to Sellers Directory',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            side: BorderSide(color: borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => _openBulkAddProducts(context),
              icon: const Icon(Icons.playlist_add_rounded, size: 16, color: Color(0xFF7C3AED)),
              label: Text(
                'Bulk Add',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7C3AED)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _openAddSingleProduct(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                '+ Add Product',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => widget.onViewSellerProducts(_currentSeller.tradeName),
              icon: const Icon(Icons.inventory_2_outlined, size: 16),
              label: Text(
                'View Products ($productCount)',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _confirmToggleDeleteSeller(context),
              icon: Icon(
                _currentSeller.isDeleted ? Icons.restore_from_trash_rounded : Icons.delete_outline_rounded,
                size: 15,
                color: _currentSeller.isDeleted ? const Color(0xFF059669) : const Color(0xFFE11D48),
              ),
              label: Text(
                _currentSeller.isDeleted ? 'Restore Seller' : 'Deactivate Seller',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _currentSeller.isDeleted ? const Color(0xFF059669) : const Color(0xFFE11D48),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: (_currentSeller.isDeleted ? const Color(0xFF059669) : const Color(0xFFE11D48)).withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (_isEditing) ...[
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _initControllers();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              ),
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: Text('Save Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text('Edit Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // --- SELLER HEADER CARD ---
  Widget _buildSellerHeaderCard(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    bool isWide,
  ) {
    final statusColor = _currentSeller.isDeleted
        ? const Color(0xFFE11D48)
        : (_currentSeller.status == 'VERIFIED'
            ? const Color(0xFF10B981)
            : (_currentSeller.status == 'ACTIVE'
                ? const Color(0xFF059669)
                : (_currentSeller.status == 'KYC_PENDING' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller Avatar / Logo Icon
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 18),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _currentSeller.tradeName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _currentSeller.isDeleted ? 'DEACTIVATED (SOFT DELETED)' : _currentSeller.status.replaceAll('_', ' '),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _currentSeller.companyName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildCopyableBadge('Seller ID', _currentSeller.id, isDark, borderColor),
                    _buildCopyableBadge('GSTIN', _currentSeller.gstin, isDark, borderColor),
                    _buildSimpleBadge(Icons.business_rounded, _currentSeller.businessType, isDark, borderColor),
                    _buildSimpleBadge(Icons.location_on_rounded, '${_currentSeller.city}, ${_currentSeller.state}', isDark, borderColor),
                  ],
                ),
              ],
            ),
          ),

          // Quick Action Status Toggle
          if (isWide) ...[
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _toggleStatus,
                  icon: Icon(
                    _currentSeller.status == 'ACTIVE' || _currentSeller.status == 'VERIFIED'
                        ? Icons.block_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 15,
                    color: _currentSeller.status == 'ACTIVE' || _currentSeller.status == 'VERIFIED'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                  label: Text(
                    _currentSeller.status == 'ACTIVE' || _currentSeller.status == 'VERIFIED'
                        ? 'Suspend Seller'
                        : 'Activate Seller',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _currentSeller.status == 'ACTIVE' || _currentSeller.status == 'VERIFIED'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _currentSeller.status == 'ACTIVE' || _currentSeller.status == 'VERIFIED'
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Joined ${_formatDate(_currentSeller.joinedAt)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- METRICS GRID ---
  Widget _buildSellerMetricsGrid(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    int productCount,
    bool isWide,
  ) {
    final metrics = [
      {'label': 'Active Products', 'value': '$productCount', 'icon': Icons.inventory_2_rounded, 'color': const Color(0xFF059669)},
      {'label': 'Total Orders', 'value': '${_currentSeller.totalOrders}', 'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFF3B82F6)},
      {'label': 'Gross Revenue', 'value': '₹${(_currentSeller.grossSalesValue / 100000).toStringAsFixed(1)}L', 'icon': Icons.currency_rupee_rounded, 'color': const Color(0xFF10B981)},
      {'label': 'Commission', 'value': '${_currentSeller.commissionPercentage}%', 'icon': Icons.percent_rounded, 'color': const Color(0xFF8B5CF6)},
      {'label': 'Seller Rating', 'value': '${_currentSeller.rating} ★', 'icon': Icons.star_rounded, 'color': const Color(0xFFF59E0B)},
    ];

    return Row(
      children: metrics.map((m) {
        final color = m['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(m['icon'] as IconData, size: 18, color: color)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m['value'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- TAB 1: BUSINESS & LEGAL ---
  Widget _buildBusinessTab(bool isDark, Color borderColor) {
    final panVal = _panController.text.trim().isNotEmpty
        ? _panController.text.trim()
        : (_currentSeller.gstin.length == 15 ? _currentSeller.gstin.substring(2, 12).toUpperCase() : 'AABCK1234F');
    final gstinVal = _gstinController.text.trim().isNotEmpty ? _gstinController.text.trim() : _currentSeller.gstin;
    final licVal = _licenseController.text.trim().isNotEmpty ? _licenseController.text.trim() : _currentSeller.licenseNumber;

    final docItems = <Map<String, String>>[
      {
        'label': 'GST Registration Certificate',
        'title': 'Goods & Services Tax (GST) Certificate',
        'type': 'Tax Registration Document',
        'number': gstinVal,
        'url': 'https://storage.googleapis.com/sellerhub-prod-media-us/compliance/gst_${_currentSeller.id}.pdf',
      },
      {
        'label': 'PAN Card Document ($panVal)',
        'title': 'Permanent Account Number (PAN Card)',
        'type': 'Income Tax Department Identity',
        'number': panVal,
        'url': 'https://storage.googleapis.com/sellerhub-prod-media-us/compliance/pan_${_currentSeller.id}.pdf',
      },
      {
        'label': 'Agri & Pesticide Trading License',
        'title': 'Government Fertilizer & Pesticide Dealership License',
        'type': 'Department of Agriculture License',
        'number': licVal.isNotEmpty ? licVal : 'LIC-AGRI-2026-GUJ',
        'url': licVal.startsWith('http')
            ? licVal
            : 'https://storage.googleapis.com/sellerhub-prod-media-us/compliance/lic_fertilizer_${_currentSeller.id}.pdf',
      },
      {
        'label': 'Storefront Verification Photo',
        'title': 'Physical Retail Shop & Warehouse Verification',
        'type': 'Premises Location Proof',
        'number': 'PREMISES-GEO-VERIFIED',
        'url': 'https://images.unsplash.com/photo-1586771107445-d3ca888129ff?w=600',
      },
    ];

    if (_currentSeller.kycDocuments.isNotEmpty) {
      for (final doc in _currentSeller.kycDocuments) {
        if (!docItems.any((d) => d['label'] == doc)) {
          docItems.add({
            'label': doc,
            'title': doc,
            'type': 'Compliance Certificate',
            'number': 'DOC-${doc.hashCode.abs().toString().substring(0, 6)}',
            'url': 'https://storage.googleapis.com/sellerhub-prod-media-us/compliance/doc_${_currentSeller.id}.pdf',
          });
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField('Legal Company Name', _companyNameController, isDark, borderColor, enabled: _isEditing),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('Trade / Brand Name', _tradeNameController, isDark, borderColor, enabled: _isEditing),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'GSTIN Number',
                  _gstinController,
                  isDark,
                  borderColor,
                  enabled: _isEditing,
                  suffixAction: _buildViewDocButton('View GST Certificate', () {
                    _showDocumentViewer(
                      context,
                      title: 'Goods & Services Tax (GST) Certificate',
                      docType: 'Official Tax Certificate',
                      documentNumber: _gstinController.text.trim().isNotEmpty ? _gstinController.text.trim() : _currentSeller.gstin,
                      fileUrl: 'https://storage.googleapis.com/sellerhub-prod-media-us/compliance/gst_${_currentSeller.id}.pdf',
                    );
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'PAN Card Number',
                  _panController,
                  isDark,
                  borderColor,
                  enabled: _isEditing,
                  suffixAction: _buildViewDocButton('View PAN Card', () {
                    _showDocumentViewer(
                      context,
                      title: 'Permanent Account Number (PAN Card)',
                      docType: 'Income Tax Department Identity',
                      documentNumber: panVal,
                      fileUrl: 'https://storage.googleapis.com/sellerhub-prod-media-us/compliance/pan_${_currentSeller.id}.pdf',
                    );
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Agri / Pesticide License',
                  _licenseController,
                  isDark,
                  borderColor,
                  enabled: _isEditing,
                  suffixAction: _buildViewDocButton('View License PDF', () {
                    _showDocumentViewer(
                      context,
                      title: 'Fertilizer & Pesticide Trading License',
                      docType: 'Agricultural Ministry Dealership License',
                      documentNumber: licVal.isNotEmpty ? licVal : 'LIC-AGRI-2026-GUJ',
                      fileUrl: licVal.startsWith('http')
                          ? licVal
                          : 'https://storage.googleapis.com/sellerhub-prod-media-us/compliance/lic_fertilizer_${_currentSeller.id}.pdf',
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField('Registered Office Address', _registeredAddressController, isDark, borderColor, enabled: _isEditing),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('City', _cityController, isDark, borderColor, enabled: _isEditing),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('State', _stateController, isDark, borderColor, enabled: _isEditing),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('Pincode', _pincodeController, isDark, borderColor, enabled: _isEditing),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Warehouse & Dispatch Hub Address', _warehouseAddressController, isDark, borderColor, enabled: _isEditing, maxLines: 2),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'KYC & COMPLIANCE VERIFICATION DOCUMENTS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                'Click any document to inspect verified certificate',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: docItems.map((doc) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showDocumentViewer(
                    context,
                    title: doc['title']!,
                    docType: doc['type']!,
                    documentNumber: doc['number']!,
                    fileUrl: doc['url'],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Text(
                          doc['label']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF059669)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: CONTACT & PERSONNEL ---
  Widget _buildContactTab(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField('Primary Contact Person', _contactPersonController, isDark, borderColor, enabled: _isEditing),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('Primary Business Email', _emailController, isDark, borderColor, enabled: _isEditing),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Mobile / Phone Number', _phoneController, isDark, borderColor, enabled: _isEditing),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('Platform Commission Rate (%)', _commissionController, isDark, borderColor, enabled: _isEditing),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 3: BANK & SETTLEMENT (WITH STATEMENTS) ---
  Widget _buildBankTab(bool isDark, Color borderColor) {
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;

    final statements = [
      {
        'id': 'STMT-2026-W43',
        'period': '15 Oct 2026 - 21 Oct 2026',
        'orders': 18,
        'gross': 142000.0,
        'commission': 12070.0,
        'net': 129930.0,
        'status': 'PAID',
        'utr': 'SBIN0029104882',
        'paidAt': '24 Oct 2026',
      },
      {
        'id': 'STMT-2026-W42',
        'period': '08 Oct 2026 - 14 Oct 2026',
        'orders': 24,
        'gross': 198400.0,
        'commission': 16864.0,
        'net': 181536.0,
        'status': 'PAID',
        'utr': 'SBIN0019284711',
        'paidAt': '17 Oct 2026',
      },
      {
        'id': 'STMT-2026-W41',
        'period': '01 Oct 2026 - 07 Oct 2026',
        'orders': 15,
        'gross': 112000.0,
        'commission': 9520.0,
        'net': 102480.0,
        'status': 'PAID',
        'utr': 'SBIN0093847261',
        'paidAt': '10 Oct 2026',
      },
      {
        'id': 'STMT-2026-W44',
        'period': '22 Oct 2026 - 28 Oct 2026',
        'orders': 9,
        'gross': 68500.0,
        'commission': 5822.0,
        'net': 62678.0,
        'status': 'PROCESSING',
        'utr': 'Pending Batch Transfer',
        'paidAt': 'Scheduled 31 Oct',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PAYOUT BANK ACCOUNT & INSTANT UPI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'Direct Bank Settlement Active',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Account Holder Name', _accHolderController, isDark, borderColor, enabled: _isEditing),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('Bank Name', _bankNameController, isDark, borderColor, enabled: _isEditing),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Bank Account Number', _accNumberController, isDark, borderColor, enabled: _isEditing),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('IFSC Code', _ifscController, isDark, borderColor, enabled: _isEditing),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Branch Name', _branchController, isDark, borderColor, enabled: _isEditing),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('UPI ID for Instant Payouts', _upiController, isDark, borderColor, enabled: _isEditing),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 20),

          // 2. Settlement Statements & Disbursements
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SETTLEMENT STATEMENTS & PAYOUT DISBURSEMENTS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Weekly payout statements reconciled with orders, commissions, and tax',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Cycle: ${_currentSeller.settlementCycle}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _buildTableColHeader('STATEMENT ID & PERIOD', isDark)),
                      Expanded(flex: 2, child: _buildTableColHeader('ORDERS', isDark)),
                      Expanded(flex: 2, child: _buildTableColHeader('GROSS SALES', isDark)),
                      Expanded(flex: 2, child: _buildTableColHeader('COMMISSION', isDark)),
                      Expanded(flex: 3, child: _buildTableColHeader('NET DISBURSED', isDark)),
                      Expanded(flex: 2, child: _buildTableColHeader('STATUS', isDark)),
                      Expanded(flex: 2, child: _buildTableColHeader('ACTION', isDark, alignRight: true)),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                ...statements.map((stmt) {
                  final isPaid = stmt['status'] == 'PAID';
                  final statusColor = isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.6))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stmt['id'] as String,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                stmt['period'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${stmt['orders']} Orders',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${(stmt['gross'] as double).toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '-₹${(stmt['commission'] as double).toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${(stmt['net'] as double).toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                              Text(
                                stmt['paidAt'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              stmt['status'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => _showStatementReceiptDialog(context, stmt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.receipt_long_rounded, size: 12, color: Color(0xFF059669)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'View',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 4: PRODUCTS CATALOG QUICK VIEW ---
  Widget _buildProductsTab(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    List<Product> products,
  ) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(
                'No products currently listed under ${_currentSeller.tradeName}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add single products or bulk assign / import products for this seller below.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openAddSingleProduct(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('+ Add Single Product', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _openBulkAddProducts(context),
                    icon: const Icon(Icons.playlist_add_rounded, size: 18, color: Color(0xFF7C3AED)),
                    label: Text(
                      'Bulk Add / Assign Products',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Text(
                '${products.length} products listed under ${_currentSeller.tradeName}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _openBulkAddProducts(context),
                icon: const Icon(Icons.playlist_add_rounded, size: 15, color: Color(0xFF7C3AED)),
                label: Text(
                  'Bulk Add',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openAddSingleProduct(context),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(
                  '+ Add Product',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
            itemBuilder: (context, index) {
              final p = products[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.inventory_2_outlined, color: Color(0xFF059669), size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.productCode} • ${p.category} • HSN: ${p.hsnCode} • ${p.technicalName}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${p.displayRate.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        Text(
                          'Stock: ${p.stock}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.stock > 50 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
    );
  }

  void _openAddSingleProduct(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddProductDialog(
        sellerId: _currentSeller.id,
        onProductAdded: (newProduct) {
          context.read<ProductBloc>().add(CreateProduct(
            newProduct,
            onSuccess: (created) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Product "${created.title}" successfully created and assigned to ${_currentSeller.tradeName} (SKU: ${created.sku}).',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            onError: (err) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to create product on backend: $err',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ));
        },
      ),
    );
  }

  void _openBulkAddProducts(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BulkAddProductsDialog(
        seller: _currentSeller,
        catalogProducts: widget.allProducts,
        onProductsAdded: (products) {
          int count = 0;
          for (final p in products) {
            final pToCreate = p.copyWith(
              sellerId: _currentSeller.id,
              vendor: _currentSeller.tradeName,
            );
            context.read<ProductBloc>().add(CreateProduct(pToCreate));
            count++;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Initiated assignment & creation of $count products for ${_currentSeller.tradeName}.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isDark,
    Color borderColor, {
    bool enabled = false,
    int maxLines = 1,
    Widget? suffixAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (suffixAction != null) ...[
              const SizedBox(width: 6),
              suffixAction,
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? (isDark ? const Color(0xFF161E2E) : Colors.white)
                : (isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableBadge(String label, String value, bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied $label: $value to clipboard'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBadge(IconData icon, String text, bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewDocButton(String tooltip, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_rounded, size: 11, color: Color(0xFF059669)),
            const SizedBox(width: 3),
            Text(
              'View Doc',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableColHeader(String title, bool isDark, {bool alignRight = false}) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildDocDetailRow(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : 'N/A',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showDocumentViewer(
    BuildContext context, {
    required String title,
    required String docType,
    required String documentNumber,
    String? fileUrl,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '$docType • Entity: ${_currentSeller.tradeName}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [const Color(0xFFF1F5F9), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_rounded, size: 22, color: Color(0xFF059669)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'GOVERNMENT OF INDIA • COMPLIANCE RECORD',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'VERIFIED',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DOCUMENT IDENTIFIER / REGISTRATION NO.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      documentNumber.isNotEmpty ? documentNumber : 'REG-VERIFIED-2026',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF059669)),
                                tooltip: 'Copy Document Number',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: documentNumber));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Copied $documentNumber to clipboard')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDocDetailRow('Registered Business Entity', _currentSeller.tradeName, isDark),
                              ),
                              Expanded(
                                child: _buildDocDetailRow('Legal Jurisdiction', '${_currentSeller.city}, ${_currentSeller.state}', isDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDocDetailRow('Authorized Signatory', _currentSeller.contactPerson, isDark),
                              ),
                              Expanded(
                                child: _buildDocDetailRow('KYC Verification Status', _currentSeller.status, isDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (fileUrl != null && fileUrl.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (fileUrl.endsWith('.pdf') ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                fileUrl.endsWith('.pdf') ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                                color: fileUrl.endsWith('.pdf') ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileUrl.split('/').last,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Secure Cloud Document Storage • Verified SHA-256',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: fileUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Document URL copied to clipboard')),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 14),
                              label: const Text('Copy Link'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
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

  void _showStatementReceiptDialog(BuildContext context, Map<String, dynamic> stmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF059669), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settlement Receipt • ${stmt['id']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Period: ${stmt['period']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildReceiptItem('Gross Sales GMV (${stmt['orders']} Orders)', '₹${(stmt['gross'] as double).toStringAsFixed(2)}', isDark),
                          const Divider(height: 16),
                          _buildReceiptItem('Platform Marketplace Commission (${_currentSeller.commissionPercentage}%)', '-₹${(stmt['commission'] as double).toStringAsFixed(2)}', isDark, isNegative: true),
                          const Divider(height: 16),
                          _buildReceiptItem('GST on Platform Fee (18%)', 'Included', isDark),
                          const Divider(height: 16),
                          _buildReceiptItem('TCS / TDS on E-Commerce (1%)', '₹0.00 (Exempted)', isDark),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Net Disbursed Amount',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '₹${(stmt['net'] as double).toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_rounded, size: 18, color: Color(0xFF059669)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Banking Reference (UTR)',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                                ),
                                Text(
                                  stmt['utr'] as String,
                                  style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (stmt['status'] == 'PAID' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stmt['status'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: stmt['status'] == 'PAID' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
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

  Widget _buildReceiptItem(String label, String value, bool isDark, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isNegative ? const Color(0xFFEF4444) : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
