import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/marketing_models.dart';
import '../../../logic/marketing/marketing_bloc.dart';
import '../../../logic/marketing/marketing_event.dart';
import '../../../logic/marketing/marketing_state.dart';

class EngagementView extends StatefulWidget {
  const EngagementView({super.key});

  @override
  State<EngagementView> createState() => _EngagementViewState();
}

class _EngagementViewState extends State<EngagementView> {
  @override
  void initState() {
    super.initState();
    context.read<MarketingBloc>().add(const LoadMarketingOverview());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF161E2E) : Colors.white;
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return BlocBuilder<MarketingBloc, MarketingState>(
      builder: (context, state) {
        final kpis = state.kpis;
        final totalSent = state.campaigns.fold<int>(0, (s, c) => s + c.sentCount);
        final totalDelivered = state.campaigns.fold<int>(0, (s, c) => s + c.deliveredCount);
        final totalOpened = state.campaigns.fold<int>(0, (s, c) => s + c.openedCount);
        final totalClicked = state.campaigns.fold<int>(0, (s, c) => s + c.clickedCount);
        final totalConverted = state.campaigns.fold<int>(0, (s, c) => s + c.convertedCount);

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
                        'Customer Engagement & Live Webhooks',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time campaign funnel telemetry and inbound webhook events streamed via WebSocket.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh Engagement Telemetry',
                  onPressed: () => context.read<MarketingBloc>().add(const LoadMarketingOverview(isRefresh: true)),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _statCard('Registered Farmers', '${kpis.totalCustomers}', const Color(0xFF059669), surface, border, textSecondary),
                _statCard('Product Reviews', '${kpis.totalReviews}', const Color(0xFFD97706), surface, border, textSecondary),
                _statCard('Webhook Events', '${kpis.totalWebhookEvents}', const Color(0xFF2563EB), surface, border, textSecondary),
                _statCard('Total Conversions', '$totalConverted', const Color(0xFF7C3AED), surface, border, textSecondary),
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
                    'Engagement Funnel Totals',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      _funnelPill('Sent', totalSent, const Color(0xFF64748B)),
                      _funnelPill('Delivered', totalDelivered, const Color(0xFF0EA5E9)),
                      _funnelPill('Opened', totalOpened, const Color(0xFF8B5CF6)),
                      _funnelPill('Clicked', totalClicked, const Color(0xFF2563EB)),
                      _funnelPill('Converted', totalConverted, const Color(0xFF059669)),
                    ],
                  ),
                ],
              ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Webhook Stream (/api/v1/webhooks/marketing)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'WEBSOCKET LIVE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.recentWebhooks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No webhook events recorded yet. Events posted to /api/v1/webhooks/marketing appear here in real time.',
                          style: GoogleFonts.plusJakartaSans(color: textSecondary),
                        ),
                      ),
                    )
                  else
                    ...state.recentWebhooks.map((w) => _webhookRow(w, isDark, border, textPrimary, textSecondary)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color accent, Color surface, Color border, Color textSecondary) {
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

  Widget _funnelPill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 8),
          Text('$count', style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _webhookRow(
    MarketingWebhookLog w,
    bool isDark,
    Color border,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              w.eventType,
              style: GoogleFonts.jetBrainsMono(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Channel: ${w.channel}${w.campaignId.isNotEmpty ? ' • Campaign: ${w.campaignId}' : ''}${w.recipient.isNotEmpty ? ' • ${w.recipient}' : ''}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (w.receivedAt != null)
            Text(
              '${w.receivedAt!.hour.toString().padLeft(2, '0')}:${w.receivedAt!.minute.toString().padLeft(2, '0')}:${w.receivedAt!.second.toString().padLeft(2, '0')}',
              style: GoogleFonts.jetBrainsMono(fontSize: 11, color: textSecondary),
            ),
        ],
      ),
    );
  }
}
