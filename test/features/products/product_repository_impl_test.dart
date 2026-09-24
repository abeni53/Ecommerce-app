import 'package:dio/dio.dart';
import 'package:ecommerce_app/core/error/failures.dart';
import 'package:ecommerce_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ProductRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = ProductRepositoryImpl(dio: dio);
  });

  Response<dynamic> ok(dynamic body) => Response<dynamic>(
    requestOptions: RequestOptions(path: '/'),
    statusCode: 200,
    data: body,
  );

  void stubGet(dynamic Function() answer) {
    when(
      () => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => answer() as Response<dynamic>);
  }

  void stubGetFailure(Object error) {
    when(
      () => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) => Future<Response<dynamic>>.error(error));
  }

  final productJson = {
    'id': 1,
    'title': 'Essence Mascara',
    'description': 'A mascara',
    'price': 9.99,
    'thumbnail': 'https://example.com/t.png',
    'category': 'beauty',
    'rating': 4.5,
    'images': <String>['https://example.com/1.png'],
    'reviews': <dynamic>[],
  };

  group('getProducts', () {
    test('parses the products array into entities', () async {
      stubGet(
        () => ok({
          'products': [productJson],
        }),
      );

      final products = await repository.getProducts();

      expect(products, hasLength(1));
      expect(products.first.title, 'Essence Mascara');
      expect(products.first.price, 9.99);
    });

    test('throws a typed Failure instead of a raw DioException', () async {
      stubGetFailure(
        DioException(
          requestOptions: RequestOptions(path: '/products'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        repository.getProducts(),
        throwsA(isA<NoConnectionFailure>()),
      );
    });

    test('maps a 500 to ServerFailure', () async {
      final options = RequestOptions(path: '/products');
      stubGetFailure(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(requestOptions: options, statusCode: 500),
        ),
      );

      await expectLater(
        repository.getProducts(),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('maps a malformed payload to ParsingFailure', () async {
      // Missing the "products" key entirely.
      stubGet(() => ok({'unexpected': true}));

      await expectLater(
        repository.getProducts(),
        throwsA(isA<ParsingFailure>()),
      );
    });
  });

  group('searchProducts', () {
    test(
      'sends the query as a parameter rather than string concatenation',
      () async {
        stubGet(() => ok({'products': <dynamic>[]}));

        await repository.searchProducts('red shoes');

        final captured = verify(
          () => dio.get<dynamic>(
            captureAny(),
            queryParameters: captureAny(named: 'queryParameters'),
          ),
        ).captured;

        expect(captured[0], 'https://dummyjson.com/products/search');
        expect(captured[1], {'q': 'red shoes'});
      },
    );
  });

  group('getProductsByCategory', () {
    test('reports a 404 as a missing category', () async {
      final options = RequestOptions(path: '/products/category/nope');
      stubGetFailure(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(requestOptions: options, statusCode: 404),
        ),
      );

      await expectLater(
        repository.getProductsByCategory('nope'),
        throwsA(
          isA<NotFoundFailure>().having(
            (f) => f.message,
            'message',
            contains('category'),
          ),
        ),
      );
    });
  });

  group('getCategories', () {
    test('extracts the slug from each category object', () async {
      stubGet(
        () => ok([
          {'slug': 'beauty', 'name': 'Beauty'},
          {'slug': 'furniture', 'name': 'Furniture'},
        ]),
      );

      expect(await repository.getCategories(), ['beauty', 'furniture']);
    });

    test('maps an unexpected shape to ParsingFailure', () async {
      stubGet(() => ok(['beauty', 'furniture']));

      await expectLater(
        repository.getCategories(),
        throwsA(isA<ParsingFailure>()),
      );
    });
  });
}
