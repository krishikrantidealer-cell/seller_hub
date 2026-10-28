import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/admin_user.dart';
import '../../../logic/admin_user/admin_user_event.dart';
import '../../../logic/admin_user/admin_user_state.dart';
import '../../../logic/admin_user/customer_bloc.dart';

class CustomersView extends StatefulWidget {
  final bool isWide;
  final ValueChanged<AdminUser>? onSelectCustomer;

  const CustomersView({
    super.key,
    required this.isWide,
    this.onSelectCustomer,
  });

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return BlocConsumer<CustomerBloc, AdminUserState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.actionSuccessMessage != null && state.actionSuccessMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final filtered = state.filteredUsers;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. KPI Metric Summary Cards
            _buildMetricsOverview(context, state, isDark, surfaceColor, borderColor),

            const SizedBox(height: 16),

            // 2. Action & Filter Bar (Search + Status + Refresh)
            _buildActionBar(context, state, isDark, surfaceColor, borderColor),

            const SizedBox(height: 16),

            // 3. Customer Data Table or Cards
            _buildCustomerContent(context, state, filtered, isDark, surfaceColor, borderColor),
          ],
        );
      },
    );
  }

  Widget _buildMetricsOverview(
    BuildContext context,
    AdminUserState state,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final items = [
          _buildMetricCard(
            title: 'TOTAL CUSTOMERS',
            value: '${state.totalCount}',
            subtitle: 'Registered buyer accounts',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF059669),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildMetricCard(
            title: 'VERIFIED BUYERS',
            value: '${state.verifiedCount}',
            subtitle: 'OTP / Phone verified',
            icon: Icons.verified_user_rounded,
            color: const Color(0xFF2563EB),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildMetricCard(
            title: 'KYC PENDING',
            value: '${state.kycPendingCount}',
            subtitle: 'Documentation incomplete',
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFD97706),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildMetricCard(
            title: 'BLOCKED ACCOUNTS',
            value: '${state.blockedCount}',
            subtitle: 'Access restricted by admin',
            icon: Icons.block_rounded,
            color: const Color(0xFFDC2626),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        ];

        if (isNarrow) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((e) => SizedBox(width: (constraints.maxWidth - 10) / 2, child: e)).toList(),
          );
        }

        return Row(
          children: items
              .map((e) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: e,
                    ),
                  ))
              .toList(),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
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
                    fontSize: 18,
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

  Widget _buildActionBar(
    BuildContext context,
    AdminUserState state,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  context.read<CustomerBloc>().add(SearchAdminUsers(val));
                },
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search customers by Name, Phone, Email, City or ID...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            context.read<CustomerBloc>().add(const SearchAdminUsers(''));
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF059669), width: 1.4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Status Filter Dropdown
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.statusFilter,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                dropdownColor: surfaceColor,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'VERIFIED', child: Text('Verified Only')),
                  DropdownMenuItem(value: 'KYC_PENDING', child: Text('KYC Pending')),
                  DropdownMenuItem(value: 'BLOCKED', child: Text('Blocked Only')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    context.read<CustomerBloc>().add(FilterAdminUsersStatus(val));
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Refresh Button
          IconButton(
            tooltip: 'Refresh customers',
            icon: const Icon(Icons.refresh_rounded, size: 18),
            onPressed: () {
              context.read<CustomerBloc>().add(const InitializeAdminUsers(forceRefresh: true));
            },
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: borderColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerContent(
    BuildContext context,
    AdminUserState state,
    List<AdminUser> filtered,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    if (state.status == AdminUserStatus.loading && state.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 2.5),
            const SizedBox(height: 12),
            Text(
              'Loading customers directory...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == AdminUserStatus.error && state.users.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
              const SizedBox(height: 10),
              Text(
                'Failed to load customers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.errorMessage ?? 'An error occurred while fetching customer records.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<CustomerBloc>().add(const InitializeAdminUsers(forceRefresh: true));
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 42,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),
              Text(
                state.users.isEmpty ? 'No customers found' : 'No matching customers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.users.isEmpty
                    ? 'No registered customer accounts retrieved from the backend API.'
                    : 'Try adjusting your search query or filter criteria.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (widget.isWide) {
      return _buildDesktopTable(context, filtered, isDark, surfaceColor, borderColor);
    }

    return _buildMobileCardList(context, filtered, isDark, surfaceColor, borderColor);
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<AdminUser> customers,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: _tableHeaderCell('CUSTOMER', isDark)),
                Expanded(flex: 2, child: _tableHeaderCell('PHONE / CONTACT', isDark)),
                Expanded(flex: 3, child: _tableHeaderCell('LOCATION / ADDRESS', isDark)),
                Expanded(flex: 2, child: _tableHeaderCell('STATUS', isDark)),
                Expanded(flex: 2, child: _tableHeaderCell('REGISTERED', isDark)),
                SizedBox(width: 130, child: _tableHeaderCell('ACTIONS', isDark, alignRight: true)),
              ],
            ),
          ),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: customers.length,
            separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
            itemBuilder: (context, index) {
                final user = customers[index];
                return InkWell(
                  onTap: () {
                    if (widget.onSelectCustomer != null) {
                      widget.onSelectCustomer!(user);
                    } else {
                      _showCustomerDetailsDialog(context, user, isDark, surfaceColor, borderColor);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Customer Column
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF059669).withValues(alpha: 0.15),
                                child: Text(
                                  _getInitials(user.fullName),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName.isNotEmpty ? user.fullName : user.displayName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: ${user.id}',
                                      style: GoogleFonts.jetBrainsMono(
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
                        ),

                        // Phone / Contact Column
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    user.phoneNumber,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              if (user.email != null && user.email!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.mail_outline_rounded,
                                      size: 13,
                                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        user.email!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Location / Address Column
                        Expanded(
                          flex: 3,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  user.fullAddress.isNotEmpty ? user.fullAddress : 'No address provided',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status Column
                        Expanded(
                          flex: 2,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              if (user.isBlocked)
                                _statusBadge('BLOCKED', const Color(0xFFDC2626), isDark)
                              else ...[
                                if (user.isVerified)
                                  _statusBadge('VERIFIED', const Color(0xFF059669), isDark),
                                if (user.isProfileComplete)
                                  _statusBadge('PROFILE OK', const Color(0xFF2563EB), isDark)
                                else
                                  _statusBadge('INCOMPLETE', const Color(0xFFD97706), isDark),
                              ],
                            ],
                          ),
                        ),

                        // Registered Column
                        Expanded(
                          flex: 2,
                          child: Text(
                            user.createdAt != null
                                ? '${user.createdAt!.day.toString().padLeft(2, '0')}/${user.createdAt!.month.toString().padLeft(2, '0')}/${user.createdAt!.year}'
                                : '—',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),

                        // Actions Column
                        SizedBox(
                          width: 130,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 16),
                                tooltip: 'View details',
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () {
                                  if (widget.onSelectCustomer != null) {
                                    widget.onSelectCustomer!(user);
                                  } else {
                                    _showCustomerDetailsDialog(
                                      context,
                                      user,
                                      isDark,
                                      surfaceColor,
                                      borderColor,
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  user.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                                  size: 16,
                                  color: user.isBlocked ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                                tooltip: user.isBlocked ? 'Unblock customer' : 'Block customer',
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () => _confirmToggleBlock(context, user),
                              ),
                              IconButton(
                                icon: Icon(
                                  user.isDeleted ? Icons.restore_from_trash_rounded : Icons.delete_outline_rounded,
                                  size: 16,
                                  color: user.isDeleted ? const Color(0xFF059669) : const Color(0xFFE11D48),
                                ),
                                tooltip: user.isDeleted ? 'Restore customer account' : 'Soft-delete / Deactivate customer',
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () => _confirmToggleDelete(context, user),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMobileCardList(
    BuildContext context,
    List<AdminUser> customers,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = customers[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF059669).withValues(alpha: 0.15),
                    child: Text(
                      _getInitials(user.fullName),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName.isNotEmpty ? user.fullName : user.displayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          user.phoneNumber,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (user.isBlocked)
                        _statusBadge('BLOCKED', const Color(0xFFDC2626), isDark)
                      else if (user.isVerified)
                        _statusBadge('VERIFIED', const Color(0xFF059669), isDark),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (user.fullAddress.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        user.fullAddress,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    user.createdAt != null
                        ? 'Registered: ${user.createdAt!.day.toString().padLeft(2, '0')}/${user.createdAt!.month.toString().padLeft(2, '0')}/${user.createdAt!.year}'
                        : '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          if (widget.onSelectCustomer != null) {
                            widget.onSelectCustomer!(user);
                          } else {
                            _showCustomerDetailsDialog(
                              context,
                              user,
                              isDark,
                              surfaceColor,
                              borderColor,
                            );
                          }
                        },
                        icon: const Icon(Icons.info_outline_rounded, size: 14),
                        label: const Text('Details'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          user.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                          size: 16,
                          color: user.isBlocked ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                        tooltip: user.isBlocked ? 'Unblock customer' : 'Block customer',
                        onPressed: () => _confirmToggleBlock(context, user),
                      ),
                      IconButton(
                        icon: Icon(
                          user.isDeleted ? Icons.restore_from_trash_rounded : Icons.delete_outline_rounded,
                          size: 16,
                          color: user.isDeleted ? const Color(0xFF059669) : const Color(0xFFE11D48),
                        ),
                        tooltip: user.isDeleted ? 'Restore customer account' : 'Deactivate customer',
                        onPressed: () => _confirmToggleDelete(context, user),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tableHeaderCell(String text, bool isDark, {bool alignRight = false}) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }

  Widget _statusBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
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

  void _confirmToggleBlock(BuildContext context, AdminUser user) {
    final willBlock = !user.isBlocked;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          willBlock ? 'Block Customer Account?' : 'Unblock Customer Account?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          willBlock
              ? 'Are you sure you want to block ${user.fullName.isNotEmpty ? user.fullName : user.phoneNumber}? They will not be able to log in or place orders.'
              : 'Are you sure you want to unblock ${user.fullName.isNotEmpty ? user.fullName : user.phoneNumber}?',
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
                    ToggleBlockAdminUser(userId: user.id, blocked: willBlock),
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

  void _confirmToggleDelete(BuildContext context, AdminUser user) {
    final willDelete = !user.isDeleted;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          willDelete ? 'Deactivate Customer Account?' : 'Restore Customer Account?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          willDelete
              ? 'Are you sure you want to deactivate / soft-delete "${user.fullName.isNotEmpty ? user.fullName : user.phoneNumber}" (ID: ${user.id})? This calls {{baseUrl}}/api/v1/admin/users/${user.id}/deletion with {"deleted": true}. Their access will be revoked while historical orders remain preserved.'
              : 'Are you sure you want to restore "${user.fullName.isNotEmpty ? user.fullName : user.phoneNumber}"? Their account will be reactivated on the marketplace.',
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
                    ToggleDeleteAdminUser(userId: user.id, deleted: willDelete),
                  );
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

  void _showCustomerDetailsDialog(
    BuildContext context,
    AdminUser user,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF059669).withValues(alpha: 0.15),
                        child: Text(
                          _getInitials(user.fullName),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName.isNotEmpty ? user.fullName : user.displayName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Role: ${user.role} • ID: ${user.id}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 14),

                  // Detail Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('CONTACT INFORMATION', isDark),
                          _infoRow('Phone Number', user.phoneNumber, isDark),
                          _infoRow('Email Address', user.email ?? 'Not provided', isDark),

                          const SizedBox(height: 14),
                          _sectionHeader('PRIMARY ADDRESS', isDark),
                          if (user.address != null) ...[
                            _infoRow('Village / Area', user.address!.villageArea.isNotEmpty ? user.address!.villageArea : '—', isDark),
                            _infoRow('Address Line 2', user.address!.address2.isNotEmpty ? user.address!.address2 : '—', isDark),
                            _infoRow('City / Tehsil', user.address!.cityTehsil.isNotEmpty ? user.address!.cityTehsil : '—', isDark),
                            _infoRow('State', user.address!.state.isNotEmpty ? user.address!.state : '—', isDark),
                            _infoRow('Pincode', user.address!.pincode.isNotEmpty ? user.address!.pincode : '—', isDark),
                          ] else
                            Text(
                              'No primary address on file.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),

                          const SizedBox(height: 14),
                          _sectionHeader('ACCOUNT STATUS & VERIFICATION', isDark),
                          _infoRow('Phone Verified', user.isVerified ? 'Yes' : 'No', isDark),
                          _infoRow('Profile Completed', user.isProfileComplete ? 'Yes' : 'No', isDark),
                          _infoRow('KYC Complete', user.isKycComplete ? 'Yes' : 'No', isDark),
                          _infoRow('Account Blocked', user.isBlocked ? 'Yes' : 'No', isDark),

                          const SizedBox(height: 14),
                          _sectionHeader('AUDIT DATES', isDark),
                          _infoRow('Created At', user.createdAt?.toIso8601String() ?? '—', isDark),
                          _infoRow('Last Updated', user.updatedAt?.toIso8601String() ?? '—', isDark),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 12),

                  // Dialog Footer Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          _confirmToggleBlock(context, user);
                        },
                        icon: Icon(
                          user.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                          size: 15,
                        ),
                        label: Text(user.isBlocked ? 'Unblock Customer' : 'Block Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isBlocked ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          _confirmToggleDelete(context, user);
                        },
                        icon: Icon(
                          user.isDeleted ? Icons.restore_from_trash_rounded : Icons.delete_outline_rounded,
                          size: 15,
                        ),
                        label: Text(user.isDeleted ? 'Restore Account' : 'Deactivate Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isDeleted ? const Color(0xFF059669) : const Color(0xFFE11D48),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: const Color(0xFF059669),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
