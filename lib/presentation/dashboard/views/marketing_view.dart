import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/marketing_models.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/marketing/marketing_bloc.dart';
import '../../../logic/marketing/marketing_event.dart';
import '../../../logic/marketing/marketing_state.dart';

class MarketingView extends StatefulWidget {
  final VoidCallback? onOpenCatalogBanners;
  final VoidCallback? onOpenCatalogCollections;

  const MarketingView({
    super.key,
    this.onOpenCatalogBanners,
    this.onOpenCatalogCollections,
  });

  @override
  State<MarketingView> createState() => _MarketingViewState();
}

class _MarketingViewState extends State<MarketingView> {
  @override
  void initState() {
    super.initState();
    context.read<MarketingBloc>().add(const LoadMarketingOverview());
  }

  Future<void> _openCreateCampaignDialog() async {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    final ctaCtrl = TextEditingController();
    String channel = 'PUSH';
    String audience = 'ALL_FARMERS';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Launch Marketing Campaign',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Campaign Title *',
                      hintText: 'e.g. Kharif Season Insecticide Offer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: channel,
                          decoration: const InputDecoration(
                            labelText: 'Channel',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'PUSH', child: Text('Push Notification')),
                            DropdownMenuItem(value: 'WHATSAPP', child: Text('WhatsApp')),
                            DropdownMenuItem(value: 'BANNER', child: Text('Storefront Banner')),
                            DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
                            DropdownMenuItem(value: 'PROMO', child: Text('Promo Blast')),
                          ],
                          onChanged: (v) => setDialogState(() => channel = v ?? 'PUSH'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: audience,
                          decoration: const InputDecoration(
                            labelText: 'Audience',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ALL_FARMERS', child: Text('All Farmers')),
                            DropdownMenuItem(value: 'REPEAT_BUYERS', child: Text('Repeat Buyers')),
                            DropdownMenuItem(value: 'NEW_SIGNUPS', child: Text('New Signups')),
                            DropdownMenuItem(value: 'CART_ABANDONED', child: Text('Cart Abandoned')),
                          ],
                          onChanged: (v) => setDialogState(() => audience = v ?? 'ALL_FARMERS'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Campaign Message *',
                      hintText: 'Write promotional copy for farmers...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Landing / CTA URL (Optional)',
                      hintText: 'https://ebskrishidukaan.com/collections/best-seller',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) return;
                context.read<MarketingBloc>().add(
                      CreateMarketingCampaign(
                        title: titleCtrl.text.trim(),
                        channel: channel,
                        targetAudience: audience,
                        message: msgCtrl.text.trim(),
                        ctaUrl: ctaCtrl.text.trim(),
                        status: 'ACTIVE',
                      ),
                    );
                Navigator.of(ctx).pop();
              },
              icon: const Icon(Icons.campaign_rounded, size: 17),
              label: const Text('Launch Campaign'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF161E2E) : Colors.white;
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final session = context.watch<AuthBloc>().state.session;
    final canManage = session?.hasPermission('MARKETING_MANAGE') ?? true;

    return BlocConsumer<MarketingBloc, MarketingState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final kpis = state.kpis;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Marketing & Storefront Growth',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Launch multi-channel campaigns, manage storefront merchandising, and sync live via WebSocket.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Refresh Marketing Overview',
                      onPressed: () => context.read<MarketingBloc>().add(const LoadMarketingOverview(isRefresh: true)),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    if (canManage) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _openCreateCampaignDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'New Campaign',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _kpiBox('Active Campaigns', '${state.campaigns.where((c) => c.status == 'ACTIVE').length}', const Color(0xFF059669), surface, border, textSecondary),
                _kpiBox('Active Banners', '${kpis.activeBanners}', const Color(0xFF2563EB), surface, border, textSecondary),
                _kpiBox('Live Collections', '${kpis.activeCollections}', const Color(0xFFD97706), surface, border, textSecondary),
                _kpiBox('Published Blogs', '${kpis.publishedBlogs} / ${kpis.totalBlogs}', const Color(0xFF7C3AED), surface, border, textSecondary),
              ],
            ),
            const SizedBox(height: 18),
            if (widget.onOpenCatalogCollections != null || widget.onOpenCatalogBanners != null)
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (widget.onOpenCatalogCollections != null)
                    OutlinedButton.icon(
                      onPressed: widget.onOpenCatalogCollections,
                      icon: const Icon(Icons.collections_bookmark_rounded, size: 16),
                      label: const Text('Manage Storefront Collections'),
                    ),
                  if (widget.onOpenCatalogBanners != null)
                    OutlinedButton.icon(
                      onPressed: widget.onOpenCatalogBanners,
                      icon: const Icon(Icons.view_carousel_rounded, size: 16),
                      label: const Text('Manage Hero Banners'),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active & Recent Campaigns (${state.campaigns.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.status == MarketingStatus.loading && state.campaigns.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.campaigns.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No campaigns launched yet. Click "New Campaign" to create your first campaign.',
                          style: GoogleFonts.plusJakartaSans(color: textSecondary),
                        ),
                      ),
                    )
                  else
                    ...state.campaigns.map((c) => _campaignRow(c, canManage, isDark, border, textPrimary, textSecondary)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiBox(String label, String value, Color accent, Color surface, Color border, Color textSecondary) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: textSecondary)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: accent)),
        ],
      ),
    );
  }

  Widget _campaignRow(
    MarketingCampaignItem c,
    bool canManage,
    bool isDark,
    Color border,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isActive = c.status == 'ACTIVE';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _chip(c.channel, const Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    _chip(c.targetAudience, const Color(0xFF7C3AED)),
                    const SizedBox(width: 6),
                    _chip(c.status, isActive ? const Color(0xFF059669) : const Color(0xFFD97706)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(c.message, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  children: [
                    Text('Sent: ${c.sentCount}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: textSecondary)),
                    Text('Delivered: ${c.deliveredCount}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: textSecondary)),
                    Text('Opened: ${c.openedCount}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: textSecondary)),
                    Text('Clicked: ${c.clickedCount}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF2563EB))),
                    Text('Converted: ${c.convertedCount}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF059669))),
                  ],
                ),
              ],
            ),
          ),
          if (canManage)
            IconButton(
              tooltip: isActive ? 'Pause Campaign' : 'Activate Campaign',
              icon: Icon(
                isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                color: isActive ? const Color(0xFFD97706) : const Color(0xFF059669),
              ),
              onPressed: () {
                context.read<MarketingBloc>().add(
                      UpdateCampaignStatus(
                        id: c.id,
                        status: isActive ? 'PAUSED' : 'ACTIVE',
                      ),
                    );
              },
            ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
