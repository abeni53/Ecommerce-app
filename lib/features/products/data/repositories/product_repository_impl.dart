import 'package:dio/dio.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final Dio dio;

  ProductRepositoryImpl({required this.dio});

  @override
  Future<List<Product>> getProducts() async {
    try {
      final response = await dio.get('https://dummyjson.com/products');
      final List<dynamic> data = response.data['products'];
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await dio.get('https://dummyjson.com/products/search?q=$query');
      final List<dynamic> data = response.data['products'];
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await dio.get('https://dummyjson.com/products/category/$category');
      final List<dynamic> data = response.data['products'];
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response = await dio.get('https://dummyjson.com/products/categories');
      // The API returns a list of objects like {"slug": "beauty", "name": "Beauty", "url": "..."}
      final List<dynamic> data = response.data;
      return data.map((json) => json['slug'] as String).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }
}
