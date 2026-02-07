import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_config.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/auth_provider.dart';

class MarketplaceHomeScreen extends ConsumerStatefulWidget {
  final int? initialTab;
  const MarketplaceHomeScreen({super.key, this.initialTab});

  @override
  ConsumerState<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends ConsumerState<MarketplaceHomeScreen> {
  late int _selectedNavIndex;
  int _currentCarouselIndex = 0;
  final PageController _carouselController = PageController();
  final TextEditingController _searchController = TextEditingController();
  // Use ApiConfig.baseUrl - update the IP in lib/core/config/api_config.dart
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  // Blue Theme Colors - Apple-like design
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color backgroundWhite = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);

  // State for dynamic data
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingBrands = true;
  bool _isLoadingProducts = true;

  // Search state
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  Timer? _searchDebounce;
  final List<String> _recentSearches = ['Seed Drill', 'Tractor parts'];

  // Sample carousel data
  final List<Map<String, String>> _carouselItems = [
    {
      'title': 'Next-Gen Tractors',
      'subtitle': 'Up to 20% off for bulk wholesaler orders',
      'tag': 'NEW ARRIVAL',
    },
    {
      'title': 'Premium Harvesters',
      'subtitle': 'Best deals on agricultural machinery',
      'tag': 'FEATURED',
    },
    {
      'title': 'Smart Irrigation',
      'subtitle': 'Modern solutions for your farm',
      'tag': 'TRENDING',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialTab ?? 0;
    _fetchBrands();
    _fetchProducts();
  }

  Future<void> _fetchBrands() async {
    try {
      debugPrint('Fetching brands...');
      final response = await _dio.get('/companies');
      debugPrint('Brands response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items = data['data'] ?? data ?? [];
        debugPrint('Found ${items.length} brands');
        setState(() {
          _brands = items.map<Map<String, dynamic>>((item) => <String, dynamic>{
            'id': item['_id']?.toString() ?? item['id']?.toString() ?? '',
            'name': item['name']?.toString() ?? '',
            'logo': item['logo'] is Map ? item['logo']['url']?.toString() ?? '' : item['logo']?.toString() ?? '',
            'slug': item['slug']?.toString() ?? '',
          }).toList();
          _isLoadingBrands = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching brands: $e');
      setState(() => _isLoadingBrands = false);
    }
  }

  Future<void> _fetchProducts() async {
    try {
      debugPrint('Fetching products...');
      final response = await _dio.get('/products');
      debugPrint('Products response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items = data['data'] ?? data ?? [];
        debugPrint('Found ${items.length} products');
        setState(() {
          _products = items.map<Map<String, dynamic>>((item) => <String, dynamic>{
            'id': item['id']?.toString() ?? item['_id']?.toString() ?? '',
            'name': item['name']?.toString() ?? '',
            'brand': item['category']?.toString() ?? '',
            'price': item['price'] ?? item['retailPrice'] ?? 0,
            'originalPrice': item['mrp'] ?? 0,
            'image': item['primaryImage']?.toString() ?? '',
            'isHot': item['isFeatured'] == true,
            'discount': 0,
            'rating': 4.5,
          }).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; _searchQuery = ''; });
      return;
    }
    setState(() { _isSearching = true; _searchQuery = query; });
    try {
      final response = await _dio.get('/products/search', queryParameters: {'q': query});
      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['data'] ?? [];
        setState(() {
          _searchResults = items.map<Map<String, dynamic>>((item) => <String, dynamic>{
            'id': item['id']?.toString() ?? item['_id']?.toString() ?? '',
            'name': item['name']?.toString() ?? '',
            'brand': item['category']?.toString() ?? '',
            'price': item['price'] ?? item['retailPrice'] ?? 0,
            'originalPrice': item['mrp'] ?? 0,
            'image': item['primaryImage']?.toString() ?? '',
            'inStock': item['inStock'] == true,
            'shortDescription': item['shortDescription']?.toString() ?? '',
          }).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  bool get _isWholesaler {
    final auth = ref.read(authProvider);
    return auth.user?.isWholesaler == true;
  }

  List<Widget> get _bodyPages {
    return [
      _buildHomeContent(),
      _buildSearchContent(),
      _buildCartContent(),
      if (_isWholesaler) _buildNegotiationsContent(),
      _buildProfileContent(),
    ];
  }

  int get _profileIndex => _isWholesaler ? 4 : 3;

  @override
  Widget build(BuildContext context) {
    // Watch auth to rebuild when role changes
    ref.watch(authProvider);
    final pages = _bodyPages;
    // Clamp nav index to valid range
    if (_selectedNavIndex >= pages.length) {
      _selectedNavIndex = 0;
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: backgroundWhite,
        body: SafeArea(
          child: IndexedStack(
            index: _selectedNavIndex,
            children: pages,
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildCarousel(),
                const SizedBox(height: 16),
                _buildBrandsSection(),
                const SizedBox(height: 24),
                _buildProductsSection('Popular Products', true),
                const SizedBox(height: 32),
                _buildProductsSection('Hot Deals', false),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchContent() {
    final popularCategories = ['🔥 Trending', 'Tractors', 'Harvesters', 'Irrigation', 'Seeds', 'Fertilizers'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explore',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.notifications_outlined, color: textPrimary, size: 22),
              ),
            ],
          ),
        ),
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                HugeIcon(icon: HugeIcons.strokeRoundedSearch02, color: primaryBlue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _searchDebounce?.cancel();
                      if (value.trim().isEmpty) {
                        setState(() { _searchResults = []; _isSearching = false; _searchQuery = ''; });
                        return;
                      }
                      setState(() => _searchQuery = value);
                      _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                        _searchProducts(value);
                      });
                    },
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Products, brands, equipment...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() { _searchResults = []; _isSearching = false; _searchQuery = ''; });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: borderLight, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: textSecondary),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedFilterHorizontal, color: textMuted, size: 22),
                  ),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator(color: primaryBlue))
              : _searchQuery.isNotEmpty
                  ? _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: textMuted),
                              const SizedBox(height: 16),
                              Text('No results found', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                              const SizedBox(height: 8),
                              Text('Try a different search term', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) => _buildSuggestionCard(_searchResults[index]),
                        )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recent Searches
                          if (_recentSearches.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Recent Searches', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
                                      GestureDetector(
                                        onTap: () => setState(() => _recentSearches.clear()),
                                        child: Text('CLEAR ALL', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: primaryBlue, letterSpacing: 0.5)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...List.generate(_recentSearches.length, (i) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40, height: 40,
                                          decoration: BoxDecoration(
                                            color: surfaceWhite,
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                                          ),
                                          child: Icon(Icons.history_rounded, color: textMuted, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              _searchController.text = _recentSearches[i];
                                              setState(() => _searchQuery = _recentSearches[i]);
                                              _searchProducts(_recentSearches[i]);
                                            },
                                            child: Text(_recentSearches[i], style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary)),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(() => _recentSearches.removeAt(i)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Icon(Icons.close_rounded, color: textMuted, size: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          // Popular Searches
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('Popular Searches', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 44,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: popularCategories.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                                    itemBuilder: (context, index) {
                                      final isFirst = index == 0;
                                      return GestureDetector(
                                        onTap: () {
                                          final term = popularCategories[index].replaceAll('🔥 ', '');
                                          _searchController.text = term;
                                          setState(() => _searchQuery = term);
                                          _searchProducts(term);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20),
                                          decoration: BoxDecoration(
                                            color: isFirst ? primaryBlue : surfaceWhite,
                                            borderRadius: BorderRadius.circular(100),
                                            border: Border.all(color: isFirst ? primaryBlue : borderLight),
                                            boxShadow: isFirst
                                                ? [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              popularCategories[index],
                                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: isFirst ? Colors.white : textPrimary),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Top Suggestions
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 32, 16, 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Top Suggestions', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
                                    Text('Based on your interest', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._products.take(5).map((product) => _buildSuggestionCard(product)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> product) {
    final heroTag = 'search-product-${product['id']}';
    final hasOriginalPrice = product['originalPrice'] != null &&
        product['originalPrice'] != product['price'] && product['originalPrice'] > 0;

    return GestureDetector(
      onTap: () => context.push('/product/${product['id']}', extra: {'heroTag': heroTag}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderLight.withOpacity(0.7)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Hero(
              tag: heroTag,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: product['image'] != null && product['image'].toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product['image'],
                          width: 100, height: 100, fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: const Color(0xFFF8F9FA)),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF8F9FA),
                            child: Center(child: Icon(Icons.image, color: textMuted)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF8F9FA),
                          child: Center(child: Icon(Icons.image, color: textMuted)),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['name'] ?? '',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product['rating'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 12, color: Color(0xFF15803D)),
                              const SizedBox(width: 2),
                              Text('${product['rating']}', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if ((product['brand'] ?? '').toString().isNotEmpty)
                    Text(product['brand'], style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('₹${_formatPrice(product['price'] ?? 0)}', style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                          if (hasOriginalPrice) ...[
                            const SizedBox(width: 6),
                            Text('₹${_formatPrice(product['originalPrice'])}', style: GoogleFonts.raleway(fontSize: 11, fontWeight: FontWeight.w400, color: textMuted, decoration: TextDecoration.lineThrough)),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text('View', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: primaryBlue)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    final cart = ref.watch(cartProvider);
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: backgroundWhite,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Cart',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: [
                  if (cart.itemCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: primaryBlue),
                      ),
                    ),
                  if (cart.items.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(cartProvider.notifier).clearCart(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: surfaceWhite,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderLight),
                        ),
                        child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedDelete02, color: textMuted, size: 18)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedShoppingCart01, color: primaryBlue.withOpacity(0.4), size: 48)),
                      ),
                      const SizedBox(height: 24),
                      Text('Your cart is empty', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
                      const SizedBox(height: 8),
                      Text('Discover products and add them here', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSecondary)),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () => setState(() => _selectedNavIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: primaryBlue.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Text('Browse Products', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Dismissible(
                      key: Key(item.productId),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => ref.read(cartProvider.notifier).removeItem(item.productId),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 24),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderLight.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: item.image != null && item.image!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: item.image!,
                                      width: 80, height: 80, fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(width: 80, height: 80, color: const Color(0xFFF1F5F9)),
                                      errorWidget: (_, __, ___) => Container(
                                        width: 80, height: 80, color: const Color(0xFFF1F5F9),
                                        child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: textMuted, size: 24)),
                                      ),
                                    )
                                  : Container(
                                      width: 80, height: 80, color: const Color(0xFFF1F5F9),
                                      child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: textMuted, size: 24)),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            // Product Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary, height: 1.2),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '₹${_formatPrice(item.price)}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: primaryBlue),
                                      ),
                                      if (item.mrp != null && item.mrp! > item.price) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '₹${_formatPrice(item.mrp!)}',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textMuted, decoration: TextDecoration.lineThrough),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Quantity Controls
                                  Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity - 1),
                                          child: Container(
                                            width: 32, height: 32,
                                            decoration: BoxDecoration(
                                              color: surfaceWhite,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: borderLight),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(Icons.remove, size: 16, color: item.quantity > 1 ? textPrimary : textMuted),
                                          ),
                                        ),
                                        Container(
                                          width: 36, alignment: Alignment.center,
                                          child: Text('${item.quantity}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                                        ),
                                        GestureDetector(
                                          onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity + 1),
                                          child: Container(
                                            width: 32, height: 32,
                                            decoration: BoxDecoration(
                                              color: primaryBlue,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.add, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Price Summary & Checkout
        if (cart.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSecondary)),
                            Text('₹${_formatPrice(cart.subtotal)}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Delivery', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSecondary)),
                            Text('₹${_formatPrice(cart.deliveryFee)}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: borderLight),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                            Text('₹${_formatPrice(cart.grandTotal)}', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: primaryBlue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Checkout Button
                  GestureDetector(
                    onTap: () => context.push('/payment/order-${DateTime.now().millisecondsSinceEpoch}'),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Proceed to Checkout', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  int _negotiationTab = 1; // 0=All, 1=Active, 2=Completed

  Widget _buildNegotiationsContent() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          color: backgroundWhite,
          child: Text(
            'Negotiations',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        // Tabs
        Container(
          color: backgroundWhite,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderLight, width: 1)),
            ),
            child: Row(
              children: [
                _buildNegotiationTab('All', 0),
                _buildNegotiationTab('Active', 1),
                _buildNegotiationTab('Completed', 2),
              ],
            ),
          ),
        ),
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Text(
                'Priority Quotes',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
              ),
            ],
          ),
        ),
        // Cards List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _buildNegotiationCard(
                requestId: 'REQ-8821',
                productName: 'Titan 5000 Harvester',
                bulkOrder: 'Bulk Order: 10 units',
                status: 'COUNTER-OFFER',
                statusColor: const Color(0xFFF59E0B),
                statusBg: const Color(0xFFFEF3C7),
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAaGgwMFJfelXOECcbEE0PcOWEJYZG_IeWUQBS3eYYeR8WGclPWdSaSr02PbM2TR18rwhnkGYJXivBh6KDC4s1uOmrpgiRDhh6z_n_S41GhE5FSy-TUXj6NpNohO60LbL3jrhLu5FwgWn51hhzM0DfENdXiue6d4kSXkE6nKm356hu9fj5KaYlwkmIaLRnv1y2nmjXJaXuF4mKUlaYBKe3beGqIjylC9XPYHyiSoZLiSM3lz5YnD9dFy4XOHyxnfFPC0wT9m1ktUPXj',
                priceRows: [
                  {'label': 'Your Quote:', 'value': '₹1,20,000', 'color': textPrimary},
                  {'label': 'Admin Price:', 'value': '₹1,25,000', 'color': primaryBlue},
                ],
                buttonLabel: 'View Details',
                buttonStyle: 'primary',
              ),
              _buildNegotiationCard(
                requestId: 'REQ-8790',
                productName: 'Industrial Mini Mill',
                bulkOrder: 'Bulk Order: 5 units',
                status: 'ACCEPTED',
                statusColor: const Color(0xFF16A34A),
                statusBg: const Color(0xFFDCFCE7),
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDeRnAVFtCPqADjT1xfxgQZUwnbDm7VXA9ZtB8Mx3smt-DQbKK30XiyblbS5DK0_BKbqx-oXRHyWv2Lup0rF6WlV8ArlL4OTx4vA9-kptmUcpYOQ7mq1ShcxTRW2p0JMw-kBheHInQujJ_LwAgIAh4WDhM9yIDHyLlquivu1NDI3Scj9aYrmL9LsMeKh49UKjV1yJmUsma6qz0NQF6IHWdr_eMyUgLNCMgfHBXskdsZfGu35NNpMmmO0eOu9hkoAX-jq80MrzIyYPB7',
                priceRows: [
                  {'label': 'Negotiated Total:', 'value': '₹45,000', 'color': const Color(0xFF16A34A)},
                ],
                showAccentBorder: true,
                buttonLabel: 'Pay Now',
                buttonStyle: 'primary',
                buttonIcon: Icons.account_balance_wallet_rounded,
              ),
              _buildNegotiationCard(
                requestId: 'REQ-8912',
                productName: 'Smart Irrigator Pro',
                bulkOrder: 'Bulk Order: 3 units',
                status: 'PENDING REVIEW',
                statusColor: const Color(0xFF6B7280),
                statusBg: const Color(0xFFF3F4F6),
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDoAi8Z9AYnnHnksg3wzDv3tFls2Idq7TqPmxGitX58sgdDcWHvml_6hb-XPe3HzyhtZRtureb4wn6zRlR-WL493UOLq22iu3vXYo-q499bvG5FGFjVhC-lYehP356yiSmrfid1DCuuIOnA_Y4emJZj5728OBUNr_sdelqFN9PCDJRcxBkGzbCmFhkCybh8txJT4hNO_eEWTrK4-IWmsMhTNyD-_hJRiyNako1lCGLbh86uokS2UzNYiUc5xX1yEnFJNNz2ty4t5sqo',
                pendingPrice: '₹88,000',
                pendingNote: 'Awaiting admin verification',
                buttonLabel: 'Under Review',
                buttonStyle: 'disabled',
                isOpaque: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNegotiationTab(String label, int index) {
    final isSelected = _negotiationTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _negotiationTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: isSelected ? primaryBlue : const Color(0xFF4C669A),
            ),
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
                      child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: textMuted, size: 40)),
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
                          'REQUEST #${requestId.replaceAll('REQ-', '')}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4C669A),
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
                        color: const Color(0xFF4C669A),
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
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF4C669A)),
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
                    // Pending Price (for pending review cards)
                    if (pendingPrice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Requested Price: ',
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF4C669A)),
                              ),
                              Text(
                                pendingPrice,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                              ),
                            ],
                          ),
                          if (pendingNote != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              pendingNote,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFF4C669A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 16),
                    // Action Button
                    GestureDetector(
                      onTap: buttonStyle == 'disabled' ? null : () {},
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

  Widget _buildProfileContent() {
    final settings = [
      {'icon': HugeIcons.strokeRoundedShoppingBag01, 'color': Colors.teal, 'title': 'My Orders', 'subtitle': null, 'onTap': () => context.push('/tracking/sample')},
      {'icon': HugeIcons.strokeRoundedFavourite, 'color': Colors.red, 'title': 'Wishlist', 'subtitle': null, 'onTap': () {}},
      {'icon': HugeIcons.strokeRoundedLocation01, 'color': Colors.green, 'title': 'Addresses', 'subtitle': null, 'onTap': () {}},
      {'icon': HugeIcons.strokeRoundedCreditCard, 'color': Colors.blue, 'title': 'Payment Methods', 'subtitle': null, 'onTap': () {}},
      {'icon': HugeIcons.strokeRoundedNotification02, 'color': Colors.purple, 'title': 'Notifications', 'subtitle': null, 'onTap': () {}},
      {'icon': HugeIcons.strokeRoundedHelpCircle, 'color': Colors.orange, 'title': 'Help & Support', 'subtitle': null, 'onTap': () => context.push('/help')},
      {'icon': HugeIcons.strokeRoundedInformationCircle, 'color': Colors.indigo, 'title': 'About', 'subtitle': null, 'onTap': () {}},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Text(
              'Account Settings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // Settings Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderLight.withOpacity(0.7)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: List.generate(settings.length, (index) {
                  final setting = settings[index];
                  return _buildSettingItem(
                    icon: setting['icon'] as IconData,
                    iconColor: setting['color'] as Color,
                    title: setting['title'] as String,
                    subtitle: setting['subtitle'] as String?,
                    showDivider: index < settings.length - 1,
                    onTap: setting['onTap'] as VoidCallback,
                  );
                }),
              ),
            ),
          ),
          // Log Out
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            child: GestureDetector(
              onTap: () => context.go('/login'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedLogout02, color: Colors.red.shade500, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Log Out',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: borderLight.withOpacity(0.5), width: 1))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(icon: icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted)),
                  ],
                ],
              ),
            ),
            HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: backgroundWhite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedPlant03, color: primaryBlue, size: 28),
              const SizedBox(width: 4),
              Text(
                'AgriMarket',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          // Actions
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedNavIndex = 1),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: surfaceWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: textPrimary, size: 20)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedNotification02, color: textPrimary, size: 20)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _carouselItems.length,
            onPageChanged: (index) {
              setState(() => _currentCarouselIndex = index);
            },
            itemBuilder: (context, index) {
              final item = _carouselItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryBlue,
                        primaryBlueDark,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background Pattern
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Opacity(
                          opacity: 0.1,
                          child: Icon(
                            Icons.agriculture,
                            size: 150,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item['tag']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Title
                            Text(
                              item['title']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // Subtitle
                            Text(
                              item['subtitle']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Carousel Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _carouselItems.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentCarouselIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentCarouselIndex == index 
                    ? primaryBlue 
                    : primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Top Brands',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          height: 90,
          child: _isLoadingBrands
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: borderLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(width: 40, height: 12, color: borderLight),
                      ],
                    ),
                  ),
                )
              : _brands.isEmpty
                  ? Center(
                      child: Text('No brands available', style: GoogleFonts.plusJakartaSans(color: textMuted)),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _brands.length,
                      itemBuilder: (context, index) {
                        final brand = _brands[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: surfaceWhite,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: borderLight, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: brand['logo'] != null && brand['logo'].toString().isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: brand['logo'],
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Center(
                                            child: HugeIcon(
                                              icon: HugeIcons.strokeRoundedBuilding03,
                                              color: primaryBlue,
                                              size: 24,
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) => Center(
                                            child: HugeIcon(
                                              icon: HugeIcons.strokeRoundedBuilding03,
                                              color: primaryBlue,
                                              size: 24,
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: HugeIcon(
                                            icon: HugeIcons.strokeRoundedBuilding03,
                                            color: primaryBlue,
                                            size: 24,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                brand['name'] ?? '',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProductsSection(String title, bool isFeatured) {
    final filteredProducts = isFeatured 
        ? _products 
        : _products.where((p) => p['isHot'] == true).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'View all',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Products Grid - 2 columns
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _isLoadingProducts
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      color: borderLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : filteredProducts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('No products available', style: GoogleFonts.plusJakartaSans(color: textMuted)),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return _buildProductCard(product);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final heroTag = 'product-image-${product['id']}';
    final hasOriginalPrice = product['originalPrice'] != null &&
        product['originalPrice'] != product['price'] &&
        (product['originalPrice'] as num?) != null &&
        (product['originalPrice'] as num) > 0;
    final discount = hasOriginalPrice
        ? (((product['originalPrice'] as num) - (product['price'] as num)) / (product['originalPrice'] as num) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => context.push(
        '/product/${product['id']}',
        extra: {'heroTag': heroTag},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF1F5F9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: heroTag,
                      child: product['image'] != null && product['image'].toString().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product['image'],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue))),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: textMuted, size: 32)),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFF1F5F9),
                              child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: textMuted, size: 32)),
                            ),
                    ),
                    // Favorite Button (top right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.favorite_border_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    // Badges (top left)
                    if (product['isHot'] == true || discount > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Row(children: [
                          if (product['isHot'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                              child: Text('HOT', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                            ),
                          if (product['isHot'] == true && discount > 0) const SizedBox(width: 4),
                          if (discount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF16A34A).withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                              child: Text('$discount% OFF', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
                            ),
                        ]),
                      ),
                    // Out of stock overlay
                    if (product['inStock'] == false)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                            child: Text('Out of Stock', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Product Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product['name'] ?? '',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary, height: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product['rating'] != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${product['rating']}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 2),
                            const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                // Brand
                Text(
                  (product['brand'] ?? '').toString().isNotEmpty ? product['brand'] : (product['category'] ?? ''),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Price
                Row(
                  children: [
                    Text(
                      '₹${_formatPrice(product['price'] ?? 0)}',
                      style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    if (hasOriginalPrice) ...[
                      const SizedBox(width: 5),
                      Text(
                        '₹${_formatPrice(product['originalPrice'])}',
                        style: GoogleFonts.raleway(fontSize: 11, fontWeight: FontWeight.w400, color: textMuted, decoration: TextDecoration.lineThrough),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final val = (price is int) ? price.toDouble() : (price as num).toDouble();
    if (val >= 100000) {
      return '${(val / 100000).toStringAsFixed(val % 100000 == 0 ? 0 : 1)}L';
    }
    if (val >= 1000) {
      final formatted = val.toStringAsFixed(0);
      final result = StringBuffer();
      int count = 0;
      for (int i = formatted.length - 1; i >= 0; i--) {
        if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
          result.write(',');
        }
        result.write(formatted[i]);
        count++;
      }
      return result.toString().split('').reversed.join('');
    }
    return val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2);
  }

  Widget _buildBottomNav() {
    final showNegotiate = _isWholesaler;
    return Container(
      decoration: BoxDecoration(
        color: surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _buildNavItem(HugeIcons.strokeRoundedHome01, 'Home', 0),
              _buildNavItem(HugeIcons.strokeRoundedSearch01, 'Search', 1),
              _buildCartNavItem(2),
              if (showNegotiate)
                _buildNavItem(HugeIcons.strokeRoundedHandGrip, 'Negotiate', 3),
              _buildNavItem(HugeIcons.strokeRoundedUser, 'Profile', _profileIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartNavItem(int index) {
    final isSelected = _selectedNavIndex == index;
    final cart = ref.watch(cartProvider);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedNavIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedShoppingCart01,
                      color: isSelected ? primaryBlue : textMuted,
                      size: 24,
                    ),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '${cart.itemCount}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? primaryBlue : textMuted,
                ),
                child: const Text('Cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedNavIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: HugeIcon(
                  icon: icon,
                  color: isSelected ? primaryBlue : textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? primaryBlue : textMuted,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
