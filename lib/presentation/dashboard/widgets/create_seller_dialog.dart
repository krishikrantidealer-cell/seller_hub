import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/admin_user.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/india_location_helper.dart';
import '../../../domain/repositories/admin_user_repository.dart';
import '../../../logic/admin_user/admin_user_event.dart';
import '../../../logic/admin_user/seller_bloc.dart';
import 'variant_live_pricing.dart';

class CreateSellerDialog extends StatefulWidget {
  final void Function(AdminUser createdSeller)? onSellerCreated;

  const CreateSellerDialog({
    super.key,
    this.onSellerCreated,
  });

  @override
  State<CreateSellerDialog> createState() => _CreateSellerDialogState();
}

class _CreateSellerDialogState extends State<CreateSellerDialog> {
  final _formKey = GlobalKey<FormState>();

  final _shopNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();

  final _villageController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _monthlyTargetController = TextEditingController();
  final _commissionController = TextEditingController();
  String _pricingModel = 'MARKETPLACE';

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isLookingUpPincode = false;
  bool _isLoadingCities = false;
  List<String> _extraPincodeCities = const [];
  PlatformFile? _logoFile;
  Uint8List? _logoBytes;

  Future<void> _pickLogo() async {
    final res = await FilePicker.pickFiles(type: FileType.image);
    if (res.isEmpty) return;
    final picked = res.first;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _logoFile = picked;
      _logoBytes = bytes;
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

  Future<void> _onPincodeChanged(String val) async {
    final clean = val.trim();
    if (clean.length != 6) return;
    setState(() => _isLookingUpPincode = true);
    final result = await IndiaLocationHelper.lookupPincode(clean);
    if (!mounted || _pincodeController.text.trim() != clean) return;
    setState(() {
      _isLookingUpPincode = false;
      if (result != null) {
        _stateController.text = result.state;
        _extraPincodeCities = result.cities;
        _cityController.text = result.primaryCity;
      }
    });
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _villageController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _monthlyTargetController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final payload = <String, dynamic>{
      'shopName': _shopNameController.text.trim(),
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'email': _emailController.text.trim().toLowerCase(),
      if (_gstController.text.trim().isNotEmpty)
        'gstNumber': _gstController.text.trim().toUpperCase(),
      'pricingModel': _pricingModel,
      'commissionPercentage': _pricingModel == 'DEALER_COMMISSION'
          ? (double.tryParse(_commissionController.text.trim()) ?? 0.0)
          : 0.0,
    };

    final village = _villageController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (village.isNotEmpty || city.isNotEmpty || state.isNotEmpty || pincode.isNotEmpty) {
      payload['address'] = {
        'villageArea': village,
        'address2': '',
        'cityTehsil': city,
        'state': state,
        'pincode': pincode,
        'country': 'India',
      };
    }

    final targetStr = _monthlyTargetController.text.trim();
    if (targetStr.isNotEmpty) {
      final target = int.tryParse(targetStr);
      if (target != null && target >= 0) {
        payload['monthlyTarget'] = target;
      }
    }

    try {
      final repository = context.read<AdminUserRepository>();
      if (_logoFile != null) {
        final logoUrl = await repository.uploadSellerLogo(_logoFile!);
        payload['shopImage'] = logoUrl;
      }
      final createdUser = await repository.createSeller(payload);

      if (mounted) {
        context.read<SellerBloc>().add(UpdateLocalAdminUser(createdUser));
        context.read<SellerBloc>().add(const InitializeAdminUsers(forceRefresh: true));

        widget.onSellerCreated?.call(createdUser);
        Navigator.of(context).pop(createdUser);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Seller "${createdUser.displayName}" created successfully!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e is ApiException
              ? e.message
              : e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Seller Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Provision a new verified seller storefront on EBS BioCrop',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        foregroundColor: textSecondary,
                        hoverColor: borderColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),

              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF881337).withValues(alpha: 0.25) : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFFBE123C) : const Color(0xFFFECDD3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Seller Logo Picker
                        _buildFieldLabel('Seller Logo (Optional)', textPrimary),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _logoBytes != null
                                    ? Image.memory(_logoBytes!, fit: BoxFit.cover)
                                    : Icon(
                                        Icons.storefront_rounded,
                                        color: textSecondary,
                                        size: 26,
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _logoFile != null
                                          ? _logoFile!.name
                                          : 'Upload Seller / Brand Logo',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PNG, JPG or WEBP (max 5 MB)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_logoFile != null)
                                IconButton(
                                  tooltip: 'Remove logo',
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => setState(() {
                                            _logoFile = null;
                                            _logoBytes = null;
                                          }),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFE11D48),
                                    size: 20,
                                  ),
                                ),
                              OutlinedButton.icon(
                                onPressed: _isSubmitting ? null : _pickLogo,
                                icon: const Icon(Icons.upload_rounded, size: 16),
                                label: Text(
                                  _logoFile != null ? 'Change' : 'Upload Logo',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF059669),
                                  side: const BorderSide(color: Color(0xFF059669)),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Shop / Trade Name
                        _buildFieldLabel('Shop / Trade Name *', textPrimary),
                        TextFormField(
                          controller: _shopNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            hint: 'e.g. Patel Agro Traders & Bio Solutions',
                            icon: Icons.store_rounded,
                            isDark: isDark,
                            borderColor: borderColor,
                            cardBgColor: cardBgColor,
                            textSecondary: textSecondary,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Shop name is required';
                            if (v.trim().length < 3) return 'Shop name must be at least 3 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Contact Person (First Name + Last Name)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('First Name *', textPrimary),
                                  TextFormField(
                                    controller: _firstNameController,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: _inputDecoration(
                                      hint: 'e.g. Ramesh',
                                      icon: Icons.person_outline_rounded,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      cardBgColor: cardBgColor,
                                      textSecondary: textSecondary,
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'First name required' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Last Name *', textPrimary),
                                  TextFormField(
                                    controller: _lastNameController,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: _inputDecoration(
                                      hint: 'e.g. Patel',
                                      icon: Icons.person_outline_rounded,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      cardBgColor: cardBgColor,
                                      textSecondary: textSecondary,
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Last name required' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Contact Details (Phone + Email)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Phone Number *', textPrimary),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: _inputDecoration(
                                      hint: '10-digit number',
                                      prefixText: '+91 ',
                                      icon: Icons.phone_rounded,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      cardBgColor: cardBgColor,
                                      textSecondary: textSecondary,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Phone number required';
                                      if (!RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) {
                                        return 'Enter valid 10-digit mobile number';
                                      }
                                      return null;
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
                                  _buildFieldLabel('Email Address *', textPrimary),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _inputDecoration(
                                      hint: 'e.g. seller@biocrop.in',
                                      icon: Icons.email_outlined,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      cardBgColor: cardBgColor,
                                      textSecondary: textSecondary,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Email is required';
                                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // GST Number
                        _buildFieldLabel('GST Number (GSTIN, Optional)', textPrimary),
                        TextFormField(
                          controller: _gstController,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(15),
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                          ],
                          decoration: _inputDecoration(
                            hint: '15-digit GSTIN, e.g. 23AAAAA0000A1Z5',
                            icon: Icons.badge_outlined,
                            isDark: isDark,
                            borderColor: borderColor,
                            cardBgColor: cardBgColor,
                            textSecondary: textSecondary,
                          ),
                          validator: (v) {
                            final trimmed = v?.trim() ?? '';
                            if (trimmed.isNotEmpty && trimmed.length != 15) {
                              return 'GSTIN must be 15 characters if provided';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Address Row: City / Tehsil + State + Pincode
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Pincode', textPrimary),
                                  TextFormField(
                                    controller: _pincodeController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                    onChanged: _onPincodeChanged,
                                    decoration: _inputDecoration(
                                      hint: '452001',
                                      icon: Icons.pin_drop_outlined,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      cardBgColor: cardBgColor,
                                      textSecondary: textSecondary,
                                    ).copyWith(
                                      suffixIcon: _isLookingUpPincode
                                          ? const Padding(
                                              padding: EdgeInsets.all(10),
                                              child: SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('State', textPrimary),
                                  Builder(
                                    builder: (context) {
                                      final normState = IndiaLocationHelper.normalizeState(_stateController.text);
                                      final states = IndiaLocationHelper.states;
                                      final selectedState = states.contains(normState) ? normState : null;
                                      return DropdownButtonFormField<String>(
                                        initialValue: selectedState,
                                        isExpanded: true,
                                        dropdownColor: surfaceColor,
                                        decoration: _inputDecoration(
                                          hint: 'Select State',
                                          icon: Icons.map_outlined,
                                          isDark: isDark,
                                          borderColor: borderColor,
                                          cardBgColor: cardBgColor,
                                          textSecondary: textSecondary,
                                        ),
                                        items: states
                                            .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) _onStateSelected(val);
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('City / Tehsil', textPrimary),
                                  Builder(
                                    builder: (context) {
                                      final normState = IndiaLocationHelper.normalizeState(_stateController.text);
                                      final hasState = IndiaLocationHelper.states.contains(normState);
                                      final cities = hasState
                                          ? IndiaLocationHelper.cachedCitiesForState(
                                              normState,
                                              extraCities: [
                                                ..._extraPincodeCities,
                                                if (_cityController.text.trim().isNotEmpty) _cityController.text.trim(),
                                              ],
                                            )
                                          : <String>[];
                                      final curCity = _cityController.text.trim();
                                      final selectedCity = cities.contains(curCity) ? curCity : null;
                                      return DropdownButtonFormField<String>(
                                        initialValue: selectedCity,
                                        isExpanded: true,
                                        dropdownColor: surfaceColor,
                                        decoration: _inputDecoration(
                                          hint: _isLoadingCities
                                              ? 'Loading...'
                                              : (hasState ? 'Select City' : 'State first'),
                                          icon: Icons.location_city_rounded,
                                          isDark: isDark,
                                          borderColor: borderColor,
                                          cardBgColor: cardBgColor,
                                          textSecondary: textSecondary,
                                        ),
                                        items: cities
                                            .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                                            .toList(),
                                        onChanged: !hasState
                                            ? null
                                            : (val) {
                                                if (val == null) return;
                                                setState(() => _cityController.text = val);
                                              },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Village / Area + Monthly Target
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Village / Area / Street', textPrimary),
                                  TextFormField(
                                    controller: _villageController,
                                    decoration: _inputDecoration(
                                      hint: 'e.g. Krishi Mandi Road, Sector 3',
                                      icon: Icons.home_work_outlined,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      cardBgColor: cardBgColor,
                                      textSecondary: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Monthly Target (₹)', textPrimary),
                                  TextFormField(
                                    controller: _monthlyTargetController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: _inputDecoration(
                                      hint: 'e.g. 100000',
                                      prefixText: '₹ ',
                                      icon: Icons.trending_up_rounded,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      cardBgColor: cardBgColor,
                                      textSecondary: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                        ),
                        if (_pricingModel == 'DEALER_COMMISSION') ...[
                          const SizedBox(height: 12),
                          _buildFieldLabel('Commission (%) *', textPrimary),
                          TextFormField(
                            controller: _commissionController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$')),
                            ],
                            decoration: _inputDecoration(
                              hint: 'e.g. 12.5',
                              icon: Icons.percent_rounded,
                              isDark: isDark,
                              borderColor: borderColor,
                              cardBgColor: cardBgColor,
                              textSecondary: textSecondary,
                            ),
                            validator: (v) {
                              if (_pricingModel != 'DEALER_COMMISSION') return null;
                              final val = double.tryParse(v?.trim() ?? '');
                              if (val == null || val < 0 || val > 100) {
                                return 'Enter commission between 0 and 100%';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              Divider(height: 1, color: borderColor),

              // Actions Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _isSubmitting ? 'Creating Seller...' : 'Create Seller',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
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

  Widget _buildFieldLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color borderColor,
    required Color cardBgColor,
    required Color textSecondary,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        color: textSecondary.withValues(alpha: 0.7),
      ),
      prefixIcon: Icon(icon, size: 18, color: textSecondary),
      filled: true,
      fillColor: cardBgColor,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE11D48)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      isDense: true,
    );
  }
}
