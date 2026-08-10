import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final productRepositoryProvider = Provider<ProductRepositoryImpl>((ref) {
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
final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String?>(() {
  return SelectedCategoryNotifier();
});

// Categories List Provider
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getCategories();
});

// Main Products Provider (Reactively updates based on search/category!)
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);

  // Simulate slight network delay for animations
  await Future.delayed(const Duration(milliseconds: 300));

  if (query.isNotEmpty) {
    return repository.searchProducts(query);
  } else if (category != null) {
    return repository.getProductsByCategory(category);
  } else {
    return repository.getProducts();
  }
});

// Recommendation Provider (Takes a category string and returns products)
final recommendationsProvider = FutureProvider.family<List<Product>, String>((ref, category) async {
  final repository = ref.watch(productRepositoryProvider);
  final products = await repository.getProductsByCategory(category);
  return products;
});
