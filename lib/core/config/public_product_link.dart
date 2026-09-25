class PublicProductLink {
  const PublicProductLink._();

  /// Override for each deployed public Veepee website, for example:
  /// --dart-define=VEEPEE_PUBLIC_WEB_BASE_URL=https://shop.example.com
  static const String _baseUrl = String.fromEnvironment(
    'VEEPEE_PUBLIC_WEB_BASE_URL',
    defaultValue: 'https://veepee-impex.vercel.app',
  );

  static String build({
    required String productId,
    String? productSlug,
    String? categorySlug,
  }) {
    final baseUri = Uri.parse(_baseUrl);
    final baseSegments = baseUri.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    final normalizedProductSlug = productSlug?.trim() ?? '';
    final pathSegments = [
      ...baseSegments,
      'products',
      normalizedProductSlug.isNotEmpty ? normalizedProductSlug : productId,
    ];

    return baseUri.replace(pathSegments: pathSegments).toString();
  }
}
