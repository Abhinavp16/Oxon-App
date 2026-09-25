import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/api_config.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/category_catalog_service.dart';
import '../../widgets/app_image.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSearchTap;
  final String? initialCategoryName;

  const CategoriesScreen({
    super.key,
    this.onSearchTap,
    this.initialCategoryName,
  });

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  static const _primaryBlue = Color(0xFF1E40AF);
  static const _background = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final items = await fetchAllCategoryPages((page, limit) async {
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
      final categories = items
          .whereType<Map>()
          .map(_mapCategory)
          .where(
            (category) =>
                category['slug'].toString().isNotEmpty &&
                (category['count'] as int) > 0,
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load categories. Pull down to try again.';
      });
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
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Categories',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed:
                        widget.onSearchTap ??
                        () => context.go('/home', extra: {'tab': 1}),
                    icon: const Icon(Icons.search_rounded, color: _primaryBlue),
                    tooltip: 'Search products',
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryBlue),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        color: _primaryBlue,
        onRefresh: _loadCategories,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 180),
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

    if (_categories.isEmpty) {
      return RefreshIndicator(
        color: _primaryBlue,
        onRefresh: _loadCategories,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 180),
            const Icon(Icons.category_outlined, size: 48, color: _textMuted),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No categories with active products are available.',
                style: GoogleFonts.plusJakartaSans(color: _textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadCategories,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.86,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) => _buildCategoryCard(_categories[index]),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final name = category['name'].toString();
    final secondaryName = category['nameHindi'].toString();
    final slug = category['slug'].toString();
    final count = category['count'] as int;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/categories/${Uri.encodeComponent(slug)}'),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: const Color(0xFFF1F5F9),
                  child: category['image'].toString().isEmpty
                      ? Icon(_categoryIcon(name), size: 42, color: _primaryBlue)
                      : AppImage(
                          imageUrl: category['image'].toString(),
                          blurHash: category['blurHash'].toString(),
                          category: name,
                          name: name,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    if (secondaryName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondaryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: _textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '$count ${count == 1 ? 'product' : 'products'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _primaryBlue,
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
}
