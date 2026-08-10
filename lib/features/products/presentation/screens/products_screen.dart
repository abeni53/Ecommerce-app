import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/products_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all our providers!
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cartItems = ref.watch(cartProvider);
    final themeMode = ref.watch(themeProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => context.push('/profile'),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => context.push('/cart'),
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 48, // Shifted over to make room for profile icon
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cartItems.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // 1. REACTIVE SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                // Instantly update the provider. The GridView will automatically refresh!
                ref.read(searchQueryProvider.notifier).setQuery(value);
                // Clear category if we are searching
                if (value.isNotEmpty) {
                   ref.read(selectedCategoryProvider.notifier).setCategory(null);
                }
              },
            ),
          ),
          
          // 2. CATEGORY CHIPS
          categoriesAsync.when(
            data: (categories) => SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  // "All" chip at index 0
                  if (index == 0) {
                    final isSelected = selectedCategory == null;
                    return ChoiceChip(
                      label: const Text('All'),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(selectedCategoryProvider.notifier).setCategory(null);
                        ref.read(searchQueryProvider.notifier).setQuery(''); // clear search
                      },
                    );
                  }
                  
                  final category = categories[index - 1];
                  final isSelected = selectedCategory == category;
                  
                  return ChoiceChip(
                    label: Text(category.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(selectedCategoryProvider.notifier).setCategory(category);
                      ref.read(searchQueryProvider.notifier).setQuery(''); // clear search
                    },
                  );
                },
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),
          
          const SizedBox(height: 8),

          // 3. PRODUCT GRID
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Error: $error')),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('No products found.', style: TextStyle(fontSize: 18)));
                }

                // Grid responsiveness
                final screenWidth = MediaQuery.of(context).size.width;
                int columns = 2;
                if (screenWidth > 1200) {
                  columns = 5;
                } else if (screenWidth > 900) {
                  columns = 4;
                } else if (screenWidth > 600) {
                  columns = 3;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        context.push('/product', extra: product);
                      },
                      child: Container(
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
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Container(
                                width: double.infinity,
                                color: Colors.white, // keep white background for products
                                child: Hero(
                                  tag: 'product_image_${product.id}',
                                  child: Image.network(
                                    product.thumbnail,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.deepPurple, 
                                    fontWeight: FontWeight.w900, 
                                    fontSize: 16
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      ref.read(cartProvider.notifier).addProduct(product);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${product.title} added to cart!'), duration: const Duration(seconds: 1)),
                                      );
                                    },
                                    child: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 400.ms, delay: (index * 50).ms).slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOutQuad);
                },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
