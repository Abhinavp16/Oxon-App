import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../core/config/api_config.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color backgroundWhite = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = false;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _dio.get('/categories');
      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['data'] ?? [];
        final cats = items.map<Map<String, dynamic>>((item) => <String, dynamic>{
          'id': item['_id']?.toString() ?? item['id']?.toString() ?? '',
          'name': item['name']?.toString() ?? '',
          'image': item['image']?.toString() ?? '',
          'count': item['productCount'] ?? item['count'] ?? 0,
        }).where((c) => (c['name'] as String).isNotEmpty).toList();

        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
        });

        if (cats.isNotEmpty) {
          _fetchProductsForCategory(cats[0]['name']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchProductsForCategory(String categoryName) async {
    setState(() => _isLoadingProducts = true);
    try {
      final response = await _dio.get('/products', queryParameters: {
        'category': categoryName,
      });
      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['data'] ?? [];
        setState(() {
          _products = items.map<Map<String, dynamic>>((item) => <String, dynamic>{
            'id': item['id']?.toString() ?? item['_id']?.toString() ?? '',
            'name': item['name']?.toString() ?? '',
            'price': item['price'] ?? item['retailPrice'] ?? 0,
            'mrp': item['mrp'] ?? 0,
            'image': item['primaryImage']?.toString() ?? '',
            'inStock': item['inStock'] != false,
            'shortDescription': item['shortDescription']?.toString() ?? '',
          }).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      setState(() => _isLoadingProducts = false);
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final num p = price is num ? price : num.tryParse(price.toString()) ?? 0;
    return NumberFormat('#,##,###').format(p);
  }

  IconData _categoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tractor')) return Icons.agriculture_rounded;
    if (lower.contains('harvest')) return Icons.grass_rounded;
    if (lower.contains('irrigat') || lower.contains('pump')) return Icons.water_drop_rounded;
    if (lower.contains('seed') || lower.contains('plant')) return Icons.eco_rounded;
    if (lower.contains('fertil') || lower.contains('chemic')) return Icons.science_rounded;
    if (lower.contains('tool') || lower.contains('equip')) return Icons.build_rounded;
    if (lower.contains('spray')) return Icons.shower_rounded;
    if (lower.contains('storage') || lower.contains('silo')) return Icons.warehouse_rounded;
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: backgroundWhite,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Text('Categories', style: GoogleFonts.plusJakartaSans(
                      fontSize: 24, fontWeight: FontWeight.w800,
                      color: textPrimary, letterSpacing: -0.3)),
                    const Spacer(),
                    if (_categories.isNotEmpty)
                      Text('${_categories.length} categories',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: textMuted)),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: _isLoadingCategories
                    ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                    : _categories.isEmpty
                        ? Center(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.category_outlined, size: 48, color: textMuted.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text('No categories found',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16, fontWeight: FontWeight.w600, color: textMuted)),
                            ]))
                        : Row(
                            children: [
                              // Left sidebar
                              _buildSidebar(),
                              // Vertical divider
                              Container(width: 1, color: borderLight),
                              // Right product grid
                              Expanded(child: _buildProductGrid()),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 88,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategoryIndex = index);
              _fetchProductsForCategory(cat['name']);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? primaryBlue.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border(left: BorderSide(color: primaryBlue, width: 3))
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryBlue.withOpacity(0.12)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14)),
                    child: Icon(
                      _categoryIcon(cat['name'] ?? ''),
                      size: 22,
                      color: isSelected ? primaryBlue : textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['name'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? primaryBlue : textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2));
    }

    if (_products.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: textMuted.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No products in this category',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textMuted)),
        ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(child: Text(
              _categories[_selectedCategoryIndex]['name'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(100)),
              child: Text('${_products.length} items',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w600, color: primaryBlue))),
          ]),
        ),
        // Products
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.68,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) => _buildProductCard(_products[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final hasMrp = product['mrp'] != null &&
        product['mrp'] != product['price'] &&
        (product['mrp'] as num) > 0;
    final discount = hasMrp
        ? (((product['mrp'] as num) - (product['price'] as num)) / (product['mrp'] as num) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => context.push('/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderLight.withOpacity(0.7)),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product['image'] != null && product['image'].toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product['image'],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: const Color(0xFFF1F5F9)),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Center(child: Icon(Icons.image, color: textMuted))))
                        : Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(child: Icon(Icons.image, color: textMuted))),
                    if (discount > 0)
                      Positioned(top: 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6)),
                          child: Text('$discount% OFF',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)))),
                    if (product['inStock'] == false)
                      Positioned.fill(child: Container(
                        color: Colors.white.withOpacity(0.7),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6)),
                          child: Text('Out of Stock',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white))))),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: textPrimary, height: 1.2),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(children: [
                      Text('₹${_formatPrice(product['price'])}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                      if (hasMrp) ...[
                        const SizedBox(width: 4),
                        Text('₹${_formatPrice(product['mrp'])}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10, color: textMuted,
                            decoration: TextDecoration.lineThrough)),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
