import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

class CartItem {
  final String productId;
  final String name;
  final String? image;
  final double price;
  final double? mrp;
  final int quantity;
  final int stock;

  CartItem({
    required this.productId,
    required this.name,
    this.image,
    required this.price,
    this.mrp,
    required this.quantity,
    this.stock = 0,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      image: image,
      price: price,
      mrp: mrp,
      quantity: quantity ?? this.quantity,
      stock: stock,
    );
  }

  double get total => price * quantity;
}

class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  CartState({this.items = const [], this.isLoading = false, this.error});

  CartState copyWith({List<CartItem>? items, bool? isLoading, String? error}) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get deliveryFee => subtotal > 0 ? 50 : 0;
  double get grandTotal => subtotal + deliveryFee;
}

class CartNotifier extends StateNotifier<CartState> {
  final Dio _dio;

  CartNotifier()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
        )),
        super(CartState());

  Future<Dio> get _authedDio async {
    final token = await StorageService.getAccessToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return _dio;
  }

  Future<void> fetchCart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = await _authedDio;
      final response = await dio.get('/cart');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final List<dynamic> rawItems = data['items'] ?? [];
        final items = rawItems.map<CartItem>((item) {
          final product = item['product'] as Map<String, dynamic>? ?? {};
          return CartItem(
            productId: item['productId']?.toString() ?? '',
            name: product['name']?.toString() ?? '',
            image: product['image']?.toString(),
            price: (item['currentPrice'] ?? product['price'] ?? 0).toDouble(),
            quantity: item['quantity'] ?? 1,
            stock: product['stock'] ?? 0,
          );
        }).toList();
        state = state.copyWith(items: items, isLoading: false);
      }
    } catch (e) {
      // If not authenticated or error, keep local state
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> addItem({
    required String productId,
    required String name,
    String? image,
    required double price,
    double? mrp,
    required int quantity,
    int stock = 99,
  }) async {
    // Update local state immediately
    final existingIndex = state.items.indexWhere((i) => i.productId == productId);
    final updatedItems = List<CartItem>.from(state.items);

    if (existingIndex >= 0) {
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      updatedItems.add(CartItem(
        productId: productId,
        name: name,
        image: image,
        price: price,
        mrp: mrp,
        quantity: quantity,
        stock: stock,
      ));
    }
    state = state.copyWith(items: updatedItems);

    // Try syncing with backend
    try {
      final dio = await _authedDio;
      await dio.post('/cart/items', data: {
        'productId': productId,
        'quantity': quantity,
      });
    } catch (_) {
      // Offline or not authenticated — local state is still valid
    }
    return true;
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity < 1) {
      removeItem(productId);
      return;
    }
    final updatedItems = state.items.map((item) {
      if (item.productId == productId) return item.copyWith(quantity: quantity);
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);

    // Background sync
    try {
      final dio = await _authedDio;
      await dio.put('/cart/items/$productId', data: {'quantity': quantity});
    } catch (_) {}
  }

  Future<void> removeItem(String productId) async {
    final updatedItems = state.items.where((i) => i.productId != productId).toList();
    state = state.copyWith(items: updatedItems);

    // Background sync
    try {
      final dio = await _authedDio;
      await dio.delete('/cart/items/$productId');
    } catch (_) {}
  }

  Future<void> clearCart() async {
    state = state.copyWith(items: []);
    try {
      final dio = await _authedDio;
      await dio.delete('/cart');
    } catch (_) {}
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
