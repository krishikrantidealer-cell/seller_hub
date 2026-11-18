import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/admin_user.dart';
import '../../../core/models/order.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/india_location_helper.dart';
import '../../../domain/repositories/admin_user_repository.dart';
import '../../../logic/admin_user/admin_user_event.dart';
import '../../../logic/admin_user/customer_bloc.dart';

class CustomerProfileView extends StatefulWidget {
  final AdminUser customer;
  final List<MarketplaceOrder> allOrders;
  final VoidCallback onBack;
  final ValueChanged<AdminUser> onCustomerUpdated;
  final ValueChanged<MarketplaceOrder>? onSelectOrder;
  final bool isCreateMode;
  final ValueChanged<AdminUser>? onCustomerCreated;

  const CustomerProfileView({
    super.key,
    required this.customer,
    this.allOrders = const [],
    required this.onBack,
    required this.onCustomerUpdated,
    this.onSelectOrder,
    this.isCreateMode = false,
    this.onCustomerCreated,
  });

  @override
  State<CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<CustomerProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdminUser _currentCustomer;
  late bool _isCreating;
  bool _isEditing = false;
  bool _isSubmitting = false;
  String? _createErrorMessage;
  bool _isLookingUpPincode = false;
  bool _isLoadingCities = false;
  String? _pincodeStatusText;
  List<String> _extraPincodeCities = const [];
  final List<_CustomerShippingEntry> _shippingEntries = [];

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
    _isCreating = widget.isCreateMode || _currentCustomer.id.isEmpty;
    _isEditing = _isCreating;
    _tabController = TabController(length: 4, vsync: this);
    _initControllers();
    if (_isCreating) {
      IndiaLocationHelper.fetchStates().then((_) {
        if (mounted) setState(() {});
      });
    }
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
    _shippingEntries.clear();
    for (final s in _currentCustomer.shippingAddresses) {
      _shippingEntries.add(_CustomerShippingEntry.fromAddress(s));
    }
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
    for (final entry in _shippingEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isCreating) {
      if (_isSubmitting) return;
      final phone = _phoneController.text.trim();
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final finalPhone = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();
      final gstin = _gstController.text.trim().toUpperCase();

      String? validationError;
      if (firstName.isEmpty || lastName.isEmpty) {
        validationError = 'First Name and Last Name are required.';
      } else if (finalPhone.length != 10) {
        validationError = 'Please enter a valid 10-digit mobile number.';
      } else if (email.isNotEmpty && !RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(email)) {
        validationError = 'Please enter a valid email address.';
      } else if (gstin.isNotEmpty && gstin.length != 15) {
        validationError = 'GSTIN must be exactly 15 alphanumeric characters if provided.';
      }

      if (validationError != null) {
        setState(() => _createErrorMessage = validationError);
        return;
      }

      final village = _villageAreaController.text.trim();
      final addr2 = _address2Controller.text.trim();
      final city = _cityController.text.trim();
      final state = _stateController.text.trim();
      final pincode = _pincodeController.text.trim();

      final shippingList = _shippingEntries
          .where((e) => !e.isEmpty)
          .map((e) => e.toAddressMap())
          .toList();

      final payload = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': finalPhone,
        if (email.isNotEmpty) 'email': email,
        if (_shopNameController.text.trim().isNotEmpty) 'shopName': _shopNameController.text.trim(),
        if (gstin.isNotEmpty) 'gstNumber': gstin,
        if (village.isNotEmpty || addr2.isNotEmpty || city.isNotEmpty || state.isNotEmpty || pincode.isNotEmpty)
          'address': {
            if (village.isNotEmpty) 'villageArea': village,
            if (addr2.isNotEmpty) 'address2': addr2,
            if (city.isNotEmpty) 'cityTehsil': city,
            if (state.isNotEmpty) 'state': state,
            if (pincode.isNotEmpty) 'pincode': pincode,
            'country': 'India',
          },
        if (shippingList.isNotEmpty) 'shippingAddresses': shippingList,
      };

      setState(() {
        _isSubmitting = true;
        _createErrorMessage = null;
      });

