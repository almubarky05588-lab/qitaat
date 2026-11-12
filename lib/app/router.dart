import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/account.dart';
import '../features/auth.dart';
import '../features/catalog.dart';
import '../features/checkout.dart';
import '../features/home.dart';
import '../features/merchant.dart';
import '../features/orders.dart';
import '../features/requests.dart';
import '../features/shell.dart';
import '../features/social.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRoute _r(String path, Widget Function(GoRouterState s) b) =>
    GoRoute(path: path, parentNavigatorKey: _rootKey, builder: (c, s) => b(s));

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    _r('/', (s) => const SplashScreen()),
    _r('/signup', (s) => const SignupScreen()),
    _r('/login', (s) => const SignupScreen(login: true)),
    _r('/otp', (s) => const OtpScreen()),

    // التبويبات السفلية
    StatefulShellRoute.indexedStack(
      builder: (c, s, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (c, s) => const HomeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/orders', builder: (c, s) => const MyOrdersScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/requests', builder: (c, s) => const MyRequestsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/account', builder: (c, s) => const AccountScreen())]),
      ],
    ),

    // المشتري
    _r('/search', (s) => SearchScreen(query: s.uri.queryParameters['q'] ?? '', brand: s.uri.queryParameters['brand'])),
    _r('/part/:id', (s) => PartDetailsScreen(id: s.pathParameters['id']!)),
    _r('/favorites', (s) => const FavoritesScreen()),
    _r('/cart', (s) => const CartScreen()),
    _r('/checkout', (s) => const PaymentScreen()),
    _r('/invoice/:id', (s) => InvoiceScreen(id: s.pathParameters['id']!)),
    _r('/invoices', (s) => const InvoicesScreen()),
    _r('/request-part', (s) => const RequestPartScreen()),
    _r('/request-sent/:id', (s) => RequestSentScreen(id: s.pathParameters['id']!)),
    _r('/offers/:id', (s) => OffersScreen(id: s.pathParameters['id']!)),
    _r('/order/:id', (s) => OrderDetailsScreen(id: s.pathParameters['id']!)),
    _r('/notifications', (s) => const NotificationsScreen()),
    _r('/chats', (s) => const ChatsScreen()),
    _r('/chat/:id', (s) => ChatScreen(id: s.pathParameters['id']!)),
    _r('/cars', (s) => const MyCarsScreen()),
    _r('/settings', (s) => const SettingsScreen()),
    _r('/edit-profile', (s) => const EditProfileScreen()),

    // التاجر / المورد
    _r('/sell', (s) => SellPartScreen(editId: s.uri.queryParameters['edit'])),
    _r('/m/dashboard', (s) => const DashboardScreen()),
    _r('/m/requests', (s) => const CustomerRequestsScreen()),
    _r('/m/offer/:id', (s) => SubmitOfferScreen(id: s.pathParameters['id']!)),
    _r('/m/listings', (s) => const MyListingsScreen()),
    _r('/m/bids', (s) => const ListingBidsScreen()),
    _r('/m/sales', (s) => const SalesOrdersScreen()),
    _r('/m/document/:id', (s) => DocumentPhotosScreen(id: s.pathParameters['id']!)),
    _r('/m/earnings', (s) => const EarningsScreen()),
    _r('/m/subscription', (s) => const SubscriptionScreen()),
  ],
);
