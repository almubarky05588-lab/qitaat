import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock.dart';

enum UserRole { buyer, merchant }

/// نوع الحساب — يُحدَّد عند التسجيل، والرقم المسجّل بدور لا يدخل بالدور الآخر
final roleProvider = StateProvider<UserRole>((ref) => UserRole.buyer);

final phoneProvider = StateProvider<String>((ref) => '');

final favoritesProvider = StateProvider<Set<String>>((ref) => {'p2', 'p5', 'p1', 'p3'});

class CartItem {
  final Product product;
  final int qty;
  const CartItem(this.product, this.qty);
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([CartItem(Mock.products[1], 1), CartItem(Mock.products[2], 1)]);

  void add(Product p) {
    final i = state.indexWhere((e) => e.product.id == p.id);
    if (i >= 0) {
      setQty(p.id, state[i].qty + 1);
    } else {
      state = [...state, CartItem(p, 1)];
    }
  }

  void setQty(String id, int qty) {
    if (qty <= 0) {
      remove(id);
      return;
    }
    state = [for (final e in state) e.product.id == id ? CartItem(e.product, qty) : e];
  }

  void remove(String id) => state = state.where((e) => e.product.id != id).toList();
  void clear() => state = [];

  int get count => state.fold(0, (a, e) => a + e.qty);
  double get subtotal => state.fold(0.0, (a, e) => a + (e.product.price ?? 0) * e.qty);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

const shippingFee = 35.0;
const vatRate = 0.15;
