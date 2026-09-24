import 'package:ecommerce_app/core/error/failures.dart';
import 'package:ecommerce_app/features/products/domain/entities/product.dart';
import 'package:ecommerce_app/features/products/domain/repositories/product_repository.dart';
import 'package:ecommerce_app/features/products/presentation/providers/products_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository repository;

  const allProducts = [
    Product(
      id: 1,
      title: 'Mascara',
      description: '',
      price: 9.99,
      thumbnail: '',
      category: 'beauty',
      rating: 4.5,
      images: [],
      reviews: [],
    ),
  ];

  const searchResults = [
    Product(
      id: 2,
      title: 'Red Lipstick',
      description: '',
      price: 4.99,
      thumbnail: '',
      category: 'beauty',
      rating: 4.0,
      images: [],
      reviews: [],
    ),
  ];

  const categoryResults = [
    Product(
      id: 3,
      title: 'Sofa',
      description: '',
      price: 199.0,
      thumbnail: '',
      category: 'furniture',
      rating: 4.2,
      images: [],
      reviews: [],
    ),
  ];

  setUp(() {
    repository = MockProductRepository();
    when(() => repository.getProducts()).thenAnswer((_) async => allProducts);
    when(
      () => repository.searchProducts(any()),
    ).thenAnswer((_) async => searchResults);
    when(
      () => repository.getProductsByCategory(any()),
    ).thenAnswer((_) async => categoryResults);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Keeps the provider alive for the duration of a test. Without a listener
  /// an in-flight provider can be disposed before it settles.
  ProviderSubscription<AsyncValue<List<Product>>> keepAlive(
    ProviderContainer container,
  ) {
    final sub = container.listen(
      productsProvider,
      (_, _) {},
      onError: (_, _) {},
    );
    addTearDown(sub.close);
    return sub;
  }

  group('ProductsNotifier', () {
    test('starts loading', () {
      final container = makeContainer();
      expect(
        container.read(productsProvider),
        isA<AsyncLoading<List<Product>>>(),
      );
    });

    test('fetches all products when there is no query or category', () async {
      final container = makeContainer();
      keepAlive(container);

      expect(await container.read(productsProvider.future), allProducts);
      verify(() => repository.getProducts()).called(1);
      verifyNever(() => repository.searchProducts(any()));
    });

    test('searches when a query is set', () async {
      final container = makeContainer();
      keepAlive(container);
      await container.read(productsProvider.future);

      container.read(searchQueryProvider.notifier).setQuery('lipstick');

      expect(await container.read(productsProvider.future), searchResults);
      verify(() => repository.searchProducts('lipstick')).called(1);
    });

    test('filters by category when one is selected', () async {
      final container = makeContainer();
      keepAlive(container);
      await container.read(productsProvider.future);

      container
          .read(selectedCategoryProvider.notifier)
          .setCategory('furniture');

      expect(await container.read(productsProvider.future), categoryResults);
      verify(() => repository.getProductsByCategory('furniture')).called(1);
    });

    test('a non-empty query wins over a selected category', () async {
      final container = makeContainer();
      keepAlive(container);

      container
          .read(selectedCategoryProvider.notifier)
          .setCategory('furniture');
      container.read(searchQueryProvider.notifier).setQuery('lipstick');

      expect(await container.read(productsProvider.future), searchResults);
      verifyNever(() => repository.getProductsByCategory(any()));
    });

    test('surfaces a repository Failure as error state', () async {
      when(
        () => repository.getProducts(),
      ).thenAnswer((_) => Future.error(const NoConnectionFailure()));

      final container = makeContainer();
      keepAlive(container);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(productsProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NoConnectionFailure>());
    });

    test('refresh() re-queries the repository', () async {
      final container = makeContainer();
      keepAlive(container);
      await container.read(productsProvider.future);

      await container.read(productsProvider.notifier).refresh();

      verify(() => repository.getProducts()).called(2);
    });

    test('refresh() recovers after a failure', () async {
      when(
        () => repository.getProducts(),
      ).thenAnswer((_) => Future.error(const TimeoutFailure()));

      final container = makeContainer();
      keepAlive(container);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(productsProvider).hasError, isTrue);

      // The network comes back.
      when(() => repository.getProducts()).thenAnswer((_) async => allProducts);
      await container.read(productsProvider.notifier).refresh();

      expect(container.read(productsProvider).value, allProducts);
      expect(container.read(productsProvider).hasError, isFalse);
    });

    test('does not hit the repository until something watches it', () {
      makeContainer();
      verifyNever(() => repository.getProducts());
    });
  });
}
