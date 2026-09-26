import 'package:flutter/material.dart';

import 'category_products_screen.dart';

class CategoriesScreen extends StatelessWidget {
  final VoidCallback? onSearchTap;
  final String? initialCategoryName;

  const CategoriesScreen({
    super.key,
    this.onSearchTap,
    this.initialCategoryName,
  });

  @override
  Widget build(BuildContext context) => CategoryProductsScreen(
    embedded: true,
    onSearchTap: onSearchTap,
    initialCategoryName: initialCategoryName,
  );
}
