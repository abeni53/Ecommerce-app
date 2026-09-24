import '../../domain/entities/product.dart';
import 'review_model.dart';

class ProductModel extends Product {
  ProductModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.thumbnail,
    required super.category,
    required super.rating,
    required super.images,
    required super.reviews,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      title: json['title'] ?? 'Unknown',
      description: json['description'] ?? 'No description available',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      thumbnail: json['thumbnail'] ?? 'https://via.placeholder.com/150',
      category: json['category'] ?? 'unknown',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
                .map((r) => ReviewModel.fromJson(r))
                .toList()
          : [],
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      thumbnail: product.thumbnail,
      category: product.category,
      rating: product.rating,
      images: product.images,
      reviews: product.reviews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'thumbnail': thumbnail,
      'category': category,
      'rating': rating,
      'images': images,
      // fromEntity rather than a cast: reviews may be plain domain entities.
      'reviews': reviews
          .map((r) => ReviewModel.fromEntity(r).toJson())
          .toList(),
    };
  }
}
