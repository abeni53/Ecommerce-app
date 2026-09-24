import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ecommerce_app/core/error/error_mapper.dart';
import 'package:ecommerce_app/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final options = RequestOptions(path: '/products');

  DioException dioError(
    DioExceptionType type, {
    int? statusCode,
    Object? cause,
  }) {
    return DioException(
      requestOptions: options,
      type: type,
      error: cause,
      response: statusCode == null
          ? null
          : Response<dynamic>(requestOptions: options, statusCode: statusCode),
    );
  }

  group('mapExceptionToFailure', () {
    test('maps every timeout type to TimeoutFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(mapExceptionToFailure(dioError(type)), isA<TimeoutFailure>());
      }
    });

    test('maps connectionError to NoConnectionFailure', () {
      expect(
        mapExceptionToFailure(dioError(DioExceptionType.connectionError)),
        isA<NoConnectionFailure>(),
      );
    });

    test(
      'maps an unknown Dio error wrapping a SocketException to NoConnection',
      () {
        expect(
          mapExceptionToFailure(
            dioError(
              DioExceptionType.unknown,
              cause: const SocketException('no route'),
            ),
          ),
          isA<NoConnectionFailure>(),
        );
      },
    );

    test('maps 401 and 403 to UnauthorisedFailure', () {
      for (final code in [401, 403]) {
        expect(
          mapExceptionToFailure(
            dioError(DioExceptionType.badResponse, statusCode: code),
          ),
          isA<UnauthorisedFailure>(),
        );
      }
    });

    test('maps 404 to NotFoundFailure carrying the resource name', () {
      final failure = mapExceptionToFailure(
        dioError(DioExceptionType.badResponse, statusCode: 404),
        resource: 'category',
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, contains('category'));
    });

    test('maps 5xx to ServerFailure carrying the status code', () {
      final failure = mapExceptionToFailure(
        dioError(DioExceptionType.badResponse, statusCode: 503),
      );

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 503);
    });

    test('maps parsing problems to ParsingFailure', () {
      expect(
        mapExceptionToFailure(const FormatException('bad json')),
        isA<ParsingFailure>(),
      );
    });

    test('maps bare SocketException and TimeoutException', () {
      expect(
        mapExceptionToFailure(const SocketException('down')),
        isA<NoConnectionFailure>(),
      );
      expect(
        mapExceptionToFailure(TimeoutException('slow')),
        isA<TimeoutFailure>(),
      );
    });

    test('falls back to UnknownFailure', () {
      expect(mapExceptionToFailure(StateError('boom')), isA<UnknownFailure>());
    });

    test('passes an existing Failure through unchanged', () {
      const original = ServerFailure(500);
      expect(mapExceptionToFailure(original), same(original));
    });
  });

  group('retryability', () {
    test('transient failures are retryable', () {
      expect(const TimeoutFailure().isRetryable, isTrue);
      expect(const NoConnectionFailure().isRetryable, isTrue);
      expect(const ServerFailure(500).isRetryable, isTrue);
    });

    test('retrying these could never help', () {
      expect(const UnauthorisedFailure().isRetryable, isFalse);
      expect(const NotFoundFailure('product').isRetryable, isFalse);
      expect(const ParsingFailure().isRetryable, isFalse);
    });
  });

  group('messages', () {
    test('never leak a class name or stack trace to the user', () {
      const failures = <Failure>[
        NoConnectionFailure(),
        TimeoutFailure(),
        UnauthorisedFailure(),
        NotFoundFailure('product'),
        ServerFailure(500),
        ParsingFailure(),
        UnknownFailure(),
      ];

      for (final failure in failures) {
        expect(failure.message, isNotEmpty);
        expect(failure.message, isNot(contains('Exception')));
        expect(failure.message, isNot(contains('DioException')));
        expect(failure.message, isNot(contains('#0')));
      }
    });
  });
}
