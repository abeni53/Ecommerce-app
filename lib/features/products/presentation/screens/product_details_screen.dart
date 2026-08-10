import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/product.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../providers/wishlist_provider.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch AI Recommendations based on this product's category!
    final recommendationsAsync = ref.watch(recommendationsProvider(product.category));
    final isFavorite = ref.watch(wishlistProvider).any((p) => p.id == product.id);
    
    // Fallback to thumbnail if images array is somehow empty
    final displayImages = product.images.isNotEmpty ? product.images : [product.thumbnail];

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              ref.read(wishlistProvider.notifier).toggleFavorite(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFavorite ? 'Removed from Wishlist' : 'Added to Wishlist'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Carousel ---
            Container(
              width: double.infinity,
              height: 350,
              color: Colors.white,
              child: PageView.builder(
                itemCount: displayImages.length,
                itemBuilder: (context, index) {
                  final imgUrl = displayImages[index];
                  Widget imageWidget = InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.network(
                      imgUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                    ),
                  );

                  // Only apply Hero to the first image so the flight transition works perfectly!
                  if (index == 0) {
                    imageWidget = Hero(
                      tag: 'product_image_${product.id}',
                      child: imageWidget,
                    );
                  }
                  return imageWidget;
                },
              ),
            ),
            
            // --- Product Info ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // --- Star Rating & Price Row ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' (${product.reviews.length} reviews)',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // --- CUSTOMER REVIEWS SECTION ---
            if (product.reviews.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Customer Reviews',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(), // let SingleChildScrollView handle scroll
                shrinkWrap: true,
                itemCount: product.reviews.length,
                itemBuilder: (context, index) {
                  final review = product.reviews[index];
                  return Container(
                    margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.deepPurple.withAlpha(50),
                              child: Text(review.reviewerName[0], style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            Row(
                              children: List.generate(5, (starIndex) {
                                return Icon(
                                  starIndex < review.rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(review.comment, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // --- AI RECOMMENDATIONS ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'You Might Also Like',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            recommendationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Center(child: Text('Failed to load recommendations')),
              data: (relatedProducts) {
                // Filter out the product we are currently looking at!
                final filtered = relatedProducts.where((p) => p.id != product.id).toList();
                
                if (filtered.isEmpty) return const SizedBox.shrink();

                return SizedBox(
                  height: 200, // Slightly taller to fit shadows
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final rec = filtered[index];
                      return GestureDetector(
                        onTap: () => context.push('/product', extra: rec),
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(bottom: 12), // Room for shadow
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                                BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                                )
                            ]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Container(
                                  height: 100,
                                  width: double.infinity,
                                  color: Colors.white,
                                  child: Image.network(rec.thumbnail, fit: BoxFit.cover),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rec.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '\$${rec.price}',
                                      style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

          ],
        ),
      ).animate().fade(duration: 400.ms).slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutQuad),
      
      // --- Sticky Bottom Add To Cart Bar ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            onPressed: () {
              ref.read(cartProvider.notifier).addProduct(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.title} added to cart!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: const Text(
              'Add to Cart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
