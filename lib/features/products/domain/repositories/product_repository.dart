import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<List<Product>> searchProducts(String query);
  Future<List<Product>> getProductsByCategory(String category);
  Future<List<String>> getCategories();
}
