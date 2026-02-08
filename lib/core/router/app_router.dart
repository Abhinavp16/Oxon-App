import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/role_login_screen.dart';
import '../../screens/auth/wholesaler_registration_screen.dart';
import '../../screens/auth/apple_signup_screen.dart';
import '../../screens/auth/auth_screen.dart';
import '../../screens/home/marketplace_home_screen.dart';
import '../../screens/product/product_detail_screen.dart';
import '../../screens/product/product_negotiation_screen.dart';
import '../../screens/product/power_tiller_detail_screen.dart';
import '../../screens/product/product_detail_video_screen.dart';
import '../../screens/product/wholesale_detail_screen.dart';
import '../../screens/product/edit_product_screen.dart';
import '../../screens/product/add_product_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/cart/shopping_cart_screen.dart';
import '../../screens/payment/payment_screen.dart';
import '../../screens/payment/upi_payment_screen.dart';
import '../../screens/negotiations/negotiations_screen.dart';
import '../../screens/negotiations/negotiation_detail_screen.dart';
import '../../screens/negotiations/negotiation_success_screen.dart';
import '../../screens/negotiations/counter_offer_screen.dart';
import '../../screens/negotiations/negotiations_tracker_screen.dart';
import '../../screens/negotiations/pending_negotiations_screen.dart';
import '../../screens/orders/order_success_screen.dart';
import '../../screens/orders/shipment_tracking_screen.dart';
import '../../screens/orders/dispatch_management_screen.dart';
import '../../screens/orders/previous_orders_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/wholesaler_profile_screen.dart';
import '../../screens/help/help_support_screen.dart';
import '../../screens/help/negotiation_guide_screen.dart';
import '../../screens/notifications/notifications_center_screen.dart';
import '../../screens/inventory/inventory_management_screen.dart';
import '../../screens/admin/analytics_dashboard_screen.dart';
import '../../screens/admin/payment_verification_screen.dart';
import '../../screens/dev/developer_menu_screen.dart';
import '../../screens/wishlist/wishlist_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AppleSignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final initialTab = extra?['tab'] as int?;
        return MarketplaceHomeScreen(initialTab: initialTab);
      },
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ProductDetailScreen(
          productId: state.pathParameters['id'] ?? '',
          heroTag: extra?['heroTag']?.toString(),
        );
      },
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/payment/:orderId',
      builder: (context, state) => PaymentScreen(
        orderId: state.pathParameters['orderId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/negotiations',
      builder: (context, state) => const NegotiationsScreen(),
    ),
    GoRoute(
      path: '/negotiation-detail/:id',
      builder: (context, state) => NegotiationDetailScreen(
        negotiationId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/negotiation-success',
      builder: (context, state) => const NegotiationSuccessScreen(),
    ),
    GoRoute(
      path: '/order-success/:orderId',
      builder: (context, state) => OrderSuccessScreen(
        orderId: state.pathParameters['orderId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/tracking/:orderId',
      builder: (context, state) => ShipmentTrackingScreen(
        orderId: state.pathParameters['orderId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/add-product',
      builder: (context, state) => const AddProductScreen(),
    ),
    GoRoute(
      path: '/dev',
      builder: (context, state) => const DeveloperMenuScreen(),
    ),
    GoRoute(
      path: '/role-login',
      builder: (context, state) => const RoleLoginScreen(),
    ),
    GoRoute(
      path: '/wholesaler-registration',
      builder: (context, state) => const WholesalerRegistrationScreen(),
    ),
        GoRoute(
      path: '/product-negotiation',
      builder: (context, state) => const ProductNegotiationScreen(),
    ),
    GoRoute(
      path: '/power-tiller',
      builder: (context, state) => const PowerTillerDetailScreen(),
    ),
    GoRoute(
      path: '/product-video',
      builder: (context, state) => const ProductDetailVideoScreen(),
    ),
    GoRoute(
      path: '/wholesale-detail',
      builder: (context, state) => const WholesaleDetailScreen(),
    ),
    GoRoute(
      path: '/edit-product',
      builder: (context, state) => const EditProductScreen(),
    ),
    GoRoute(
      path: '/shopping-cart',
      builder: (context, state) => const ShoppingCartScreen(),
    ),
    GoRoute(
      path: '/upi-payment',
      builder: (context, state) => const UpiPaymentScreen(),
    ),
    GoRoute(
      path: '/counter-offer',
      builder: (context, state) => const CounterOfferScreen(),
    ),
    GoRoute(
      path: '/negotiations-tracker',
      builder: (context, state) => const NegotiationsTrackerScreen(),
    ),
    GoRoute(
      path: '/pending-negotiations',
      builder: (context, state) => const PendingNegotiationsScreen(),
    ),
    GoRoute(
      path: '/dispatch-management',
      builder: (context, state) => const DispatchManagementScreen(),
    ),
    GoRoute(
      path: '/previous-orders',
      builder: (context, state) => const PreviousOrdersScreen(),
    ),
    GoRoute(
      path: '/wholesaler-profile',
      builder: (context, state) => const WholesalerProfileScreen(),
    ),
    GoRoute(
      path: '/negotiation-guide',
      builder: (context, state) => const NegotiationGuideScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsCenterScreen(),
    ),
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryManagementScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsDashboardScreen(),
    ),
    GoRoute(
      path: '/payment-verification',
      builder: (context, state) => const PaymentVerificationScreen(),
    ),
    GoRoute(
      path: '/wishlist',
      builder: (context, state) => const WishlistScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);
