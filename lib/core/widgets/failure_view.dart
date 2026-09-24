import 'package:flutter/material.dart';

import '../error/error_mapper.dart';
import '../error/failures.dart';

/// The app's single error state widget.
///
/// Takes the raw error from an `AsyncValue` so call sites stay short:
/// `error: (e, _) => FailureView(error: e, onRetry: ...)`.
class FailureView extends StatelessWidget {
  const FailureView({
    super.key,
    required this.error,
    this.onRetry,
    this.onSignIn,
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final VoidCallback? onSignIn;

  /// Tighter layout for inline sections such as a recommendations strip.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final failure = mapExceptionToFailure(error);

    final icon = switch (failure) {
      NoConnectionFailure() => Icons.wifi_off,
      TimeoutFailure() => Icons.hourglass_disabled,
      UnauthorisedFailure() => Icons.lock_outline,
      NotFoundFailure() => Icons.search_off,
      ServerFailure() => Icons.cloud_off,
      ParsingFailure() => Icons.data_object,
      UnknownFailure() => Icons.error_outline,
    };

    final showSignIn = failure is UnauthorisedFailure && onSignIn != null;
    final showRetry = !showSignIn && failure.isRetryable && onRetry != null;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 28 : 48,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: compact ? 6 : 12),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: compact
                  ? Theme.of(context).textTheme.bodySmall
                  : Theme.of(context).textTheme.bodyLarge,
            ),
            if (showSignIn || showRetry) SizedBox(height: compact ? 8 : 16),
            if (showSignIn)
              FilledButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.login),
                label: const Text('Sign in'),
              )
            else if (showRetry)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
          ],
        ),
      ),
    );
  }
}
