import '../../domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.rating,
    required super.comment,
    required super.reviewerName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      reviewerName: json['reviewerName'] ?? 'Anonymous',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'reviewerName': reviewerName,
    };
  }
}
