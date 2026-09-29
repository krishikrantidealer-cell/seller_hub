import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSent = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: SelectionArea(
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          child: _isSent ? _buildSuccessView(context) : _buildFormView(context),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final textMuted = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkAccentBg : AppTheme.lightAccentBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  color: isDark ? AppTheme.primaryLight : AppTheme.primaryDeep,
                  size: 24,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Reset your password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your registered email address or phone number and we will send you a password recovery link.',
            style: TextStyle(fontSize: 13.5, color: textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            'Registered Email or Phone',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'e.g. dealer@agrobusiness.com or 9876543210',
              prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: textMuted),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your registered email or phone';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleReset,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    )
                  : const Text('Send Reset Instructions'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkAccentBg : AppTheme.lightAccentBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded, color: AppTheme.success, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          'Recovery link sent!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'We have sent password reset instructions to ${_emailController.text}. Please check your inbox and spam folders.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: textSecondary, height: 1.4),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }
}
