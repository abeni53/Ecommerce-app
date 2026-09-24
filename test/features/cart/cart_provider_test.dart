import 'dart:convert';

import 'package:ecommerce_app/features/cart/domain/entities/cart_item.dart';
import 'package:ecommerce_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:ecommerce_app/features/products/domain/entities/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Product product(int id, {double price = 10.0}) => Product(
  id: id,
  title: 'Product $id',
  description: '',
  price: price,
  thumbnail: '',
  category: 'test',
  rating: 4,
  images: const [],
  reviews: const [],
);

void main() {
  // SharedPreferences needs a platform channel; this fakes it in-memory.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('adding items', () {
    test('adds a new product with quantity 1', () {
      final container = makeContainer();

      container.read(cartProvider.notifier).addProduct(product(1));

      final cart = container.read(cartProvider);
      expect(cart, hasLength(1));
      expect(cart.single.product.id, 1);
      expect(cart.single.quantity, 1);
    });

    test(
      'adding the same product increments quantity instead of duplicating',
      () {
        final container = makeContainer();
        final notifier = container.read(cartProvider.notifier);

        notifier.addProduct(product(1));
        notifier.addProduct(product(1));
        notifier.addProduct(product(1));

        final cart = container.read(cartProvider);
        expect(cart, hasLength(1));
        expect(cart.single.quantity, 3);
      },
    );

    test('different products are separate lines', () {
      final container = makeContainer();
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(product(1));
      notifier.addProduct(product(2));

      expect(container.read(cartProvider), hasLength(2));
    });

    test('does not mutate the previous state in place', () {
      final container = makeContainer();
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(product(1));
      final first = container.read(cartProvider);

      notifier.addProduct(product(2));
      final second = container.read(cartProvider);

      // Riverpod compares by identity, so a new list must be assigned.
      expect(identical(first, second), isFalse);
      expect(first, hasLength(1));
    });
  });

  group('removing and decrementing', () {
    test('removeProduct drops the whole line regardless of quantity', () {
      final container = makeContainer();
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(product(1));
      notifier.addProduct(product(1));
      notifier.removeProduct(1);

      expect(container.read(cartProvider), isEmpty);
    });

    test('decrementQuantity reduces the count', () {
      final container = makeContainer();
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(product(1));
      notifier.addProduct(product(1));
      notifier.decrementQuantity(1);

      expect(container.read(cartProvider).single.quantity, 1);
    });

    test('decrementing the last one removes the line entirely', () {
      final container = makeContainer();
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(product(1));
      notifier.decrementQuantity(1);

      expect(container.read(cartProvider), isEmpty);
    });

    test('decrementing a product that is not in the cart is a no-op', () {
      final container = makeContainer();
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(product(1));
      notifier.decrementQuantity(999);

      expect(container.read(cartProvider), hasLength(1));
    });

    test('clearCart empties everything', () {
      final container = makeContainer();
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(product(1));
      notifier.addProduct(product(2));
      notifier.clearCart();

      expect(container.read(cartProvider), isEmpty);
    });
  });

  group('cartTotalProvider', () {
    test('is zero for an empty cart', () {
      expect(makeContainer().read(cartTotalProvider), 0.0);
    });

    test('multiplies price by quantity across lines', () {
      final container = makeContainer();
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(product(1, price: 10));
      notifier.addProduct(product(1, price: 10));
      notifier.addProduct(product(2, price: 5.5));

      expect(container.read(cartTotalProvider), 25.5);
    });

    test('recalculates when the cart changes', () {
      final container = makeContainer();
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(product(1, price: 10));
      expect(container.read(cartTotalProvider), 10);

      notifier.removeProduct(1);
      expect(container.read(cartTotalProvider), 0);
    });
  });

  group('persistence', () {
    test('writes the cart to storage after a change', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();

      container.read(cartProvider.notifier).addProduct(product(1));
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('cart_data');
      expect(stored, isNotNull);
      expect(json.decode(stored!), hasLength(1));
    });

    test('restores a previously saved cart', () async {
      final saved = json.encode([
        CartItem(product: product(7), quantity: 4).toJson(),
      ]);
      SharedPreferences.setMockInitialValues({'cart_data': saved});

      final container = makeContainer();
      container.read(cartProvider);
      await Future<void>.delayed(Duration.zero);

      final cart = container.read(cartProvider);
      expect(cart, hasLength(1));
      expect(cart.single.product.id, 7);
      expect(cart.single.quantity, 4);
    });

    test('serialising a plain domain Product does not throw', () {
      // Regression: toJson used to downcast to ProductModel and crash on a
      // product that came from anywhere other than the API parser.
      expect(() => CartItem(product: product(1)).toJson(), returnsNormally);
    });

    test('recovers from corrupt stored data instead of crashing', () async {
      SharedPreferences.setMockInitialValues({'cart_data': 'not valid json{['});

      final container = makeContainer();
      container.read(cartProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(cartProvider), isEmpty);

      // The bad entry is cleared so it cannot fail again on the next launch.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cart_data'), isNull);
    });
  });
}
