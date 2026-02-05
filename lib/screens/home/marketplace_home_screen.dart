import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  int _selectedNavIndex = 0;

  // Colors from design
  static const Color primary = Color(0xFF2d6a4f);
  static const Color secondary = Color(0xFF40916c);
  static const Color backgroundLight = Color(0xFFf8fbf9);
  static const Color textDark = Color(0xFF0d121b);
  static const Color gray100 = Color(0xFFf3f4f6);
  static const Color gray200 = Color(0xFFe5e7eb);
  static const Color gray400 = Color(0xFF9ca3af);
  static const Color gray500 = Color(0xFF6b7280);
  static const Color blue50 = Color(0xFFeff6ff);
  static const Color blue100 = Color(0xFFdbeafe);
  static const Color blue500 = Color(0xFF3b82f6);
  static const Color blue700 = Color(0xFF1d4ed8);
  static const Color blue900 = Color(0xFF1e3a8a);
  static const Color green50 = Color(0xFFf0fdf4);
  static const Color green200 = Color(0xFFbbf7d0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Column(
        children: [
          // Top Navigation
          Container(
            color: backgroundLight,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: gray100)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.menu, color: primary, size: 30),
                    ),
                    Expanded(
                      child: Text(
                        'AgriMach Marketplace',
                        textAlign: TextAlign.center,
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
                      child: Icon(Icons.shopping_cart, color: primary),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(Icons.search, color: primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search tractors, harvesters, tools...',
                                hintStyle: GoogleFonts.inter(
                                  color: gray400,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Category Slider
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildCategoryItem(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBV6WNNM71q1ZPCBsLopFGCbFBnSlNGwaIQmqwJ0RiKL9Lgy07pJqKQ3rVY4hnpzlYY0rgvXhEFkE6V5kI6oMacKXPWmz1AF6i64qAkRtQ5PJjf9m9SusKloVu9gPmtxdMxg8SNcOg27Y44MAHUGBsX8sSPKLzbc3RXC7-RY4DsgxhVHPbC-8Vg-HYUosVBKp0b5vSakf5kJUTAgLynxXSwGImWXsQg5-Ja4T0opZHUJbT_tSHHCFOYLdQ7D1OhXDJqjGTYHKN1Gfgh',
                          'Mini Mills',
                          true,
                        ),
                        _buildCategoryItem(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCKfwdGy4ser9LF_qpdGaOuccpSiWd4UD8VgZnBInSzjArUfHYCtTwd8UihVYZWjebIU4_AktByc3fLkAW6eD0HxurjKoPcZ7RozbCUklH5T-pRJFNAJ15fD435m2YKu09fEI5iIkT9Y0_BrSSTjItc6qJkGnt4FVdP4Bz2R9oh8TbPO13ysX0I3lkI7iPP7A8vOk_ZHH2qr6B23hQEArHeNDzbn3idHEyDaC8MlMgicQb6ydgT0avBzDTZ2elmPHGcnrPMRIb9GvgE',
                          'Chainsaws',
                          false,
                        ),
                        _buildCategoryItem(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuAhFoRduuVtcziUg645ykWRCpOiUklpd7sJeP1X0CIj_wQfemeEZA6-ffvgBjRW01O4FgTqSon6gmvsTIJq4xid4dMLXYscfTck764vSxjTyBcGBEluvIred2aLVsTqCH_f-PSf7V2FQkUblik6Dj32wX7UPZH_6OfEUKrlxJbQPbFmvxvDxt58MOOhucbteDb9T-j_DMa-2ikJyJzncnAX1g6kBYYYq2yKma9EIGlWDsie23pmqX_4Hey2SLt6V2QEdIjc8S27foP5',
                          'Farming Tools',
                          false,
                        ),
                        _buildCategoryItem(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBwSfToSv7jv6anw78VBARymBgdsnV9oroaJ3fMlOhk-ZaWYn4fpmEnUBUr43bc5756mMyImDmSKVh9Ra1vcDdLXxhymYI9D5d1Na7IC7sbPYZNRqalC1dZ1tZYZCs18lOjsBV0ObDqXAb5cwSRq0BSMMeF3j5tAS8qr0JGVgcDFjBhJbHmmyyGDw_Isnmqjof2y5DyiN2bDUDf92jYcsn1RwJrZ-T-TOfTVZcdPQ3uT275-6hcAO-xIBkCEuhiJQ_hyj2bp8PmCcwM',
                          'Tractors',
                          false,
                        ),
                      ],
                    ),
                  ),

                  // Featured Products Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Products',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                            letterSpacing: -0.015 * 22,
                          ),
                        ),
                        Text(
                          'View All',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Product Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildProductCard(
                          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBY-zk5FiEndc_-knQOpJocZAcvworTwYA780fuc7IJUA41Tcv-jBY3JDWZOAHHWSOR22RTLhbR9zQ-kMmlfosyue4-qz6j5fPnqD-pJLIS2uFn6uSJYjj1nxwryCChmZxVR5TK_6ip-uMgHpCZ3lBhpQ6BkTjyT44jR-Cz06YNAfg43J47CenHeLrjBWFghK65SJx_sRhlfOcHFhMK4mjg3LMI5PKtpJ7zMHiDBKa1bUjTMreaFq1aXO48ToJqwRp-2UEolzahNwA_',
                          badge: 'Top Rated',
                          title: 'Multi-Crop Power Tiller',
                          price: '₹45,000',
                          description: 'High-efficiency 7HP engine for tough terrains.',
                        ),
                        const SizedBox(height: 16),
                        _buildProductCard(
                          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC7qF0zKGBS75MgtGSuRjIZF_ASuXRoX9Ah-yja17OpZ_vV0MdLierC3JSXu1-h2XpHJJDi0sRmKnUzqjOZZYb7nyRpD6FASScgi5VsC-AyyP5o_qdcHsJ3Rbq-nJAr5d_iekQPC2XiTsRnTuwaWLeeIJD3Hn6beEFlYjs7CrcnyTOAcJFH1R9Q3VzT7maEufMX1I-iaNHSi4Q0UO8vXo5n6H4Ry0TI0FAZfti4ViZXTblYWv4iIkVBP13Hkd7dZa_8PwLaDZkrSIH_',
                          badge: 'New Arrival',
                          title: 'Solar Water Pump 5HP',
                          price: '₹82,500',
                          description: 'Eco-friendly irrigation with high flow capacity.',
                        ),
                      ],
                    ),
                  ),

                  // Bulk Inquiry Banner
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Opacity(
                                opacity: 0.1,
                                child: Icon(Icons.handshake, size: 120, color: Colors.white),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WHOLESALE EXCLUSIVE',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: green200,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bulk Inquiry for Wholesalers',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.015 * 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Negotiate bulk pricing directly with verified manufacturers and save up to 30%.',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: green50,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: primary,
                                        elevation: 2,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Inquire Now',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Colors.white)),
                                      ),
                                      child: Text(
                                        'Learn More',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
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
                  ),

                  // Manual UPI Banner
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: blue50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: blue100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: blue500,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manual UPI Verification',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: blue900,
                                  ),
                                ),
                                Text(
                                  'Secure payments with manual screenshot verification for wholesalers.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: blue700,
                                  ),
                                ),
                              ],
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
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          border: Border(top: BorderSide(color: gray100)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', 0, true),
                _buildNavItem(Icons.category, 'Categories', 1, false),
                _buildNavItem(Icons.handshake, 'Deals', 2, false),
                _buildNavItem(Icons.person, 'Profile', 3, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String imageUrl, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? primary : primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: gray200),
                errorWidget: (context, url, error) => Container(color: gray200),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required String imageUrl,
    required String badge,
    required String title,
    required String price,
    required String description,
  }) {
    return Container(
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: gray200),
                errorWidget: (context, url, error) => Container(color: gray200),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: secondary,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      price,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: gray500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Add to Cart',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: gray200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.favorite_border, color: gray400),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? primary : gray400),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? primary : gray400,
            ),
          ),
        ],
      ),
    );
  }
}
