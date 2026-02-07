import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  State<NotificationsCenterScreen> createState() => _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  int _selectedNavIndex = 2;

  // Colors from design
  static const Color primary = Color(0xFF46ec13);
  static const Color backgroundLight = Color(0xFFf6f8f6);
  static const Color textDark = Color(0xFF111b0d);
  static const Color statusGreen = Color(0xFF22c55e);
  static const Color statusBlue = Color(0xFF3b82f6);
  static const Color statusOrange = Color(0xFFf97316);
  static const Color gray100 = Color(0xFFf3f4f6);
  static const Color gray200 = Color(0xFFe5e7eb);
  static const Color gray400 = Color(0xFF9ca3af);
  static const Color gray500 = Color(0xFF6b7280);
  static const Color gray600 = Color(0xFF4b5563);
  static const Color red500 = Color(0xFFef4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Column(
        children: [
          // Header
          Container(
            color: backgroundLight.withOpacity(0.8),
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: gray200)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios, color: textDark),
                    ),
                    Expanded(
                      child: Text(
                        'Notifications',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.settings, color: textDark),
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
                  // Today Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'TODAY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: gray500,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  _buildNotificationItem(
                    icon: Icons.check_circle,
                    iconColor: statusGreen,
                    iconBgColor: statusGreen.withOpacity(0.1),
                    title: 'Negotiation Accepted',
                    time: '2h ago',
                    description: 'Your bulk price for ',
                    highlight: '50 Mini Mills',
                    descriptionSuffix: ' was approved!',
                    actionText: 'View Details',
                  ),

                  _buildNotificationItem(
                    icon: Icons.description,
                    iconColor: statusOrange,
                    iconBgColor: statusOrange.withOpacity(0.1),
                    title: 'Counter-offer Received',
                    time: '5h ago',
                    description: 'Admin has proposed a new price for the ',
                    highlight: 'Heavy Duty Tractor',
                    descriptionSuffix: ' fleet request.',
                    actionText: 'Respond Now',
                  ),

                  // Earlier Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'EARLIER',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: gray500,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  _buildNotificationItem(
                    icon: Icons.verified,
                    iconColor: statusBlue,
                    iconBgColor: statusBlue.withOpacity(0.1),
                    title: 'Payment Verified',
                    time: 'Yesterday',
                    description: 'Your order ',
                    highlight: '#123',
                    descriptionSuffix: ' is now being processed.',
                    actionText: 'View Order',
                  ),

                  _buildNotificationItem(
                    icon: Icons.local_shipping,
                    iconColor: gray600,
                    iconBgColor: gray100,
                    title: 'Order Shipped',
                    time: '2 days ago',
                    description: 'The parts for ',
                    highlight: 'Irrigation System #88',
                    descriptionSuffix: ' have been dispatched.',
                    actionText: 'Track Shipment',
                  ),

                  _buildNotificationItem(
                    icon: Icons.campaign,
                    iconColor: primary,
                    iconBgColor: primary.withOpacity(0.1),
                    title: 'New Inventory Alert',
                    time: 'Sep 24',
                    description: 'Fresh stock of harvesters just arrived from the factory. Bulk discounts available.',
                    highlight: null,
                    descriptionSuffix: null,
                    actionText: null,
                    opacity: 0.75,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: Border(top: BorderSide(color: gray200)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.home, 'Home', 0, false),
                _buildNavItem(Icons.list_alt, 'Orders', 1, false),
                _buildNavItem(Icons.notifications, 'Alerts', 2, true, showBadge: true),
                _buildNavItem(Icons.person, 'Profile', 3, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String time,
    required String description,
    String? highlight,
    String? descriptionSuffix,
    String? actionText,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: gray100)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: gray400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Description
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: gray600,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(text: description),
                        if (highlight != null)
                          TextSpan(
                            text: highlight,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        if (descriptionSuffix != null)
                          TextSpan(text: descriptionSuffix),
                      ],
                    ),
                  ),

                  // Action Button
                  if (actionText != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          actionText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: primary),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isSelected, {bool showBadge = false}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? primary : gray400,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? primary : gray400,
                ),
              ),
            ],
          ),
          if (showBadge)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: red500,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
