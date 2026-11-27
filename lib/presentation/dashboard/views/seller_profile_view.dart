import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/admin_user.dart';
import '../../../core/models/seller.dart';
import '../../../core/models/product.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/file_download_helper.dart';
import '../../../core/utils/india_location_helper.dart';
import '../../../logic/product/product_bloc.dart';
import '../../../logic/product/product_event.dart';
import '../../../logic/admin_user/admin_user_event.dart';
import '../../../logic/admin_user/seller_bloc.dart';
import '../../../domain/repositories/admin_user_repository.dart';
import '../widgets/bulk_add_products_dialog.dart';
import '../widgets/variant_live_pricing.dart';

class SellerProfileView extends StatefulWidget {
  final SellerProfile seller;
  final List<Product> allProducts;
  final VoidCallback onBack;
  final ValueChanged<SellerProfile> onSellerUpdated;
  final ValueChanged<String> onViewSellerProducts;
  final bool isCreateMode;
  final ValueChanged<SellerProfile>? onSellerCreated;

  const SellerProfileView({
    super.key,
    required this.seller,
    required this.allProducts,
    required this.onBack,
    required this.onSellerUpdated,
    required this.onViewSellerProducts,
    this.isCreateMode = false,
    this.onSellerCreated,
  });

  @override
  State<SellerProfileView> createState() => _SellerProfileViewState();
}

