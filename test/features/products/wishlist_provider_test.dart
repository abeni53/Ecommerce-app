import 'package:ecommerce_app/features/products/domain/entities/product.dart';
import 'package:ecommerce_app/features/products/presentation/providers/wishlist_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Product product(int id) => Product(
  id: id,
  title: 'Product $id',
  description: '',
  price: 10,
  thumbnail: '',
  category: 'test',
  rating: 4,
  images: const [],
  reviews: const [],
);

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('starts empty', () {
    expect(makeContainer().read(wishlistProvider), isEmpty);
  });

  test('toggleFavorite adds a product that is not yet saved', () {
    final container = makeContainer();

    container.read(wishlistProvider.notifier).toggleFavorite(product(1));

    expect(container.read(wishlistProvider).single.id, 1);
  });

  test('toggleFavorite removes a product that is already saved', () {
    final container = makeContainer();
    final notifier = container.read(wishlistProvider.notifier);

    notifier.toggleFavorite(product(1));
    notifier.toggleFavorite(product(1));

    expect(container.read(wishlistProvider), isEmpty);
  });

  test('matches on id, not object identity', () {
    final container = makeContainer();
    final notifier = container.read(wishlistProvider.notifier);

    notifier.toggleFavorite(product(1));
    // A different instance representing the same product must still toggle off.
    notifier.toggleFavorite(product(1));

    expect(container.read(wishlistProvider), isEmpty);
  });

  test('keeps unrelated products when removing one', () {
    final container = makeContainer();
    final notifier = container.read(wishlistProvider.notifier);

    notifier.toggleFavorite(product(1));
    notifier.toggleFavorite(product(2));
    notifier.toggleFavorite(product(1));

    expect(container.read(wishlistProvider).single.id, 2);
  });

  test('isFavorite reflects the current list', () {
    final container = makeContainer();
    final notifier = container.read(wishlistProvider.notifier);

    expect(notifier.isFavorite(1), isFalse);
    notifier.toggleFavorite(product(1));
    expect(notifier.isFavorite(1), isTrue);
    expect(notifier.isFavorite(2), isFalse);
  });

  test('assigns a new list rather than mutating in place', () {
    final container = makeContainer();
    final notifier = container.read(wishlistProvider.notifier);

    notifier.toggleFavorite(product(1));
    final first = container.read(wishlistProvider);

    notifier.toggleFavorite(product(2));
    final second = container.read(wishlistProvider);

    expect(identical(first, second), isFalse);
    expect(first, hasLength(1));
  });
}
