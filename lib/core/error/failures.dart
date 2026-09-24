/// Domain-level description of what went wrong.
///
/// `sealed` lets the compiler prove that every switch over a failure is
/// exhaustive — adding a new failure later becomes a compile error in each
/// place that forgot to handle it.
sealed class Failure implements Exception {
  const Failure();

  /// Text shown to the user. Never a class name or a stack trace.
  String get message;

  /// Whether a retry could plausibly succeed.
  bool get isRetryable => true;
}

class NoConnectionFailure extends Failure {
  const NoConnectionFailure();

  @override
  String get message => 'No internet connection. Check your network.';
}

class TimeoutFailure extends Failure {
  const TimeoutFailure();

  @override
  String get message => 'The request took too long. Please try again.';
}

class UnauthorisedFailure extends Failure {
  const UnauthorisedFailure();

  @override
  String get message => 'Your session expired. Please sign in again.';

  @override
  bool get isRetryable => false;
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(this.resource);

  final String resource;

  @override
  String get message => 'We could not find that $resource.';

  @override
  bool get isRetryable => false;
}

class ServerFailure extends Failure {
  const ServerFailure(this.statusCode);

  final int statusCode;

  @override
  String get message => 'Something broke on our side ($statusCode).';
}

/// The response arrived but did not match what the model expected — usually a
/// backend contract change. The user can do nothing about it.
class ParsingFailure extends Failure {
  const ParsingFailure();

  @override
  String get message => 'We received unexpected data. We are on it.';

  @override
  bool get isRetryable => false;
}

class UnknownFailure extends Failure {
  const UnknownFailure();

  @override
  String get message => 'Something went wrong. Please try again.';
}
