import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/seller.dart';
import '../../../core/models/product.dart';

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
                height: 520,
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

  // --- TOP ACTION BAR ---
  Widget _buildTopActionBar(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    int productCount,
  ) {
    return Row(
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
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => widget.onViewSellerProducts(_currentSeller.tradeName),
          icon: const Icon(Icons.inventory_2_outlined, size: 16),
          label: Text(
            'View Products ($productCount)',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 10),
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
          const SizedBox(width: 8),
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
    final statusColor = _currentSeller.status == 'VERIFIED'
        ? const Color(0xFF10B981)
        : (_currentSeller.status == 'ACTIVE'
            ? const Color(0xFF059669)
            : (_currentSeller.status == 'KYC_PENDING' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)));

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
                        _currentSeller.status.replaceAll('_', ' '),
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
                child: _buildTextField('GSTIN Number', _gstinController, isDark, borderColor, enabled: _isEditing),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('PAN Card Number', _panController, isDark, borderColor, enabled: _isEditing),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('Agri / Pesticide License', _licenseController, isDark, borderColor, enabled: _isEditing),
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
          Text(
            'KYC & COMPLIANCE VERIFICATION DOCUMENTS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _currentSeller.kycDocuments.map((doc) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text(
                      doc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
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

  // --- TAB 3: BANK & SETTLEMENT ---
  Widget _buildBankTab(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                'Add products on behalf of this seller from the Products tab.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