class _SellerProfileViewState extends State<SellerProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SellerProfile _currentSeller;
  late bool _isCreating;
  bool _isEditing = false;
  bool _isSubmitting = false;
  bool _isUploadingLogo = false;
  String? _pendingLogoUrl;
  String? _createErrorMessage;
  bool _isLookingUpPincode = false;
  bool _isLoadingCities = false;
  String? _pincodeStatusText;
  List<String> _extraPincodeCities = const [];
  String _pricingModel = 'MARKETPLACE';

  // Staged documents during seller creation (Create Mode)
  PlatformFile? _stagedGstFile;
  PlatformFile? _stagedPanFile;
  PlatformFile? _stagedAadhaarFile;
  PlatformFile? _stagedCancelledChequeFile;
  PlatformFile? _stagedAgreementFile;
  final List<PlatformFile> _stagedLicenceFiles = [];

  // Dynamic Warehouse Addresses (same schema as Address)
  final List<_WarehouseAddressEntry> _warehouseEntries = [];

  // Edit Controllers
  late TextEditingController _companyNameController;
  late TextEditingController _tradeNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
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
  late TextEditingController _commissionController;
  late TextEditingController _monthlyTargetController;
  late TextEditingController _notesController;
  late TextEditingController _passwordController;

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
    _isCreating = widget.isCreateMode || _currentSeller.id.isEmpty;
    _isEditing = _isCreating;
    _tabController = TabController(length: 2, vsync: this);
    _initControllers();
    IndiaLocationHelper.fetchStates().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _initControllers() {
    final contactParts = _currentSeller.contactPerson.trim().split(RegExp(r'\s+'));
    final initFirst = contactParts.isNotEmpty && contactParts.first.isNotEmpty ? contactParts.first : '';
    final initLast = contactParts.length > 1 ? contactParts.sublist(1).join(' ') : '';
    _companyNameController = TextEditingController(text: _currentSeller.companyName);
    _tradeNameController = TextEditingController(text: _currentSeller.tradeName);
    _firstNameController = TextEditingController(text: initFirst);
    _lastNameController = TextEditingController(text: initLast);
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
    _warehouseEntries.clear();
    for (final wh in _currentSeller.warehouseAddresses) {
      _warehouseEntries.add(_WarehouseAddressEntry.fromAddress(wh));
    }
    _pricingModel = _currentSeller.pricingModel.isNotEmpty ? _currentSeller.pricingModel : 'MARKETPLACE';
    _commissionController = TextEditingController(
      text: _currentSeller.commissionPercentage > 0 ? _currentSeller.commissionPercentage.toString() : '',
    );
    _monthlyTargetController = TextEditingController(
      text: _currentSeller.monthlyTarget != null ? _currentSeller.monthlyTarget.toString() : '',
    );
    _notesController = TextEditingController(text: _currentSeller.notes ?? '');
    _passwordController = TextEditingController();

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
    _firstNameController.dispose();
    _lastNameController.dispose();
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
    for (final entry in _warehouseEntries) {
      entry.dispose();
    }
    _commissionController.dispose();
    _monthlyTargetController.dispose();
    _notesController.dispose();
    _passwordController.dispose();
    _bankNameController.dispose();
    _accHolderController.dispose();
    _accNumberController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isCreating) {
      if (_isSubmitting) return;
      final tradeName = _tradeNameController.text.trim().isNotEmpty
          ? _tradeNameController.text.trim()
          : _companyNameController.text.trim();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();
      final cleanPhone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      final finalPhone = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
      final gstin = _gstinController.text.trim().toUpperCase();
      final panNumber = _panController.text.trim().toUpperCase();
      final licenceNo = _licenseController.text.trim();
      final password = _passwordController.text;

      String? validationError;
      if (tradeName.isEmpty) {
        validationError = 'Shop / Trade Name is required.';
      } else if (firstName.isEmpty || lastName.isEmpty) {
        validationError = 'Owner First Name and Last Name are required.';
      } else if (finalPhone.length != 10) {
        validationError = 'Please enter a valid 10-digit mobile number.';
      } else if (email.isEmpty || !RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(email)) {
        validationError = 'Please enter a valid email address.';
      } else if (gstin.isNotEmpty && gstin.length != 15) {
        validationError = 'GSTIN must be exactly 15 alphanumeric characters if provided.';
      } else if (password.isNotEmpty && password.trim().length < 6) {
        validationError = 'Password must be at least 6 characters if provided.';
      }

      double? dealerCommission;
      if (validationError == null && _pricingModel == 'DEALER_COMMISSION') {
        dealerCommission = double.tryParse(_commissionController.text.trim());
        if (dealerCommission == null || dealerCommission < 0 || dealerCommission > 100) {
          validationError = 'Please enter a valid Commission (%) between 0 and 100 for Dealer Commission.';
        }
      }

      if (validationError != null) {
        setState(() => _createErrorMessage = validationError);
        return;
      }

      final payload = <String, dynamic>{
        'shopName': tradeName,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': finalPhone,
        'email': email,
        if (gstin.isNotEmpty) 'gstNumber': gstin,
        if (panNumber.isNotEmpty) 'panNumber': panNumber,
        if (licenceNo.isNotEmpty) 'licenceNo': licenceNo,
        if (password.trim().isNotEmpty) 'password': password.trim(),
        if (_pendingLogoUrl != null && _pendingLogoUrl!.isNotEmpty) 'shopImage': _pendingLogoUrl,
        'pricingModel': _pricingModel,
        'commissionPercentage': _pricingModel == 'DEALER_COMMISSION' ? (dealerCommission ?? 0.0) : 0.0,
      };

      final regAddr = _registeredAddressController.text.trim();
      final city = _cityController.text.trim();
      final state = _stateController.text.trim();
      final pincode = _pincodeController.text.trim();
      if (regAddr.isNotEmpty || city.isNotEmpty || state.isNotEmpty || pincode.isNotEmpty) {
        payload['address'] = {
          if (regAddr.isNotEmpty) 'villageArea': regAddr,
          if (city.isNotEmpty) 'cityTehsil': city,
          if (state.isNotEmpty) 'state': state,
          if (pincode.isNotEmpty) 'pincode': pincode,
          'country': 'India',
        };
      }

      final warehouseList = _warehouseEntries
          .where((e) => !e.isEmpty)
          .map((e) => e.toAddressMap())
          .toList();
      if (warehouseList.isNotEmpty) {
        payload['warehouseAddresses'] = warehouseList;
      }

      final bankName = _bankNameController.text.trim();
      final accHolder = _accHolderController.text.trim();
      final accNumber = _accNumberController.text.trim();
      final ifsc = _ifscController.text.trim().toUpperCase();
      final branch = _branchController.text.trim();
      final upi = _upiController.text.trim();
      if (bankName.isNotEmpty ||
          accHolder.isNotEmpty ||
          accNumber.isNotEmpty ||
          ifsc.isNotEmpty ||
          branch.isNotEmpty ||
          upi.isNotEmpty) {
        payload['bankDetails'] = {
          if (bankName.isNotEmpty) 'bankName': bankName,
          if (accHolder.isNotEmpty) 'accountHolderName': accHolder,
          if (accNumber.isNotEmpty) 'accountNumber': accNumber,
          if (ifsc.isNotEmpty) 'ifscCode': ifsc,
          if (branch.isNotEmpty) 'branch': branch,
          if (upi.isNotEmpty) 'upiId': upi,
        };
      }

      final targetInt = int.tryParse(_monthlyTargetController.text.trim());
      if (targetInt != null && targetInt >= 0) {
        payload['monthlyTarget'] = targetInt;
      }
      final notes = _notesController.text.trim();
      if (notes.isNotEmpty) {
        payload['notes'] = notes;
      }

      setState(() {
        _isSubmitting = true;
        _createErrorMessage = null;
      });

      try {
        final repository = context.read<AdminUserRepository>();
        final created = await repository.createSeller(payload);
        if (!mounted) return;

        context.read<SellerBloc>().add(UpdateLocalAdminUser(created));
        context.read<SellerBloc>().add(const InitializeAdminUsers(forceRefresh: true));

        final profile = SellerProfile.fromAdminUser(created);
        setState(() {
          _currentSeller = profile;
          _isCreating = false;
          _isEditing = false;
          _isSubmitting = false;
        });
        widget.onSellerCreated?.call(profile);
        widget.onSellerUpdated(profile);

        final hasStagedDocs = _stagedGstFile != null ||
            _stagedPanFile != null ||
            _stagedAadhaarFile != null ||
            _stagedCancelledChequeFile != null ||
            _stagedAgreementFile != null ||
            _stagedLicenceFiles.isNotEmpty;

        if (hasStagedDocs) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seller registered! Uploading staged documents...'),
              duration: Duration(seconds: 3),
            ),
          );
          context.read<SellerBloc>().add(
                UploadSellerDocuments(
                  userId: created.id,
                  gstCertificate: _stagedGstFile,
                  panCard: _stagedPanFile,
                  aadhaarCard: _stagedAadhaarFile,
                  cancelledCheque: _stagedCancelledChequeFile,
                  agreement: _stagedAgreementFile,
                  licenceFiles: _stagedLicenceFiles.isNotEmpty ? List.from(_stagedLicenceFiles) : null,
                  onSuccess: (updated) {
                    if (!mounted) return;
                    setState(() {
                      _currentSeller = SellerProfile.fromAdminUser(updated);
                      _stagedGstFile = null;
                      _stagedPanFile = null;
                      _stagedAadhaarFile = null;
                      _stagedCancelledChequeFile = null;
                      _stagedAgreementFile = null;
                      _stagedLicenceFiles.clear();
                    });
                    widget.onSellerUpdated(_currentSeller);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF059669),
                        content: Text('Seller "${profile.tradeName}" registered and all documents uploaded!'),
                      ),
                    );
                  },
                  onError: (err) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFFE11D48),
                        content: Text('Seller registered, but document upload failed: $err'),
                      ),
                    );
                  },
                ),
              );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF059669),
              content: Text('Seller "${profile.tradeName}" registered successfully!'),
            ),
          );
        }
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

    double effectiveCommission = 0.0;
    if (_pricingModel == 'DEALER_COMMISSION') {
      final parsedComm = double.tryParse(_commissionController.text.trim());
      if (parsedComm == null || parsedComm < 0 || parsedComm > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid Commission (%) between 0 and 100 for Dealer Commission.'),
            backgroundColor: Color(0xFFE11D48),
          ),
        );
        return;
      }
      effectiveCommission = parsedComm;
    }

    final pricingChanged = _currentSeller.pricingModel != _pricingModel ||
        _currentSeller.commissionPercentage != effectiveCommission;

    final contactParts = _contactPersonController.text.trim().split(RegExp(r'\s+'));
    final firstName = contactParts.isNotEmpty && contactParts.first.isNotEmpty
        ? contactParts.first
        : _firstNameController.text.trim();
    final lastName = contactParts.length > 1
        ? contactParts.sublist(1).join(' ')
        : _lastNameController.text.trim();
    final tradeName = _tradeNameController.text.trim().isNotEmpty
        ? _tradeNameController.text.trim()
        : _companyNameController.text.trim();
    final gstin = _gstinController.text.trim().toUpperCase();
    final panNumber = _panController.text.trim().toUpperCase();
    final licenceNo = _licenseController.text.trim();
    final regAddr = _registeredAddressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();
    final warehouseList = _warehouseEntries
        .where((e) => !e.isEmpty)
        .map((e) => e.toAddressMap())
        .toList();

    final cleanEditPhone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final finalEditPhone = cleanEditPhone.length > 10
        ? cleanEditPhone.substring(cleanEditPhone.length - 10)
        : cleanEditPhone;
    final targetInt = int.tryParse(_monthlyTargetController.text.trim());

    final updatePayload = <String, dynamic>{
      if (tradeName.isNotEmpty) 'shopName': tradeName,
      if (firstName.isNotEmpty) 'firstName': firstName,
      if (lastName.isNotEmpty) 'lastName': lastName,
      if (finalEditPhone.length == 10) 'phoneNumber': finalEditPhone,
      if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim().toLowerCase(),
      'gstNumber': gstin,
      'panNumber': panNumber,
      'licenceNo': licenceNo,
      if (regAddr.isNotEmpty || city.isNotEmpty || state.isNotEmpty || pincode.isNotEmpty)
        'address': {
          if (regAddr.isNotEmpty) 'villageArea': regAddr,
          if (city.isNotEmpty) 'cityTehsil': city,
          if (state.isNotEmpty) 'state': state,
          if (pincode.isNotEmpty) 'pincode': pincode,
          'country': 'India',
        },
      'warehouseAddresses': warehouseList,
      'pricingModel': _pricingModel,
      'commissionPercentage': effectiveCommission,
      if (targetInt != null && targetInt >= 0) 'monthlyTarget': targetInt,
      'notes': _notesController.text.trim(),
      if (_passwordController.text.trim().length >= 6) 'password': _passwordController.text.trim(),
      'bankDetails': {
        'bankName': _bankNameController.text.trim(),
        'accountHolderName': _accHolderController.text.trim(),
        'accountNumber': _accNumberController.text.trim(),
        'ifscCode': _ifscController.text.trim().toUpperCase(),
        'branch': _branchController.text.trim(),
        'upiId': _upiController.text.trim(),
        if (_currentSeller.bankDetails.cancelledCheque.isNotEmpty)
          'cancelledCheque': _currentSeller.bankDetails.cancelledCheque,
      },
    };

    try {
      final repository = context.read<AdminUserRepository>();
      final savedUser = await repository.updateUser(
        userId: _currentSeller.id,
        data: updatePayload,
      );
      if (!mounted) return;
      context.read<SellerBloc>().add(UpdateLocalAdminUser(savedUser));
      final updated = SellerProfile.fromAdminUser(savedUser);
      setState(() {
        _currentSeller = updated;
        _isEditing = false;
      });
      widget.onSellerUpdated(updated);
      if (pricingChanged) {
        try {
          context.read<ProductBloc>().add(const InitializeProducts());
        } catch (_) {}
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seller profile for "${updated.tradeName}" updated successfully.'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : 'Failed to update seller: $e',
          ),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleStatus() {
    final willSuspend = _currentSeller.status == 'ACTIVE' ||
        _currentSeller.status == 'VERIFIED' ||
        !_currentSeller.isBlocked;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(willSuspend ? 'Suspend Seller?' : 'Activate Seller?'),
        content: Text(
          willSuspend
              ? 'Suspending "${_currentSeller.tradeName}" will block their login, deactivate all their public product listings from the storefront, and prevent new orders.'
              : 'Activating "${_currentSeller.tradeName}" will restore their account access and allow them to manage listings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              final nextStatus = willSuspend ? 'SUSPENDED' : 'ACTIVE';
              final updated = _currentSeller.copyWith(
                status: nextStatus,
                isBlocked: willSuspend,
                updatedAt: DateTime.now(),
              );
              setState(() => _currentSeller = updated);
              widget.onSellerUpdated(updated);

              context.read<SellerBloc>().add(
                    ToggleBlockAdminUser(
                      userId: _currentSeller.id,
                      blocked: willSuspend,
                    ),
                  );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Seller status updated to $nextStatus'),
                  backgroundColor: willSuspend ? const Color(0xFFEF4444) : const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: willSuspend ? const Color(0xFFDC2626) : const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: Text(willSuspend ? 'Suspend' : 'Activate'),
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

    // Filter products belonging to this seller
    final sellerProducts = widget.allProducts.where((p) =>
        p.sellerId == _currentSeller.id ||
        (p.sellerName.isNotEmpty && p.sellerName.toLowerCase() == _currentSeller.tradeName.toLowerCase()) ||
        (p.vendor.isNotEmpty && p.vendor.toLowerCase() == _currentSeller.tradeName.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigation & Actions Breadcrumb Bar
        _buildTopActionBar(context, isDark, surfaceColor, borderColor, sellerProducts.length),

        const SizedBox(height: 18),

        // If soft-deleted / in trash, show a prominent restoration banner
        if (_currentSeller.isDeleted) ...[
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
                        'This seller account is soft-deleted and placed in Trash',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFF9F1239),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Storefront and catalog products are deactivated. Historical orders, transactions, and settlement ledgers remain preserved. You can restore this seller anytime.',
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
                  onPressed: () => _confirmToggleDeleteSeller(context),
                  icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
                  label: const Text('Restore Seller'),
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

        if (_isCreating) ...[
          _buildCreateSellerForm(context, isDark, surfaceColor, borderColor, isWide),
        ] else ...[
          // Seller Header Banner Card
          _buildSellerHeaderCard(context, isDark, surfaceColor, borderColor, isWide),

          const SizedBox(height: 18),

          // KPI Metric Strip
          _buildSellerMetricsGrid(context, isDark, surfaceColor, borderColor, sellerProducts.length, isWide),
          const SizedBox(height: 18),

          // 2-Tab Bar: Profile & Business Details | Products Catalog
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
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
                const Tab(icon: Icon(Icons.business_center_rounded, size: 18), text: 'Profile & Business Details'),
                Tab(icon: const Icon(Icons.inventory_2_rounded, size: 18), text: 'Products Catalog (${sellerProducts.length})'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 1) {
                return _buildProductsTab(isDark, surfaceColor, borderColor, sellerProducts);
              }
              return _buildSellerProfileCards(context, isDark, surfaceColor, borderColor, isWide);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSellerProfileCards(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    bool isWide,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCreateBusinessCard(isDark, surfaceColor, borderColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildCreateContactCard(isDark, surfaceColor, borderColor)),
            ],
          )
        else ...[
          _buildCreateBusinessCard(isDark, surfaceColor, borderColor),
          const SizedBox(height: 16),
          _buildCreateContactCard(isDark, surfaceColor, borderColor),
        ],
        const SizedBox(height: 16),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCreateAddressCard(isDark, surfaceColor, borderColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildCreateBankCard(isDark, surfaceColor, borderColor)),
            ],
          )
        else ...[
          _buildCreateAddressCard(isDark, surfaceColor, borderColor),
          const SizedBox(height: 16),
          _buildCreateBankCard(isDark, surfaceColor, borderColor),
        ],
        const SizedBox(height: 16),
        if (_isEditing)
          _buildCreateWarehousesCard(isDark, surfaceColor, borderColor)
        else
          _buildCreateSectionCard(
            icon: Icons.warehouse_outlined,
            stepNumber: '05',
            title: 'Warehouse & Dispatch Addresses',
            subtitle: 'Registered fulfillment and dispatch warehouse locations',
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            child: _buildWarehouseAddressesSection(isDark, borderColor),
          ),
        const SizedBox(height: 16),
        _buildDocumentsSection(context, isDark, borderColor),
        if (_isEditing) ...[
          const SizedBox(height: 16),
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
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _initControllers();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text('Save Changes', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  void _confirmPermanentDeleteSeller(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 8),
            Text(
              'Permanently Delete Seller?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete "${_currentSeller.tradeName}" (ID: ${_currentSeller.id}) from the database?',
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
                'Endpoint: DELETE /api/v1/admin/users/${_currentSeller.id}/permanent\n\n'
                'Warning: This action is permanent and IRREVERSIBLE. All seller credentials and access will be completely wiped from the database. Note: Accounts with existing orders or products cannot be permanently deleted.',
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
              context.read<SellerBloc>().add(
                    PermanentlyDeleteAdminUser(_currentSeller.id),
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
        if (_isCreating) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _saveChanges,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_business_rounded, size: 17),
                label: Text(
                  _isSubmitting ? 'Creating Seller...' : 'Create Seller Account',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ] else ...[
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
              if (_currentSeller.isDeleted)
                OutlinedButton.icon(
                  onPressed: () => _confirmPermanentDeleteSeller(context),
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
      ],
    );
  }

  Future<void> _pickAndUploadSellerLogo() async {
    final repo = context.read<AdminUserRepository>();
    final sellerBloc = context.read<SellerBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final res = await FilePicker.pickFiles(type: FileType.image);
    if (res.isEmpty || !mounted) return;
    setState(() => _isUploadingLogo = true);
    try {
      final logoUrl = await repo.uploadSellerLogo(res.first);
      if (!mounted) return;
      if (_isCreating) {
        setState(() {
          _pendingLogoUrl = logoUrl;
          _isUploadingLogo = false;
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Seller logo uploaded! It will be saved when you create the seller.'),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final savedUser = await repo.updateUser(
        userId: _currentSeller.id,
        data: {'shopImage': logoUrl},
      );
      if (!mounted) return;
      sellerBloc.add(UpdateLocalAdminUser(savedUser));
      final updated = SellerProfile.fromAdminUser(savedUser);
      setState(() {
        _currentSeller = updated;
        _pendingLogoUrl = null;
        _isUploadingLogo = false;
      });
      widget.onSellerUpdated(updated);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Seller logo updated successfully!'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingLogo = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update logo: $e'),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                : const Color(0xFFEF4444)));

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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _isEditing && !_isUploadingLogo ? _pickAndUploadSellerLogo : null,
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
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
                      clipBehavior: Clip.antiAlias,
                      child: _isUploadingLogo
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : ((_isCreating ? _pendingLogoUrl : (_pendingLogoUrl ?? _currentSeller.shopImage)) != null &&
                                  (_isCreating ? _pendingLogoUrl : (_pendingLogoUrl ?? _currentSeller.shopImage))!.trim().isNotEmpty)
                              ? Image.network(
                                  (_isCreating ? _pendingLogoUrl : (_pendingLogoUrl ?? _currentSeller.shopImage))!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                                ),
                    ),
                    if (_isEditing)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isUploadingLogo ? null : _pickAndUploadSellerLogo,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ((_isCreating ? _pendingLogoUrl : (_pendingLogoUrl ?? _currentSeller.shopImage)) != null &&
                                  (_isCreating ? _pendingLogoUrl : (_pendingLogoUrl ?? _currentSeller.shopImage))!.trim().isNotEmpty)
                              ? Icons.edit_rounded
                              : Icons.upload_rounded,
                          size: 13,
                          color: const Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isUploadingLogo
                              ? 'Uploading...'
                              : (((_isCreating ? _pendingLogoUrl : (_pendingLogoUrl ?? _currentSeller.shopImage)) != null &&
                                      (_isCreating ? _pendingLogoUrl : (_pendingLogoUrl ?? _currentSeller.shopImage))!.trim().isNotEmpty)
                                  ? 'Change Logo'
                                  : 'Upload Logo'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
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
                            ? (_tradeNameController.text.trim().isNotEmpty ? _tradeNameController.text.trim() : 'Register New Seller')
                            : _currentSeller.tradeName,
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
                        _isCreating
                            ? 'NEW SELLER DRAFT'
                            : (_currentSeller.isDeleted ? 'DEACTIVATED (SOFT DELETED)' : _currentSeller.status.replaceAll('_', ' ')),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _isCreating ? const Color(0xFFF59E0B) : statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _isCreating
                      ? (_companyNameController.text.trim().isNotEmpty
                          ? _companyNameController.text.trim()
                          : 'Fill in the merchant details below to register storefront & warehouse')
                      : _currentSeller.companyName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                if (_isCreating)
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildSimpleBadge(Icons.storefront_rounded, 'Role: ROLE_SELLER', isDark, borderColor),
                      _buildSimpleBadge(Icons.app_registration_rounded, 'Seller Onboarding', isDark, borderColor),
                    ],
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildCopyableBadge('Seller No', _currentSeller.sellerNumber, isDark, borderColor),
                      _buildSimpleBadge(
                        _currentSeller.pricingModel == 'DEALER_COMMISSION'
                            ? Icons.handshake_outlined
                            : Icons.storefront_rounded,
                        _currentSeller.pricingModel == 'DEALER_COMMISSION'
                            ? 'Dealer Commission (${_currentSeller.commissionPercentage.toStringAsFixed(_currentSeller.commissionPercentage == _currentSeller.commissionPercentage.roundToDouble() ? 0 : 1)}%)'
                            : 'Marketplace Pricing',
                        isDark,
                        borderColor,
                      ),
                      if (_currentSeller.phone.isNotEmpty)
                        _buildCopyableBadge('Mobile', _currentSeller.phone, isDark, borderColor),
                      if (_currentSeller.gstin.isNotEmpty)
                        _buildCopyableBadge('GSTIN', _currentSeller.gstin, isDark, borderColor),
                      if (_currentSeller.city.isNotEmpty || _currentSeller.state.isNotEmpty)
                        _buildSimpleBadge(
                          Icons.location_on_rounded,
                          [_currentSeller.city, _currentSeller.state].where((s) => s.isNotEmpty).join(', '),
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

  // --- WAREHOUSE ADDRESSES SECTION ---
  Widget _buildWarehouseAddressesSection(bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warehouse_outlined, size: 18, color: Color(0xFF059669)),
            const SizedBox(width: 8),
            Text(
              'Warehouse & Dispatch Addresses (${_isEditing ? _warehouseEntries.length : _currentSeller.warehouseAddresses.length})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            if (_isEditing)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _warehouseEntries.add(_WarehouseAddressEntry());
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Warehouse'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: BorderSide(color: const Color(0xFF059669).withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isEditing) ...[
          if (_warehouseEntries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                'No warehouse addresses configured. Click "Add Warehouse" above to add one.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            )
          else
            for (int i = 0; i < _warehouseEntries.length; i++) ...[
              _buildWarehouseEntryCard(i, _warehouseEntries[i], isDark, borderColor),
              if (i < _warehouseEntries.length - 1) const SizedBox(height: 12),
            ],
        ] else if (_currentSeller.warehouseAddresses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              'No warehouse addresses added.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          )
        else
          for (int i = 0; i < _currentSeller.warehouseAddresses.length; i++) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warehouse_outlined, size: 16, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Warehouse #${i + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentSeller.warehouseAddresses[i].formatted,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < _currentSeller.warehouseAddresses.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }

  // --- BUSINESS & COMPLIANCE DOCUMENTS SECTION ---
  Widget _buildDocumentsSection(BuildContext context, bool isDark, Color borderColor) {
    final hasGst = _stagedGstFile != null || (_currentSeller.gstCertificate != null && _currentSeller.gstCertificate!.trim().isNotEmpty);
    final hasPan = _stagedPanFile != null || (_currentSeller.panCard != null && _currentSeller.panCard!.trim().isNotEmpty);
    final hasAadhaar = _stagedAadhaarFile != null || (_currentSeller.aadhaarCard != null && _currentSeller.aadhaarCard!.trim().isNotEmpty);
    final hasCheque = _stagedCancelledChequeFile != null || _currentSeller.bankDetails.cancelledCheque.trim().isNotEmpty;
    final hasAgreement = _stagedAgreementFile != null || (_currentSeller.agreement != null && _currentSeller.agreement!.trim().isNotEmpty);
    final hasLicence = _stagedLicenceFiles.isNotEmpty || _currentSeller.licenceImages.isNotEmpty;

    int readyCount = 0;
    if (hasGst) readyCount++;
    if (hasPan) readyCount++;
    if (hasAadhaar) readyCount++;
    if (hasCheque) readyCount++;
    if (hasAgreement) readyCount++;
    if (hasLicence) readyCount++;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
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
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder_copy_outlined, size: 18, color: Color(0xFF059669)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUSINESS & COMPLIANCE DOCUMENTS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$readyCount / 6 Documents Uploaded (PDF, PNG, JPG, WEBP)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth >= 680;
              final slots = [
                _buildDocSlot(
                  title: 'GST Certificate',
                  docType: 'gstCertificate',
                  backendDocType: 'gst-certificate',
                  subtitle: _currentSeller.gstin.isNotEmpty ? 'GSTIN: ${_currentSeller.gstin}' : 'Optional',
                  fileUrl: _currentSeller.gstCertificate,
                  isUploaded: _currentSeller.gstCertificate != null && _currentSeller.gstCertificate!.trim().isNotEmpty,
                  stagedFiles: _stagedGstFile != null ? [_stagedGstFile!] : [],
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                _buildDocSlot(
                  title: 'PAN Card',
                  docType: 'panCard',
                  backendDocType: 'pan-card',
                  subtitle: _currentSeller.panNumber.isNotEmpty ? 'PAN: ${_currentSeller.panNumber}' : 'Company / Proprietor PAN',
                  fileUrl: _currentSeller.panCard,
                  isUploaded: _currentSeller.panCard != null && _currentSeller.panCard!.trim().isNotEmpty,
                  stagedFiles: _stagedPanFile != null ? [_stagedPanFile!] : [],
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                _buildDocSlot(
                  title: 'Aadhaar Card',
                  docType: 'aadhaarCard',
                  backendDocType: 'aadhaar-card',
                  subtitle: 'Authorized Signatory Identity',
                  fileUrl: _currentSeller.aadhaarCard,
                  isUploaded: _currentSeller.aadhaarCard != null && _currentSeller.aadhaarCard!.trim().isNotEmpty,
                  stagedFiles: _stagedAadhaarFile != null ? [_stagedAadhaarFile!] : [],
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                _buildDocSlot(
                  title: 'Agri / Trade Licence',
                  docType: 'licenceImage',
                  backendDocType: 'licence',
                  subtitle: _currentSeller.licenseNumber.isNotEmpty ? 'Licence: ${_currentSeller.licenseNumber}' : 'Fertilizer / Pesticide Licence',
                  fileUrl: _currentSeller.licenceImages.isNotEmpty ? _currentSeller.licenceImages.first : null,
                  isUploaded: _currentSeller.licenceImages.isNotEmpty,
                  stagedFiles: _stagedLicenceFiles,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                _buildDocSlot(
                  title: 'Bank Cancelled Cheque',
                  docType: 'cancelledCheque',
                  backendDocType: 'cancelled-cheque',
                  subtitle: 'Payout Bank Verification Cheque',
                  fileUrl: _currentSeller.bankDetails.cancelledCheque.isNotEmpty
                      ? _currentSeller.bankDetails.cancelledCheque
                      : null,
                  isUploaded: _currentSeller.bankDetails.cancelledCheque.trim().isNotEmpty,
                  stagedFiles: _stagedCancelledChequeFile != null ? [_stagedCancelledChequeFile!] : [],
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                _buildDocSlot(
                  title: 'Seller Agreement',
                  docType: 'agreement',
                  backendDocType: 'agreement',
                  subtitle: 'Signed Seller Onboarding Agreement',
                  fileUrl: _currentSeller.agreement,
                  isUploaded: _currentSeller.agreement != null && _currentSeller.agreement!.trim().isNotEmpty,
                  stagedFiles: _stagedAgreementFile != null ? [_stagedAgreementFile!] : [],
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ];
              if (!twoCol) {
                return Column(
                  children: [
                    for (int i = 0; i < slots.length; i++) ...[
                      slots[i],
                      if (i < slots.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: slots[0]),
                      const SizedBox(width: 12),
                      Expanded(child: slots[1]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: slots[2]),
                      const SizedBox(width: 12),
                      Expanded(child: slots[3]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: slots[4]),
                      const SizedBox(width: 12),
                      Expanded(child: slots[5]),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocSlot({
    required String title,
    required String docType,
    required String backendDocType,
    required String subtitle,
    required String? fileUrl,
    required bool isUploaded,
    required List<PlatformFile> stagedFiles,
    required bool isDark,
    required Color borderColor,
  }) {
    final isStaged = stagedFiles.isNotEmpty;
    final isReady = isUploaded || isStaged;
    final statusColor = isReady ? const Color(0xFF10B981) : const Color(0xFF64748B);
    final statusBadge = isStaged ? 'STAGED' : (isUploaded ? 'UPLOADED' : 'NOT UPLOADED');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isReady ? const Color(0xFF10B981).withValues(alpha: 0.3) : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReady ? Icons.task_alt_rounded : Icons.upload_file_outlined,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusBadge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isReady && !_isCreating) ...[
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => _SellerDocumentPreviewDialog(
                        title: title,
                        sellerId: _currentSeller.id,
                        backendDocType: backendDocType,
                        availableLicences: _currentSeller.licenceImages,
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              ElevatedButton.icon(
                onPressed: () => _pickAndUploadDocument(docType),
                icon: Icon(isReady ? Icons.sync_rounded : Icons.upload_rounded, size: 13),
                label: Text(isReady ? 'Replace' : 'Upload', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReady ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)) : const Color(0xFF059669),
                  foregroundColor: isReady ? (isDark ? Colors.white : const Color(0xFF0F172A)) : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _removeStagedDocument(String docKey) {
    setState(() {
      if (docKey == 'gstCertificate') {
        _stagedGstFile = null;
      } else if (docKey == 'panCard') {
        _stagedPanFile = null;
      } else if (docKey == 'aadhaarCard') {
        _stagedAadhaarFile = null;
      } else if (docKey == 'cancelledCheque') {
        _stagedCancelledChequeFile = null;
      } else if (docKey == 'agreement') {
        _stagedAgreementFile = null;
      } else if (docKey == 'licenceImage') {
        _stagedLicenceFiles.clear();
      }
    });
  }

  Future<void> _pickAndUploadDocument(String docType) async {
    try {
      final isLicence = docType == 'licenceImage';
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (files.isEmpty) return;

      if (_isCreating) {
        setState(() {
          if (docType == 'gstCertificate') {
            _stagedGstFile = files.first;
          } else if (docType == 'panCard') {
            _stagedPanFile = files.first;
          } else if (docType == 'aadhaarCard') {
            _stagedAadhaarFile = files.first;
          } else if (docType == 'cancelledCheque') {
            _stagedCancelledChequeFile = files.first;
          } else if (docType == 'agreement') {
            _stagedAgreementFile = files.first;
          } else if (isLicence) {
            _stagedLicenceFiles.addAll(files);
          }
        });
        return;
      }

      if (!mounted) return;
      context.read<SellerBloc>().add(
            UploadSellerDocuments(
              userId: _currentSeller.id,
              gstCertificate: docType == 'gstCertificate' ? files.first : null,
              panCard: docType == 'panCard' ? files.first : null,
              aadhaarCard: docType == 'aadhaarCard' ? files.first : null,
              cancelledCheque: docType == 'cancelledCheque' ? files.first : null,
              agreement: docType == 'agreement' ? files.first : null,
              licenceFiles: isLicence ? files : null,
              replaceLicenceFiles: false,
              onSuccess: (updatedUser) {
                if (!mounted) return;
                final updatedProfile = SellerProfile.fromAdminUser(updatedUser);
                setState(() => _currentSeller = updatedProfile);
                widget.onSellerUpdated(updatedProfile);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Document uploaded successfully!'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
              onError: (err) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upload failed: $err'),
                    backgroundColor: const Color(0xFFE11D48),
                  ),
                );
              },
            ),
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick file: $e'), backgroundColor: const Color(0xFFE11D48)),
      );
    }
  }

  Widget _buildProductsTab(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    List<Product> products,
  ) {
    Widget colHeader(String label, {bool alignRight = false}) => Text(
          label,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Text(
                  '${products.length} products listed under ${_currentSeller.tradeName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _openBulkAddProducts(context),
                  icon: const Icon(Icons.playlist_add_rounded, size: 16, color: Color(0xFF7C3AED)),
                  label: Text(
                    'Bulk Add / Assign Products',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7C3AED)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => widget.onViewSellerProducts(_currentSeller.tradeName),
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: Text(
                    'Open in Catalog',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 44, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
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
                    'Use "Bulk Add / Assign Products" above to assign or import products for this seller.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            )
          else ...[
            // Table Header matching ProductCatalogView
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Expanded(flex: 5, child: colHeader('PRODUCT & COMPOSITION')),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: colHeader('PRODUCT CODE / HSN')),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: colHeader('CATEGORY & PACK')),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: colHeader('PRICE / MRP')),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: colHeader('STOCK LEVEL')),
                  const SizedBox(width: 8),
                  SizedBox(width: 110, child: colHeader('AVAILABILITY')),
                  const SizedBox(width: 8),
                  SizedBox(width: 88, child: colHeader('ACTIONS', alignRight: true)),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),
            for (int i = 0; i < products.length; i++) ...[
              _buildSellerProductRow(products[i], isDark, borderColor),
              if (i < products.length - 1) Divider(height: 1, color: borderColor),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSellerProductRow(Product p, bool isDark, Color borderColor) {
    final isActive = p.status.toUpperCase() == 'ACTIVE';
    final statusColor = isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final mrp = p.variants.isNotEmpty ? p.variants.first.printedMrp : p.printedMrp;
    final packCount = p.variants.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          // PRODUCT & COMPOSITION
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: p.candidateImageUrls.isNotEmpty
                      ? Image.network(
                          p.candidateImageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF059669)),
                        )
                      : const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF059669)),
                ),
                const SizedBox(width: 12),
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
                      if (p.technicalName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          p.technicalName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // PRODUCT CODE / HSN
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.productCode,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'HSN: ${p.hsnCode.isNotEmpty ? p.hsnCode : "—"}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // CATEGORY & PACK
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.category.isNotEmpty ? p.category : 'Uncategorized',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$packCount ${packCount == 1 ? "variant" : "variants"}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // PRICE / MRP
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${p.displayRate.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
                Text(
                  'MRP: ₹${mrp.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // STOCK LEVEL
          Expanded(
            flex: 2,
            child: Text(
              '${p.stock} units',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.stock > 50 ? const Color(0xFF10B981) : (p.stock > 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // AVAILABILITY
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  p.status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ACTIONS
          SizedBox(
            width: 88,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => widget.onViewSellerProducts(_currentSeller.tradeName),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Catalog →',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
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
            final pToAssign = p.copyWith(
              sellerId: _currentSeller.id,
              vendor: _currentSeller.tradeName,
              sellerName: _currentSeller.tradeName,
            );
            final isExistingUnassignedProduct = p.id.isNotEmpty &&
                !p.id.startsWith('temp_') &&
                !p.id.startsWith('assigned_');

            if (isExistingUnassignedProduct) {
              context.read<ProductBloc>().add(UpdateProduct(
                pToAssign,
                onSuccess: (updated) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Assigned "${updated.title}" to ${_currentSeller.tradeName} (SKU: ${updated.sku}).',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: const Color(0xFF059669),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                },
                onError: (err) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to assign product: $err',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                },
              ));
            } else {
              context.read<ProductBloc>().add(CreateProduct(
                pToAssign,
                onSuccess: (created) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Assigned "${created.title}" to ${_currentSeller.tradeName} (SKU: ${created.sku}).',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: const Color(0xFF059669),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                },
                onError: (err) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to assign product: $err',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                },
              ));
            }
            count++;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Assigning $count product(s) to ${_currentSeller.tradeName}...',
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

  Widget _buildCreateSellerForm(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    bool isWide,
  ) {
    final shopPreview = _tradeNameController.text.trim().isNotEmpty
        ? _tradeNameController.text.trim()
        : (_companyNameController.text.trim().isNotEmpty
            ? _companyNameController.text.trim()
            : 'New Seller Store');
    final phoneDigits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final readyCount = [
      _tradeNameController.text.trim().isNotEmpty || _companyNameController.text.trim().isNotEmpty,
      _firstNameController.text.trim().isNotEmpty,
      _lastNameController.text.trim().isNotEmpty,
      phoneDigits.length >= 10,
      RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(_emailController.text.trim()),
    ].where((ok) => ok).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Onboarding Header
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF064E3B).withValues(alpha: 0.45), const Color(0xFF0F172A)]
                  : [const Color(0xFFECFDF5), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF059669).withValues(alpha: isDark ? 0.35 : 0.25),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 14,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _isUploadingLogo ? null : _pickAndUploadSellerLogo,
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF059669).withValues(alpha: 0.28),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _isUploadingLogo
                                  ? const Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : (_pendingLogoUrl != null && _pendingLogoUrl!.trim().isNotEmpty)
                                      ? Image.network(
                                          _pendingLogoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.storefront_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.storefront_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 11, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _isUploadingLogo ? null : _pickAndUploadSellerLogo,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (_pendingLogoUrl != null && _pendingLogoUrl!.trim().isNotEmpty)
                                    ? Icons.edit_rounded
                                    : Icons.upload_rounded,
                                size: 13,
                                color: const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isUploadingLogo
                                    ? 'Uploading...'
                                    : ((_pendingLogoUrl != null && _pendingLogoUrl!.trim().isNotEmpty)
                                        ? 'Change Logo'
                                        : 'Upload Logo'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            shopPreview,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'NEW SELLER ONBOARDING',
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
                        'Register a seller store with business identity, owner contact, address, warehouses, and bank settlement.',
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
                    color: readyCount == 5
                        ? const Color(0xFF059669).withValues(alpha: 0.5)
                        : borderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      readyCount == 5 ? Icons.check_circle_rounded : Icons.fact_check_outlined,
                      size: 17,
                      color: readyCount == 5 ? const Color(0xFF059669) : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$readyCount / 5 Required Fields Ready',
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

        // Inline Validation / API Error Banner
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

        // Row 1: Business & Tax Identity + Owner & Contact Details
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCreateBusinessCard(isDark, surfaceColor, borderColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildCreateContactCard(isDark, surfaceColor, borderColor)),
            ],
          )
        else ...[
          _buildCreateBusinessCard(isDark, surfaceColor, borderColor),
          const SizedBox(height: 16),
          _buildCreateContactCard(isDark, surfaceColor, borderColor),
        ],
        const SizedBox(height: 16),

        // Row 2: Business Address + Bank & Settlement
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCreateAddressCard(isDark, surfaceColor, borderColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildCreateBankCard(isDark, surfaceColor, borderColor)),
            ],
          )
        else ...[
          _buildCreateAddressCard(isDark, surfaceColor, borderColor),
          const SizedBox(height: 16),
          _buildCreateBankCard(isDark, surfaceColor, borderColor),
        ],
        const SizedBox(height: 16),

        // Row 3: Warehouse Addresses (Multiple)
        _buildCreateWarehousesCard(isDark, surfaceColor, borderColor),
        const SizedBox(height: 16),

        // Row 4: Business & Compliance Documents (Optional)
        _buildCreateDocumentsCard(isDark, surfaceColor, borderColor),
        const SizedBox(height: 20),

        // Bottom Action Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Text(
                'Fields marked with * are required to provision the seller account.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _saveChanges,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add_business_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'Creating Seller...' : 'Create Seller Account',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateSectionCard({
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF059669).withValues(alpha: 0.16),
                      const Color(0xFF10B981).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
                ),
                child: Icon(icon, size: 19, color: const Color(0xFF059669)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          margin: const EdgeInsets.only(right: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            stepNumber,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
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
          const SizedBox(height: 18),
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
    String? prefixText,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
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
          enabled: _isEditing,
          readOnly: !_isEditing,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          onChanged: (val) {
            setState(() {});
            onChanged?.call(val);
          },
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            helperStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
            prefixText: prefixText,
            prefixStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF059669),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
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

  Widget _buildCreateBusinessCard(bool isDark, Color surfaceColor, Color borderColor) {
    final gstLen = _gstinController.text.trim().length;
    return _buildCreateSectionCard(
      icon: Icons.business_center_rounded,
      stepNumber: '01',
      title: 'Business & Tax Identity',
      subtitle: 'Storefront name, legal entity & GST compliance',
      isDark: isDark,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      child: Column(
        children: [
          _buildCreateInput(
            controller: _tradeNameController,
            label: 'Shop / Trade Name *',
            hint: 'e.g. GreenField Agro Kendra',
            prefixIcon: Icons.store_outlined,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 14),
          _buildCreateInput(
            controller: _companyNameController,
            label: 'Legal Company Name',
            hint: 'e.g. GreenField Agro Pvt. Ltd.',
            prefixIcon: Icons.apartment_rounded,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 14),
          _buildCreateInput(
            controller: _gstinController,
            label: 'GSTIN (15 Characters, Optional)',
            hint: 'e.g. 23AABCU9603R1ZM',
            prefixIcon: Icons.receipt_long_outlined,
            helperText: '$gstLen / 15 characters',
            inputFormatters: [
              LengthLimitingTextInputFormatter(15),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCreateInput(
                  controller: _panController,
                  label: 'PAN Number',
                  hint: 'e.g. AABCU9603R',
                  inputFormatters: [LengthLimitingTextInputFormatter(10)],
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCreateInput(
                  controller: _licenseController,
                  label: 'Agri / Trade License No.',
                  hint: 'Optional license ID',
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

  Widget _buildCreateContactCard(bool isDark, Color surfaceColor, Color borderColor) {
    return _buildCreateSectionCard(
      icon: Icons.person_outline_rounded,
      stepNumber: '02',
      title: 'Owner & Contact Details',
      subtitle: 'Primary account holder & login credentials',
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
                  hint: 'e.g. Rajesh',
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
                  hint: 'e.g. Sharma',
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildEnhancedPhoneInput(isDark, borderColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildCreateInput(
                  controller: _monthlyTargetController,
                  label: 'Monthly Sales Target (₹)',
                  hint: 'Optional e.g. 250000',
                  prefixIcon: Icons.trending_up_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCreateInput(
            controller: _emailController,
            label: 'Email Address *',
            hint: 'seller@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
            borderColor: borderColor,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 14),
            _buildCreateInput(
              controller: _passwordController,
              label: _isCreating
                  ? 'Login Password (Optional)'
                  : 'Set / Reset Login Password (Optional)',
              hint: 'Min 6 characters (for email & password login)',
              prefixIcon: Icons.lock_outline_rounded,
              isDark: isDark,
              borderColor: borderColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedPhoneInput(bool isDark, Color borderColor) {
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final isValid = digits.length == 10;
    return Column(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (isValid ? const Color(0xFF059669) : const Color(0xFF64748B)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${digits.length} / 10 digits',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isValid ? const Color(0xFF059669) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isValid ? const Color(0xFF059669).withValues(alpha: 0.65) : borderColor,
              width: isValid ? 1.3 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withValues(alpha: 0.55),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_android_rounded, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Text(
                      '+91',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: borderColor),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  enabled: _isEditing,
                  readOnly: !_isEditing,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: '98765 43210',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    suffixIcon: isValid
                        ? const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF059669))
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onPincodeChanged(String val) async {
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

  Future<void> _onStateSelected(String val) async {
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

  Widget _buildCreateAddressCard(bool isDark, Color surfaceColor, Color borderColor) {
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

    return _buildCreateSectionCard(
      icon: Icons.location_on_outlined,
      stepNumber: '03',
      title: 'Business Address & Notes',
      subtitle: 'Enter 6-digit PIN Code to auto-fetch State & City, or select manually',
      isDark: isDark,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PIN Code (Auto-Fetch)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: _onPincodeChanged,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 132001',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.pin_drop_outlined, size: 18, color: Color(0xFF64748B)),
                        suffixIcon: _isLookingUpPincode
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
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
                    if (_pincodeStatusText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _pincodeStatusText!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _pincodeStatusText!.startsWith('Auto-filled')
                              ? const Color(0xFF059669)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildCreateInput(
                  controller: _registeredAddressController,
                  label: 'Street / Village / Area',
                  hint: 'e.g. Shop 12, Krishi Upaj Mandi Road',
                  prefixIcon: Icons.home_work_outlined,
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
                      dropdownColor: surfaceColor,
                      decoration: dropdownDecoration('-- Select State --', Icons.map_outlined),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      items: stateOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: !_isEditing
                          ? null
                          : (val) {
                              if (val != null) _onStateSelected(val);
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
                      dropdownColor: surfaceColor,
                      decoration: dropdownDecoration(
                        _isLoadingCities
                            ? 'Loading cities...'
                            : (effectiveState == null ? 'Select State first' : '-- Select City --'),
                        Icons.location_city_rounded,
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      items: cityOptions
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (!_isEditing || effectiveState == null)
                          ? null
                          : (val) {
                              if (val == null) return;
                              setState(() => _cityController.text = val);
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCreateInput(
            controller: _notesController,
            label: 'Internal Onboarding Notes',
            hint: 'Optional notes about dealer agreement or pickup schedule...',
            maxLines: 2,
            isDark: isDark,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateBankCard(bool isDark, Color surfaceColor, Color borderColor) {
    return _buildCreateSectionCard(
      icon: Icons.account_balance_outlined,
      stepNumber: '04',
      title: 'Commercial Pricing & Bank Settlement',
      subtitle: 'Pricing model, dealer commission & optional payout account',
      isDark: isDark,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      child: Column(
        children: [
          if (_isCreating)
            PricingModeToggle(
              isMarketplace: _pricingModel != 'DEALER_COMMISSION',
              onChanged: (isMarketplace) {
                setState(() {
                  _pricingModel = isMarketplace ? 'MARKETPLACE' : 'DEALER_COMMISSION';
                  if (isMarketplace) {
                    _commissionController.clear();
                  }
                });
              },
              isDark: isDark,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    _pricingModel == 'DEALER_COMMISSION'
                        ? Icons.handshake_outlined
                        : Icons.storefront_rounded,
                    size: 18,
                    color: const Color(0xFF059669),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _pricingModel == 'DEALER_COMMISSION'
                          ? 'Pricing Model: Dealer Commission (${_currentSeller.commissionPercentage.toStringAsFixed(_currentSeller.commissionPercentage == _currentSeller.commissionPercentage.roundToDouble() ? 0 : 1)}%)'
                          : 'Pricing Model: Marketplace',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Locked',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (_pricingModel == 'DEALER_COMMISSION') ...[
            const SizedBox(height: 12),
            _buildCreateInput(
              controller: _commissionController,
              label: 'Commission (%) *',
              hint: 'e.g. 12.5',
              prefixIcon: Icons.percent_rounded,
              helperText: 'Dealer commission deducted from selling rate (0 – 100%)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$')),
              ],
              isDark: isDark,
              borderColor: borderColor,
            ),
          ],
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCreateInput(
                  controller: _accHolderController,
                  label: 'Account Holder Name',
                  hint: 'As per bank passbook',
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCreateInput(
                  controller: _bankNameController,
                  label: 'Bank Name',
                  hint: 'e.g. State Bank of India',
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
                child: _buildCreateInput(
                  controller: _accNumberController,
                  label: 'Account Number',
                  hint: 'Enter account number',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCreateInput(
                  controller: _ifscController,
                  label: 'IFSC Code',
                  hint: 'e.g. SBIN0001234',
                  inputFormatters: [LengthLimitingTextInputFormatter(11)],
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
                child: _buildCreateInput(
                  controller: _branchController,
                  label: 'Branch Name',
                  hint: 'e.g. Main Market Branch',
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCreateInput(
                  controller: _upiController,
                  label: 'UPI ID',
                  hint: 'e.g. shop@okaxis',
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

  Widget _buildCreateWarehousesCard(bool isDark, Color surfaceColor, Color borderColor) {
    return _buildCreateSectionCard(
      icon: Icons.warehouse_outlined,
      stepNumber: '05',
      title: 'Warehouse Addresses (Optional)',
      subtitle: 'Add one or more dispatch warehouse addresses (same structure as business address)',
      isDark: isDark,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_warehouseEntries.isEmpty)
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
                  Icon(Icons.warehouse_outlined, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No warehouse addresses added yet. Click "Add Warehouse" to add one or more warehouse locations.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _warehouseEntries.add(_WarehouseAddressEntry());
                      });
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Warehouse'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: BorderSide(color: const Color(0xFF059669).withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            for (int i = 0; i < _warehouseEntries.length; i++) ...[
              _buildWarehouseEntryCard(i, _warehouseEntries[i], isDark, borderColor),
              if (i < _warehouseEntries.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _warehouseEntries.add(_WarehouseAddressEntry());
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Another Warehouse'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: BorderSide(color: const Color(0xFF059669).withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarehouseEntryCard(int index, _WarehouseAddressEntry entry, bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              const Icon(Icons.warehouse_outlined, size: 16, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Text(
                'Warehouse #${index + 1}',
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
                    final removed = _warehouseEntries.removeAt(index);
                    removed.dispose();
                  });
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                tooltip: 'Remove Warehouse',
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
                  controller: entry.villageAreaController,
                  label: 'Street / Village / Area',
                  hint: 'e.g. Plot 42, Industrial Estate',
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCreateInput(
                  controller: entry.address2Controller,
                  label: 'Landmark / Address 2',
                  hint: 'Optional',
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final selectedState = IndiaLocationHelper.normalizeState(entry.stateController.text);
              final stateOptions = IndiaLocationHelper.states;
              final effectiveState = stateOptions.contains(selectedState) ? selectedState : null;
              final cityOptions = effectiveState != null
                  ? IndiaLocationHelper.cachedCitiesForState(
                      effectiveState,
                      extraCities: [
                        ...entry.extraCities,
                        if (entry.cityTehsilController.text.trim().isNotEmpty)
                          entry.cityTehsilController.text.trim(),
                      ],
                    )
                  : (entry.cityTehsilController.text.trim().isNotEmpty
                      ? <String>[entry.cityTehsilController.text.trim()]
                      : <String>[]);
              final currentCity = entry.cityTehsilController.text.trim();
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

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCreateInput(
                      controller: entry.pincodeController,
                      label: 'PIN Code (Auto-Fetch)',
                      hint: 'e.g. 462039',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: (val) => _onWarehousePincodeChanged(entry, val),
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            if (val != null) _onWarehouseStateSelected(entry, val);
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
                            entry.isLoadingCities ? 'Loading...' : 'Select City',
                            Icons.location_city_outlined,
                          ),
                          items: cityOptions
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => entry.cityTehsilController.text = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (entry.pincodeStatusText != null) ...[
            const SizedBox(height: 6),
            Text(
              entry.pincodeStatusText!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onWarehouseStateSelected(_WarehouseAddressEntry entry, String val) async {
    setState(() {
      entry.stateController.text = val;
      entry.cityTehsilController.text = '';
      entry.extraCities = const [];
      entry.isLoadingCities = true;
    });
    await IndiaLocationHelper.fetchCitiesForState(val);
    if (!mounted || entry.stateController.text != val) return;
    setState(() => entry.isLoadingCities = false);
  }

  Future<void> _onWarehousePincodeChanged(_WarehouseAddressEntry entry, String val) async {
    final clean = val.trim();
    if (clean.length != 6) {
      if (entry.pincodeStatusText != null) {
        setState(() => entry.pincodeStatusText = null);
      }
      return;
    }
    final result = await IndiaLocationHelper.lookupPincode(clean);
    if (!mounted || entry.pincodeController.text.trim() != clean) return;
    setState(() {
      if (result != null) {
        entry.stateController.text = result.state;
        entry.extraCities = result.cities;
        entry.cityTehsilController.text = result.primaryCity;
        entry.pincodeStatusText = 'Auto-filled: ${result.primaryCity}, ${result.state}';
      } else {
        entry.pincodeStatusText = 'PIN not found — select State & City manually';
      }
    });
  }
  Widget _buildCreateDocumentsCard(bool isDark, Color surfaceColor, Color borderColor) {
    Widget docTile({
      required String title,
      required String docKey,
      required IconData icon,
      PlatformFile? singleFile,
      List<PlatformFile>? multiFiles,
    }) {
      final hasFile = singleFile != null || (multiFiles != null && multiFiles.isNotEmpty);
      final fileName = singleFile?.name ??
          (multiFiles != null && multiFiles.isNotEmpty
              ? '${multiFiles.length} file(s) attached'
              : 'PDF, PNG, JPG or WEBP');
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasFile
              ? const Color(0xFF059669).withValues(alpha: isDark ? 0.14 : 0.06)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFile ? const Color(0xFF059669).withValues(alpha: 0.45) : borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.check_circle_rounded : icon,
              size: 20,
              color: hasFile ? const Color(0xFF059669) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: hasFile ? const Color(0xFF059669) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile)
              IconButton(
                onPressed: () => _removeStagedDocument(docKey),
                icon: const Icon(Icons.close_rounded, size: 17, color: Color(0xFFEF4444)),
                tooltip: 'Remove',
              )
            else
              OutlinedButton(
                onPressed: () => _pickAndUploadDocument(docKey),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: BorderSide(color: const Color(0xFF059669).withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                ),
                child: Text('Attach', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      );
    }

    return _buildCreateSectionCard(
      icon: Icons.upload_file_outlined,
      stepNumber: '06',
      title: 'Business & Compliance Documents (Optional)',
      subtitle: 'Attached files are uploaded automatically right after seller creation',
      isDark: isDark,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoCol = constraints.maxWidth >= 680;
          if (!twoCol) {
            return Column(
              children: [
                docTile(title: 'GST Certificate', docKey: 'gstCertificate', icon: Icons.receipt_long_outlined, singleFile: _stagedGstFile),
                const SizedBox(height: 10),
                docTile(title: 'PAN Card', docKey: 'panCard', icon: Icons.credit_card_outlined, singleFile: _stagedPanFile),
                const SizedBox(height: 10),
                docTile(title: 'Aadhaar Card', docKey: 'aadhaarCard', icon: Icons.badge_outlined, singleFile: _stagedAadhaarFile),
                const SizedBox(height: 10),
                docTile(title: 'Agri / Trade Licence', docKey: 'licenceImage', icon: Icons.workspace_premium_outlined, multiFiles: _stagedLicenceFiles),
                const SizedBox(height: 10),
                docTile(title: 'Bank Cancelled Cheque', docKey: 'cancelledCheque', icon: Icons.account_balance_wallet_outlined, singleFile: _stagedCancelledChequeFile),
                const SizedBox(height: 10),
                docTile(title: 'Seller Agreement', docKey: 'agreement', icon: Icons.handshake_outlined, singleFile: _stagedAgreementFile),
              ],
            );
          }
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: docTile(title: 'GST Certificate', docKey: 'gstCertificate', icon: Icons.receipt_long_outlined, singleFile: _stagedGstFile)),
                  const SizedBox(width: 12),
                  Expanded(child: docTile(title: 'PAN Card', docKey: 'panCard', icon: Icons.credit_card_outlined, singleFile: _stagedPanFile)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: docTile(title: 'Aadhaar Card', docKey: 'aadhaarCard', icon: Icons.badge_outlined, singleFile: _stagedAadhaarFile)),
                  const SizedBox(width: 12),
                  Expanded(child: docTile(title: 'Agri / Trade Licence', docKey: 'licenceImage', icon: Icons.workspace_premium_outlined, multiFiles: _stagedLicenceFiles)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: docTile(title: 'Bank Cancelled Cheque', docKey: 'cancelledCheque', icon: Icons.account_balance_wallet_outlined, singleFile: _stagedCancelledChequeFile)),
                  const SizedBox(width: 12),
                  Expanded(child: docTile(title: 'Seller Agreement', docKey: 'agreement', icon: Icons.handshake_outlined, singleFile: _stagedAgreementFile)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SellerDocumentPreviewDialog extends StatefulWidget {
  final String title;
  final String sellerId;
  final String backendDocType;
  final List<String> availableLicences;

  const _SellerDocumentPreviewDialog({
    required this.title,
    required this.sellerId,
    required this.backendDocType,
    this.availableLicences = const [],
  });

  @override
  State<_SellerDocumentPreviewDialog> createState() => _SellerDocumentPreviewDialogState();
}

class _SellerDocumentPreviewDialogState extends State<_SellerDocumentPreviewDialog> {
  Uint8List? _fileBytes;
  bool _loading = true;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await context.read<AdminUserRepository>().downloadSellerDocument(
            userId: widget.sellerId,
            documentType: widget.backendDocType,
            index: _selectedIndex,
          );
      if (!mounted) return;
      setState(() {
        _fileBytes = bytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _isPdf =>
      _fileBytes != null &&
      _fileBytes!.length >= 4 &&
      _fileBytes![0] == 0x25 &&
      _fileBytes![1] == 0x50 &&
      _fileBytes![2] == 0x44 &&
      _fileBytes![3] == 0x46;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 580),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: Color(0xFF059669)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (widget.backendDocType == 'licence' && widget.availableLicences.length > 1) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 0; i < widget.availableLicences.length; i++)
                      ChoiceChip(
                        label: Text('File ${i + 1}'),
                        selected: _selectedIndex == i,
                        onSelected: (selected) {
                          if (selected) {
                            _selectedIndex = i;
                            _loadDocument();
                          }
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text('Unable to load preview: $_error'))
                          : _fileBytes == null || _fileBytes!.isEmpty
                              ? const Center(child: Text('No document data'))
                              : _isPdf
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.picture_as_pdf_rounded, size: 52, color: Color(0xFFE11D48)),
                                          const SizedBox(height: 10),
                                          Text(
                                            'PDF Document (${(_fileBytes!.length / 1024).toStringAsFixed(1)} KB)',
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    )
                                  : InteractiveViewer(
                                      child: Image.memory(_fileBytes!, fit: BoxFit.contain),
                                    ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_fileBytes != null && _fileBytes!.isNotEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: () => downloadBytes(
                        _fileBytes!,
                        '${widget.backendDocType}-${_selectedIndex + 1}.${_isPdf ? "pdf" : "png"}',
                      ),
                      icon: const Icon(Icons.download_rounded, size: 15),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarehouseAddressEntry {
  final TextEditingController villageAreaController;
  final TextEditingController address2Controller;
  final TextEditingController cityTehsilController;
  final TextEditingController stateController;
  final TextEditingController pincodeController;
  String? pincodeStatusText;
  List<String> extraCities = const [];
  bool isLoadingCities = false;

  _WarehouseAddressEntry({
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

  factory _WarehouseAddressEntry.fromAddress(UserAddress address) {
    return _WarehouseAddressEntry(
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