      try {
        final repository = context.read<AdminUserRepository>();
        final created = await repository.createCustomer(payload);
        if (!mounted) return;
        context.read<CustomerBloc>().add(UpdateLocalAdminUser(created));
        context.read<CustomerBloc>().add(const InitializeAdminUsers(forceRefresh: true));
        setState(() {
          _currentCustomer = created;
          _isCreating = false;
          _isEditing = false;
          _isSubmitting = false;
        });
        widget.onCustomerCreated?.call(created);
        widget.onCustomerUpdated(created);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text('Customer "${created.fullName}" registered successfully!'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _createErrorMessage = e is ApiException
              ? e.message
              : e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
        });
      }
      return;
    }

    final village = _villageAreaController.text.trim();
    final addr2 = _address2Controller.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();

    final updatePayload = <String, dynamic>{
      if (_firstNameController.text.trim().isNotEmpty) 'firstName': _firstNameController.text.trim(),
      if (_lastNameController.text.trim().isNotEmpty) 'lastName': _lastNameController.text.trim(),
      if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim().toLowerCase(),
      if (_shopNameController.text.trim().isNotEmpty) 'shopName': _shopNameController.text.trim(),
      'gstNumber': _gstController.text.trim().toUpperCase(),
      if (village.isNotEmpty || addr2.isNotEmpty || city.isNotEmpty || state.isNotEmpty || pincode.isNotEmpty)
        'address': {
          if (village.isNotEmpty) 'villageArea': village,
          if (addr2.isNotEmpty) 'address2': addr2,
          if (city.isNotEmpty) 'cityTehsil': city,
          if (state.isNotEmpty) 'state': state,
          if (pincode.isNotEmpty) 'pincode': pincode,
          'country': 'India',
        },
    };

    try {
      final repository = context.read<AdminUserRepository>();
      final saved = await repository.updateUser(
        userId: _currentCustomer.id,
        data: updatePayload,
      );
      if (!mounted) return;
      setState(() {
        _currentCustomer = saved;
        _isEditing = false;
      });
      widget.onCustomerUpdated(saved);
      context.read<CustomerBloc>().add(UpdateLocalAdminUser(saved));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer profile for "${saved.fullName}" updated successfully.'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : 'Failed to update customer: $e'),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

        // If soft-deleted / in trash, show a prominent restoration banner
        if (_currentCustomer.isDeleted) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF881337).withValues(alpha: 0.25) : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFFBE123C).withValues(alpha: 0.5) : const Color(0xFFFECDD3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFE11D48)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This customer account is soft-deleted and placed in Trash',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFF9F1239),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'The user cannot log in or make purchases. Historical orders and data remain preserved. You can restore this account anytime.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFFFECDD3) : const Color(0xFFBE123C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _confirmToggleDelete(context),
                  icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
                  label: const Text('Restore Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Customer Header Card or Modern Create Form
        if (_isCreating)
          _buildCreateCustomerForm(isDark, surfaceColor, borderColor, isWide)
        else ...[
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
                    Tab(icon: Icon(Icons.business_center_rounded, size: 18), text: 'Business & Tax'),
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
      ],
    );
  }

  void _confirmToggleDelete(BuildContext context) {
    final willDelete = !_currentCustomer.isDeleted;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          willDelete ? 'Deactivate Customer Account?' : 'Restore Customer Account?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          willDelete
              ? 'Are you sure you want to deactivate / soft-delete "${_currentCustomer.fullName.isNotEmpty ? _currentCustomer.fullName : _currentCustomer.phoneNumber}"? This triggers the soft-delete API {{baseUrl}}/api/v1/admin/users/${_currentCustomer.id}/deletion with {"deleted": true}. Their access will be revoked while historical orders remain preserved.'
              : 'Are you sure you want to restore "${_currentCustomer.fullName.isNotEmpty ? _currentCustomer.fullName : _currentCustomer.phoneNumber}"? Their account will be reactivated on the marketplace.',
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
              context.read<CustomerBloc>().add(
                    ToggleDeleteAdminUser(userId: _currentCustomer.id, deleted: willDelete),
                  );
              setState(() {
                _currentCustomer = _currentCustomer.copyWith(isDeleted: willDelete);
              });
              widget.onCustomerUpdated(_currentCustomer);
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

  void _confirmPermanentDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 8),
            Text(
              'Permanently Delete Customer?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete "${_currentCustomer.fullName.isNotEmpty ? _currentCustomer.fullName : _currentCustomer.phoneNumber}" (ID: ${_currentCustomer.id}) from the database?',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                'Endpoint: DELETE /api/v1/admin/users/${_currentCustomer.id}/permanent\n\n'
                'Warning: This action is permanent and IRREVERSIBLE. All customer details and credentials will be permanently erased. Note: Accounts with existing orders cannot be permanently deleted.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF991B1B)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<CustomerBloc>().add(
                    PermanentlyDeleteAdminUser(_currentCustomer.id),
                  );
              widget.onBack();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
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
        if (_isCreating) ...[
          OutlinedButton(
            onPressed: widget.onBack,
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
            icon: const Icon(Icons.person_add_rounded, size: 16),
            label: Text('Create Customer Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ] else if (_isEditing) ...[
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
            onPressed: () => _confirmToggleDelete(context),
            icon: Icon(
              _currentCustomer.isDeleted ? Icons.restore_from_trash_rounded : Icons.delete_outline_rounded,
              size: 15,
              color: _currentCustomer.isDeleted ? const Color(0xFF059669) : const Color(0xFFE11D48),
            ),
            label: Text(
              _currentCustomer.isDeleted ? 'Restore Account' : 'Deactivate Account',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _currentCustomer.isDeleted ? const Color(0xFF059669) : const Color(0xFFE11D48),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: (_currentCustomer.isDeleted ? const Color(0xFF059669) : const Color(0xFFE11D48)).withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (_currentCustomer.isDeleted) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _confirmPermanentDelete(context),
              icon: const Icon(
                Icons.delete_forever_rounded,
                size: 15,
                color: Color(0xFFDC2626),
              ),
              label: Text(
                'Delete Forever',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2626),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
          const SizedBox(width: 8),
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
    final statusColor = _currentCustomer.isDeleted
        ? const Color(0xFFE11D48)
        : (_currentCustomer.isBlocked
            ? const Color(0xFFDC2626)
            : (_currentCustomer.isVerified
                ? const Color(0xFF059669)
                : const Color(0xFFD97706)));

    final statusText = _currentCustomer.isDeleted
        ? 'DEACTIVATED (SOFT DELETED)'
        : (_currentCustomer.isBlocked
            ? 'BLOCKED'
            : (_currentCustomer.isVerified ? 'VERIFIED BUYER' : 'UNVERIFIED'));

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
                        _isCreating
                            ? ((_firstNameController.text.trim().isNotEmpty || _lastNameController.text.trim().isNotEmpty)
                                ? '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim()
                                : 'Register New Customer')
                            : (_currentCustomer.fullName.isNotEmpty
                                ? _currentCustomer.fullName
                                : _currentCustomer.displayName),
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
                        color: (_isCreating ? const Color(0xFFF59E0B) : statusColor).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: (_isCreating ? const Color(0xFFF59E0B) : statusColor).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _isCreating ? 'NEW DRAFT' : statusText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _isCreating ? const Color(0xFFF59E0B) : statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isCreating) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Fill in buyer name, 10-digit mobile number, and delivery address to create a customer account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ] else if (_currentCustomer.shopName != null && _currentCustomer.shopName!.isNotEmpty) ...[
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
                if (_isCreating)
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildSimpleBadge(Icons.person_rounded, 'Role: ROLE_CUSTOMER', isDark, borderColor),
                      _buildSimpleBadge(Icons.verified_user_outlined, 'Status: Active on creation', isDark, borderColor),
                    ],
                  )
                else
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
          if (isWide && !_isCreating) ...[
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
                    : _buildReadOnlyField('Phone Number', _currentCustomer.phoneNumber, isDark, borderColor, copyable: true),
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

  // --- TAB 3: BUSINESS & TAX ---
  Widget _buildKycTab(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('TAX & VERIFICATION', isDark),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField(
                  'Phone Verified',
                  _currentCustomer.isVerified ? 'Verified' : 'Unverified',
                  isDark,
                  borderColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildReadOnlyField(
                  'Profile Completed',
                  _currentCustomer.isProfileComplete ? 'Completed' : 'Incomplete',
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
          _sectionTitle('SHOP IMAGE', isDark),
          const SizedBox(height: 14),
          _buildDocumentCard(
            title: 'Shop / Farm Image',
            imageUrl: _currentCustomer.shopImage,
            icon: Icons.storefront_outlined,
            isDark: isDark,
            borderColor: borderColor,
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

  Widget _buildReadOnlyField(String label, String value, bool isDark, Color borderColor, {bool copyable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            if (copyable && value.isNotEmpty && value != '—')
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied $label: $value to clipboard'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded, size: 11, color: Color(0xFF059669)),
                      const SizedBox(width: 3),
                      Text(
                        'Copy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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

  Widget _buildCreateCustomerForm(bool isDark, Color surfaceColor, Color borderColor, bool isWide) {
    final firstReady = _firstNameController.text.trim().isNotEmpty;
    final lastReady = _lastNameController.text.trim().isNotEmpty;
    final phoneDigits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final phoneReady = phoneDigits.length == 10;
    final readyCount = [firstReady, lastReady, phoneReady].where((e) => e).length;

    final selectedState = IndiaLocationHelper.normalizeState(_stateController.text);
    final stateOptions = IndiaLocationHelper.states;
    final effectiveState = stateOptions.contains(selectedState) ? selectedState : null;
    final cityOptions = effectiveState != null
        ? IndiaLocationHelper.cachedCitiesForState(
            effectiveState,
            extraCities: [
              ..._extraPincodeCities,
              if (_cityController.text.trim().isNotEmpty) _cityController.text.trim(),
            ],
          )
        : <String>[];
    final currentCity = _cityController.text.trim();
    final effectiveCity = cityOptions.contains(currentCity) ? currentCity : null;

    InputDecoration dropdownDecoration(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
          filled: true,
          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Onboarding Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F2922), const Color(0xFF161E2E)]
                  : [const Color(0xFFECFDF5), const Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF059669).withValues(alpha: isDark ? 0.35 : 0.25),
            ),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _firstNameController.text.trim().isNotEmpty
                                ? '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim()
                                : 'New Customer Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'NEW CUSTOMER',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Register a customer with personal details, login credentials, primary address, and delivery addresses.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: readyCount == 3
                        ? const Color(0xFF059669).withValues(alpha: 0.5)
                        : borderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      readyCount == 3 ? Icons.check_circle_rounded : Icons.fact_check_outlined,
                      size: 17,
                      color: readyCount == 3 ? const Color(0xFF059669) : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$readyCount / 3 Required Fields Ready',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_createErrorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.16 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _createErrorMessage!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _createErrorMessage = null),
                  icon: const Icon(Icons.close_rounded, size: 17, color: Color(0xFFEF4444)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Row 1: Customer Details + Primary Address
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCreateCustomerDetailsCard(isDark, surfaceColor, borderColor)),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCreateCustomerAddressCard(
                  isDark,
                  surfaceColor,
                  borderColor,
                  effectiveState,
                  stateOptions,
                  effectiveCity,
                  cityOptions,
                  dropdownDecoration,
                ),
              ),
            ],
          )
        else ...[
          _buildCreateCustomerDetailsCard(isDark, surfaceColor, borderColor),
          const SizedBox(height: 16),
          _buildCreateCustomerAddressCard(
            isDark,
            surfaceColor,
            borderColor,
            effectiveState,
            stateOptions,
            effectiveCity,
            cityOptions,
            dropdownDecoration,
          ),
        ],
        const SizedBox(height: 16),

        // Row 2: Shipping / Delivery Addresses (Optional)
        _buildCreateCustomerShippingCard(isDark, surfaceColor, borderColor),
        const SizedBox(height: 20),

        // Bottom Action Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : widget.onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _saveChanges,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'Creating...' : 'Create Customer Account',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateCustomerSection({
    required IconData icon,
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Widget child,
  }) {
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
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF059669)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stepNumber,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCreateInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required Color borderColor,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: (v) {
            setState(() {});
            onChanged?.call(v);
          },
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateCustomerDetailsCard(bool isDark, Color surfaceColor, Color borderColor) {
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final phoneValid = digits.length == 10;

    return _buildCreateCustomerSection(
      icon: Icons.person_outline_rounded,
      stepNumber: '01',
      title: 'Customer & Account Details',
      subtitle: 'Identity, contact credentials, and optional business info',
      isDark: isDark,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCreateInput(
                  controller: _firstNameController,
                  label: 'First Name *',
                  hint: 'e.g. Ramesh',
                  prefixIcon: Icons.badge_outlined,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCreateInput(
                  controller: _lastNameController,
                  label: 'Last Name *',
                  hint: 'e.g. Patel',
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mobile Number *',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                  ),
                  Text(
                    '${digits.length} / 10 digits',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: phoneValid ? const Color(0xFF059669) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: '10-digit mobile number',
                  prefixText: '+91  ',
                  prefixStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: phoneValid ? const Color(0xFF059669) : borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCreateInput(
            controller: _emailController,
            label: 'Email Address (Optional)',
            hint: 'customer@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCreateInput(
                  controller: _shopNameController,
                  label: 'Shop / Farm Name (Optional)',
                  hint: 'e.g. Kisan Agro Center',
                  prefixIcon: Icons.storefront_outlined,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCreateInput(
                  controller: _gstController,
                  label: 'GSTIN (Optional)',
                  hint: '15-char GSTIN',
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(15),
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
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

  Future<void> _onCustomerPincodeChanged(String val) async {
    final clean = val.trim();
    if (clean.length != 6) {
      if (_pincodeStatusText != null || _isLookingUpPincode) {
        setState(() {
          _isLookingUpPincode = false;
          _pincodeStatusText = null;
        });
      }
      return;
    }
    setState(() {
      _isLookingUpPincode = true;
      _pincodeStatusText = null;
    });
    final result = await IndiaLocationHelper.lookupPincode(clean);
    if (!mounted || _pincodeController.text.trim() != clean) return;
    setState(() {
      _isLookingUpPincode = false;
      if (result != null) {
        _stateController.text = result.state;
        _extraPincodeCities = result.cities;
        _cityController.text = result.primaryCity;
        _pincodeStatusText = 'Auto-filled: ${result.primaryCity}, ${result.state}';
      } else {
        _pincodeStatusText = 'PIN not found — select State & City manually';
      }
    });
  }

  Future<void> _onCustomerStateSelected(String val) async {
    setState(() {
      _stateController.text = val;
      _cityController.text = '';
      _extraPincodeCities = const [];
      _isLoadingCities = true;
    });
    await IndiaLocationHelper.fetchCitiesForState(val);
    if (!mounted || _stateController.text != val) return;
    setState(() => _isLoadingCities = false);
  }

  Widget _buildCreateCustomerAddressCard(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    String? effectiveState,
    List<String> stateOptions,
    String? effectiveCity,
    List<String> cityOptions,
    InputDecoration Function(String hint, IconData icon) dropdownDecoration,
  ) {
    return _buildCreateCustomerSection(
      icon: Icons.location_on_outlined,
      stepNumber: '02',
      title: 'Primary Address',
      subtitle: 'Enter 6-digit PIN Code to auto-fetch State & City, or select manually',
      isDark: isDark,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      child: Column(
        children: [
          _buildCreateInput(
            controller: _pincodeController,
            label: 'PIN Code (Auto-Fetch)',
            hint: 'e.g. 462001',
            prefixIcon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: _onCustomerPincodeChanged,
            isDark: isDark,
            borderColor: borderColor,
          ),
          if (_pincodeStatusText != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _pincodeStatusText!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF059669),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'State',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: effectiveState,
                      isExpanded: true,
                      decoration: dropdownDecoration('Select State', Icons.map_outlined),
                      items: stateOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) _onCustomerStateSelected(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'City / Tehsil',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: effectiveCity,
                      isExpanded: true,
                      decoration: dropdownDecoration(
                        _isLoadingCities ? 'Loading...' : 'Select City',
                        Icons.location_city_outlined,
                      ),
                      items: cityOptions
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _cityController.text = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCreateInput(
            controller: _villageAreaController,
            label: 'Street / Village / Area',
            hint: 'House / Plot / Village / Road',
            prefixIcon: Icons.home_outlined,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 14),
          _buildCreateInput(
            controller: _address2Controller,
            label: 'Landmark / Address 2 (Optional)',
            hint: 'Near landmark or locality',
            isDark: isDark,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCustomerShippingCard(bool isDark, Color surfaceColor, Color borderColor) {
    return _buildCreateCustomerSection(
      icon: Icons.local_shipping_outlined,
      stepNumber: '03',
      title: 'Shipping / Delivery Addresses (Optional)',
      subtitle: 'Add one or more delivery addresses for orders',
      isDark: isDark,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_shippingEntries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No extra shipping addresses added. Click "Add Shipping Address" if different from primary address.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _shippingEntries.add(_CustomerShippingEntry())),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Shipping Address'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: BorderSide(color: const Color(0xFF059669).withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            for (int i = 0; i < _shippingEntries.length; i++) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Text(
                          'Shipping Address #${i + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              final removed = _shippingEntries.removeAt(i);
                              removed.dispose();
                            });
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildCreateInput(
                            controller: _shippingEntries[i].villageAreaController,
                            label: 'Street / Village / Area',
                            hint: 'House / Plot / Road',
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCreateInput(
                            controller: _shippingEntries[i].address2Controller,
                            label: 'Landmark / Address 2',
                            hint: 'Optional',
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
                          child: _buildCreateInput(
                            controller: _shippingEntries[i].pincodeController,
                            label: 'PIN Code',
                            hint: 'e.g. 462001',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            onChanged: (val) async {
                              final clean = val.trim();
                              if (clean.length != 6) return;
                              final result = await IndiaLocationHelper.lookupPincode(clean);
                              if (!mounted || _shippingEntries[i].pincodeController.text.trim() != clean) return;
                              if (result != null) {
                                setState(() {
                                  _shippingEntries[i].stateController.text = result.state;
                                  _shippingEntries[i].cityTehsilController.text = result.primaryCity;
                                });
                              }
                            },
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCreateInput(
                            controller: _shippingEntries[i].cityTehsilController,
                            label: 'City / Tehsil',
                            hint: 'e.g. Bhopal',
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCreateInput(
                            controller: _shippingEntries[i].stateController,
                            label: 'State',
                            hint: 'e.g. Madhya Pradesh',
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < _shippingEntries.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _shippingEntries.add(_CustomerShippingEntry())),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Another Shipping Address'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                side: BorderSide(color: const Color(0xFF059669).withValues(alpha: 0.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerShippingEntry {
  final TextEditingController villageAreaController;
  final TextEditingController address2Controller;
  final TextEditingController cityTehsilController;
  final TextEditingController stateController;
  final TextEditingController pincodeController;

  _CustomerShippingEntry({
    String villageArea = '',
    String address2 = '',
    String cityTehsil = '',
    String state = '',
    String pincode = '',
  })  : villageAreaController = TextEditingController(text: villageArea),
        address2Controller = TextEditingController(text: address2),
        cityTehsilController = TextEditingController(text: cityTehsil),
        stateController = TextEditingController(text: state),
        pincodeController = TextEditingController(text: pincode);

  factory _CustomerShippingEntry.fromAddress(UserAddress address) {
    return _CustomerShippingEntry(
      villageArea: address.villageArea,
      address2: address.address2,
      cityTehsil: address.cityTehsil,
      state: address.state,
      pincode: address.pincode,
    );
  }

  bool get isEmpty =>
      villageAreaController.text.trim().isEmpty &&
      address2Controller.text.trim().isEmpty &&
      cityTehsilController.text.trim().isEmpty &&
      stateController.text.trim().isEmpty &&
      pincodeController.text.trim().isEmpty;

  Map<String, dynamic> toAddressMap() => {
        if (villageAreaController.text.trim().isNotEmpty) 'villageArea': villageAreaController.text.trim(),
        if (address2Controller.text.trim().isNotEmpty) 'address2': address2Controller.text.trim(),
        if (cityTehsilController.text.trim().isNotEmpty) 'cityTehsil': cityTehsilController.text.trim(),
        if (stateController.text.trim().isNotEmpty) 'state': stateController.text.trim(),
        if (pincodeController.text.trim().isNotEmpty) 'pincode': pincodeController.text.trim(),
        'country': 'India',
      };

  void dispose() {
    villageAreaController.dispose();
    address2Controller.dispose();
    cityTehsilController.dispose();
    stateController.dispose();
    pincodeController.dispose();
  }
}
