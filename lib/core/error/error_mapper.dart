import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'failures.dart';

/// The single place in the app that knows Dio exists.
///
/// Repositories funnel every caught exception through here, so the
/// presentation layer only ever sees a [Failure]. Swapping Dio for another
/// HTTP client means changing this function and nothing else.
Failure mapExceptionToFailure(Object error, {String resource = 'item'}) {
  if (error is Failure) return error;

  if (error is DioException) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const TimeoutFailure(),
      DioExceptionType.connectionError => const NoConnectionFailure(),
      DioExceptionType.badResponse => _fromStatusCode(
        error.response?.statusCode,
        resource,
      ),
      // Dio reports a lost socket as `unknown`, so inspect the cause.
      DioExceptionType.unknown when error.error is SocketException =>
        const NoConnectionFailure(),
      _ => const UnknownFailure(),
    };
  }

  if (error is SocketException) return const NoConnectionFailure();
  if (error is TimeoutException) return const TimeoutFailure();
  // A shape mismatch in JSON surfaces as one of these.
  if (error is FormatException ||
      error is TypeError ||
      error is NoSuchMethodError) {
    return const ParsingFailure();
  }

  return const UnknownFailure();
}

Failure _fromStatusCode(int? code, String resource) => switch (code) {
  401 || 403 => const UnauthorisedFailure(),
  404 => NotFoundFailure(resource),
  final int c when c >= 500 => ServerFailure(c),
  _ => const UnknownFailure(),
};
