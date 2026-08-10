import 'review.dart';

class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final String thumbnail;
  final String category;
  final double rating;
  final List<String> images;
  final List<Review> reviews;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.thumbnail,
    required this.category,
    required this.rating,
    required this.images,
    required this.reviews,
  });
}
