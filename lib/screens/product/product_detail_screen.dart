import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/wishlist_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? heroTag;

  const ProductDetailScreen({super.key, required this.productId, this.heroTag});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _cartBounce;
  late Animation<double> _cartScale;
  final PageController _imgCtrl = PageController();
  int _imgIndex = 0;
  bool _addedToCart = false;
  bool _descExpanded = false;
  // _isFav removed – now using wishlistProvider
  bool _shippingOpen = false;
  YoutubePlayerController? _ytCtrl;
  bool _videoReady = false;
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  String? _error;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  // Spotlyst Q1 Design Tokens
  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _green = Color(0xFF16A34A);
  static const Color _red = Color(0xFFEF4444);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _txt = Color(0xFF1E293B);
  static const Color _txtSec = Color(0xFF64748B);
  static const Color _txtMuted = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _violet = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _cartBounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _cartScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _cartBounce, curve: Curves.easeOutBack));
    _fetchProduct();
  }

  @override
  void dispose() {
    _cartBounce.dispose();
    _imgCtrl.dispose();
    _ytCtrl?.dispose();
    super.dispose();
  }

  void _initYoutube() {
    final url = _product?['videoUrl']?.toString() ?? '';
    if (url.isEmpty) return;
    final id = YoutubePlayer.convertUrlToId(url);
    if (id == null) return;
    _ytCtrl = YoutubePlayerController(initialVideoId: id,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false,
        enableCaption: false, showLiveFullscreenButton: false,
        disableDragSeek: false, forceHD: false));
  }

  void _openFullscreenVideo() {
    final url = _product?['videoUrl']?.toString() ?? '';
    if (url.isEmpty) return;
    final vid = YoutubePlayer.convertUrlToId(url);
    if (vid == null) return;

    // Pause inline player if playing
    _ytCtrl?.pause();

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FullscreenVideoPage(videoId: vid),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _fetchProduct() async {
    try {
      final r = await _dio.get('/products/${widget.productId}');
      if (r.statusCode == 200) {
        setState(() { _product = r.data['data'] ?? r.data; _isLoading = false; });
        _trackView();
      }
    } catch (e) {
      debugPrint('Error fetching product: $e');
      setState(() { _isLoading = false; _error = 'Failed to load product details'; });
    }
  }

  Future<void> _trackView() async {
    try {
      final token = await StorageService.getAccessToken();
      await _dio.post('/products/${widget.productId}/view',
        data: {'source': 'direct'},
        options: token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null,
      );
    } catch (_) {}
  }

  Future<void> _trackEvent(String event) async {
    try {
      final token = await StorageService.getAccessToken();
      await _dio.post('/products/${widget.productId}/event',
        data: {'event': event, 'source': 'direct'},
        options: token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null,
      );
    } catch (_) {}
  }

  List<String> get _images {
    if (_product == null) return [];
    final imgs = _product!['images'] as List<dynamic>?;
    if (imgs == null || imgs.isEmpty) return [];
    return imgs.map((e) => (e as Map<String, dynamic>)['url']?.toString() ?? '')
        .where((u) => u.isNotEmpty).toList();
  }

  List<Map<String, dynamic>> get _specs {
    if (_product == null) return [];
    return (_product!['specifications'] as List<dynamic>?)
        ?.map((e) => e as Map<String, dynamic>).toList() ?? [];
  }

  List<String> get _bullets {
    if (_product == null) return [];
    return (_product!['bulletPoints'] as List<dynamic>?)
        ?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() ?? [];
  }

  String _fmt(dynamic price) {
    if (price == null) return '0';
    final v = (price is int) ? price.toDouble() : (price as num).toDouble();
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(v % 100000 == 0 ? 0 : 1)}L';
    if (v >= 1000) {
      final f = v.toStringAsFixed(0);
      final r = StringBuffer();
      int c = 0;
      for (int i = f.length - 1; i >= 0; i--) {
        if (c == 3 || (c > 3 && (c - 3) % 2 == 0)) r.write(',');
        r.write(f[i]); c++;
      }
      return r.toString().split('').reversed.join('');
    }
    return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
  }

  IconData _specIcon(String key) {
    final k = key.toLowerCase();
    if (k.contains('engine') || k.contains('power') || k.contains('hp')) return Icons.settings_suggest;
    if (k.contains('fuel')) return Icons.local_gas_station;
    if (k.contains('warranty')) return Icons.verified;
    if (k.contains('rpm') || k.contains('speed')) return Icons.speed;
    if (k.contains('weight')) return Icons.fitness_center;
    if (k.contains('dimension') || k.contains('size')) return Icons.straighten;
    if (k.contains('material')) return Icons.diamond;
    if (k.contains('capacity')) return Icons.water_drop;
    return Icons.info_outline;
  }

  // ══════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final bp = MediaQuery.of(context).padding.bottom;
    final tp = MediaQuery.of(context).padding.top;

    if (_isLoading) {
      return Scaffold(backgroundColor: _bg, body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 28, height: 28,
            child: CircularProgressIndicator(color: _blue, strokeWidth: 2.5)),
          const SizedBox(height: 14),
          Text('Loading product...', style: GoogleFonts.plusJakartaSans(
            color: _txtSec, fontSize: 14)),
        ])));
    }

    if (_error != null || _product == null) {
      return Scaffold(backgroundColor: _bg, body: SafeArea(
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(8),
            child: Align(alignment: Alignment.centerLeft,
              child: IconButton(onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: _blue, size: 20)))),
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: _txtMuted, size: 48),
            const SizedBox(height: 12),
            Text(_error ?? 'Product not found',
              style: GoogleFonts.plusJakartaSans(color: _txtSec, fontSize: 15)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () { setState(() { _isLoading = true; _error = null; }); _fetchProduct(); },
              child: Text('Retry', style: GoogleFonts.plusJakartaSans(
                color: _blue, fontSize: 15, fontWeight: FontWeight.w600))),
          ]))),
        ])));
    }

    final name = _product!['name']?.toString() ?? 'Product';
    final desc = _product!['description']?.toString() ??
        _product!['shortDescription']?.toString() ?? '';
    final sku = _product!['sku']?.toString() ?? '';
    final price = _product!['price'] ?? _product!['retailPrice'];
    final mrp = _product!['mrp'];
    final wsPrice = _product!['wholesalePrice'];
    final minWsQty = _product!['minWholesaleQuantity'] ?? 5;
    final stock = _product!['stock'] ?? 0;
    final inStock = (stock is int ? stock : 0) > 0;
    final isFeatured = _product!['isFeatured'] == true;
    final isHot = _product!['isHot'] == true;
    final isWholesaler = ref.read(authProvider).user?.isWholesaler == true;
    final negEnabled = _product!['negotiationEnabled'] == true && isWholesaler;
    int disc = 0;
    final mrpNum = (mrp is num) ? mrp : null;
    final priceNum = (price is num) ? price : null;
    if (mrpNum != null && priceNum != null && mrpNum > priceNum) {
      disc = (((mrpNum - priceNum) / mrpNum) * 100).round();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(backgroundColor: _bg,
        body: Stack(children: [
          CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
            SliverToBoxAdapter(child: SizedBox(height: tp + 56)),
            SliverToBoxAdapter(child: _imageCarousel()),
            SliverToBoxAdapter(child: _infoSection(name, sku, price, mrp, disc,
                stock, inStock, isFeatured, isHot)),
            if (_specs.isNotEmpty) SliverToBoxAdapter(child: _specsSection()),
            if (negEnabled) SliverToBoxAdapter(child: _negotiateCard(
                name, price, wsPrice, minWsQty)),
            if (desc.isNotEmpty) SliverToBoxAdapter(child: _descSection(desc)),
            SliverToBoxAdapter(child: _videoSection()),
            SliverToBoxAdapter(child: _shippingSection()),
            SliverToBoxAdapter(child: SizedBox(height: 100 + bp)),
          ]),
          _topBar(tp, name, inStock),
          _bottomBar(name, price, mrp, stock, inStock, bp,
              negEnabled, wsPrice, minWsQty),
        ])),
    );
  }

  // ── TOP BAR ──
  Widget _topBar(double tp, String name, bool inStock) {
    return Positioned(top: 0, left: 0, right: 0,
      child: ClipRect(
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.fromLTRB(8, tp + 4, 8, 10),
            decoration: BoxDecoration(
              color: _card.withOpacity(0.85),
              border: Border(bottom: BorderSide(color: _border.withOpacity(0.5)))),
            child: Row(children: [
              _circleBtn(Icons.arrow_back_ios_new, () => context.pop()),
              const SizedBox(width: 4),
              Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _txt)),
                Text(inStock ? 'In Stock' : 'Out of Stock',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: inStock ? _green : _red)),
              ])),
              const SizedBox(width: 4),
              _circleBtn(Icons.share_outlined, () {
                final p = _product;
                if (p == null) return;
                final pName = p['name']?.toString() ?? 'Product';
                final pPrice = p['price'] ?? p['retailPrice'];
                final shareText = 'Check out $pName'
                    '${pPrice != null ? ' - ₹${_fmt(pPrice)}' : ''}'
                    ' on AgriMart!\n\nhttps://agrimart.app/product/${widget.productId}';
                SharePlus.instance.share(ShareParams(text: shareText));
              }),
              Builder(builder: (ctx) {
                final isFav = ref.watch(wishlistProvider).contains(widget.productId);
                return _circleBtn(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  () {
                    final p = _product;
                    if (p == null) return;
                    final item = WishlistItem(
                      productId: widget.productId,
                      name: p['name']?.toString() ?? '',
                      image: _images.isNotEmpty ? _images.first : null,
                      price: (p['price'] ?? 0).toDouble(),
                      mrp: p['mrp'] != null ? (p['mrp'] as num).toDouble() : null,
                      category: p['category']?.toString(),
                    );
                    ref.read(wishlistProvider.notifier).toggle(item);
                  },
                  color: isFav ? _red : _txtSec);
              }),
            ])))));
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(onTap: onTap,
      child: Container(width: 38, height: 38,
        decoration: BoxDecoration(color: _bg.withOpacity(0.6), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: color ?? _txt)));
  }

  // ── IMAGE CAROUSEL ──
  Widget _imageCarousel() {
    if (_images.isEmpty) {
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(height: 260,
          decoration: BoxDecoration(color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border)),
          child: const Center(
            child: Icon(Icons.image_outlined, size: 56, color: _txtMuted))));
    }
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 16, offset: const Offset(0, 4))]),
        child: ClipRRect(borderRadius: BorderRadius.circular(20),
          child: Stack(children: [
            AspectRatio(aspectRatio: 4 / 3,
              child: PageView.builder(
                controller: _imgCtrl, itemCount: _images.length,
                onPageChanged: (i) => setState(() => _imgIndex = i),
                itemBuilder: (_, i) {
                  final img = CachedNetworkImage(
                    imageUrl: _images[i], fit: BoxFit.contain,
                    placeholder: (_, __) => Container(color: _card,
                      child: const Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: _blue)))),
                    errorWidget: (_, __, ___) => Container(color: _card,
                      child: const Center(child: Icon(Icons.broken_image,
                        size: 48, color: _txtMuted))));
                  if (i == 0 && widget.heroTag != null) {
                    return Hero(tag: widget.heroTag!,
                      child: Container(color: _card, child: img));
                  }
                  return Container(color: _card, child: img);
                })),
            if (_images.length > 1)
              Positioned(bottom: 14, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_images.length, (i) =>
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: i == _imgIndex ? 20 : 6, height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _imgIndex ? _blue : _txt.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3)))))),
          ]))));
  }

  // ── PRODUCT INFO ──
  Widget _infoSection(String name, String sku, dynamic price, dynamic mrp,
      int disc, dynamic stock, bool inStock, bool featured, bool hot) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
          blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (featured || hot) ...[
          Row(children: [
            if (featured) _badge('Top Rated', _blue),
            if (hot) ...[
              if (featured) const SizedBox(width: 8),
              _badge('Hot Deal', _amber)],
          ]),
          const SizedBox(height: 12),
        ],
        if (sku.isNotEmpty) Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(sku, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: _txtMuted, letterSpacing: 0.5))),
        Text(name, style: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w800, color: _txt,
          height: 1.2, letterSpacing: -0.3)),
        const SizedBox(height: 16),
        // Price container
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _bg,
            borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            if (price != null) Text('₹${_fmt(price)}',
              style: GoogleFonts.raleway(fontSize: 28,
                fontWeight: FontWeight.w700, color: _txt)),
            if (mrp != null && mrp != price) ...[
              const SizedBox(width: 10),
              Text('₹${_fmt(mrp)}', style: GoogleFonts.raleway(
                fontSize: 16, color: _txtMuted,
                decoration: TextDecoration.lineThrough))],
            if (disc > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
                child: Text('$disc% OFF', style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _green)))],
          ])),
        const SizedBox(height: 12),
        Row(children: [
          Icon(inStock ? Icons.check_circle : Icons.cancel,
            size: 16, color: inStock ? _green : _red),
          const SizedBox(width: 6),
          Text(
            inStock
              ? (stock is int && stock <= 10
                  ? 'Only $stock left' : 'In stock')
              : 'Out of stock',
            style: GoogleFonts.plusJakartaSans(fontSize: 13,
              fontWeight: FontWeight.w600,
              color: inStock ? _green : _red)),
          const Spacer(),
          Text('Incl. taxes', style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: _txtMuted)),
        ]),
      ]));
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: GoogleFonts.plusJakartaSans(
        fontSize: 11, fontWeight: FontWeight.w700, color: color)));
  }

  // ── SPECIFICATIONS ──
  Widget _specsSection() {
    final previewCount = _specs.length > 3 ? 3 : _specs.length;
    final hasMore = _specs.length > 3;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
          blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.settings_suggest_outlined, color: _blue, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('Specifications', style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w700, color: _txt))),
          Text('${_specs.length} specs', style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: _txtMuted)),
        ]),
        const SizedBox(height: 14),
        // Vertical spec list with fade
        Stack(children: [
          Column(children: List.generate(previewCount, (i) {
            final key = _specs[i]['key']?.toString() ?? '';
            final val = _specs[i]['value']?.toString() ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: i < previewCount - 1
                  ? Border(bottom: BorderSide(color: _border.withOpacity(0.4)))
                  : null),
              child: Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(_specIcon(key), color: _blue, size: 18)),
                const SizedBox(width: 14),
                Expanded(child: Text(key, style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w500, color: _txtSec))),
                Text(val, style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _txt)),
              ]));
          })),
          // Fade overlay at the bottom
          if (hasMore) Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_card.withOpacity(0.0), _card])))),
        ]),
        // View All button
        if (hasMore) GestureDetector(
          onTap: _openSpecsSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _border.withOpacity(0.4)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('View all ${_specs.length} specifications',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _blue)),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _blue),
            ])),
        ),
        if (!hasMore) const SizedBox(height: 20),
      ]));
  }

  void _openSpecsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle bar
          Center(child: Container(width: 40, height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(color: _border,
              borderRadius: BorderRadius.circular(100)))),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.settings_suggest_outlined,
                  color: _blue, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('All Specifications', style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _txt)),
                Text('${_specs.length} specs', style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: _txtSec)),
              ])),
              IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close_rounded, color: _txtMuted, size: 22)),
            ])),
          const SizedBox(height: 8),
          Divider(height: 1, color: _border.withOpacity(0.5)),
          // Specs list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: _specs.length,
              separatorBuilder: (_, __) => Divider(
                height: 1, color: _border.withOpacity(0.4)),
              itemBuilder: (_, i) {
                final key = _specs[i]['key']?.toString() ?? '';
                final val = _specs[i]['value']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(10)),
                      child: Icon(_specIcon(key), color: _blue, size: 18)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(key, style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: _txtSec, letterSpacing: 0.2)),
                      const SizedBox(height: 2),
                      Text(val, style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _txt)),
                    ])),
                  ]));
              }),
          ),
        ]),
      ),
    );
  }

  // ── NEGOTIATE CARD ──
  Widget _negotiateCard(String name, dynamic price,
      dynamic wsPrice, dynamic minQty) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.handshake_outlined,
              color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bulk Negotiation', style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Get wholesale pricing for custom bulk orders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: Colors.white.withOpacity(0.8))),
          ])),
        ]),
        if (wsPrice != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Text('Wholesale: ', style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: Colors.white.withOpacity(0.7))),
              Text('₹${_fmt(wsPrice)}/unit', style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ]))],
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _openNegotiateSheet(name, price, wsPrice, minQty),
          child: Container(width: double.infinity, height: 48,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.request_quote_outlined, size: 18, color: _violet),
              const SizedBox(width: 8),
              Text('Start Negotiation', style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w700, color: _violet)),
            ]))),
      ]));
  }

  // ── DESCRIPTION ──
  Widget _descSection(String description) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
          blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Description', style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: _txt)),
        const SizedBox(height: 12),
        Text(
          _descExpanded ? description
            : (description.length > 200
                ? '${description.substring(0, 200)}...' : description),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: _txtSec, height: 1.7)),
        if (_bullets.isNotEmpty) ...[
          const SizedBox(height: 14),
          ...(_descExpanded ? _bullets : _bullets.take(3)).map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(margin: const EdgeInsets.only(top: 6),
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: _blue, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Text(p, style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w500, color: _txt))),
            ])))],
        if (description.length > 200 || _bullets.length > 3) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Text(_descExpanded ? 'Show less' : 'Read more',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600, color: _blue)))],
      ]));
  }

  // ── VIDEO (lazy) ──
  Widget _videoSection() {
    final url = _product?['videoUrl']?.toString() ?? '';
    if (url.isEmpty) return const SizedBox.shrink();
    final vid = YoutubePlayer.convertUrlToId(url);
    if (vid == null) return const SizedBox.shrink();

    if (!_videoReady) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: GestureDetector(
          onTap: () { _initYoutube(); setState(() => _videoReady = true); },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 10, offset: const Offset(0, 2))]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(alignment: Alignment.center, children: [
                CachedNetworkImage(
                  imageUrl: 'https://img.youtube.com/vi/$vid/hqdefault.jpg',
                  width: double.infinity, height: 200, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(height: 200, color: _bg),
                  errorWidget: (_, __, ___) => Container(height: 200, color: _bg,
                    child: const Center(child: Icon(Icons.play_circle_outline,
                      size: 48, color: _txtMuted)))),
                Container(width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 32)),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent,
                          Colors.black.withOpacity(0.6)])),
                    child: Row(children: [
                      const Icon(Icons.play_circle_filled,
                        color: Color(0xFFFF0000), size: 18),
                      const SizedBox(width: 8),
                      Text('Product Demo',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13,
                          fontWeight: FontWeight.w600, color: Colors.white)),
                    ]))),
              ])))));
    }
    if (_ytCtrl == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(20),
            child: YoutubePlayer(
              controller: _ytCtrl!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: _blue,
              progressColors: const ProgressBarColors(
                playedColor: Color(0xFFFF0000),
                handleColor: Color(0xFFFF0000)))),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: _openFullscreenVideo,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle),
                child: const Icon(Icons.fullscreen_rounded,
                  color: Colors.white, size: 22)),
            ),
          ),
        ],
      ));
  }

  // ── SHIPPING ──
  Widget _shippingSection() {
    final terms = _product?['shippingTerms']?.toString() ??
        'Free shipping on orders above ₹5,000. Standard delivery 5-7 '
        'business days.\n\nReturn Policy: 7-day returns for unused items '
        'in original packaging.';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
          blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _shippingOpen = !_shippingOpen),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              const Icon(Icons.local_shipping_outlined,
                size: 20, color: _txtSec),
              const SizedBox(width: 12),
              Expanded(child: Text('Shipping & Returns',
                style: GoogleFonts.plusJakartaSans(fontSize: 15,
                  fontWeight: FontWeight.w600, color: _txt))),
              AnimatedRotation(
                turns: _shippingOpen ? 0.25 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.chevron_right,
                  color: _txtMuted, size: 20)),
            ]))),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(terms, style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: _txtSec, height: 1.6))),
          crossFadeState: _shippingOpen
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOut,
        ),
      ]));
  }

  // ── BOTTOM BAR ──
  Widget _bottomBar(String name, dynamic price, dynamic mrp, dynamic stock,
      bool inStock, double bp, bool negEnabled,
      dynamic wsPrice, dynamic minQty) {
    return Positioned(left: 0, right: 0, bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bp + 10),
        decoration: BoxDecoration(color: _card,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
            blurRadius: 20, offset: const Offset(0, -4))]),
        child: Row(children: [
          // Cart button
          ScaleTransition(scale: _cartScale,
            child: GestureDetector(
              onTap: inStock && !_addedToCart ? () {
                final img = _images.isNotEmpty ? _images[0] : null;
                ref.read(cartProvider.notifier).addItem(
                  productId: widget.productId, name: name, image: img,
                  price: (price is int) ? price.toDouble()
                      : (price as num?)?.toDouble() ?? 0,
                  mrp: (mrp is int) ? mrp.toDouble()
                      : (mrp as num?)?.toDouble(),
                  quantity: 1, stock: stock is int ? stock : 99);
                _trackEvent('cart_add');
                setState(() => _addedToCart = true);
                _cartBounce.forward().then((_) => _cartBounce.reverse());
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _addedToCart = false);
                });
              } : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: _addedToCart ? _green : _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _addedToCart ? _green : _border)),
                child: Icon(
                  _addedToCart ? Icons.check_rounded
                      : Icons.shopping_cart_outlined,
                  size: 20,
                  color: _addedToCart ? Colors.white : _blue)))),
          const SizedBox(width: 10),
          // Buy Now
          Expanded(child: GestureDetector(
            onTap: inStock ? () {
              final img = _images.isNotEmpty ? _images[0] : null;
              ref.read(cartProvider.notifier).addItem(
                productId: widget.productId, name: name, image: img,
                price: (price is int) ? price.toDouble()
                    : (price as num?)?.toDouble() ?? 0,
                mrp: (mrp is int) ? mrp.toDouble()
                    : (mrp as num?)?.toDouble(),
                quantity: 1, stock: stock is int ? stock : 99);
              _trackEvent('cart_add');
              context.go('/home', extra: {'tab': 2});
            } : null,
            child: Container(height: 52,
              decoration: BoxDecoration(
                color: inStock ? _blue : _txtMuted,
                borderRadius: BorderRadius.circular(16),
                boxShadow: inStock ? [BoxShadow(
                  color: _blue.withOpacity(0.25),
                  blurRadius: 12, offset: const Offset(0, 4))] : null),
              child: Center(child: Text('Buy Now',
                style: GoogleFonts.plusJakartaSans(fontSize: 16,
                  fontWeight: FontWeight.w700, color: Colors.white)))))),
          // Negotiate
          if (negEnabled) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _openNegotiateSheet(
                  name, price, wsPrice, minQty),
              child: Container(height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                    color: _violet.withOpacity(0.25),
                    blurRadius: 12, offset: const Offset(0, 4))]),
                child: Row(children: [
                  const Icon(Icons.handshake_outlined,
                    color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('Negotiate', style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: Colors.white)),
                ])))],
        ])));
  }

  // ══════════════════════════════════════════
  // NEGOTIATE SHEET (native Flutter animation)
  // ══════════════════════════════════════════
  void _openNegotiateSheet(String productName, dynamic retailPrice,
      dynamic wsPrice, dynamic minQty) {
    final rp = retailPrice != null
        ? (retailPrice is int ? retailPrice.toDouble()
            : (retailPrice as num).toDouble())
        : 0.0;
    final wp = wsPrice != null
        ? (wsPrice is int ? wsPrice.toDouble()
            : (wsPrice as num).toDouble())
        : rp * 0.85;
    final minQ = minQty is int ? minQty : 10;
    int step = 0;
    int qty = 1;
    double target = wp;
    final qtyCtrl = TextEditingController(text: '$qty');
    final priceCtrl = TextEditingController(text: _fmt(target));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        Widget content;
        if (step == 0) {
          content = _sheetStep1(qty, qtyCtrl, minQ,
            (q) => setSheet(() => qty = q),
            () => setSheet(() => step = 1));
        } else if (step == 1) {
          content = _sheetStep2(qty, target, priceCtrl, rp,
            (p) => setSheet(() => target = p),
            () => setSheet(() => step = 0),
            () => setSheet(() => step = 2));
        } else {
          content = _sheetStep3(productName, qty, target, rp,
            () => setSheet(() => step = 1),
            () { Navigator.of(ctx).pop(); _submitNegotiation(qty, target); });
        }

        return Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(ctx).padding.top + 40),
          decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28))),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 12, 20,
              MediaQuery.of(ctx).padding.bottom + 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: _border,
                  borderRadius: BorderRadius.circular(100)))),
              _stepDots(step),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(step), child: content)),
            ])));
      }),
    ).then((_) { qtyCtrl.dispose(); priceCtrl.dispose(); });
  }

  Widget _stepDots(int cur) {
    return Row(children: List.generate(3, (i) {
      final done = i < cur;
      final active = i == cur;
      return Expanded(child: Row(children: [
        if (i > 0) Expanded(child: Container(
          height: 2, color: done ? _blue : _border)),
        Container(width: 28, height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: done || active ? _blue : _bg,
            border: Border.all(
              color: done || active ? _blue : _border, width: 2)),
          child: Center(child: done
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : Text('${i + 1}', style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: active ? Colors.white : _txtMuted)))),
        if (i < 2) Expanded(child: Container(
          height: 2, color: done ? _blue : _border)),
      ]));
    }));
  }

  // Step 1: Quantity
  Widget _sheetStep1(int qty, TextEditingController ctrl, int minQ,
      ValueChanged<int> onQty, VoidCallback onNext) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _violet.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.inventory_2_outlined,
            color: _violet, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('How many units?', style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w700, color: _txt)),
          Text('Select quantity for your bulk quote',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: _txtSec)),
        ])),
      ]),
      const SizedBox(height: 20),
      Text('QUICK SELECT', style: GoogleFonts.plusJakartaSans(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: _txtSec, letterSpacing: 1)),
      const SizedBox(height: 8),
      Row(children: [10, 25, 50, 100].map((q) {
        final sel = qty == q;
        return Expanded(child: GestureDetector(
          onTap: () { onQty(q); ctrl.text = '$q'; },
          child: Container(
            margin: EdgeInsets.only(right: q == 100 ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sel ? _blue : _bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? _blue : _border)),
            alignment: Alignment.center,
            child: Text('$q', style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: sel ? Colors.white : _txt)))));
      }).toList()),
      const SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(color: _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border)),
        child: TextField(controller: ctrl,
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final p = int.tryParse(v); if (p != null) onQty(p);
          },
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w700, color: _txt),
          decoration: InputDecoration(
            hintText: 'Custom quantity',
            hintStyle: GoogleFonts.plusJakartaSans(color: _txtMuted),
            prefixIcon: Icon(Icons.edit_outlined,
              color: _txtSec, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14)))),
      const SizedBox(height: 20),
      GestureDetector(onTap: qty >= 1 ? onNext : null,
        child: Container(width: double.infinity, height: 52,
          decoration: BoxDecoration(
            color: qty >= 1 ? _blue : _border,
            borderRadius: BorderRadius.circular(14),
            boxShadow: qty >= 1 ? [BoxShadow(
              color: _blue.withOpacity(0.3),
              blurRadius: 12, offset: const Offset(0, 4))] : null),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Continue to Pricing', style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: qty >= 1 ? Colors.white : _txtMuted)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20,
              color: qty >= 1 ? Colors.white : _txtMuted),
          ]))),
    ]);
  }

  // Step 2: Price
  Widget _sheetStep2(int qty, double target, TextEditingController ctrl,
      double rp, ValueChanged<double> onPrice,
      VoidCallback onBack, VoidCallback onNext) {
    final savings = (rp - target) * qty;
    final pct = rp > 0 ? ((rp - target) / rp * 100).round() : 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.payments_outlined, color: _blue, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Set Your Price', style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w700, color: _txt)),
          Text('$qty units · Retail: ₹${_fmt(rp)}/unit',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: _txtSec)),
        ])),
      ]),
      const SizedBox(height: 18),
      Text('TARGET PRICE PER UNIT', style: GoogleFonts.plusJakartaSans(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: _txtSec, letterSpacing: 1)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border)),
        child: TextField(controller: ctrl,
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final p = double.tryParse(v.replaceAll(',', ''));
            if (p != null) onPrice(p);
          },
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24, fontWeight: FontWeight.w700, color: _txt),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: GoogleFonts.plusJakartaSans(
              fontSize: 24, fontWeight: FontWeight.w700, color: _blue),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14)))),
      const SizedBox(height: 10),
      Row(children: [0.80, 0.85, 0.90].map((f) {
        final v = rp * f;
        final sel = (target - v).abs() < 1;
        return Expanded(child: GestureDetector(
          onTap: () { onPrice(v); ctrl.text = _fmt(v); },
          child: Container(
            margin: EdgeInsets.only(right: f == 0.90 ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _blue.withOpacity(0.08) : _bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? _blue : _border)),
            child: Column(children: [
              Text('₹${_fmt(v)}', style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: sel ? _blue : _txt)),
              Text('${((1 - f) * 100).round()}% off',
                style: GoogleFonts.plusJakartaSans(fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: sel ? _blue : _txtSec)),
            ]))));
      }).toList()),
      if (target > 0 && target < rp) ...[
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _green.withOpacity(0.2))),
          child: Row(children: [
            Icon(Icons.savings_outlined, color: _green, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Save ₹${_fmt(savings)} total ($pct% off × $qty units)',
              style: GoogleFonts.plusJakartaSans(fontSize: 13,
                fontWeight: FontWeight.w600, color: _green))),
          ]))],
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: GestureDetector(onTap: onBack,
          child: Container(height: 50,
            decoration: BoxDecoration(color: _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border)),
            child: Center(child: Text('Back',
              style: GoogleFonts.plusJakartaSans(fontSize: 14,
                fontWeight: FontWeight.w700, color: _txt)))))),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: GestureDetector(
          onTap: target > 0 ? onNext : null,
          child: Container(height: 50,
            decoration: BoxDecoration(
              color: target > 0 ? _blue : _border,
              borderRadius: BorderRadius.circular(14),
              boxShadow: target > 0 ? [BoxShadow(
                color: _blue.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))] : null),
            child: Center(child: Text('Review Quote',
              style: GoogleFonts.plusJakartaSans(fontSize: 14,
                fontWeight: FontWeight.w700,
                color: target > 0 ? Colors.white : _txtMuted)))))),
      ]),
    ]);
  }

  // Step 3: Review
  Widget _sheetStep3(String productName, int qty, double target, double rp,
      VoidCallback onBack, VoidCallback onSubmit) {
    final total = target * qty;
    final saved = (rp * qty) - total;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.fact_check_outlined,
            color: _green, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Review Quote', style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w700, color: _txt)),
          Text('Confirm details before submitting',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: _txtSec)),
        ])),
      ]),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border)),
        child: Column(children: [
          _reviewLine('Product', productName),
          _divider(),
          _reviewLine('Quantity', '$qty units'),
          _divider(),
          _reviewLine('Your Price', '₹${_fmt(target)}/unit'),
          _divider(),
          _reviewLine('Retail Price', '₹${_fmt(rp)}/unit', muted: true),
          _divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total', style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w700, color: _txt)),
            Text('₹${_fmt(total)}', style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w800, color: _blue)),
          ]),
        ])),
      if (saved > 0) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _green.withOpacity(0.2))),
          child: Row(children: [
            Icon(Icons.trending_down_rounded, color: _green, size: 18),
            const SizedBox(width: 8),
            Text('You save ₹${_fmt(saved)} vs retail',
              style: GoogleFonts.plusJakartaSans(fontSize: 13,
                fontWeight: FontWeight.w600, color: _green)),
          ]))],
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _amber.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _amber.withOpacity(0.2))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: _amber, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Bulk orders require manual UPI verification before processing.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12,
              color: const Color(0xFF92400E), height: 1.4))),
        ])),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: GestureDetector(onTap: onBack,
          child: Container(height: 50,
            decoration: BoxDecoration(color: _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border)),
            child: Center(child: Text('Edit',
              style: GoogleFonts.plusJakartaSans(fontSize: 14,
                fontWeight: FontWeight.w700, color: _txt)))))),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: GestureDetector(onTap: onSubmit,
          child: Container(height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                color: _violet.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.send_rounded,
                color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Submit Quote', style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: Colors.white)),
            ])))),
      ]),
    ]);
  }

  Widget _reviewLine(String label, String value, {bool muted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 14, color: _txtSec)),
      Flexible(child: Text(value,
        style: GoogleFonts.plusJakartaSans(fontSize: 14,
          fontWeight: FontWeight.w600,
          color: muted ? _txtMuted : _txt,
          decoration: muted ? TextDecoration.lineThrough : null),
        textAlign: TextAlign.right,
        maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _divider() => Container(height: 1,
    color: _border.withOpacity(0.5),
    margin: const EdgeInsets.symmetric(vertical: 10));

  Future<void> _submitNegotiation(int qty, double pricePerUnit) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/negotiations', data: {
        'productId': widget.productId,
        'quantity': qty,
        'pricePerUnit': pricePerUnit,
      });

      if (response.data['success'] == true && mounted) {
        final negNumber = response.data['data']?['negotiationNumber'] ?? '';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Quotation $negNumber submitted for $qty units!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600))),
          ]),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16)));
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['message']?.toString() ?? 'Failed to submit negotiation';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Something went wrong: $e'),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16)));
    }
  }
}

// ══════════════════════════════════════════
// FULLSCREEN VIDEO PAGE (overlay)
// ══════════════════════════════════════════
class _FullscreenVideoPage extends StatefulWidget {
  final String videoId;
  const _FullscreenVideoPage({required this.videoId});

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        showLiveFullscreenButton: false,
        hideControls: false,
        forceHD: true,
      ),
    );
    // Lock to landscape for the fullscreen video page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _controller.dispose();
    // Restore portrait orientation and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFF2563EB),
              progressColors: const ProgressBarColors(
                playedColor: Color(0xFFFF0000),
                handleColor: Color(0xFFFF0000),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
