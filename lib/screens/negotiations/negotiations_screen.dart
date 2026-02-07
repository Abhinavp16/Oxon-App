import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
class NegotiationsScreen extends StatefulWidget {
  const NegotiationsScreen({super.key});

  @override
  State<NegotiationsScreen> createState() => _NegotiationsScreenState();
}

class _NegotiationsScreenState extends State<NegotiationsScreen> {
  int _selectedTab = 1;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color backgroundWhite = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color slateBlue = Color(0xFF4C669A);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: backgroundWhite,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                color: backgroundWhite,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: textPrimary),
                    ),
                    Expanded(
                      child: Text(
                        'Negotiations',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              // Tabs
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderLight, width: 1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildTab('All', 0),
                      const SizedBox(width: 32),
                      _buildTab('Active', 1),
                      const SizedBox(width: 32),
                      _buildTab('Completed', 2),
                    ],
                  ),
                ),
              ),
              // Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Priority Quotes',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3),
                  ),
                ),
              ),
              // Cards
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    _buildNegotiationCard(
                      requestId: '8821',
                      productName: 'John Deere 5050D Tractor',
                      bulkOrder: 'Bulk Order: 10 units',
                      status: 'COUNTER-OFFER',
                      statusColor: const Color(0xFFF59E0B),
                      statusBg: const Color(0xFFFEF3C7),
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAaGgwMFJfelXOECcbEE0PcOWEJYZG_IeWUQBS3eYYeR8WGclPWdSaSr02PbM2TR18rwhnkGYJXivBh6KDC4s1uOmrpgiRDhh6z_n_S41GhE5FSy-TUXj6NpNohO60LbL3jrhLu5FwgWn51hhzM0DfENdXiue6d4kSXkE6nKm356hu9fj5KaYlwkmIaLRnv1y2nmjXJaXuF4mKUlaYBKe3beGqIjylC9XPYHyiSoZLiSM3lz5YnD9dFy4XOHyxnfFPC0wT9m1ktUPXj',
                      priceRows: [
                        {'label': 'Your Quote:', 'value': '\$120,000', 'color': textPrimary},
                        {'label': 'Admin Price:', 'value': '\$125,000', 'color': primaryBlue},
                      ],
                      buttonLabel: 'View Details',
                      buttonStyle: 'primary',
                    ),
                    _buildNegotiationCard(
                      requestId: '8790',
                      productName: 'Mahindra Arjun 555 DI',
                      bulkOrder: 'Bulk Order: 5 units',
                      status: 'ACCEPTED',
                      statusColor: const Color(0xFF16A34A),
                      statusBg: const Color(0xFFDCFCE7),
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDeRnAVFtCPqADjT1xfxgQZUwnbDm7VXA9ZtB8Mx3smt-DQbKK30XiyblbS5DK0_BKbqx-oXRHyWv2Lup0rF6WlV8ArlL4OTx4vA9-kptmUcpYOQ7mq1ShcxTRW2p0JMw-kBheHInQujJ_LwAgIAh4WDhM9yIDHyLlquivu1NDI3Scj9aYrmL9LsMeKh49UKjV1yJmUsma6qz0NQF6IHWdr_eMyUgLNCMgfHBXskdsZfGu35NNpMmmO0eOu9hkoAX-jq80MrzIyYPB7',
                      priceRows: [
                        {'label': 'Negotiated Total:', 'value': '\$45,000', 'color': const Color(0xFF16A34A)},
                      ],
                      showAccentBorder: true,
                      buttonLabel: 'Pay Now',
                      buttonStyle: 'primary',
                      buttonIcon: Icons.account_balance_wallet_rounded,
                    ),
                    _buildNegotiationCard(
                      requestId: '8912',
                      productName: 'New Holland T6 Series',
                      bulkOrder: 'Bulk Order: 3 units',
                      status: 'PENDING REVIEW',
                      statusColor: const Color(0xFF6B7280),
                      statusBg: const Color(0xFFF3F4F6),
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDoAi8Z9AYnnHnksg3wzDv3tFls2Idq7TqPmxGitX58sgdDcWHvml_6hb-XPe3HzyhtZRtureb4wn6zRlR-WL493UOLq22iu3vXYo-q499bvG5FGFjVhC-lYehP356yiSmrfid1DCuuIOnA_Y4emJZj5728OBUNr_sdelqFN9PCDJRcxBkGzbCmFhkCybh8txJT4hNO_eEWTrK4-IWmsMhTNyD-_hJRiyNako1lCGLbh86uokS2UzNYiUc5xX1yEnFJNNz2ty4t5sqo',
                      pendingPrice: '\$88,000',
                      pendingNote: 'Awaiting admin verification',
                      buttonLabel: 'Under Review',
                      buttonStyle: 'disabled',
                      isOpaque: true,
                    ),
                  ],
                ),
              ),
              // Bottom Verification Banner
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  border: const Border(top: BorderSide(color: borderLight)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Icon(Icons.verified_user_outlined, color: primaryBlue, size: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Manual Verification', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
                            Text('UPI payments verified within 2-4 hours', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: slateBlue)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('HELP', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: primaryBlue)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.only(top: 16, bottom: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryBlue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: isSelected ? primaryBlue : slateBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildNegotiationCard({
    required String requestId,
    required String productName,
    required String bulkOrder,
    required String status,
    required Color statusColor,
    required Color statusBg,
    String? imageUrl,
    List<Map<String, dynamic>>? priceRows,
    String? pendingPrice,
    String? pendingNote,
    bool showAccentBorder = false,
    required String buttonLabel,
    required String buttonStyle,
    IconData? buttonIcon,
    bool isOpaque = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: isOpaque ? 0.85 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderLight),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              if (imageUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFFF1F5F9)),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(child: Icon(Icons.image_outlined, color: textMuted, size: 40)),
                    ),
                  ),
                ),
              // Card Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Request ID + Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'REQUEST #$requestId',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: slateBlue,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Product Name
                    Text(
                      productName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Bulk Order
                    Text(
                      bulkOrder,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: slateBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Price Details
                    if (priceRows != null && priceRows.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: backgroundWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: showAccentBorder
                              ? const Border(left: BorderSide(color: Color(0xFF16A34A), width: 4))
                              : null,
                        ),
                        child: Column(
                          children: priceRows.map((row) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: row == priceRows.last ? 0 : 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    row['label'] as String,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: slateBlue),
                                  ),
                                  Text(
                                    row['value'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: row['color'] == const Color(0xFF16A34A) ? 18 : 14,
                                      fontWeight: FontWeight.w700,
                                      color: row['color'] as Color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    // Pending Price
                    if (pendingPrice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Requested Price: ', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: slateBlue)),
                              Text(pendingPrice, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                            ],
                          ),
                          if (pendingNote != null) ...[
                            const SizedBox(height: 4),
                            Text(pendingNote, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontStyle: FontStyle.italic, color: slateBlue)),
                          ],
                        ],
                      ),
                    const SizedBox(height: 16),
                    // Action Button
                    GestureDetector(
                      onTap: buttonStyle == 'disabled' ? null : () {
                        if (buttonLabel == 'Pay Now') {
                          context.push('/payment/negotiation-$requestId');
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: buttonStyle == 'primary'
                              ? primaryBlue
                              : buttonStyle == 'disabled'
                                  ? borderLight
                                  : surfaceWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: buttonStyle == 'outline' ? Border.all(color: borderLight) : null,
                          boxShadow: buttonStyle == 'primary' && buttonIcon != null
                              ? [BoxShadow(color: primaryBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (buttonIcon != null) ...[
                              Icon(buttonIcon, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              buttonLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: buttonStyle == 'primary'
                                    ? Colors.white
                                    : buttonStyle == 'disabled'
                                        ? const Color(0xFF9CA3AF)
                                        : textPrimary,
                              ),
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
        ),
      ),
    );
  }
}
