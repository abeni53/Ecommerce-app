import 'package:dio/dio.dart';
import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final Dio dio;

  ProductRepositoryImpl({required this.dio});

  static const _baseUrl = 'https://dummyjson.com';

  @override
  Future<List<Product>> getProducts() {
    return _fetchProducts('$_baseUrl/products', resource: 'product');
  }

  @override
  Future<List<Product>> searchProducts(String query) {
    return _fetchProducts(
      '$_baseUrl/products/search',
      queryParameters: {'q': query},
      resource: 'product',
    );
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) {
    return _fetchProducts(
      '$_baseUrl/products/category/$category',
      resource: 'category',
    );
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response = await dio.get<dynamic>('$_baseUrl/products/categories');
      // The API returns objects like {"slug": "beauty", "name": "Beauty", ...}
      final data = response.data as List<dynamic>;
      return data
          .map((json) => (json as Map<String, dynamic>)['slug'] as String)
          .toList();
    } catch (e) {
      throw mapExceptionToFailure(e, resource: 'category');
    }
  }

  Future<List<Product>> _fetchProducts(
    String url, {
    Map<String, dynamic>? queryParameters,
    required String resource,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        url,
        queryParameters: queryParameters,
      );
      final data = (response.data as Map<String, dynamic>)['products'] as List;
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Catching at the data boundary is fine because the error is converted
      // to a domain Failure instead of a String.
      throw mapExceptionToFailure(e, resource: resource);
    }
  }
}
