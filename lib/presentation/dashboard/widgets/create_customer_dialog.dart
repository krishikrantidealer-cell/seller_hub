import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/admin_user.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/repositories/admin_user_repository.dart';
import '../../../logic/admin_user/admin_user_event.dart';
import '../../../logic/admin_user/customer_bloc.dart';

class CreateCustomerDialog extends StatefulWidget {
  final void Function(AdminUser createdCustomer)? onCustomerCreated;

  const CreateCustomerDialog({
    super.key,
    this.onCustomerCreated,
  });

  @override
  State<CreateCustomerDialog> createState() => _CreateCustomerDialogState();
}

class _CreateCustomerDialogState extends State<CreateCustomerDialog> {
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  final _villageController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _villageController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
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
      'role': 'CUSTOMER',
      'phoneNumber': _phoneController.text.trim(),
    };

    final firstName = _firstNameController.text.trim();
    if (firstName.isNotEmpty) payload['firstName'] = firstName;

    final lastName = _lastNameController.text.trim();
    if (lastName.isNotEmpty) payload['lastName'] = lastName;

    final email = _emailController.text.trim().toLowerCase();
    if (email.isNotEmpty) payload['email'] = email;

    final village = _villageController.text.trim();
    final address2 = _address2Controller.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (village.isNotEmpty || address2.isNotEmpty || city.isNotEmpty || state.isNotEmpty || pincode.isNotEmpty) {
      payload['address'] = {
        'villageArea': village,
        'address2': address2,
        'cityTehsil': city,
        'state': state,
        'pincode': pincode,
        'country': 'India',
      };
    }

    try {
      final repository = context.read<AdminUserRepository>();
      final createdUser = await repository.createCustomer(payload);

      if (mounted) {
        context.read<CustomerBloc>().add(UpdateLocalAdminUser(createdUser));
        context.read<CustomerBloc>().add(const InitializeAdminUsers(forceRefresh: true));

        widget.onCustomerCreated?.call(createdUser);
        Navigator.of(context).pop(createdUser);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Customer "${createdUser.displayName}" created successfully!'),
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
        constraints: const BoxConstraints(maxWidth: 580),
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
                      child: const Icon(Icons.person_add_rounded, color: Color(0xFF059669), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Customer Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Provision a new farmer or buyer account on EBS BioCrop',
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

                        // Phone Number
                        _buildFieldLabel('Phone Number *', textPrimary),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: _inputDecoration(
                            hint: '10-digit mobile number',
                            prefixText: '+91 ',
                            icon: Icons.phone_rounded,
                            isDark: isDark,
                            borderColor: borderColor,
                            cardBgColor: cardBgColor,
                            textSecondary: textSecondary,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Phone number is required';
                            if (!RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) {
                              return 'Enter a valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Name Row (First Name + Last Name)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('First Name', textPrimary),
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
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Last Name', textPrimary),
                                  TextFormField(
                                    controller: _lastNameController,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: _inputDecoration(
                                      hint: 'e.g. Sharma',
                                      icon: Icons.person_outline_rounded,
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

                        // Email Address
                        _buildFieldLabel('Email Address (Optional)', textPrimary),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            hint: 'e.g. farmer@example.com',
                            icon: Icons.email_outlined,
                            isDark: isDark,
                            borderColor: borderColor,
                            cardBgColor: cardBgColor,
                            textSecondary: textSecondary,
                          ),
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                                return 'Enter a valid email address';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Delivery Address: Village / Street + Address Line 2
                        _buildFieldLabel('Village / Street / Colony', textPrimary),
                        TextFormField(
                          controller: _villageController,
                          decoration: _inputDecoration(
                            hint: 'e.g. Village Rampura, Ward 4',
                            icon: Icons.home_outlined,
                            isDark: isDark,
                            borderColor: borderColor,
                            cardBgColor: cardBgColor,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Address Line 2 / Landmark', textPrimary),
                        TextFormField(
                          controller: _address2Controller,
                          decoration: _inputDecoration(
                            hint: 'e.g. Near Panchayat Bhavan',
                            icon: Icons.signpost_outlined,
                            isDark: isDark,
                            borderColor: borderColor,
                            cardBgColor: cardBgColor,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // City / State / Pincode Row
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
                                      hint: 'e.g. Bhopal',
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
                                      hint: '462016',
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
                        _isSubmitting ? 'Creating Customer...' : 'Create Customer',
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
