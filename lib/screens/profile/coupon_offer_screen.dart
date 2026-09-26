import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/services/redeemed_coupon_service.dart';
import '../../core/services/storage_service.dart';

class CouponOfferScreen extends ConsumerStatefulWidget {
  const CouponOfferScreen({super.key});

  @override
  ConsumerState<CouponOfferScreen> createState() => _CouponOfferScreenState();
}

class _CouponOfferScreenState extends ConsumerState<CouponOfferScreen> {
  static const _background = Color(0xFFF7F5F0);
  static const _amber = Color(0xFFD97706);
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE7E1D7);

  List<_CouponEntry> _coupons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = ref.read(authProvider).user;
    final userData = await StorageService.getUserData();
    final userKey = user?.id.isNotEmpty == true
        ? user!.id
        : (user?.phone ??
              user?.email ??
              userData?['id']?.toString() ??
              userData?['_id']?.toString() ??
              userData?['phone']?.toString() ??
              userData?['email']?.toString() ??
              'guest');
    final redeemed = await RedeemedCouponService.getCoupons(userKey: userKey);
    final couponsByKey = <String, _CouponEntry>{};

    try {
      final targetGroup = user?.role == 'wholesaler' ? 'wholesaler' : 'buyer';
      final response = await ref
          .read(apiClientProvider)
          .get('/offers', queryParameters: {'targetGroup': targetGroup});
      final items = response.data['data'];
      if (items is List) {
        for (final raw in items.whereType<Map>()) {
          final item = Map<String, dynamic>.from(raw);
          final code = item['code']?.toString().trim().toUpperCase() ?? '';
          final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
          final entry = _CouponEntry(
            code: code,
            title: item['title']?.toString().trim() ?? 'Special offer',
            rule: _offerRule(item),
            discountLabel: _discountLabel(item),
            isLive: true,
          );
          couponsByKey[code.isNotEmpty ? code : 'offer-$id'] = entry;
        }
      }
    } catch (_) {
      _error = 'Live offers could not be refreshed. Showing saved coupons.';
    }

    for (final coupon in redeemed) {
      couponsByKey.putIfAbsent(
        coupon.code,
        () => _CouponEntry(
          code: coupon.code,
          title: coupon.title,
          rule: coupon.rule,
          discountLabel: 'COUPON',
          isLive: false,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _coupons = couponsByKey.values.toList();
      _loading = false;
    });
  }

  String _offerRule(Map<String, dynamic> item) {
    final description = item['description']?.toString().trim() ?? '';
    if (description.isNotEmpty) return description;

    final type = item['discountType']?.toString();
    final value = item['discountValue'];
    final discount = type == 'percentage'
        ? '${_formatNumber(value)}% off'
        : '₹${_formatNumber(value)} off';
    final minimum = item['minPurchaseAmount'];
    if (minimum is num && minimum > 0) {
      return '$discount on orders above ₹${_formatNumber(minimum)}';
    }
    return discount;
  }

  String _discountLabel(Map<String, dynamic> item) {
    final value = _formatNumber(item['discountValue']);
    return item['discountType']?.toString() == 'percentage'
        ? '$value%\nOFF'
        : '₹$value\nOFF';
  }

  String _formatNumber(dynamic value) {
    final number = value is num ? value : num.tryParse(value?.toString() ?? '');
    if (number == null) return '0';
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(1);
  }

  Future<void> _copyCode(String code) async {
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$code copied',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'My Coupons',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _amber,
        onRefresh: _loadCoupons,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF292524), Color(0xFF44403C)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1C1917).withValues(alpha: 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      color: Color(0xFF1C1917),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savings, ready to use',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Copy a code and apply it in your cart.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            height: 1.4,
                            color: const Color(0xFFD6D3D1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_loading) ...[
                    const SizedBox(width: 10),
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        '${_coupons.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _muted),
              ),
            ],
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(color: _amber)),
              )
            else if (_coupons.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      size: 36,
                      color: _muted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No coupons are available right now.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'Your available ${_coupons.length == 1 ? 'offer' : 'offers'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(height: 10),
              ..._coupons.map(_couponCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _couponCard(_CouponEntry coupon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFFBF2)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF78350F).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: coupon.isLive
                        ? const [Color(0xFFF59E0B), Color(0xFFEA580C)]
                        : const [Color(0xFF78716C), Color(0xFF44403C)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  coupon.discountLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: coupon.discountLabel == 'COUPON' ? 10 : 15,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            coupon.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _text,
                            ),
                          ),
                        ),
                        if (coupon.isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'LIVE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      coupon.rule,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.4,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDashedDivider(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'USE CODE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      coupon.code.isEmpty ? 'AUTO OFFER' : coupon.code,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                  ],
                ),
              ),
              if (coupon.code.isNotEmpty)
                FilledButton.icon(
                  onPressed: () => _copyCode(coupon.code),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF292524),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text('Copy'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 10).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: 5,
              child: Divider(height: 1, thickness: 1, color: _border),
            ),
          ),
        );
      },
    );
  }
}

class _CouponEntry {
  final String code;
  final String title;
  final String rule;
  final String discountLabel;
  final bool isLive;

  const _CouponEntry({
    required this.code,
    required this.title,
    required this.rule,
    required this.discountLabel,
    required this.isLive,
  });
}
