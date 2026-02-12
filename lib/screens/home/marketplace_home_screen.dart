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
import '../../core/services/notification_service.dart';

class MarketplaceHomeScreen extends ConsumerStatefulWidget {
  final int? initialTab;
  const MarketplaceHomeScreen({super.key, this.initialTab});

  @override
  ConsumerState<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends ConsumerState<MarketplaceHomeScreen> {
  late int _selectedNavIndex;
  bool _isCheckingOut = false;
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

  // Filter state
  String? _selectedFilterCategory;
  String? _selectedFilterBrand;
  List<String> _categories = [];

  // Notification state
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoadingNotifications = false;
  StateSetter? _dialogSetter;

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
    _fetchCategories();
    _initNotifications();
    _fetchNotificationCount();
    // Fetch cart from server so it persists across app restarts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).fetchCart();
    });
  }

  Future<void> _initNotifications() async {
    try {
      await ref.read(notificationServiceProvider).initialize();
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
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

  Future<void> _fetchCategories() async {
    try {
      final response = await _dio.get('/products/categories');
      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['data'] ?? [];
        setState(() {
          _categories = items.map<String>((item) => item['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty && _selectedFilterCategory == null && _selectedFilterBrand == null) {
      setState(() { _searchResults = []; _isSearching = false; _searchQuery = ''; });
      return;
    }
    setState(() => _isSearching = true);
    if (query.isNotEmpty) setState(() => _searchQuery = query);
    try {
      final params = <String, dynamic>{};
      if (query.trim().isNotEmpty) params['q'] = query;
      if (_selectedFilterCategory != null) params['category'] = _selectedFilterCategory;
      if (_selectedFilterBrand != null) params['brand'] = _selectedFilterBrand;

      final endpoint = query.trim().isNotEmpty ? '/products/search' : '/products';
      final response = await _dio.get(endpoint, queryParameters: params);
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

  void _showFilterSheet() {
    String? tempCategory = _selectedFilterCategory;
    String? tempBrand = _selectedFilterBrand;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
            decoration: const BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: borderLight, borderRadius: BorderRadius.circular(2)),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters', style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary)),
                      GestureDetector(
                        onTap: () {
                          setSheetState(() { tempCategory = null; tempBrand = null; });
                        },
                        child: Text('Reset', style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600, color: primaryBlue)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Category section
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category', style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _categories.map((cat) {
                            final selected = tempCategory == cat;
                            return GestureDetector(
                              onTap: () => setSheetState(() => tempCategory = selected ? null : cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? primaryBlue : surfaceWhite,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: selected ? primaryBlue : borderLight),
                                  boxShadow: selected ? [BoxShadow(color: primaryBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
                                ),
                                child: Text(cat, style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : textSecondary)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        // Brand section
                        Text('Brand', style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _brands.map((brand) {
                            final name = brand['name'] as String;
                            final selected = tempBrand == name;
                            return GestureDetector(
                              onTap: () => setSheetState(() => tempBrand = selected ? null : name),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? primaryBlue : surfaceWhite,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: selected ? primaryBlue : borderLight),
                                  boxShadow: selected ? [BoxShadow(color: primaryBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
                                ),
                                child: Text(name, style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : textSecondary)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Apply button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilterCategory = tempCategory;
                          _selectedFilterBrand = tempBrand;
                        });
                        Navigator.pop(ctx);
                        _searchProducts(_searchQuery);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('Apply Filters', style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/notifications/my', queryParameters: {'limit': 1});
      if (response.statusCode == 200) {
        setState(() {
          _unreadCount = response.data['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  Future<void> _fetchNotifications([void Function(void Function())? dialogSetter]) async {
    final update = dialogSetter ?? setState;
    update(() => _isLoadingNotifications = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/notifications/my', queryParameters: {'limit': 10});
      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['data'] ?? [];
        final mapped = items.map<Map<String, dynamic>>((item) => <String, dynamic>{
          'id': item['_id']?.toString() ?? '',
          'title': item['title']?.toString() ?? '',
          'body': item['body']?.toString() ?? '',
          'type': item['type']?.toString() ?? 'general',
          'isRead': item['isRead'] == true,
          'createdAt': item['createdAt']?.toString() ?? '',
          'data': item['data'] ?? {},
        }).toList();
        _notifications = mapped;
        _unreadCount = response.data['unreadCount'] ?? 0;
        _isLoadingNotifications = false;
        update(() {});
        // Also update parent so badge refreshes
        if (dialogSetter != null && mounted) setState(() {});
      } else {
        _isLoadingNotifications = false;
        update(() {});
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _isLoadingNotifications = false;
      update(() {});
    }
  }

  Future<void> _markNotificationsRead([void Function(void Function())? dialogSetter]) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/notifications/mark-read', data: {});
      _unreadCount = 0;
      for (var n in _notifications) { n['isRead'] = true; }
      if (dialogSetter != null) dialogSetter(() {});
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error marking notifications read: $e');
    }
  }

  void _showNotificationPopup() {
    _isLoadingNotifications = true;
    _dialogSetter = null;
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Trigger fetch only once per dialog open, deferred to avoid setState-during-build
          if (_dialogSetter == null) {
            _dialogSetter = setDialogState;
            Future.microtask(() => _fetchNotifications(setDialogState));
          }
          return GestureDetector(
            onTap: () => Navigator.pop(ctx),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {}, // absorb taps on the popup itself
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.88,
                        constraints: const BoxConstraints(maxHeight: 420),
                        decoration: BoxDecoration(
                          color: surfaceWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8)),
                            BoxShadow(color: primaryBlue.withOpacity(0.06), blurRadius: 40, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Text('Notifications', style: GoogleFonts.plusJakartaSans(
                                      fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary)),
                                    if (_unreadCount > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(100)),
                                        child: Text('$_unreadCount', style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                      ),
                                    ],
                                  ]),
                                  Row(children: [
                                    if (_unreadCount > 0)
                                      GestureDetector(
                                        onTap: () => _markNotificationsRead(setDialogState),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text('Mark all read', style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12, fontWeight: FontWeight.w600, color: primaryBlue)),
                                        ),
                                      ),
                                    IconButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      icon: const Icon(Icons.close_rounded, size: 20, color: textMuted),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: borderLight),
                            // Content
                            _isLoadingNotifications
                              ? const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2)),
                                )
                              : _notifications.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 56, height: 56,
                                          decoration: BoxDecoration(
                                            color: primaryBlue.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(Icons.notifications_none_rounded, size: 28, color: primaryBlue.withOpacity(0.5)),
                                        ),
                                        const SizedBox(height: 12),
                                        Text('No notifications yet', style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                                        const SizedBox(height: 4),
                                        Text("You're all caught up!", style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13, color: textMuted)),
                                      ],
                                    ),
                                  )
                                : Flexible(
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      itemCount: _notifications.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1, color: borderLight, indent: 60),
                                      itemBuilder: (_, i) => _buildNotificationItem(_notifications[i]),
                                    ),
                                  ),
                            // Footer
                            if (_notifications.isNotEmpty) ...[
                              const Divider(height: 1, color: borderLight),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  context.push('/notifications');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Text('View All Notifications', style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: primaryBlue)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) => _dialogSetter = null);
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] == true;
    final type = notification['type']?.toString() ?? 'general';
    final createdAt = notification['createdAt']?.toString() ?? '';

    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (type) {
      case 'payment_verified':
        icon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF16A34A);
        iconBg = const Color(0xFFF0FDF4);
        break;
      case 'payment_rejected':
        icon = Icons.cancel_rounded;
        iconColor = const Color(0xFFEF4444);
        iconBg = const Color(0xFFFEF2F2);
        break;
      case 'order_update':
        icon = Icons.local_shipping_rounded;
        iconColor = const Color(0xFF2563EB);
        iconBg = const Color(0xFFEFF6FF);
        break;
      case 'negotiation_update':
        icon = Icons.handshake_rounded;
        iconColor = const Color(0xFFF59E0B);
        iconBg = const Color(0xFFFFFBEB);
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = const Color(0xFF8B5CF6);
        iconBg = const Color(0xFFF5F3FF);
    }

    String timeAgo = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 1) {
          timeAgo = 'Just now';
        } else if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    return Container(
      color: isRead ? Colors.transparent : primaryBlue.withOpacity(0.02),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(notification['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: isRead ? FontWeight.w600 : FontWeight.w700, color: textPrimary)),
                    ),
                    if (!isRead)
                      Container(
                        width: 8, height: 8, margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(notification['body'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary, height: 1.4)),
                if (timeAgo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(timeAgo, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addr1Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCtrl.dispose();
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
                const SizedBox(height: 32),
                _buildWhyBuySection(),
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
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedFilterHorizontal,
                            color: (_selectedFilterCategory != null || _selectedFilterBrand != null) ? primaryBlue : textMuted, size: 22),
                          if (_selectedFilterCategory != null || _selectedFilterBrand != null)
                            Positioned(
                              top: -2, right: -4,
                              child: Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    ),
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
    if (_showAddressForm) return _buildAddressForm();
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
                    onTap: _isCheckingOut ? null : _proceedToCheckout,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isCheckingOut ? primaryBlue.withOpacity(0.6) : primaryBlue,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isCheckingOut) ...[
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 12),
                          ],
                          Text(_isCheckingOut ? 'Creating Order...' : 'Proceed to Checkout',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          if (!_isCheckingOut) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                          ],
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

  int _negotiationTab = 0;
  bool _isNegotiationsLoading = true;
  List<Map<String, dynamic>> _negotiations = [];

  Future<void> _fetchNegotiations() async {
    setState(() => _isNegotiationsLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/negotiations');
      if (response.data['success'] == true) {
        final List items = response.data['data'] ?? [];
        setState(() { _negotiations = items.cast<Map<String, dynamic>>(); _isNegotiationsLoading = false; });
      }
    } catch (e) {
      setState(() => _isNegotiationsLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredNegotiations {
    if (_negotiationTab == 0) return _negotiations;
    if (_negotiationTab == 1) {
      return _negotiations.where((n) => ['pending', 'countered'].contains(n['status'])).toList();
    }
    return _negotiations.where((n) => ['accepted', 'rejected', 'expired', 'converted'].contains(n['status'])).toList();
  }

  Map<String, dynamic> _getNegStatusDisplay(String status) {
    switch (status) {
      case 'pending': return {'label': 'PENDING', 'color': const Color(0xFF6B7280), 'bg': const Color(0xFFF3F4F6)};
      case 'countered': return {'label': 'COUNTER-OFFER', 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFEF3C7)};
      case 'accepted': return {'label': 'ACCEPTED', 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFDCFCE7)};
      case 'rejected': return {'label': 'REJECTED', 'color': const Color(0xFFDC2626), 'bg': const Color(0xFFFEE2E2)};
      case 'expired': return {'label': 'EXPIRED', 'color': const Color(0xFF9CA3AF), 'bg': const Color(0xFFF3F4F6)};
      case 'converted': return {'label': 'CONVERTED', 'color': const Color(0xFF7C3AED), 'bg': const Color(0xFFF3E8FF)};
      default: return {'label': status.toUpperCase(), 'color': const Color(0xFF6B7280), 'bg': const Color(0xFFF3F4F6)};
    }
  }

  Widget _buildNegotiationsContent() {
    if (_isNegotiationsLoading && _negotiations.isEmpty) {
      _fetchNegotiations();
    }
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          color: backgroundWhite,
          child: Text(
            'Negotiations',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
          ),
        ),
        // Tabs
        Container(
          color: backgroundWhite,
          child: Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: borderLight, width: 1))),
            child: Row(
              children: [
                _buildNegotiationTab('All', 0),
                _buildNegotiationTab('Active', 1),
                _buildNegotiationTab('Completed', 2),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: _isNegotiationsLoading
              ? const Center(child: CircularProgressIndicator(color: primaryBlue))
              : _filteredNegotiations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.handshake_outlined, size: 48, color: textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            _negotiationTab == 1 ? 'No active negotiations' :
                            _negotiationTab == 2 ? 'No completed negotiations' :
                            'No negotiations yet',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text('Start negotiating on product pages', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF4C669A))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNegotiations,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _filteredNegotiations.length,
                        itemBuilder: (context, index) => _buildNegotiationCard(_filteredNegotiations[index]),
                      ),
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
            border: Border(bottom: BorderSide(color: isSelected ? primaryBlue : Colors.transparent, width: 3)),
          ),
          child: Text(
            label, textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: isSelected ? primaryBlue : const Color(0xFF4C669A)),
          ),
        ),
      ),
    );
  }

  Widget _buildNegotiationCard(Map<String, dynamic> negotiation) {
    final status = negotiation['status'] as String? ?? 'pending';
    final statusDisplay = _getNegStatusDisplay(status);
    final product = negotiation['product'] as Map<String, dynamic>? ?? {};
    final productName = product['name'] as String? ?? 'Unknown Product';
    final imageUrl = product['image'] as String? ?? '';
    final quantity = negotiation['requestedQuantity'] ?? 0;
    final requestedPrice = negotiation['requestedPricePerUnit'] ?? 0;
    final currentPrice = negotiation['currentPricePerUnit'] ?? 0;
    final currentTotal = negotiation['currentTotalPrice'] ?? 0;
    final currentOfferBy = negotiation['currentOfferBy'] as String? ?? '';
    final negotiationNumber = negotiation['negotiationNumber'] as String? ?? '';
    final negotiationId = (negotiation['id'] ?? negotiation['_id'] ?? '').toString();
    final canPay = negotiation['canPay'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () async {
          final result = await context.push('/negotiation-detail/$negotiationId');
          if (result == true) _fetchNegotiations();
        },
        child: Container(
          decoration: BoxDecoration(
            color: surfaceWhite, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderLight),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: 2.4,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFFF1F5F9)),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: textMuted, size: 40)),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          negotiationNumber.isNotEmpty ? negotiationNumber : 'NEGOTIATION',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4C669A), letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: statusDisplay['bg'] as Color, borderRadius: BorderRadius.circular(100)),
                          child: Text(
                            statusDisplay['label'] as String,
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: statusDisplay['color'] as Color, letterSpacing: 0.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(productName, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary, height: 1.2, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text('Qty: $quantity units', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF4C669A))),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: backgroundWhite, borderRadius: BorderRadius.circular(8),
                        border: status == 'accepted' ? const Border(left: BorderSide(color: Color(0xFF16A34A), width: 4)) : null,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Your Price/unit:', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF4C669A))),
                              Text('₹$requestedPrice', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                status == 'countered' && currentOfferBy == 'admin' ? 'Admin Counter:' : 'Current Price/unit:',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF4C669A)),
                              ),
                              Text('₹$currentPrice', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: status == 'accepted' ? const Color(0xFF16A34A) : primaryBlue)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Divider(height: 1),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total:', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                              Text('₹$currentTotal', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: status == 'accepted' ? const Color(0xFF16A34A) : textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNegActionButton(status, currentOfferBy, canPay, negotiationId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNegActionButton(String status, String currentOfferBy, bool canPay, String negotiationId) {
    String label; String style; IconData? icon; VoidCallback? onTap;
    if (status == 'countered' && currentOfferBy == 'admin') {
      label = 'Respond to Counter'; style = 'primary'; icon = Icons.reply_rounded;
      onTap = () async { final r = await context.push('/negotiation-detail/$negotiationId'); if (r == true) _fetchNegotiations(); };
    } else if (status == 'accepted' && canPay) {
      label = 'Proceed to Order'; style = 'primary'; icon = Icons.account_balance_wallet_rounded;
      onTap = () => _proceedToNegotiationOrder(negotiationId);
    } else if (status == 'pending') {
      label = 'Under Review'; style = 'disabled';
    } else if (status == 'rejected') {
      label = 'Rejected'; style = 'disabled';
    } else if (status == 'expired') {
      label = 'Expired'; style = 'disabled';
    } else {
      label = 'View Details'; style = 'outline';
      onTap = () async { final r = await context.push('/negotiation-detail/$negotiationId'); if (r == true) _fetchNegotiations(); };
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 44,
        decoration: BoxDecoration(
          color: style == 'primary' ? primaryBlue : style == 'disabled' ? borderLight : surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: style == 'outline' ? Border.all(color: borderLight) : null,
          boxShadow: style == 'primary' && icon != null ? [BoxShadow(color: primaryBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 6)],
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700,
              color: style == 'primary' ? Colors.white : style == 'disabled' ? const Color(0xFF9CA3AF) : textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final settings = [
      {'icon': HugeIcons.strokeRoundedShoppingBag01, 'color': Colors.teal, 'title': 'My Orders', 'subtitle': null, 'onTap': () => context.push('/previous-orders')},
      {'icon': HugeIcons.strokeRoundedFavourite, 'color': Colors.red, 'title': 'Wishlist', 'subtitle': null, 'onTap': () => context.push('/wishlist')},
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
              GestureDetector(
                onTap: _showNotificationPopup,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
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
                    if (_unreadCount > 0)
                      Positioned(
                        top: -2, right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text('$_unreadCount', textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
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

  // ── Checkout state for inline address form ──
  bool _showAddressForm = false;
  final _addrFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addr1Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  Future<void> _proceedToCheckout() async {
    // Validate stock before showing address form
    setState(() => _isCheckingOut = true);
    final result = await ref.read(cartProvider.notifier).validateStock();
    if (!mounted) return;
    setState(() => _isCheckingOut = false);

    final bool valid = result['valid'] ?? true;
    if (!valid) {
      final issues = ((result['issues'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
      _showStockIssueSnackbar(issues);
      return;
    }

    final auth = ref.read(authProvider);
    _nameCtrl.text = auth.user?.name ?? '';
    _phoneCtrl.text = auth.user?.phone ?? '';
    setState(() => _showAddressForm = true);
  }

  void _showStockIssueSnackbar(List<Map<String, dynamic>> issues) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cannot proceed — stock issues:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          ...issues.map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('• ${i['message'] ?? 'Stock issue'}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500)),
          )),
        ],
      ),
      backgroundColor: const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16)));
  }

  Future<void> _confirmAndPay() async {
    if (!_addrFormKey.currentState!.validate()) return;

    final address = {
      'fullName': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'addressLine1': _addr1Ctrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'pincode': _pinCtrl.text.trim(),
    };

    setState(() { _showAddressForm = false; _isCheckingOut = true; });
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/orders', data: {
        'shippingAddress': address,
      });

      if (!mounted) return;
      setState(() => _isCheckingOut = false);

      if (response.data['success'] == true) {
        final orderId = response.data['data']['orderId'].toString();
        ref.read(cartProvider.notifier).clearCart();
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) context.push('/payment/$orderId');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingOut = false);
      final msg = e.response?.data?['message']?.toString() ?? 'Checkout failed';
      // If it's a stock issue from the server, refresh cart to show updated stock
      final code = e.response?.data?['code']?.toString();
      if (code == 'INSUFFICIENT_STOCK') {
        ref.read(cartProvider.notifier).fetchCart();
        ref.read(cartProvider.notifier).validateStock();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingOut = false);
    }
  }

  Widget _buildAddressForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(key: _addrFormKey, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => setState(() => _showAddressForm = false),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Text('Shipping Address', style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
        ]),
        const SizedBox(height: 24),
        _addrField('Full Name', _nameCtrl),
        const SizedBox(height: 14),
        _addrField('Phone', _phoneCtrl, keyboard: TextInputType.phone),
        const SizedBox(height: 14),
        _addrField('Address Line 1', _addr1Ctrl),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _addrField('City', _cityCtrl)),
          const SizedBox(width: 12),
          Expanded(child: _addrField('State', _stateCtrl)),
        ]),
        const SizedBox(height: 14),
        _addrField('Pincode', _pinCtrl, keyboard: TextInputType.number),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _confirmAndPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('Confirm & Pay', style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w700)))),
      ])),
    );
  }

  Future<void> _proceedToNegotiationOrder(String negotiationId) async {
    final auth = ref.read(authProvider);
    final nameC = TextEditingController(text: auth.user?.name ?? '');
    final phoneC = TextEditingController(text: auth.user?.phone ?? '');
    final addr1C = TextEditingController();
    final cityC = TextEditingController();
    final stateC = TextEditingController();
    final pinC = TextEditingController();
    final fk = GlobalKey<FormState>();

    final address = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top + 40),
        decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(key: fk, child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: borderLight, borderRadius: BorderRadius.circular(100)))),
            Text('Shipping Address', style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 20),
            _addrField('Full Name', nameC),
            const SizedBox(height: 12),
            _addrField('Phone', phoneC, keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            _addrField('Address Line 1', addr1C),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _addrField('City', cityC)),
              const SizedBox(width: 12),
              Expanded(child: _addrField('State', stateC)),
            ]),
            const SizedBox(height: 12),
            _addrField('Pincode', pinC, keyboard: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (fk.currentState!.validate()) {
                    Navigator.of(ctx).pop({
                      'fullName': nameC.text.trim(),
                      'phone': phoneC.text.trim(),
                      'addressLine1': addr1C.text.trim(),
                      'city': cityC.text.trim(),
                      'state': stateC.text.trim(),
                      'pincode': pinC.text.trim(),
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Confirm & Proceed', style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700)))),
          ]))))),
    );

    nameC.dispose(); phoneC.dispose(); addr1C.dispose();
    cityC.dispose(); stateC.dispose(); pinC.dispose();

    if (address == null || !mounted) return;

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/orders/from-negotiation', data: {
        'negotiationId': negotiationId,
        'shippingAddress': address,
      });

      if (!mounted) return;
      if (response.data['success'] == true) {
        final orderId = response.data['data']['orderId'].toString();
        context.push('/payment/$orderId');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['message']?.toString() ?? 'Failed to create order';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16)));
    }
  }

  Widget _addrField(String label, TextEditingController ctrl, {TextInputType? keyboard}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildWhyBuySection() {
    final items = [
      {'icon': Icons.verified_rounded, 'color': const Color(0xFF2563EB), 'bg': const Color(0xFFEFF6FF), 'title': 'Premium Quality', 'subtitle': 'Certified products'},
      {'icon': Icons.local_offer_rounded, 'color': const Color(0xFF7C3AED), 'bg': const Color(0xFFF5F3FF), 'title': 'Bulk Pricing', 'subtitle': 'Best wholesale rates'},
      {'icon': Icons.local_shipping_rounded, 'color': const Color(0xFF0891B2), 'bg': const Color(0xFFECFEFF), 'title': 'Fast Delivery', 'subtitle': 'Pan-India shipping'},
      {'icon': Icons.support_agent_rounded, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFF0FDF4), 'title': '24/7 Support', 'subtitle': 'Always here to help'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [const Color(0xFFF8FAFC), const Color(0xFFEFF6FF)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.7)),
        ),
        child: Column(
          children: [
            Text('Why Buy From Us?', style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text('Trusted by 500+ businesses across India', style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary)),
            const SizedBox(height: 24),
            Row(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: _buildWhyBuyItem(
                    items[i]['icon'] as IconData,
                    items[i]['color'] as Color,
                    items[i]['bg'] as Color,
                    items[i]['title'] as String,
                    items[i]['subtitle'] as String,
                  )),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyBuyItem(IconData icon, Color color, Color bg, String title, String subtitle) {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary, height: 1.2)),
        const SizedBox(height: 2),
        Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(
          fontSize: 9, fontWeight: FontWeight.w500, color: textMuted)),
      ],
    );
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
