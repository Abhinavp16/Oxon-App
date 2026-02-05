import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentVerificationScreen extends StatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  State<PaymentVerificationScreen> createState() => _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  int _selectedTab = 0;

  // Colors from design
  static const Color primary = Color(0xFF135bec);
  static const Color backgroundLight = Color(0xFFf6f6f8);
  static const Color textDark = Color(0xFF0d121b);
  static const Color textSecondary = Color(0xFF4c669a);
  static const Color borderColor = Color(0xFFcfd7e7);
  static const Color gray100 = Color(0xFFf3f4f6);
  static const Color gray200 = Color(0xFFe5e7eb);
  static const Color yellow100 = Color(0xFFfef9c3);
  static const Color yellow700 = Color(0xFFa16207);
  static const Color red50 = Color(0xFFfef2f2);
  static const Color red200 = Color(0xFFfecaca);
  static const Color red600 = Color(0xFFdc2626);

  final List<String> _tabs = ['Pending', 'Approved', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Column(
        children: [
          // TopAppBar
          Container(
            color: backgroundLight,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.arrow_back_ios, color: textDark),
                    ),
                    Expanded(
                      child: Text(
                        'Payment Verification',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                          letterSpacing: -0.015 * 18,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.tune, color: textDark),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedTab == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = index),
                    child: Container(
                      padding: const EdgeInsets.only(top: 16, bottom: 13),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? primary : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        _tabs[index],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? primary : textSecondary,
                          letterSpacing: 0.015 * 14,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Text(
                    'Verification Details',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: -0.015 * 18,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Active Expanded Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gray100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Now',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                                Text(
                                  'Buyer: GreenFields Agri',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: yellow100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'REVIEWING',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: yellow700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Receipt Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDHTOJcn3axqC434_7cyS78EaI-gJkzE0BsN5Pjum_h5-KGRUCXSyfgZsKNLR10kWiNn0sa-hYeTeINCLeaeICFgtexMvJbL86fsoU1f3xfm8MQYwlE_zAc6KOTbMZyq_P5P0XqVR_JDEe_Wm1ZprRAdEJWSBkmnwwin8Mn0Ael6virFIE1MxLU6yJvFomPMC5ZBjNG0w3nlH2G57sZBjN3SO2Kwf05avRIXaqqnblHJ1HNOP6igMO0O_rBkoJJ48cDQ8_kZxhqgfrj',
                            width: double.infinity,
                            height: 256,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(height: 256, color: gray200),
                            errorWidget: (context, url, error) => Container(height: 256, color: gray200),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Transaction Details
                        Container(
                          padding: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: gray100)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: 0.6,
                                child: Text(
                                  'TRANSACTION RECORDED',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildDetailItem('Order ID', '#AGR-8821')),
                                  Expanded(child: _buildDetailItem('Amount', '₹4,50,000')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildDetailItem('Date', 'Oct 24, 2023')),
                                  Expanded(child: _buildDetailItem('UPI ID Ref', '324901XXXX77')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Flag Issues
                        Text(
                          'Flag Issues (Optional)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFlagChip('Wrong Amount'),
                            _buildFlagChip('Blurred Image'),
                            _buildFlagChip('Invalid Ref ID'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: Text(
                                    'Approve Payment',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: Icon(Icons.cancel, size: 18, color: red600),
                                  label: Text(
                                    'Reject',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: red600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: red50,
                                    side: BorderSide(color: red200),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Other Pending Header
                  Text(
                    'Other Pending',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: -0.015 * 18,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pending Card 1
                  _buildPendingCard(
                    time: '15 mins ago',
                    buyer: 'Buyer: Kissan Motors',
                    orderId: '#AGR-8742',
                    amount: '₹1,20,000',
                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBjoZtOm2sJfrmiWIsqupzPTAfKMV2mfbZjRjzToSSaE74MmMcBXRimmw3fC7uVScV3bVEwRni74UOMS0sw4QbO4IRk0A_iVOLr2Xb536xBSbtUR5TETxY61lp39YYCsmQRCQcBAyISmyHWDnMP9peTrXtcacpUr5yL_joeGY7WZYUkKUdQy1dF8RdBpnqK9TH9t2JJhgOvqdEk5Do737A0eRtmWGPf0lLDhGYrznrhgO-zXiWe33DM82XWNqT-hVPMwK6bWRuqEHmI',
                  ),
                  const SizedBox(height: 16),

                  // Pending Card 2
                  _buildPendingCard(
                    time: '1 hour ago',
                    buyer: 'Buyer: AgroPioneer Ltd',
                    orderId: '#AGR-8700',
                    amount: '₹8,90,000',
                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD9J2dffGbM4jsqY0y-Uj294VFdm8uCh2cA8bxj32Y_NOihfSy9b2kRTEy3NuVrmsfkQTzG3o4M_tkb291zqV87gLKZZ980oiWy2jKe0q0f3yGeAYuzfjAv9nxUEJA3pB75FWvvpVmw_Y-tRsOqsn2w0Qp3VyzIB_g76KKxLwl0OGNe-52pxy8HNJtN4J-YWsSAE9otslPO6-vMqVDOwKmbOwsWDTWh42j8Za8zvxIq2-6OKUEZ2WpuWXzcrhtdw3fuqSWrQpFPOdYm',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFlagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: gray200),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4b5563),
        ),
      ),
    );
  }

  Widget _buildPendingCard({
    required String time,
    required String buyer,
    required String orderId,
    required String amount,
    required String imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                Text(
                  buyer,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$orderId | $amount',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFe7ebf3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Review',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.open_in_full, size: 14, color: textDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 96,
                height: 96,
                color: gray200,
              ),
              errorWidget: (context, url, error) => Container(
                width: 96,
                height: 96,
                color: gray200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
