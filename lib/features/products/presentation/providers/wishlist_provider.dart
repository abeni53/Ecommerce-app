import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';

class WishlistNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    return [];
  }

  void toggleFavorite(Product product) {
    final currentState = state;
    if (currentState.any((p) => p.id == product.id)) {
      state = currentState.where((p) => p.id != product.id).toList();
    } else {
      state = [...currentState, product];
    }
  }

  bool isFavorite(int productId) {
    return state.any((p) => p.id == productId);
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, List<Product>>(() {
  return WishlistNotifier();
});
