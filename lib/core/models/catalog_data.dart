class ProductCategoryRef {
  final String id;
  final String name;
  final String slug;

  const ProductCategoryRef({this.id = '', this.name = '', this.slug = ''});

  factory ProductCategoryRef.fromJson(Map<dynamic, dynamic> json) =>
      ProductCategoryRef(
        id: (json['_id'] ?? json['id'])?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
      );

  Map<String, String> toJson() => {'_id': id, 'name': name, 'slug': slug};
}

class ProductCategoryData {
  final List<ProductCategoryRef> categories;
  final ProductCategoryRef? primary;
  final String displayName;
  final String displaySlug;

  const ProductCategoryData({
    required this.categories,
    required this.primary,
    required this.displayName,
    required this.displaySlug,
  });

  factory ProductCategoryData.fromProduct(Map<dynamic, dynamic> product) {
    final categories = <ProductCategoryRef>[];
    final rawCategories = product['categories'];
    if (rawCategories is List) {
      for (final value in rawCategories.whereType<Map>()) {
        final category = ProductCategoryRef.fromJson(value);
        if (category.id.isNotEmpty ||
            category.name.isNotEmpty ||
            category.slug.isNotEmpty) {
          categories.add(category);
        }
      }
    }

    ProductCategoryRef? primary;
    final rawPrimary = product['primaryCategory'];
    if (rawPrimary is Map) {
      primary = ProductCategoryRef.fromJson(rawPrimary);
    } else if (rawPrimary != null && rawPrimary.toString().trim().isNotEmpty) {
      primary = ProductCategoryRef(name: rawPrimary.toString());
    }
    final primaryCategoryId = product['primaryCategoryId']?.toString() ?? '';
    if (primary == null && primaryCategoryId.isNotEmpty) {
      for (final category in categories) {
        if (category.id == primaryCategoryId) {
          primary = category;
          break;
        }
      }
    }

    final legacyCategory = product['category'];
    final legacy = legacyCategory is Map
        ? ProductCategoryRef.fromJson(legacyCategory)
        : ProductCategoryRef(
            name: (legacyCategory ?? product['categoryName'])?.toString() ?? '',
            slug: product['categorySlug']?.toString() ?? '',
          );
    final fallback =
        primary ?? (categories.isNotEmpty ? categories.first : legacy);

    return ProductCategoryData(
      categories: categories,
      primary: primary,
      displayName: fallback.name.isNotEmpty ? fallback.name : legacy.name,
      displaySlug: fallback.slug.isNotEmpty ? fallback.slug : legacy.slug,
    );
  }
}

class CatalogPageInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;

  const CatalogPageInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
  });

  factory CatalogPageInfo.fromPayload(
    Map<dynamic, dynamic> payload, {
    required int requestedPage,
    required int requestedLimit,
    required int itemCount,
    int loadedCount = 0,
  }) {
    final data = payload['data'];
    final metadata = payload['pagination'] is Map
        ? payload['pagination'] as Map
        : data is Map && data['pagination'] is Map
        ? data['pagination'] as Map
        : payload['meta'] is Map
        ? payload['meta'] as Map
        : payload;
    final page = _asInt(
      metadata['page'] ?? metadata['currentPage'],
      requestedPage,
    );
    final limit = _asInt(
      metadata['limit'] ?? metadata['pageSize'],
      requestedLimit,
    );
    final total = _asInt(
      metadata['total'] ?? metadata['totalItems'] ?? metadata['count'],
      0,
    );
    final totalPages = _asInt(metadata['totalPages'] ?? metadata['pages'], 0);
    final explicitHasNext = metadata['hasNext'];
    final hasNext =
        explicitHasNext == true ||
        (totalPages > 0 && page < totalPages) ||
        (total > 0 && loadedCount + itemCount < total) ||
        (explicitHasNext == null &&
            totalPages == 0 &&
            total == 0 &&
            itemCount >= limit);

    return CatalogPageInfo(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: hasNext,
    );
  }

  static int _asInt(dynamic value, int fallback) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<dynamic> catalogItems(Map<dynamic, dynamic> payload) {
  final data = payload['data'];
  if (data is List) return data;
  if (data is Map) {
    final nested = data['products'] ?? data['items'] ?? data['results'];
    if (nested is List) return nested;
  }
  final rootItems =
      payload['products'] ?? payload['items'] ?? payload['results'];
  return rootItems is List ? rootItems : const [];
}

List<Map<String, dynamic>> dedupeProducts(
  Iterable<Map<String, dynamic>> existing,
  Iterable<Map<String, dynamic>> incoming,
) {
  final result = <Map<String, dynamic>>[];
  final ids = <String>{};
  for (final product in [...existing, ...incoming]) {
    final id = (product['id'] ?? product['_id'])?.toString() ?? '';
    if (id.isEmpty || ids.add(id)) result.add(product);
  }
  return result;
}
