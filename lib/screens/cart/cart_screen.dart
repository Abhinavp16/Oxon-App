import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<Map<String, dynamic>> _cartItems = [
    {
      'name': 'Portable Mini Mill',
      'price': 1200.00,
      'quantity': 1,
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuA4kKhdoeO83iysXA1Us6Yb2KQU-t_7JzFSAbIeaIQNqDn4N0ZC544pF4QHjUDmuTwwX7hj_3eTfg8vXtqMbj-LAKFGOZ1zjkROJkWmlF_lllVj8ue4ZdP2LCxMTvheOeS5zvQ2WP_J4tdNxXb55aSjWfSVK5fHDF8sDGw-uaZVhwE1OrmsJfgOf5XZ04Zhb7cwNNK37oJRvZ4NQAxJ0G_9Nn6i97gjI5D3EbuNTqoArbzJ27abeNbtH1AzwY_b14iP25Xao4NbYa89',
    },
    {
      'name': 'Garden Power Tiller',
      'price': 850.00,
      'quantity': 2,
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBC7pHzkPGNTDXhKz1oluYbkGKwXyrhgE2TAO7nJyuqiFypYcdXYcAzAJLzcncH72zl2Je1BIz4T1liY264MoCHkv6lVr54vvBSsMSy0GerGOIqySQter5QIfBIlrTwSKrNz0NA0lH9CE2YFpBYmH71skYGJHWasP6hU7qKG0sRDphLYq-cUNsA3ZPV3U2cN9f1T1WvICx-ystdu2C8znBc2quyeYnIKkxeXikN1wqZObDCpquv_3jOzoXHfJN4NNRtx389y_W-YE2Q',
    },
    {
      'name': 'Solar Water Pump',
      'price': 450.00,
      'quantity': 1,
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAC6vQUrWMxt2OF80Llpuz5qZ0pGd4ZJ-taxSWhvGTf_Dk5Mto-jDNqYXAeCsWR2OQ6zi3XahtkybeW1k5C-OK9SgvwWXxAqpJpnTbX49Xh18f5ggUJJaPNaGBqWHFeUojjT_hl3eKRITBgyBXbWn23x-Ia-3AGVnlCP1KdgEdHIKGQeArjlqv2UcZON86ZrVLnfffcxkf8PCZQmeheCWbrP7sj7j2ULz3cXafLL_Ovk1-uNfwZ8alf99rhagUP10pkQ3Zy4A3xa_ze',
    },
  ];

  double get _subtotal => _cartItems.fold(
      0, (sum, item) => sum + (item['price'] * item['quantity']));
  double get _discount => 150.00;
  double get _deliveryFee => 50.00;
  double get _grandTotal => _subtotal - _discount + _deliveryFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        ),
        title: Text(
          'Shopping Cart',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.delete_outline, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _cartItems.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.gray50,
              ),
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return _buildCartItem(item, index);
              },
            ),
          ),

          // Price Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.gray200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Summary',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPriceRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildPriceRow('Discount', '-\$${_discount.toStringAsFixed(2)}',
                      valueColor: AppColors.success),
                  const SizedBox(height: 8),
                  _buildPriceRow('Delivery Fee', '\$${_deliveryFee.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.gray100),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${_grandTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.push('/payment/order-${DateTime.now().millisecondsSinceEpoch}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Proceed to Checkout',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 20),
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
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item['image'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.gray100,
                width: 80,
                height: 80,
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.gray100,
                width: 80,
                height: 80,
                child: const Icon(Icons.image),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item['price'].toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Quantity Selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    if (item['quantity'] > 1) {
                      setState(() => _cartItems[index]['quantity']--);
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '-',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  alignment: Alignment.center,
                  child: Text(
                    '${item['quantity']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _cartItems[index]['quantity']++);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '+',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildPriceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
