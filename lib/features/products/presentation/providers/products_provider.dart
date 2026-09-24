import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

// Typed to the interface, not the implementation, so tests can override it
// with a mock.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProductRepositoryImpl(dio: dio);
});

// Search State Notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// Category State Notifier
class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setCategory(String? category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String?>(() {
      return SelectedCategoryNotifier();
    });

// Categories List Provider
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getCategories();
});

// Main Products Provider (Reactively updates based on search/category!)
class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() {
    final repository = ref.watch(productRepositoryProvider);
    final query = ref.watch(searchQueryProvider);
    final category = ref.watch(selectedCategoryProvider);

    if (query.isNotEmpty) return repository.searchProducts(query);
    if (category != null) return repository.getProductsByCategory(category);
    return repository.getProducts();
  }

  /// Re-runs build(). The previous list stays visible underneath the loading
  /// state, so a retry does not blank the grid.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(
      ProductsNotifier.new,
    );

// Recommendation Provider (Takes a category string and returns products)
final recommendationsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  category,
) async {
  final repository = ref.watch(productRepositoryProvider);
  final products = await repository.getProductsByCategory(category);
  return products;
});
