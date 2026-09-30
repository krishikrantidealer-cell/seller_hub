import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/seller.dart';
import '../../../core/models/product.dart';

class SellersView extends StatefulWidget {
  final List<SellerProfile> sellers;
  final List<Product> products;
  final ValueChanged<SellerProfile> onSelectSeller;
  final ValueChanged<String> onViewSellerProducts;
  final ValueChanged<SellerProfile> onSellerAdded;

  const SellersView({
    super.key,
    required this.sellers,
    required this.products,
    required this.onSelectSeller,
    required this.onViewSellerProducts,
    required this.onSellerAdded,
  });

  @override
  State<SellersView> createState() => _SellersViewState();
}

class _SellersViewState extends State<SellersView> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  final List<String> _statusOptions = const [
    'All',
    'VERIFIED',
    'ACTIVE',
    'KYC_PENDING',
    'SUSPENDED',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final isWide = MediaQuery.of(context).size.width >= 960;

    // Filter sellers by query & status
    final filtered = widget.sellers.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.tradeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.gstin.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.city.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatusFilter == 'All' || s.status == _selectedStatusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    final verifiedCount = widget.sellers.where((s) => s.status == 'VERIFIED').length;
    final pendingCount = widget.sellers.where((s) => s.status == 'KYC_PENDING').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Bar (Search + Onboard Button)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search sellers by Trade Name, Legal Name, ID, GSTIN, or City...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
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
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => _openOnboardSellerDialog(context),
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: Text(
                  'Onboard Seller',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Status Filter Chips & Metrics Strip
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusOptions.map((status) {
                    final isSelected = _selectedStatusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        label: Text(status.replaceAll('_', ' ')),
                        selected: isSelected,
                        selectedColor: const Color(0xFF059669).withValues(alpha: 0.16),
                        backgroundColor: surfaceColor,
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF059669) : borderColor,
                        ),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        onSelected: (_) => setState(() => _selectedStatusFilter = status),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 8),
              _buildMiniMetricBadge('Total Sellers', '${widget.sellers.length}', const Color(0xFF059669), isDark),
              const SizedBox(width: 6),
              _buildMiniMetricBadge('Verified', '$verifiedCount', const Color(0xFF10B981), isDark),
              const SizedBox(width: 6),
              _buildMiniMetricBadge('KYC Pending', '$pendingCount', const Color(0xFFF59E0B), isDark),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // High-Density Responsive Table Container
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              // Table Header (Desktop Only)
              if (isWide)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0A0F1D).withValues(alpha: 0.7) : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: _buildColHeader('SELLER & TRADE NAME', isDark)),
                      Expanded(flex: 3, child: _buildColHeader('CONTACT & LOCATION', isDark)),
                      Expanded(flex: 2, child: _buildColHeader('GSTIN & LICENSE', isDark)),
                      Expanded(flex: 2, child: _buildColHeader('METRICS & ORDERS', isDark)),
                      Expanded(flex: 2, child: _buildColHeader('STATUS', isDark)),
                      Expanded(flex: 2, child: _buildColHeader('ACTION', isDark, alignRight: true)),
                    ],
                  ),
                ),

              if (isWide) Divider(height: 1, color: borderColor),

              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 36, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        const SizedBox(height: 8),
                        Text(
                          'No sellers matching your search criteria',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final seller = filtered[index];
                    final productCount = widget.products.where((p) =>
                        p.sellerId == seller.id ||
                        (p.vendor.isNotEmpty && p.vendor.toLowerCase() == seller.tradeName.toLowerCase())).length;

                    return isWide
                        ? _buildTableRow(context, seller, productCount, isDark, borderColor)
                        : _buildMobileCard(context, seller, productCount, isDark, borderColor);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- DESKTOP TABLE ROW ---
  Widget _buildTableRow(
    BuildContext context,
    SellerProfile s,
    int productCount,
    bool isDark,
    Color borderColor,
  ) {
    final statusColor = s.status == 'VERIFIED'
        ? const Color(0xFF10B981)
        : (s.status == 'ACTIVE'
            ? const Color(0xFF059669)
            : (s.status == 'KYC_PENDING' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSelectSeller(s),
        hoverColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Seller & Trade Name (Flex 5)
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.tradeName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'ID: ${s.id.length > 12 ? '${s.id.substring(0, 10)}...' : s.id} • ${s.companyName}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contact & Location (Flex 3)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.contactPerson} • ${s.phone}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.city}, ${s.state}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // GSTIN & License (Flex 2)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.gstin,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.licenseNumber.isNotEmpty ? s.licenseNumber : 'Agri License Verified',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Metrics & Orders (Flex 2)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$productCount Products',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.totalOrders} Orders • ${s.rating} ★',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Status (Flex 2)
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      s.status.replaceAll('_', ' '),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ),

              // Action (Flex 2)
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => widget.onSelectSeller(s),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      'Profile',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MOBILE CARD ---
  Widget _buildMobileCard(
    BuildContext context,
    SellerProfile s,
    int productCount,
    bool isDark,
    Color borderColor,
  ) {
    return InkWell(
      onTap: () => widget.onSelectSeller(s),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.tradeName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s.status.replaceAll('_', ' '),
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF059669)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${s.contactPerson} • ${s.city}, ${s.state} • GST: ${s.gstin}',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$productCount Products listed',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6)),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => widget.onViewSellerProducts(s.tradeName),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: borderColor),
                      ),
                      child: Text('Products', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => widget.onSelectSeller(s),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Profile', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColHeader(String title, bool isDark, {bool alignRight = false}) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildMiniMetricBadge(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  void _openOnboardSellerDialog(BuildContext context) {
    final companyController = TextEditingController();
    final tradeController = TextEditingController();
    final personController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final gstinController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController(text: 'Gujarat');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: borderColor)),
        child: Container(
          width: 540,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Icon(Icons.person_add_rounded, color: Color(0xFF059669), size: 20)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Onboard New Seller',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _buildDialogField('Trade / Brand Name *', tradeController, 'e.g. Kisan Care', isDark, borderColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDialogField('Legal Entity Name *', companyController, 'e.g. Kisan Care Pvt Ltd', isDark, borderColor)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDialogField('Contact Person *', personController, 'e.g. Ramesh Patel', isDark, borderColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDialogField('Phone Number *', phoneController, '+91 98765 43210', isDark, borderColor)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDialogField('Email Address *', emailController, 'seller@brand.com', isDark, borderColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDialogField('GSTIN *', gstinController, '24AABCK1234F1Z5', isDark, borderColor)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDialogField('City', cityController, 'Ahmedabad', isDark, borderColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDialogField('State', stateController, 'Gujarat', isDark, borderColor)),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (tradeController.text.trim().isEmpty || companyController.text.trim().isEmpty) return;

                      final newSeller = SellerProfile(
                        id: '6ab${DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(21, '0')}',
                        sellerCode: 'SLR-NEW-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                        companyName: companyController.text.trim(),
                        tradeName: tradeController.text.trim(),
                        contactPerson: personController.text.trim(),
                        email: emailController.text.trim(),
                        phone: phoneController.text.trim(),
                        gstin: gstinController.text.trim(),
                        city: cityController.text.trim(),
                        state: stateController.text.trim(),
                        status: 'ACTIVE',
                        isVerified: true,
                        joinedAt: DateTime.now(),
                      );

                      widget.onSellerAdded(newSeller);
                      Navigator.of(ctx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Seller "${newSeller.tradeName}" registered successfully.'),
                          backgroundColor: const Color(0xFF059669),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Register Seller', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, String hint, bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          ),
        ),
      ],
    );
  }
}
