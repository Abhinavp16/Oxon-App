import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/config/api_config.dart';
import '../../core/providers/cart_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? heroTag;

  const ProductDetailScreen({super.key, required this.productId, this.heroTag});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _cartAnimController;
  late Animation<double> _cartScaleAnim;
  final PageController _imgController = PageController();
  int _currentImageIndex = 0;
  bool _addedToCart = false;
  bool _descExpanded = false;
  bool _isFavorited = false;
  bool _shippingExpanded = false;
  YoutubePlayerController? _ytController;
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  String? _error;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  // iOS Design System
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosBg = Color(0xFFF2F2F7);
  static const Color iosCard = Color(0xFFFFFFFF);
  static const Color iosGreen = Color(0xFF34C759);
  static const Color iosRed = Color(0xFFFF3B30);
  static const Color iosOrange = Color(0xFFFF9500);
  static const Color txtDark = Color(0xFF1C1C1E);
  static const Color txtSec = Color(0xFF8E8E93);
  static const Color txtTert = Color(0xFFAEAEB2);

  @override
  void initState() {
    super.initState();
    _cartAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _cartScaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _cartAnimController, curve: Curves.easeOutBack),
    );
    _fetchProduct();
  }

  @override
  void dispose() {
    _cartAnimController.dispose();
    _imgController.dispose();
    _ytController?.dispose();
    super.dispose();
  }

  void _initYoutubePlayer() {
    final videoUrl = _product?['videoUrl']?.toString() ?? '';
    if (videoUrl.isEmpty) return;
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null) return;
    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: false,
        showLiveFullscreenButton: false,
      ),
    );
  }

  Future<void> _fetchProduct() async {
    try {
      final response = await _dio.get('/products/${widget.productId}');
      if (response.statusCode == 200) {
        setState(() { _product = response.data['data'] ?? response.data; _isLoading = false; });
        _initYoutubePlayer();
      }
    } catch (e) {
      debugPrint('Error fetching product: $e');
      setState(() { _isLoading = false; _error = 'Failed to load product details'; });
    }
  }

  List<String> get _images {
    if (_product == null) return [];
    final images = _product!['images'] as List<dynamic>?;
    if (images == null || images.isEmpty) return [];
    return images.map((e) => (e as Map<String, dynamic>)['url']?.toString() ?? '').where((u) => u.isNotEmpty).toList();
  }

  List<Map<String, dynamic>> get _specs {
    if (_product == null) return [];
    final s = _product!['specifications'] as List<dynamic>?;
    if (s == null) return [];
    return s.map((e) => e as Map<String, dynamic>).toList();
  }

  List<String> get _bullets {
    if (_product == null) return [];
    final p = _product!['bulletPoints'] as List<dynamic>?;
    if (p == null) return [];
    return p.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  String _fmtPrice(dynamic price) {
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

  @override
  Widget build(BuildContext context) {
    final bp = MediaQuery.of(context).padding.bottom;
    final tp = MediaQuery.of(context).padding.top;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: iosBg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: iosBlue, strokeWidth: 2.5)),
            const SizedBox(height: 16),
            Text('Loading...', style: GoogleFonts.plusJakartaSans(color: txtSec, fontSize: 15)),
          ]),
        ),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        backgroundColor: iosBg,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(children: [
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, color: iosBlue, size: 22)),
              ]),
            ),
            Expanded(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: txtSec, size: 48),
                  const SizedBox(height: 16),
                  Text(_error ?? 'Product not found', style: GoogleFonts.plusJakartaSans(color: txtSec, fontSize: 16)),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () { setState(() { _isLoading = true; _error = null; }); _fetchProduct(); },
                    child: Text('Retry', style: GoogleFonts.plusJakartaSans(color: iosBlue, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
    }

    final name = _product!['name']?.toString() ?? 'Product';
    final desc = _product!['description']?.toString() ?? _product!['shortDescription']?.toString() ?? '';
    final sku = _product!['sku']?.toString() ?? '';
    final price = _product!['price'] ?? _product!['retailPrice'];
    final mrp = _product!['mrp'];
    final wsPrice = _product!['wholesalePrice'];
    final minWsQty = _product!['minWholesaleQuantity'] ?? 5;
    final stock = _product!['stock'] ?? 0;
    final inStock = (stock is int ? stock : 0) > 0;
    final isFeatured = _product!['isFeatured'] == true;
    final isHot = _product!['isHot'] == true;
    final negEnabled = _product!['negotiationEnabled'] == true;

    int disc = 0;
    if (mrp != null && price != null && (mrp as num) > (price as num)) {
      disc = ((((mrp as num) - (price as num)) / (mrp as num)) * 100).round();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: iosBg,
        body: Stack(children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: tp + 52)),
              SliverToBoxAdapter(child: _buildImageCarousel()),
              SliverToBoxAdapter(child: _buildInfoCard(name, sku, price, mrp, disc, stock, inStock, isFeatured, isHot)),
              if (_specs.isNotEmpty) SliverToBoxAdapter(child: _buildSpecsSection()),
              if (negEnabled && wsPrice != null) SliverToBoxAdapter(child: _buildWholesaleCard(wsPrice, minWsQty)),
              if (desc.isNotEmpty) SliverToBoxAdapter(child: _buildDescSection(desc)),
              SliverToBoxAdapter(child: _buildVideoDemo()),
              SliverToBoxAdapter(child: _buildInfoList()),
              SliverToBoxAdapter(child: SizedBox(height: 100 + bp)),
            ],
          ),
          _buildNavBar(tp, name, inStock),
          _buildBottomBar(name, price, mrp, stock, inStock, bp),
        ]),
      ),
    );
  }

  // ─── FROSTED NAV BAR ───
  Widget _buildNavBar(double tp, String name, bool inStock) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(4, tp + 2, 4, 10),
            decoration: BoxDecoration(
              color: iosBg.withOpacity(0.8),
              border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40, height: 40, alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back_ios_new, color: iosBlue, size: 22),
                ),
              ),
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: txtDark)),
                  const SizedBox(height: 1),
                  Text(inStock ? 'In Stock' : 'Out of Stock',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: txtSec)),
                ]),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(width: 40, height: 40, alignment: Alignment.center,
                  child: const Icon(Icons.ios_share, color: iosBlue, size: 22)),
              ),
              GestureDetector(
                onTap: () => setState(() => _isFavorited = !_isFavorited),
                child: Container(width: 40, height: 40, alignment: Alignment.center,
                  child: Icon(_isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? iosRed : iosBlue, size: 22)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── IMAGE CAROUSEL ───
  Widget _buildImageCarousel() {
    if (_images.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 280,
          decoration: BoxDecoration(color: iosCard, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: const Center(child: Icon(Icons.image, size: 64, color: txtTert)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: PageView.builder(
                controller: _imgController,
                itemCount: _images.length,
                onPageChanged: (i) => setState(() => _currentImageIndex = i),
                itemBuilder: (context, index) {
                  final img = CachedNetworkImage(
                    imageUrl: _images[index], fit: BoxFit.contain,
                    placeholder: (_, __) => Container(color: iosCard,
                      child: const Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: iosBlue)))),
                    errorWidget: (_, __, ___) => Container(color: iosCard,
                      child: const Center(child: Icon(Icons.broken_image, size: 48, color: txtTert))),
                  );
                  if (index == 0 && widget.heroTag != null) {
                    return Hero(tag: widget.heroTag!, child: Container(color: iosCard, child: img));
                  }
                  return Container(color: iosCard, child: img);
                },
              ),
            ),
            if (_images.length > 1)
              Positioned(
                bottom: 12, left: 0, right: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(_images.length, (i) {
                          return Container(width: 6, height: 6,
                            margin: EdgeInsets.only(right: i < _images.length - 1 ? 6 : 0),
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              color: i == _currentImageIndex ? txtDark : txtDark.withOpacity(0.3)));
                        })),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 12, right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2))),
                    child: Icon(Icons.view_in_ar, size: 20, color: Colors.grey.shade700),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── PRODUCT INFO CARD ───
  Widget _buildInfoCard(String name, String sku, dynamic price, dynamic mrp,
      int disc, dynamic stock, bool inStock, bool featured, bool hot) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: iosCard, borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1)),
          ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Badges + SKU
          Row(children: [
            if (featured) _iosBadge('Top Rated', iosBlue, Colors.white),
            if (hot) ...[if (featured) const SizedBox(width: 8), _iosBadge('Hot', iosOrange, Colors.white)],
            if (sku.isNotEmpty) ...[const SizedBox(width: 8),
              Text(sku, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: txtSec))],
          ]),
          const SizedBox(height: 10),
          // Name
          Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: txtDark, height: 1.2, letterSpacing: -0.5)),
          const SizedBox(height: 16),
          // Price
          Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                if (price != null)
                  Text('₹${_fmtPrice(price)}', style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.w600, color: txtDark)),
                if (mrp != null && mrp != price) ...[const SizedBox(width: 8),
                  Text('₹${_fmtPrice(mrp)}', style: GoogleFonts.raleway(fontSize: 17, fontWeight: FontWeight.w400, color: txtTert, decoration: TextDecoration.lineThrough))],
              ]),
              const SizedBox(height: 2),
              Text(disc > 0 ? '$disc% off · Includes taxes' : 'Includes taxes',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: iosGreen)),
            ]),
          ),
          // Stock
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(children: [
              const Icon(Icons.inventory_2_outlined, size: 18, color: iosOrange),
              const SizedBox(width: 8),
              Text(
                inStock ? (stock is int && stock <= 10 ? 'Only $stock units left in stock' : 'In stock') : 'Currently out of stock',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: inStock ? txtDark : iosRed)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _iosBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: bg.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 1))]),
      child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ─── SPECIFICATIONS ───
  Widget _buildSpecsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: iosCard, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Specifications', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: txtDark)),
          const SizedBox(height: 14),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _specs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final spec = _specs[index];
                final key = spec['key']?.toString() ?? '';
                final val = spec['value']?.toString() ?? '';
                return Container(
                  width: 110, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8F8FA), borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_specIcon(key), color: iosBlue, size: 22),
                    const SizedBox(height: 6),
                    Text(key, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: txtSec),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: txtDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  // ─── WHOLESALE CARD ───
  Widget _buildWholesaleCard(dynamic wsPrice, dynamic minQty) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF007AFF), Color(0xFF5856D6)])),
        child: Stack(children: [
          Positioned(right: -30, bottom: -30,
            child: Transform.rotate(angle: 0.2,
              child: Icon(Icons.handshake, size: 160, color: Colors.white.withOpacity(0.1)))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.groups, color: Colors.white, size: 16)),
              const SizedBox(width: 8),
              Text('BUSINESS', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.9), letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 10),
            Text('Wholesale Program', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Bulk pricing available for orders over $minQty units. Contact sales directly.',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9), height: 1.4)),
            if (wsPrice != null) ...[const SizedBox(height: 8),
              Text('Wholesale price: ₹${_fmtPrice(wsPrice)} per unit',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8)))],
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: iosBlue, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Get Bulk Quote', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600)))),
          ]),
        ]),
      ),
    );
  }

  // ─── DESCRIPTION ───
  Widget _buildDescSection(String description) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: iosCard, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Description', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w600, color: txtDark)),
          const SizedBox(height: 12),
          Text(
            _descExpanded ? description : (description.length > 200 ? '${description.substring(0, 200)}...' : description),
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w400, color: const Color(0xFF6B7280), height: 1.6)),
          if (_bullets.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...(_descExpanded ? _bullets : _bullets.take(3)).map((p) => Container(
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8F8FA), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.check_circle, color: iosBlue, size: 20), const SizedBox(width: 12),
                Expanded(child: Text(p, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF374151)))),
              ]),
            )),
          ],
          if (description.length > 200 || _bullets.length > 3)
            Padding(padding: const EdgeInsets.only(top: 12),
              child: SizedBox(width: double.infinity, height: 40,
                child: TextButton(
                  onPressed: () => setState(() => _descExpanded = !_descExpanded),
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFFEFF6FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(_descExpanded ? 'Show Less' : 'Read More',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: iosBlue))))),
        ]),
      ),
    );
  }

  // ─── VIDEO DEMO ───
  Widget _buildVideoDemo() {
    if (_ytController == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              color: iosCard,
              child: Row(children: [
                const Icon(Icons.play_circle_filled, color: Color(0xFFFF0000), size: 20),
                const SizedBox(width: 8),
                Text('Product Demo', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: txtDark)),
              ]),
            ),
            YoutubePlayer(
              controller: _ytController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: iosBlue,
              progressColors: const ProgressBarColors(
                playedColor: Color(0xFFFF0000),
                handleColor: Color(0xFFFF0000),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── SHIPPING & RETURNS ───
  Widget _buildInfoList() {
    final terms = _product?['shippingTerms']?.toString() ??
        'Free shipping on orders above ₹5,000. Standard delivery within 5-7 business days. Express delivery available at additional cost.\n\nReturn Policy: Products can be returned within 7 days of delivery if unused and in original packaging. Damaged or defective items will be replaced free of charge.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: iosCard, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(children: [
          GestureDetector(
            onTap: () => setState(() => _shippingExpanded = !_shippingExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(children: [
                const Icon(Icons.local_shipping_outlined, color: txtSec, size: 22), const SizedBox(width: 14),
                Expanded(child: Text('Shipping & Returns', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500, color: txtDark))),
                AnimatedRotation(turns: _shippingExpanded ? 0.25 : 0, duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20)),
              ]),
            ),
          ),
          if (_shippingExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(terms, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF6B7280), height: 1.6)),
            ),
        ]),
      ),
    );
  }

  // ─── BOTTOM BAR ───
  Widget _buildBottomBar(String name, dynamic price, dynamic mrp, dynamic stock, bool inStock, double bp) {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 14, 16, bp + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: Row(children: [
          // Add to Cart
          Expanded(
            child: ScaleTransition(
              scale: _cartScaleAnim,
              child: GestureDetector(
                onTap: inStock && !_addedToCart ? () {
                  final img = _images.isNotEmpty ? _images[0] : null;
                  ref.read(cartProvider.notifier).addItem(
                    productId: widget.productId, name: name, image: img,
                    price: (price is int) ? price.toDouble() : (price as num?)?.toDouble() ?? 0,
                    mrp: (mrp is int) ? mrp.toDouble() : (mrp as num?)?.toDouble(),
                    quantity: 1, stock: stock is int ? stock : 99);
                  setState(() => _addedToCart = true);
                  _cartAnimController.forward().then((_) => _cartAnimController.reverse());
                  Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _addedToCart = false); });
                } : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 50,
                  decoration: BoxDecoration(
                    color: _addedToCart ? iosGreen : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(25)),
                  alignment: Alignment.center,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _addedToCart
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20, key: ValueKey('check'))
                        : const Icon(Icons.shopping_cart_outlined, color: Color(0xFF007AFF), size: 20, key: ValueKey('cart')),
                    ),
                    const SizedBox(width: 8),
                    Text(_addedToCart ? 'Added!' : 'Add to Cart',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600,
                        color: _addedToCart ? Colors.white : iosBlue)),
                  ])),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Buy Now
          Expanded(
            child: GestureDetector(
              onTap: inStock ? () {
                final img = _images.isNotEmpty ? _images[0] : null;
                ref.read(cartProvider.notifier).addItem(
                  productId: widget.productId, name: name, image: img,
                  price: (price is int) ? price.toDouble() : (price as num?)?.toDouble() ?? 0,
                  mrp: (mrp is int) ? mrp.toDouble() : (mrp as num?)?.toDouble(),
                  quantity: 1, stock: stock is int ? stock : 99);
                context.go('/home', extra: {'tab': 2});
              } : null,
              child: Container(height: 50,
                decoration: BoxDecoration(
                  color: inStock ? iosBlue : txtTert,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: inStock ? [BoxShadow(color: iosBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : null),
                alignment: Alignment.center,
                child: Text('Buy Now', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))),
            ),
          ),
        ]),
      ),
    );
  }
}
