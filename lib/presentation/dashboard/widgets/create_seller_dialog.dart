import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/admin_user.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/repositories/admin_user_repository.dart';
import '../../../logic/admin_user/admin_user_event.dart';
import '../../../logic/admin_user/seller_bloc.dart';

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

  bool _isSubmitting = false;
  String? _errorMessage;

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
      'role': 'SELLER',
      'shopName': _shopNameController.text.trim(),
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'email': _emailController.text.trim().toLowerCase(),
      'gstNumber': _gstController.text.trim().toUpperCase(),
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
                        _buildFieldLabel('GST Number (GSTIN) *', textPrimary),
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
                            if (v == null || v.trim().isEmpty) return 'GST number is required';
                            if (v.trim().length != 15) return 'GSTIN must be exactly 15 alphanumeric characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Address Row: City / Tehsil + State + Pincode
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('City / Tehsil', textPrimary),
                                  TextFormField(
                                    controller: _cityController,
                                    decoration: _inputDecoration(
                                      hint: 'e.g. Indore',
                                      icon: Icons.location_city_rounded,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      cardBgColor: cardBgColor,
                                      textSecondary: textSecondary,
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
                                  TextFormField(
                                    controller: _stateController,
                                    decoration: _inputDecoration(
                                      hint: 'e.g. Madhya Pradesh',
                                      icon: Icons.map_outlined,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      cardBgColor: cardBgColor,
                                      textSecondary: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
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
                                    decoration: _inputDecoration(
                                      hint: '452001',
                                      icon: Icons.pin_drop_outlined,
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
