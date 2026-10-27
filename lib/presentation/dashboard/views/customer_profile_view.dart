import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/admin_user.dart';
import '../../../core/models/order.dart';
import '../../../logic/admin_user/admin_user_event.dart';
import '../../../logic/admin_user/customer_bloc.dart';

class CustomerProfileView extends StatefulWidget {
  final AdminUser customer;
  final List<MarketplaceOrder> allOrders;
  final VoidCallback onBack;
  final ValueChanged<AdminUser> onCustomerUpdated;
  final ValueChanged<MarketplaceOrder>? onSelectOrder;

  const CustomerProfileView({
    super.key,
    required this.customer,
    this.allOrders = const [],
    required this.onBack,
    required this.onCustomerUpdated,
    this.onSelectOrder,
  });

  @override
  State<CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<CustomerProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdminUser _currentCustomer;
  bool _isEditing = false;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _shopNameController;
  late TextEditingController _villageAreaController;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _gstController;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _tabController = TabController(length: 4, vsync: this);
    _initControllers();
  }

  void _initControllers() {
    _firstNameController = TextEditingController(text: _currentCustomer.firstName);
    _lastNameController = TextEditingController(text: _currentCustomer.lastName);
    _phoneController = TextEditingController(text: _currentCustomer.phoneNumber);
    _emailController = TextEditingController(text: _currentCustomer.email ?? '');
    _shopNameController = TextEditingController(text: _currentCustomer.shopName ?? '');

    final addr = _currentCustomer.address;
    _villageAreaController = TextEditingController(text: addr?.villageArea ?? '');
    _address2Controller = TextEditingController(text: addr?.address2 ?? '');
    _cityController = TextEditingController(text: addr?.cityTehsil ?? '');
    _stateController = TextEditingController(text: addr?.state ?? '');
    _pincodeController = TextEditingController(text: addr?.pincode ?? '');
    _gstController = TextEditingController(text: _currentCustomer.gstNumber ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _shopNameController.dispose();
    _villageAreaController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedAddress = UserAddress(
      villageArea: _villageAreaController.text.trim(),
      address2: _address2Controller.text.trim(),
      cityTehsil: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
    );

    final updated = _currentCustomer.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      shopName: _shopNameController.text.trim().isNotEmpty ? _shopNameController.text.trim() : null,
      address: updatedAddress,
      gstNumber: _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _currentCustomer = updated;
      _isEditing = false;
    });

    widget.onCustomerUpdated(updated);
    context.read<CustomerBloc>().add(UpdateLocalAdminUser(updated));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Customer profile for "${updated.fullName}" updated successfully.'),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmToggleBlock() {
    final willBlock = !_currentCustomer.isBlocked;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          willBlock ? 'Block Customer Account?' : 'Unblock Customer Account?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          willBlock
              ? 'Are you sure you want to block ${_currentCustomer.fullName}? They will not be able to log in or place orders.'
              : 'Are you sure you want to unblock ${_currentCustomer.fullName}?',
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
              final updated = _currentCustomer.copyWith(isBlocked: willBlock, updatedAt: DateTime.now());
              setState(() => _currentCustomer = updated);
              widget.onCustomerUpdated(updated);
              context.read<CustomerBloc>().add(
                    ToggleBlockAdminUser(userId: _currentCustomer.id, blocked: willBlock),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: willBlock ? const Color(0xFFDC2626) : const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: Text(willBlock ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final isWide = MediaQuery.of(context).size.width >= 960;

    // Filter orders belonging to this customer
    final customerOrders = widget.allOrders.where((o) {
      final matchesPhone = o.shippingAddress.phone.contains(_currentCustomer.phoneNumber) ||
          _currentCustomer.phoneNumber.contains(o.shippingAddress.phone);
      final matchesName = o.company.toLowerCase().contains(_currentCustomer.fullName.toLowerCase()) ||
          o.shippingAddress.recipientName.toLowerCase().contains(_currentCustomer.fullName.toLowerCase());
      return matchesPhone || matchesName;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Action Bar
        _buildTopActionBar(context, isDark, surfaceColor, borderColor),

        const SizedBox(height: 18),

        // Customer Header Card
        _buildCustomerHeaderCard(context, isDark, surfaceColor, borderColor, isWide),

        const SizedBox(height: 18),

        // KPI Metric Strip
        _buildCustomerMetricsGrid(context, isDark, surfaceColor, borderColor, customerOrders, isWide),

        const SizedBox(height: 18),

        // Tab Bar Section
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
                  Tab(icon: Icon(Icons.badge_rounded, size: 18), text: 'Personal & Account'),
                  Tab(icon: Icon(Icons.location_on_rounded, size: 18), text: 'Delivery Addresses'),
                  Tab(icon: Icon(Icons.verified_user_rounded, size: 18), text: 'KYC & Compliance'),
                  Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Orders History'),
                ],
              ),
              Divider(height: 1, color: borderColor),
              SizedBox(
                height: 540,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPersonalTab(isDark, borderColor),
                    _buildAddressTab(isDark, borderColor),
                    _buildKycTab(isDark, borderColor),
                    _buildOrdersTab(isDark, surfaceColor, borderColor, customerOrders),
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
  ) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: Text(
            'Back to Customers Directory',
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

  // --- CUSTOMER HEADER CARD ---
  Widget _buildCustomerHeaderCard(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    bool isWide,
  ) {
    final statusColor = _currentCustomer.isBlocked
        ? const Color(0xFFDC2626)
        : (_currentCustomer.isVerified
            ? const Color(0xFF059669)
            : const Color(0xFFD97706));

    final statusText = _currentCustomer.isBlocked
        ? 'BLOCKED'
        : (_currentCustomer.isVerified ? 'VERIFIED BUYER' : 'UNVERIFIED');

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
          // Avatar
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
            child: Center(
              child: Text(
                _getInitials(_currentCustomer.fullName),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
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
                        _currentCustomer.fullName.isNotEmpty
                            ? _currentCustomer.fullName
                            : _currentCustomer.displayName,
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
                        statusText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_currentCustomer.shopName != null && _currentCustomer.shopName!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    _currentCustomer.shopName!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildCopyableBadge('Customer ID', _currentCustomer.id, isDark, borderColor),
                    _buildCopyableBadge('Phone', _currentCustomer.phoneNumber, isDark, borderColor),
                    _buildSimpleBadge(Icons.shield_outlined, _currentCustomer.role, isDark, borderColor),
                    if (_currentCustomer.address != null && _currentCustomer.address!.cityTehsil.isNotEmpty)
                      _buildSimpleBadge(
                        Icons.location_on_rounded,
                        '${_currentCustomer.address!.cityTehsil}, ${_currentCustomer.address!.state}',
                        isDark,
                        borderColor,
                      ),
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
                  onPressed: _confirmToggleBlock,
                  icon: Icon(
                    _currentCustomer.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                    size: 15,
                    color: _currentCustomer.isBlocked ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                  label: Text(
                    _currentCustomer.isBlocked ? 'Unblock Customer' : 'Block Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _currentCustomer.isBlocked ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _currentCustomer.isBlocked ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentCustomer.createdAt != null
                      ? 'Member since ${_currentCustomer.createdAt!.day}/${_currentCustomer.createdAt!.month}/${_currentCustomer.createdAt!.year}'
                      : '',
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

  // --- KPI METRICS GRID ---
  Widget _buildCustomerMetricsGrid(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    List<MarketplaceOrder> customerOrders,
    bool isWide,
  ) {
    final totalSpent = customerOrders.fold<double>(0.0, (acc, o) => acc + o.grandTotal);

    final cards = [
      _buildMetricCard(
        title: 'PHONE VERIFICATION',
        value: _currentCustomer.isVerified ? 'VERIFIED' : 'PENDING',
        subtitle: _currentCustomer.isVerified ? 'Mobile OTP verified' : 'OTP verification required',
        icon: Icons.verified_user_rounded,
        color: _currentCustomer.isVerified ? const Color(0xFF059669) : const Color(0xFFD97706),
        isDark: isDark,
        surfaceColor: surfaceColor,
        borderColor: borderColor,
      ),
      _buildMetricCard(
        title: 'PROFILE COMPLETION',
        value: _currentCustomer.isProfileComplete ? 'COMPLETE' : 'INCOMPLETE',
        subtitle: _currentCustomer.isProfileComplete ? 'Address & details saved' : 'Basic info missing',
        icon: Icons.assignment_turned_in_rounded,
        color: _currentCustomer.isProfileComplete ? const Color(0xFF2563EB) : const Color(0xFFD97706),
        isDark: isDark,
        surfaceColor: surfaceColor,
        borderColor: borderColor,
      ),
      _buildMetricCard(
        title: 'ORDERS PLACED',
        value: '${customerOrders.length}',
        subtitle: 'Total: ₹${totalSpent.toStringAsFixed(0)} spent',
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFF8B5CF6),
        isDark: isDark,
        surfaceColor: surfaceColor,
        borderColor: borderColor,
      ),
      _buildMetricCard(
        title: 'ACCOUNT STATUS',
        value: _currentCustomer.isBlocked ? 'BLOCKED' : 'ACTIVE',
        subtitle: _currentCustomer.isBlocked ? 'Login restricted by admin' : 'Full marketplace access',
        icon: _currentCustomer.isBlocked ? Icons.lock_rounded : Icons.check_circle_rounded,
        color: _currentCustomer.isBlocked ? const Color(0xFFDC2626) : const Color(0xFF059669),
        isDark: isDark,
        surfaceColor: surfaceColor,
        borderColor: borderColor,
      ),
    ];

    if (!isWide) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards.map((c) => SizedBox(width: (MediaQuery.of(context).size.width - 56) / 2, child: c)).toList(),
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c))).toList(),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: PERSONAL & ACCOUNT ---
  Widget _buildPersonalTab(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PERSONAL PROFILE', isDark),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _isEditing
                    ? _buildEditableField('First Name', _firstNameController, isDark, borderColor)
                    : _buildReadOnlyField('First Name', _currentCustomer.firstName, isDark, borderColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _isEditing
                    ? _buildEditableField('Last Name', _lastNameController, isDark, borderColor)
                    : _buildReadOnlyField('Last Name', _currentCustomer.lastName, isDark, borderColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _isEditing
                    ? _buildEditableField('Shop / Farm Name (Optional)', _shopNameController, isDark, borderColor)
                    : _buildReadOnlyField('Shop / Farm Name', _currentCustomer.shopName ?? 'Not specified', isDark, borderColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildReadOnlyField('System Role', _currentCustomer.role, isDark, borderColor),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _sectionTitle('CONTACT DETAILS', isDark),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _isEditing
                    ? _buildEditableField('Phone Number', _phoneController, isDark, borderColor)
                    : _buildReadOnlyField('Phone Number', _currentCustomer.phoneNumber, isDark, borderColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _isEditing
                    ? _buildEditableField('Email Address', _emailController, isDark, borderColor)
                    : _buildReadOnlyField('Email Address', _currentCustomer.email ?? 'No email on file', isDark, borderColor),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _sectionTitle('AUDIT & SYSTEM INFORMATION', isDark),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField('Customer ID', _currentCustomer.id, isDark, borderColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildReadOnlyField(
                  'Registration Date',
                  _currentCustomer.createdAt != null
                      ? _currentCustomer.createdAt!.toIso8601String()
                      : '—',
                  isDark,
                  borderColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildReadOnlyField(
                  'Last Updated',
                  _currentCustomer.updatedAt != null
                      ? _currentCustomer.updatedAt!.toIso8601String()
                      : '—',
                  isDark,
                  borderColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2: ADDRESSES & SHIPPING ---
  Widget _buildAddressTab(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PRIMARY BILLING & DELIVERY ADDRESS', isDark),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _isEditing
                    ? _buildEditableField('Village / Area / Street', _villageAreaController, isDark, borderColor)
                    : _buildReadOnlyField('Village / Area', _currentCustomer.address?.villageArea ?? '—', isDark, borderColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _isEditing
                    ? _buildEditableField('Address Line 2 (Landmark)', _address2Controller, isDark, borderColor)
                    : _buildReadOnlyField('Address Line 2', _currentCustomer.address?.address2 ?? '—', isDark, borderColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _isEditing
                    ? _buildEditableField('City / Tehsil', _cityController, isDark, borderColor)
                    : _buildReadOnlyField('City / Tehsil', _currentCustomer.address?.cityTehsil ?? '—', isDark, borderColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _isEditing
                    ? _buildEditableField('State', _stateController, isDark, borderColor)
                    : _buildReadOnlyField('State', _currentCustomer.address?.state ?? '—', isDark, borderColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _isEditing
                    ? _buildEditableField('Pincode', _pincodeController, isDark, borderColor)
                    : _buildReadOnlyField('Pincode', _currentCustomer.address?.pincode ?? '—', isDark, borderColor),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _sectionTitle('ADDITIONAL SHIPPING ADDRESSES', isDark),
          const SizedBox(height: 14),
          if (_currentCustomer.shippingAddresses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Text(
                    'No additional shipping addresses saved by this customer.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._currentCustomer.shippingAddresses.map((addr) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Color(0xFF059669), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            addr.formatted,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // --- TAB 3: KYC & COMPLIANCE ---
  Widget _buildKycTab(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('KYC & VERIFICATION STATUS', isDark),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField(
                  'KYC Complete',
                  _currentCustomer.isKycComplete ? 'Completed' : 'Pending Verification',
                  isDark,
                  borderColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildReadOnlyField(
                  'KYC Status',
                  _currentCustomer.kycStatus ?? 'Not submitted',
                  isDark,
                  borderColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _isEditing
                    ? _buildEditableField('GST Number', _gstController, isDark, borderColor)
                    : _buildReadOnlyField('GST Number', _currentCustomer.gstNumber ?? 'Not registered', isDark, borderColor),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _sectionTitle('DOCUMENTATION & IMAGES', isDark),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDocumentCard(
                  title: 'Fertilizer / Pest Licence',
                  imageUrl: _currentCustomer.licenceImage,
                  icon: Icons.assignment_outlined,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDocumentCard(
                  title: 'Shop / Farm Image',
                  imageUrl: _currentCustomer.shopImage,
                  icon: Icons.storefront_outlined,
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

  Widget _buildDocumentCard({
    required String title,
    required String? imageUrl,
    required IconData icon,
    required bool isDark,
    required Color borderColor,
  }) {
    final hasDoc = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF059669)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasDoc)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    imageUrl,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Text(
              'No document uploaded',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }

  // --- TAB 4: ORDERS & PURCHASE HISTORY ---
  Widget _buildOrdersTab(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    List<MarketplaceOrder> orders,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 44, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No orders recorded for this customer',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When this customer places orders across the marketplace, they will appear here.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
      itemBuilder: (context, index) {
        final order = orders[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_rounded, color: Color(0xFF059669), size: 18),
          ),
          title: Text(
            'Order #${order.orderNumber}',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          subtitle: Text(
            '${order.items.length} items • Seller: ${order.sellerName} • ${order.orderStatus}',
            style: GoogleFonts.plusJakartaSans(fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₹${order.grandTotal.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 10),
              if (widget.onSelectOrder != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  onPressed: () => widget.onSelectOrder!(order),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- HELPER WIDGETS ---
  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: const Color(0xFF059669),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF059669), width: 1.4),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableBadge(String label, String text, bool isDark, Color borderColor) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied to clipboard'),
            duration: const Duration(milliseconds: 1400),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
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
            Text(
              text,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.copy_rounded, size: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBadge(IconData icon, String text, bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF059669)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'CU';
    final parts = trimmed.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
