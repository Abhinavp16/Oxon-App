import '../models/catalog_data.dart';

typedef CategoryPageRequest =
    Future<Map<dynamic, dynamic>> Function(int page, int limit);

Future<List<Map<dynamic, dynamic>>> fetchAllCategoryPages(
  CategoryPageRequest request, {
  int limit = 50,
}) async {
  final categories = <Map<dynamic, dynamic>>[];
  final keys = <String>{};
  var page = 1;

  while (page <= 100) {
    final payload = await request(page, limit);
    final items = catalogItems(payload).whereType<Map>().toList();
    final loadedCount = categories.length;
    for (final item in items) {
      final key = (item['_id'] ?? item['id'] ?? item['slug'])?.toString() ?? '';
      if (key.isEmpty || keys.add(key)) categories.add(item);
    }

    final pagination = CatalogPageInfo.fromPayload(
      payload,
      requestedPage: page,
      requestedLimit: limit,
      itemCount: items.length,
      loadedCount: loadedCount,
    );
    if (!pagination.hasNext || items.isEmpty) break;
    page = pagination.page + 1;
  }
  return categories;
}
