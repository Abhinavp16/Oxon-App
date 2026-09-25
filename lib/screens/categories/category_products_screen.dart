import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/api_config.dart';
import '../../core/models/catalog_data.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/category_catalog_service.dart';
import '../../widgets/app_image.dart';
import '../../widgets/product_image_placeholder.dart';

class CategoryProductsScreen extends ConsumerStatefulWidget {
  final String slug;

  const CategoryProductsScreen({super.key, required this.slug});

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends ConsumerState<CategoryProductsScreen> {
  static const _primaryBlue = Color(0xFF1E40AF);
  static const _background = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _category;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasNext = false;
  String? _error;
  int _totalProducts = 0;
  int _page = 1;
  int _requestGeneration = 0;

  String get _slug => widget.slug.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void didUpdateWidget(covariant CategoryProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 360) {
      return;
    }
    _loadMore();
  }

  Future<void> _loadInitial() async {
    final generation = ++_requestGeneration;
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _error = null;
      _products = [];
      _hasNext = false;
      _totalProducts = 0;
      _page = 1;
      _category = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final categoryPages = fetchAllCategoryPages((page, limit) async {
        final response = await api.get(
          '/categories',
          queryParameters: {
            'active': true,
            'parent': 'root',
            'page': page,
            'limit': limit,
          },
        );
        return response.data as Map;
      });
      final responses = await Future.wait([
        api.get('/categories/slug/${Uri.encodeComponent(_slug)}'),
        api.get(
          '/products',
          queryParameters: {
            'categorySlug': _slug,
            'page': 1,
            'limit': _pageSize,
          },
        ),
      ]);
      final category = _mapCategory(
        Map<String, dynamic>.from(responses[0].data['data'] as Map),
      );
      final categories = (await categoryPages)
          .map(_mapCategory)
          .where(
            (item) =>
                item['slug'].toString().isNotEmpty &&
                (item['count'] as int) > 0,
          )
          .toList();
      if (!mounted || generation != _requestGeneration) return;
      final productResponse = responses[1].data as Map;
      final productItems = catalogItems(productResponse);
      final products = productItems.whereType<Map>().map(_mapProduct).toList();
      final pagination = CatalogPageInfo.fromPayload(
        productResponse,
        requestedPage: 1,
        requestedLimit: _pageSize,
        itemCount: productItems.length,
      );

      setState(() {
        _category = category;
        _categories = categories;
        _products = dedupeProducts(const [], products);
        _page = pagination.page;
        _hasNext = pagination.hasNext;
        _totalProducts = pagination.total > 0
            ? pagination.total
            : _asInt(category['count']);
        _isInitialLoading = false;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _isInitialLoading = false;
        _error = 'Unable to load this category. Pull down to try again.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isInitialLoading || _isLoadingMore || !_hasNext || _error != null) {
      return;
    }

    final generation = _requestGeneration;
    final nextPage = _page + 1;
    setState(() => _isLoadingMore = true);

    try {
      final response = await ref
          .read(apiClientProvider)
          .get(
            '/products',
            queryParameters: {
              'categorySlug': _slug,
              'page': nextPage,
              'limit': _pageSize,
            },
          );
      if (!mounted || generation != _requestGeneration) return;

      final payload = response.data as Map;
      final productItems = catalogItems(payload);
      final incoming = productItems.whereType<Map>().map(_mapProduct).toList();
      final pagination = CatalogPageInfo.fromPayload(
        payload,
        requestedPage: nextPage,
        requestedLimit: _pageSize,
        itemCount: productItems.length,
        loadedCount: _products.length,
      );
      setState(() {
        _products = dedupeProducts(_products, incoming);
        _page = pagination.page;
        _hasNext = pagination.hasNext;
        if (pagination.total > 0) _totalProducts = pagination.total;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Map<String, dynamic> _mapCategory(Map item) {
    final image = item['image'];
    final rawImage = image is Map ? image['url'] : image;
    return {
      'name': item['name']?.toString() ?? '',
      'nameHindi': item['nameHindi']?.toString() ?? '',
      'slug': item['slug']?.toString() ?? '',
      'image': _resolveImageUrl(rawImage?.toString() ?? ''),
      'blurHash': image is Map ? image['blurHash']?.toString() ?? '' : '',
      'count': _asInt(
        item['productCount'] ??
            item['recursiveProductCount'] ??
            item['activeRecursiveProductCount'] ??
            item['count'],
      ),
    };
  }

  Map<String, dynamic> _mapProduct(Map item) {
    final categoryData = ProductCategoryData.fromProduct(item);
    return {
      'id': item['id']?.toString() ?? item['_id']?.toString() ?? '',
      'name': item['name']?.toString() ?? '',
      'nameHindi': item['nameHindi']?.toString() ?? '',
      'category': categoryData.displayName,
      'categorySlug': categoryData.displaySlug,
      'categories': categoryData.categories
          .map((value) => value.toJson())
          .toList(),
      'primaryCategory': categoryData.primary?.toJson(),
      'categoryIds': item['categoryIds'],
      'primaryCategoryId': item['primaryCategoryId'],
      'price': item['price'] ?? item['retailPrice'] ?? 0,
      'mrp': item['mrp'] ?? 0,
      'image': _resolveImageUrl(item['primaryImage']?.toString() ?? ''),
      'blurHash': item['primaryBlurHash']?.toString() ?? '',
      'inStock': item['inStock'] != false,
      'rating': item['rating'],
    };
  }

  int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  String _resolveImageUrl(String value) {
    final url = value.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) {
      return '${ApiConfig.baseUrl.replaceFirst('/api/v1', '')}$url';
    }
    return '';
  }

  String _displayCategoryName(Map<String, dynamic> category) {
    final hindiName = category['nameHindi'].toString();
    return ref.watch(localeProvider) == 'Hindi' && hindiName.isNotEmpty
        ? hindiName
        : category['name'].toString();
  }

  String _displayProductName(Map<String, dynamic> product) {
    final hindiName = product['nameHindi'].toString();
    return ref.watch(localeProvider) == 'Hindi' && hindiName.isNotEmpty
        ? hindiName
        : product['name'].toString();
  }

  String _formatPrice(dynamic value) {
    final price = value is num
        ? value
        : num.tryParse(value?.toString() ?? '') ?? 0;
    return price.toStringAsFixed(0);
  }

  IconData _categoryIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('tractor') || value.contains('harvest')) {
      return Icons.agriculture_rounded;
    }
    if (value.contains('irrigat') || value.contains('pump')) {
      return Icons.water_drop_rounded;
    }
    if (value.contains('seed') || value.contains('plant')) {
      return Icons.eco_rounded;
    }
    if (value.contains('fertil') || value.contains('chemic')) {
      return Icons.science_rounded;
    }
    if (value.contains('tool') || value.contains('equip')) {
      return Icons.build_rounded;
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = _category == null
        ? 'Category'
        : _displayCategoryName(_category!);
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(categoryName),
            if (_categories.isNotEmpty) _buildCategorySelector(),
            Expanded(child: _buildProductContent(categoryName)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String categoryName) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 10, 16, 8),
    child: Row(
      children: [
        IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, color: _textPrimary),
          tooltip: 'Back',
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            categoryName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildCategorySelector() => SizedBox(
    height: 108,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: _categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final selected = category['slug'] == _slug;
        final name = category['name'].toString();
        return Material(
          color: selected ? _primaryBlue.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: selected
                ? null
                : () => context.go(
                    '/categories/${Uri.encodeComponent(category['slug'].toString())}',
                  ),
            child: Container(
              width: 86,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? _primaryBlue : _border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: category['image'].toString().isEmpty
                        ? Icon(_categoryIcon(name), color: _primaryBlue)
                        : AppImage(
                            imageUrl: category['image'].toString(),
                            blurHash: category['blurHash'].toString(),
                            category: name,
                            name: name,
                            fit: BoxFit.contain,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _displayCategoryName(category),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? _primaryBlue : _textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _buildProductContent(String categoryName) {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryBlue),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        color: _primaryBlue,
        onRefresh: _loadInitial,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 160),
            const Icon(Icons.cloud_off_rounded, size: 48, color: _textMuted),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: _textMuted),
              ),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return RefreshIndicator(
        color: _primaryBlue,
        onRefresh: _loadInitial,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.inventory_2_outlined, size: 48, color: _textMuted),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No active products are available in $categoryName.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: _textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadInitial,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$categoryName products',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$_totalProducts items',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductCard(_products[index]),
                childCount: _products.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.57,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: _isLoadingMore
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: _primaryBlue,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : !_hasNext
                  ? Center(
                      child: Text(
                        'You have reached all $_totalProducts products.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _textMuted,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final price = product['price'];
    final mrp = product['mrp'];
    final hasMrp = mrp is num && price is num && mrp > price && mrp > 0;
    final rating = product['rating'];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product['id']}'),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product['image'].toString().isEmpty
                        ? ProductImagePlaceholder(
                            category: product['category'].toString(),
                            name: product['name'].toString(),
                          )
                        : AppImage(
                            imageUrl: product['image'].toString(),
                            blurHash: product['blurHash'].toString(),
                            category: product['category'].toString(),
                            name: product['name'].toString(),
                            fit: BoxFit.contain,
                          ),
                    if (product['inStock'] == false)
                      Container(
                        color: Colors.white.withValues(alpha: 0.72),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Out of stock',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 36,
                      child: Text(
                        _displayProductName(product),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (rating != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '₹${_formatPrice(price)}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _textPrimary,
                          ),
                        ),
                        if (hasMrp) ...[
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '₹${_formatPrice(mrp)}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: const Color(0xFFEF4444),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ],
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
}
