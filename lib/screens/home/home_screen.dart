import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildDealsTab(),
          _buildStockTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: Border(top: BorderSide(color: AppColors.gray200)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, Icons.dashboard, 'Home'),
                _buildNavItem(1, Icons.handshake, 'Deals'),
                _buildNavItem(2, Icons.inventory_2, 'Stock'),
                _buildNavItem(3, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.gray400,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.agriculture, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'AgriMart',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: () => context.push('/cart'),
                  icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Categories
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('All', true),
                      _buildCategoryChip('Tillers', false),
                      _buildCategoryChip('Harvesters', false),
                      _buildCategoryChip('Pumps', false),
                      _buildCategoryChip('Sprayers', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Featured Product
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => context.push('/product/1'),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBY-zk5FiEndc_-knQOpJocZAcvworTwYA780fuc7IJUA41Tcv-jBY3JDWZOAHHWSOR22RTLhbR9zQ-kMmlfosyue4-qz6j5fPnqD-pJLIS2uFn6uSJYjj1nxwryCChmZxVR5TK_6ip-uMgHpCZ3lBhpQ6BkTjyT44jR-Cz06YNAfg43J47CenHeLrjBWFghK65SJx_sRhlfOcHFhMK4mjg3LMI5PKtpJ7zMHiDBKa1bUjTMreaFq1aXO48ToJqwRp-2UEolzahNwA_',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.gray100),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.gray100,
                            child: const Icon(Icons.image, color: AppColors.gray400),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TOP RATED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.info,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'WHOLESALE ONLY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Multi-Crop Power Tiller',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Wholesale Price: Negotiable',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Minimum Order Quantity: 5 Units',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Products Grid Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Equipment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
        ),

        // Products Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildProductCard(index),
              childCount: 4,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (value) {},
      ),
    );
  }

  Widget _buildProductCard(int index) {
    final products = [
      {'name': 'Garden Power Tiller', 'price': '\$850', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBC7pHzkPGNTDXhKz1oluYbkGKwXyrhgE2TAO7nJyuqiFypYcdXYcAzAJLzcncH72zl2Je1BIz4T1liY264MoCHkv6lVr54vvBSsMSy0GerGOIqySQter5QIfBIlrTwSKrNz0NA0lH9CE2YFpBYmH71skYGJHWasP6hU7qKG0sRDphLYq-cUNsA3ZPV3U2cN9f1T1WvICx-ystdu2C8znBc2quyeYnIKkxeXikN1wqZObDCpquv_3jOzoXHfJN4NNRtx389y_W-YE2Q'},
      {'name': 'Solar Water Pump', 'price': '\$450', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAC6vQUrWMxt2OF80Llpuz5qZ0pGd4ZJ-taxSWhvGTf_Dk5Mto-jDNqYXAeCsWR2OQ6zi3XahtkybeW1k5C-OK9SgvwWXxAqpJpnTbX49Xh18f5ggUJJaPNaGBqWHFeUojjT_hl3eKRITBgyBXbWn23x-Ia-3AGVnlCP1KdgEdHIKGQeArjlqv2UcZON86ZrVLnfffcxkf8PCZQmeheCWbrP7sj7j2ULz3cXafLL_Ovk1-uNfwZ8alf99rhagUP10pkQ3Zy4A3xa_ze'},
      {'name': 'Portable Mini Mill', 'price': '\$1,200', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuA4kKhdoeO83iysXA1Us6Yb2KQU-t_7JzFSAbIeaIQNqDn4N0ZC544pF4QHjUDmuTwwX7hj_3eTfg8vXtqMbj-LAKFGOZ1zjkROJkWmlF_lllVj8ue4ZdP2LCxMTvheOeS5zvQ2WP_J4tdNxXb55aSjWfSVK5fHDF8sDGw-uaZVhwE1OrmsJfgOf5XZ04Zhb7cwNNK37oJRvZ4NQAxJ0G_9Nn6i97gjI5D3EbuNTqoArbzJ27abeNbtH1AzwY_b14iP25Xao4NbYa89'},
      {'name': 'Industrial Harvester', 'price': '\$12,000', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCfjvY9qv7e2DrzoarDJlFi_jYIt61c3SXbMznlWUWHVcJoUrnydvSqGF6yKzkzfXBQq3_yM3Z5VzEdlK3w7KAxeOykQnfDpLNZrPwqKa5FBnH4Y2ZPNm4rXLmiuQ2V-PH4PkiyfkUOoNOk1pdpgQpodhuCfmqNSww3HoRcN6IKmN1twcPfV9kocnazApf4grG6fJrExHZmzBuYtiadH4f8-CdumZ1O02LS4JIL7qC0l-ae7fhmAQXlhVFeAceRkqyU4pJPL1B11B5s'},
    ];

    final product = products[index];
    return GestureDetector(
      onTap: () => context.push('/product/${index + 1}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: product['image']!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(color: AppColors.gray100),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.gray100,
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['price']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsTab() {
    return const NegotiationsPlaceholder();
  }

  Widget _buildStockTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            onPressed: () => context.push('/add-product'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: const Center(child: Text('Stock Management')),
    );
  }

  Widget _buildProfileTab() {
    return const ProfilePlaceholder();
  }
}

class NegotiationsPlaceholder extends StatelessWidget {
  const NegotiationsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deals'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.push('/negotiations'),
          child: const Text('View Negotiations'),
        ),
      ),
    );
  }
}

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.push('/profile'),
          child: const Text('View Profile'),
        ),
      ),
    );
  }
}
