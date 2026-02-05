import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLandingScreen extends StatelessWidget {
  const AppLandingScreen({super.key});

  // Colors from design
  static const Color primary = Color(0xFF1e40af);
  static const Color primaryLight = Color(0xFF3b82f6);
  static const Color accentBlue = Color(0xFF0ea5e9);
  static const Color backgroundLight = Color(0xFFf8fafc);
  static const Color textDark = Color(0xFF0f172a);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate200 = Color(0xFFe2e8f0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: backgroundLight.withOpacity(0.95),
                border: Border(bottom: BorderSide(color: slate200)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.menu, color: primary, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      'AgriWholesale',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                        letterSpacing: -0.015 * 18,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Icon(Icons.account_circle, color: primary, size: 28),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero Image Section
                    Container(
                      margin: const EdgeInsets.all(16),
                      height: 420,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlvbLtA4H6PZZv0n1bhPVBF7ikunjzXpYbOyFNx55XSstICiUTKNOwfcy1L2xOeQ3T2PKdW-xrC9CHKyGWiBkxANSfLNp7WBN1aiXiPr8FTza3UtgjB2dNwiUy9pk3fMJ4rMD5bB8f4WmFSb-dR1LjTvdzgchz56UJGTDlcNdFYvzwcopDSoxjbAGgdBxX3vUg_uq44YwYhlvt_-zH4X4xe7YGstUmTboxw83rItHFuXWfeT9a5z3fPTaDjpeJZReu7R_ek3-9UrgB',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: slate200),
                              errorWidget: (context, url, error) => Container(color: slate200),
                            ),
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    const Color(0xFF0f172a).withOpacity(0.95),
                                    const Color(0xFF0f172a).withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.4, 1.0],
                                ),
                              ),
                            ),
                            // Content
                            Positioned(
                              left: 24,
                              right: 24,
                              bottom: 24,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryLight,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'WHOLESALE PORTAL',
                                      style: GoogleFonts.publicSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Empowering Farmers with Quality Machinery',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.1,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Our Mission
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                      child: Column(
                        children: [
                          Text(
                            'OUR MISSION',
                            style: GoogleFonts.publicSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: primaryLight,
                              letterSpacing: 3.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Providing modern solutions for the next generation of agriculture.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.publicSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: slate600,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // The Professional Edge
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The Professional Edge',
                            style: GoogleFonts.publicSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 64,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primaryLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Feature Cards
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildFeatureCard(
                            icon: Icons.sell,
                            title: 'Bulk Wholesale Prices',
                            description: 'Access exclusive industrial rates with volume-based pricing structures for massive savings.',
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureCard(
                            icon: Icons.handshake,
                            title: 'Direct Negotiation',
                            description: 'Skip the middleman. Chat directly with manufacturers for transparent, tailored deal-making.',
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureCard(
                            icon: Icons.verified_user,
                            title: 'Verified Equipment',
                            description: 'Certified and inspected by expert engineers to ensure peak performance in your fields.',
                          ),
                        ],
                      ),
                    ),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Get Started',
                                style: GoogleFonts.publicSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.015 * 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textDark,
                                side: BorderSide(color: slate200, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Learn More',
                                style: GoogleFonts.publicSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.015 * 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom indicator
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: 128,
                        height: 6,
                        decoration: BoxDecoration(
                          color: slate200,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(icon, color: primaryLight, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.publicSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: slate600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
