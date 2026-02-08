import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import '../../core/theme/app_theme.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/auth_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    // Only fetch from server if local cart is empty; otherwise items are already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = ref.read(cartProvider);
      if (cart.items.isEmpty && !cart.isLoading) {
        ref.read(cartProvider.notifier).fetchCart();
      }
    });
  }

  String _fmt(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  Future<void> _proceedToCheckout() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return;

    // Show shipping address dialog
    final address = await _showAddressDialog();
    if (address == null || !mounted) return;

    setState(() => _isCheckingOut = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/orders', data: {
        'shippingAddress': address,
      });

      if (!mounted) return;
      setState(() => _isCheckingOut = false);

      if (response.data['success'] == true) {
        final orderId = response.data['data']['orderId'];
        ref.read(cartProvider.notifier).fetchCart(); // refresh (cart cleared server-side)
        context.push('/payment/$orderId');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingOut = false);
      final msg = e.response?.data?['message']?.toString() ?? 'Checkout failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingOut = false);
    }
  }

  Future<Map<String, String>?> _showAddressDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addr1Ctrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Pre-fill from auth state
    final auth = ref.read(authProvider);
    nameCtrl.text = auth.user?.name ?? '';
    phoneCtrl.text = auth.user?.phone ?? '';

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top + 40),
        decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(key: formKey, child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(100)))),
            Text('Shipping Address', style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            _field('Full Name', nameCtrl),
            const SizedBox(height: 12),
            _field('Phone', phoneCtrl, keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            _field('Address Line 1', addr1Ctrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('City', cityCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _field('State', stateCtrl)),
            ]),
            const SizedBox(height: 12),
            _field('Pincode', pinCtrl, keyboard: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(ctx).pop({
                      'fullName': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'addressLine1': addr1Ctrl.text.trim(),
                      'city': cityCtrl.text.trim(),
                      'state': stateCtrl.text.trim(),
                      'pincode': pinCtrl.text.trim(),
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Confirm & Pay', style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700)))),
          ]))))),
    );

    nameCtrl.dispose(); phoneCtrl.dispose(); addr1Ctrl.dispose();
    cityCtrl.dispose(); stateCtrl.dispose(); pinCtrl.dispose();
    return result;
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboard}) {
    return TextFormField(controller: ctrl, keyboardType: keyboard,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
        filled: true, fillColor: AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5))));
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary)),
        title: Text('Shopping Cart',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(onPressed: () => ref.read(cartProvider.notifier).clearCart(),
              icon: const Icon(Icons.delete_outline, color: AppColors.textPrimary)),
        ],
      ),
      body: cart.isLoading
        ? const Center(child: CircularProgressIndicator())
        : cart.items.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.gray300),
              const SizedBox(height: 16),
              Text('Your cart is empty', style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextButton(onPressed: () => context.go('/home'),
                child: Text('Browse Products', style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
            ]))
          : Column(children: [
              Expanded(child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: cart.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray50),
                itemBuilder: (_, i) => _buildCartItem(cart.items[i]))),

              // Price Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.gray200)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 10, offset: const Offset(0, -5))]),
                child: SafeArea(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Price Summary', style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  _buildPriceRow('Subtotal', '₹${_fmt(cart.subtotal)}'),
                  const SizedBox(height: 8),
                  _buildPriceRow('Delivery Fee', '₹${_fmt(cart.deliveryFee)}'),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.gray100),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Grand Total', style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('₹${_fmt(cart.grandTotal)}', style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _isCheckingOut ? null : _proceedToCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isCheckingOut
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Proceed to Checkout', style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, size: 20),
                          ]))),
                ]))),
            ]),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: item.image != null
            ? CachedNetworkImage(imageUrl: item.image!, width: 80, height: 80, fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.gray100, width: 80, height: 80),
                errorWidget: (_, __, ___) => Container(color: AppColors.gray100, width: 80, height: 80,
                  child: const Icon(Icons.image)))
            : Container(color: AppColors.gray100, width: 80, height: 80,
                child: const Icon(Icons.image))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('₹${_fmt(item.price)}', style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ])),
        Container(
          decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            InkWell(onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity - 1),
              child: Container(width: 32, height: 32, alignment: Alignment.center,
                child: Text('-', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600)))),
            Container(width: 24, alignment: Alignment.center,
              child: Text('${item.quantity}', style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700))),
            InkWell(onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity + 1),
              child: Container(width: 32, height: 32, alignment: Alignment.center,
                child: Text('+', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600)))),
          ])),
      ]),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color? valueColor}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary)),
      Text(value, style: GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? AppColors.textPrimary)),
    ]);
  }
}
