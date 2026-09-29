import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'widgets/branding_banner.dart';
import 'widgets/otp_login_form.dart';
import 'widgets/password_login_form.dart';
import 'widgets/theme_toggle_button.dart';

class SellerLoginPage extends StatefulWidget {
  const SellerLoginPage({super.key});

  @override
  State<SellerLoginPage> createState() => _SellerLoginPageState();
}

class _SellerLoginPageState extends State<SellerLoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onLoginSuccess() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 24),
            const SizedBox(width: 10),
            Text(
              'Login Successful',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Welcome to Seller Hub! You are being redirected to your seller dashboard.',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Proceed to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? AppTheme.darkSurfaceBg : AppTheme.lightSurfaceBg;

    return SelectionArea(
      child: Scaffold(
        backgroundColor: surfaceBg,
        body: Stack(
          children: [
            // Main Content Area
            isDesktop
                ? Row(
                    children: [
                      // Left Branding & Value Proposition Banner
                      const Expanded(
                        flex: 5,
                        child: BrandingBanner(),
                      ),

                      // Right Authentication Form Area
                      Expanded(
                        flex: 6,
                        child: Container(
                          color: surfaceBg,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 490),
                                child: _buildAuthCard(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: surfaceBg,
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Column(
                              children: [
                                _buildMobileHeader(context),
                                const SizedBox(height: 20),
                                _buildAuthCard(context),
                                const SizedBox(height: 24),
                                _buildFooterLinks(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

            // Top-right Theme Toggle on Desktop
            if (isDesktop)
              const Positioned(
                top: 20,
                right: 24,
                child: ThemeToggleButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.primary : AppTheme.primaryDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.agriculture_rounded,
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELLER HUB',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.primaryDeep,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Agri-Commerce Portal',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const ThemeToggleButton(),
      ],
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final tabBg = isDark ? AppTheme.darkTabBg : AppTheme.lightTabBg;
    final activeTabBg = isDark ? const Color(0xFF243048) : Colors.white;
    final primaryColor = isDark ? AppTheme.primaryLight : AppTheme.primaryDeep;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            'Welcome back, Partner',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to manage your inventory, orders, and settlements.',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Tab Bar (Password vs OTP)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: tabBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: 1),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: activeTabBg,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: isDark ? AppTheme.primary : AppTheme.primaryDeep,
              unselectedLabelColor: textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Password'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Mobile OTP'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tab views
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return _tabController.index == 0
                  ? PasswordLoginForm(onLoginSuccess: _onLoginSuccess)
                  : OtpLoginForm(onLoginSuccess: _onLoginSuccess);
            },
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: border, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'New to Seller Hub?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                ),
              ),
              Expanded(child: Divider(color: border, thickness: 1)),
            ],
          ),
          const SizedBox(height: 18),

          // Register Call-to-action
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Redirecting to Seller Onboarding Registration...')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? AppTheme.primary : AppTheme.primaryDeep,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                foregroundColor: primaryColor,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 19,
                      color: isDark ? AppTheme.primary : AppTheme.primaryDeep,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Register as a New Seller / Dealer',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? AppTheme.primaryLight : AppTheme.primaryDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Support contacts banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C241B) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppTheme.primary.withValues(alpha: 0.35) : AppTheme.primaryDeep.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.headset_mic_rounded,
                    color: isDark ? AppTheme.primary : AppTheme.primaryDeep,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                        color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF0F5132),
                      ),
                      children: [
                        const TextSpan(text: 'Need help logging in? Call Seller Support: '),
                        TextSpan(
                          text: '1800-300-8899',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.primaryLight : const Color(0xFF064E3B),
                          ),
                        ),
                        const TextSpan(
                          text: ' (Mon-Sat, 10AM-7PM)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildFooterLink(context, 'Seller Policies'),
        _buildFooterLink(context, 'Privacy Policy'),
        _buildFooterLink(context, 'Terms of Service'),
        _buildFooterLink(context, 'Help Center'),
      ],
    );
  }

  Widget _buildFooterLink(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {},
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
