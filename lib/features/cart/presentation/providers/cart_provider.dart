import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    // Initial state is empty, but we'll try to load it right away!
    _loadCart();
    return [];
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('cart_data');
      if (cartString == null) return;

      final List<dynamic> decoded = json.decode(cartString);
      state = decoded
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt or outdated stored data must not crash startup; an empty cart
      // is recoverable, a crash loop is not.
      state = [];
      await _clearStoredCart();
    }
  }

  Future<void> _clearStoredCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_data');
  }

  Future<void> _saveCart(List<CartItem> cart) async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = json.encode(cart.map((item) => item.toJson()).toList());
    await prefs.setString('cart_data', cartString);
  }

  void addProduct(Product product) {
    final currentState = state;
    final existingItemIndex = currentState.indexWhere(
      (item) => item.product.id == product.id,
    );

    List<CartItem> updatedCart;
    if (existingItemIndex >= 0) {
      updatedCart = List.from(currentState);
      final existingItem = updatedCart[existingItemIndex];
      updatedCart[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
    } else {
      updatedCart = [...currentState, CartItem(product: product)];
    }

    state = updatedCart;
    _saveCart(updatedCart);
  }

  void removeProduct(int productId) {
    final updatedCart = state
        .where((item) => item.product.id != productId)
        .toList();
    state = updatedCart;
    _saveCart(updatedCart);
  }

  void decrementQuantity(int productId) {
    final currentState = state;
    final existingItemIndex = currentState.indexWhere(
      (item) => item.product.id == productId,
    );

    if (existingItemIndex >= 0) {
      final existingItem = currentState[existingItemIndex];
      if (existingItem.quantity > 1) {
        final List<CartItem> updatedCart = List.from(currentState);
        updatedCart[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity - 1,
        );
        state = updatedCart;
        _saveCart(updatedCart);
      } else {
        removeProduct(productId);
      }
    }
  }

  void clearCart() {
    state = [];
    _saveCart([]);
  }
}

// 1. Provider for the Cart State (The List of Items)
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

// 2. Provider for the Total Price (Automatically calculates the total)
final cartTotalProvider = Provider<double>((ref) {
  final cartItems = ref.watch(cartProvider);
  double total = 0.0;
  for (final item in cartItems) {
    total += item.product.price * item.quantity;
  }
  return total;
});
