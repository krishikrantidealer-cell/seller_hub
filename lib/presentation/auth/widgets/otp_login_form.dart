import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';

class OtpLoginForm extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const OtpLoginForm({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<OtpLoginForm> createState() => _OtpLoginFormState();
}

class _OtpLoginFormState extends State<OtpLoginForm> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpPinController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _pinFocus = FocusNode();

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _sendViaWhatsApp = true;
  int _timerSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpPinController.dispose();
    _phoneFocus.dispose();
    _pinFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _timerSeconds = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter a valid 10-digit registered mobile number',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(20),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    context.read<AuthBloc>().add(OtpRequested(phone));

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
      _startTimer();
      _otpPinController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pinFocus.requestFocus();
      });
    });
  }

  void _verifyOtp() {
    final otp = _otpPinController.text.trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter the full 6-digit OTP code',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(20),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    context.read<AuthBloc>().add(OtpSubmitted(
      phoneNumber: _phoneController.text.trim(),
      otp: otp,
    ));

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onLoginSuccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeInQuad,
        transitionBuilder: (child, animation) {
          final isPhoneView = child.key == const ValueKey('phone_input_view');
          final offsetAnimation = Tween<Offset>(
            begin: Offset(isPhoneView ? -0.03 : 0.03, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart));
          final scaleAnimation = Tween<double>(
            begin: 0.985,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            ),
          );
        },
        child: !_isOtpSent
            ? KeyedSubtree(
                key: const ValueKey('phone_input_view'),
                child: _buildPhoneInputView(context, isDark),
              )
            : KeyedSubtree(
                key: const ValueKey('otp_verify_view'),
                child: _buildOtpVerificationView(context, isDark),
              ),
      ),
    );
  }

  Widget _buildPhoneInputView(BuildContext context, bool isDark) {
    final isValidLength = _phoneController.text.length == 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label with live indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mobile Number',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
            if (isValidLength)
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    '10 Digits',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Phone Input with Country Code Badge
        TextField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            hintText: 'Enter 10-digit number',
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 12, right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    '+91',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 18,
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ),
            suffixIcon: _phoneController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    onPressed: () => _phoneController.clear(),
                  )
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isValidLength
                    ? const Color(0xFF059669)
                    : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
                width: isValidLength ? 1.4 : 1.0,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Color(0xFF059669), width: 1.6),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onSubmitted: (_) => _sendOtp(),
        ),

        const SizedBox(height: 12),

        // WhatsApp OTP option checkbox
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _sendViaWhatsApp = !_sendViaWhatsApp),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: _sendViaWhatsApp,
                    activeColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _sendViaWhatsApp = val ?? true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Send backup OTP via WhatsApp Business',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Send OTP Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Send OTP Verification Code',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpVerificationView(BuildContext context, bool isDark) {
    // Luxury Pinput Theme Definitions
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2333) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF059669),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.6),
          width: 1.4,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with Phone number & Change button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    '+91 ${_phoneController.text}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  setState(() => _isOtpSent = false);
                  _phoneFocus.requestFocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text(
                        'Change',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
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
        ),

        const SizedBox(height: 18),

        // Pinput 6-Digit Grid
        Center(
          child: Pinput(
            length: 6,
            controller: _otpPinController,
            focusNode: _pinFocus,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            submittedPinTheme: submittedPinTheme,
            autofocus: true,
            showCursor: true,
            cursor: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  width: 18,
                  height: 2.2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            onCompleted: (pin) => _verifyOtp(),
          ),
        ),

        const SizedBox(height: 16),

        // Resend Timer & Resend Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  _timerSeconds > 0
                      ? 'Resend OTP in 00:${_timerSeconds.toString().padLeft(2, '0')}'
                      : 'Didn\'t receive OTP?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            if (_timerSeconds == 0)
              TextButton(
                onPressed: _sendOtp,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Resend Code',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // Verify & Login Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Verify & Proceed to Dashboard',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
