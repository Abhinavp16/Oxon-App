import 'package:flutter_test/flutter_test.dart';
import 'package:veepee_impex/core/models/catalog_data.dart';
import 'package:veepee_impex/core/config/public_product_link.dart';
import 'package:veepee_impex/core/services/category_catalog_service.dart';

void main() {
  test('parses new product categories and keeps a scalar display category', () {
    final parsed = ProductCategoryData.fromProduct({
      'category': 'Legacy',
      'categorySlug': 'legacy',
      'categories': [
        {'_id': '1', 'name': 'Tools', 'slug': 'tools'},
        {'_id': '2', 'name': 'Farm', 'slug': 'farm'},
      ],
      'primaryCategory': {'_id': '2', 'name': 'Farm', 'slug': 'farm'},
    });

    expect(parsed.categories, hasLength(2));
    expect(parsed.primary?.id, '2');
    expect(parsed.displayName, 'Farm');
    expect(parsed.displaySlug, 'farm');
  });

  test('falls back to legacy category fields', () {
    final parsed = ProductCategoryData.fromProduct({
      'category': 'Legacy',
      'categorySlug': 'legacy',
    });

    expect(parsed.categories, isEmpty);
    expect(parsed.displayName, 'Legacy');
    expect(parsed.displaySlug, 'legacy');
  });

  test('infers pagination from all supported metadata', () {
    expect(
      CatalogPageInfo.fromPayload(
        {
          'pagination': {'page': 1, 'limit': 20, 'totalPages': 2},
        },
        requestedPage: 1,
        requestedLimit: 20,
        itemCount: 20,
      ).hasNext,
      isTrue,
    );
    expect(
      CatalogPageInfo.fromPayload(
        {
          'pagination': {'page': 2, 'limit': 20, 'hasNext': false},
        },
        requestedPage: 2,
        requestedLimit: 20,
        itemCount: 3,
      ).hasNext,
      isFalse,
    );
  });

  test('deduplicates products by either id field', () {
    final products = dedupeProducts(
      [
        {'id': 'a'},
      ],
      [
        {'_id': 'a'},
        {'id': 'b'},
      ],
    );
    expect(products.map((item) => item['id'] ?? item['_id']), ['a', 'b']);
  });

  test('public links always use the canonical product route', () {
    expect(
      PublicProductLink.build(
        productId: '123',
        productSlug: 'seed-drill',
        categorySlug: 'equipment',
      ),
      'https://veepee-impex.vercel.app/products/seed-drill',
    );
    expect(
      PublicProductLink.build(productId: '123'),
      'https://veepee-impex.vercel.app/products/123',
    );
  });

  test('category loader retrieves every page in backend order', () async {
    final requestedPages = <int>[];
    final categories = await fetchAllCategoryPages((page, limit) async {
      requestedPages.add(page);
      return {
        'data': [
          {'_id': '$page', 'name': 'Category $page'},
        ],
        'pagination': {
          'page': page,
          'limit': limit,
          'totalPages': 3,
          'hasNext': page < 3,
        },
      };
    });

    expect(requestedPages, [1, 2, 3]);
    expect(categories.map((item) => item['name']), [
      'Category 1',
      'Category 2',
      'Category 3',
    ]);
  });
}
