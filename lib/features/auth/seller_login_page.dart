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
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.success),
            SizedBox(width: 10),
            Text('Login Successful', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Welcome to Seller Hub! You are being redirected to your seller dashboard.',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
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
                                constraints: const BoxConstraints(maxWidth: 480),
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
                                const SizedBox(height: 24),
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
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.primaryDark,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Agri-Commerce Portal',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontWeight: FontWeight.w500,
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
    final activeTabBg = isDark ? const Color(0xFF334155) : Colors.white;
    final primaryColor = isDark ? AppTheme.primaryLight : AppTheme.primaryDeep;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
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
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to manage your inventory, orders, and settlements.',
            style: TextStyle(
              fontSize: 13.5,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Tab Bar (Password vs OTP)
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: tabBg,
              borderRadius: BorderRadius.circular(10),
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
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: primaryColor,
              unselectedLabelColor: textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Password'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_android_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Mobile OTP'),
                    ],
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
              Expanded(child: Divider(color: border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'New to Seller Hub?',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                ),
              ),
              Expanded(child: Divider(color: border)),
            ],
          ),
          const SizedBox(height: 18),

          // Register Call-to-action
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Redirecting to Seller Onboarding Registration...')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? AppTheme.primary : AppTheme.primaryDeep,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                foregroundColor: primaryColor,
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Register as a New Seller / Dealer',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Support contacts banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkAccentBg : AppTheme.lightAccentBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.headset_mic_outlined,
                  color: isDark ? AppTheme.primaryLight : AppTheme.primaryDeep,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFD1FAE5) : AppTheme.primaryDark,
                      ),
                      children: const [
                        TextSpan(text: 'Need help logging in? Contact Seller Support at '),
                        TextSpan(
                          text: '1800-300-8899',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' (Mon-Sat, 9AM-7PM)'),
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
      spacing: 16,
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
          fontSize: 12,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
